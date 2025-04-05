package LWP::CurlLog;
use strict;
use warnings;

BEGIN {
    eval {
        require LWP::UserAgent;
    };
    eval {
        require HTTP::Tiny;
    };
}

our $VERSION = "0.04";
our %opts = (
    file => undef,
    response => 1,
    options => "-k",
    timing => 0,
    trace => 0,
);

sub import {
    my ($package, %args) = @_;
    for my $key (keys %args) {
        $opts{$key} = $args{$key};
    }

    if (!$opts{file}) {
        $opts{fh} = \*STDERR;
    }
    else {
        my $expanded_file = $opts{file};
        if ($expanded_file =~ m{^~/}) {
            my $home = $ENV{HOME} || (getpwuid($<))[7];
            $expanded_file =~ s{^~/}{$home/};
        }
        open $opts{fh}, ">>", $expanded_file or die "Can't open $opts{file}: $!";
    }
    select($opts{fh});
    $| = 1;
    select(STDOUT);
}

no strict "refs";
no warnings "redefine";

my $orig_lusr = \&LWP::UserAgent::send_request;
*{"LWP::UserAgent::send_request"} = sub {
    my ($self, $req) = @_;
    my $headers = {};
    for my $name ($req->headers()->header_field_names()) {
        $headers->{$name} = $req->{headers}{$name};
    }
    my $content = $req->decoded_content();
    my $res = request("LWP", $orig_lusr, \@_, $req->method(), $req->uri(), $headers, $content);
    return $res;
};

my $orig_htr = \&HTTP::Tiny::_request;
*{"HTTP::Tiny::_request"} = sub {
    my ($self, $method, $url, $args) = @_;
    my $res = request("HT", $orig_htr, \@_, $method, $url, $args->{headers}, $args->{content});
    return $res;
};

sub request {
    my ($module, $orig_sub, $orig_args, $method, $url, $headers, $content) = @_;

    my $cmd = "curl ";
    if ($url =~ /[=&;?]/) {
        $cmd .= "\"$url\" ";
    }
    else {
        $cmd .= "$url ";
    }
    if ($opts{options}) {
        $cmd .= "$opts{options} ";
    }

    if ($method && ($method ne "GET" || length $content)) {
        $cmd .= "-X $method ";
    }

    for my $name (keys %$headers) {
        if ($name =~ /^(Content-Length|User-Agent)$/i) {
            next;
        }
        my $value = $headers->{$name};
        $value =~ s{([\\\$"])}{\\$1}g;
        $cmd .= "-H \"$name: $value\" ";
    }

    if (defined $content && length $content) {
        $content =~ s{([\\\$"])}{\\$1}g;
        $cmd .= "-d \"$content\" ";
    }
    $cmd =~ s/\s*$//;

    log_print("# " . localtime() . " $module request\n");
    log_print_stack();
    log_print("$cmd\n");
    my $time1 = time();
    my $res = $orig_sub->(@$orig_args);
    my $time2 = time();

    if ($opts{response}) {
        log_print("\n# " . localtime() . " $module response\n");
        my $str;
        if (eval {$res->isa("HTTP::Response")}) {
            $str = $res->as_string();
        }
        else {
            $str = "$res->{protocol} $res->{status} $res->{reason}\n";
            for my $name (keys %{$res->{headers}}) {
                $str .= "$name: $res->{headers}{$name}\n";
            }
            $str .= "\n";
            $str .= $res->{content};
        }
        $str =~ s/\s*$//g;
        log_print("$str\n");
    }
    if ($opts{timing}) {
        my $diff = $time2 - $time1;
        log_print("# ${diff}s\n");
    }

    log_print("\n");

    return $res;
}

sub log_print {
    my (@args) = @_;
    my $mesg = join("", @args);
    print {$opts{fh}} $mesg;
}


sub log_print_stack {
    my @callers;
    for (my $i = 0; my @caller = caller($i); $i++) {
        push @callers, \@caller;
    }

    my @filtered_callers;
    CALLER: for my $caller (reverse @callers) {
        my ($package, $file, $line, $long_name) = @$caller;
        for my $test_package ("LWP::CurlLog", "HTTP::Tiny", "HTTP::AnyUA", "LWP::UserAgent") {
            if ($package =~ /^${test_package}($|::)/) {
                last CALLER;
            }
        }
        push @filtered_callers, $caller;

    }
    if (!$opts{trace}) {
        @filtered_callers = ($filtered_callers[-1]);
    }

    for my $caller (@filtered_callers) {
        my ($package, $file, $line, $long_name) = @$caller;
        my $name = $long_name;
        $name =~ s/.*:://;
        log_print("#     $name $file $line\n");
    }
}

1;

__END__

=encoding utf8

=head1 NAME

LWP::CurlLog - Log LWP::UserAgent / HTTP::Tiny requests as curl commands

=head1 SYNOPSIS

    use LWP::CurlLog;

=head1 DESCRIPTION

This module can be used to log LWP::UserAgent or HTTP::Tiny requests as curl
commands so you can redo requests the perl script makes, manually, on the
command line. Just include a statement "use LWP::CurlLog;" to the top of your
perl script and then check the output for curl commands.

The default location is to STDERR, but you can change it
by setting the file option on the use line like this:

    use LWP::CurlLog file => "~/curl.log";

The log will include the response in it's output. If that's unwanted,
do this:

    use LWP::CurlLog response => 0;

You can include timing information like this:

    use LWP::CurlLog timing => 1;

=head1 METACPAN

L<https://metacpan.org/pod/LWP::CurlLog>

=head1 REPOSITORY

L<https://github.com/zorgnax/lwpcurllog>

=head1 AUTHOR

Jacob Gelbman, E<lt>gelbman@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jacob Gelbman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

