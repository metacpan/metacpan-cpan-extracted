package LWP::CurlLog;
use strict;
use warnings;
use LWP::UserAgent ();

our $VERSION = "0.03";
our %opts = (
    file => undef,
    response => 1,
    options => "-k",
    timing => 0,
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
        my $file2 = $opts{file};
        if ($file2 =~ m{^~/}) {
            my $home = $ENV{HOME} || (getpwuid($<))[7];
            $file2 =~ s{^~/}{$home/};
        }
        open $opts{fh}, ">>", $file2 or die "Can't open $opts{file}: $!";
    }
    select($opts{fh});
    $| = 1;
    select(STDOUT);
}

no strict "refs";
no warnings "redefine";

my $orig_sub = \&LWP::UserAgent::send_request;
*{"LWP::UserAgent::send_request"} = sub {
    my ($self, $request) = @_;

    my $cmd = "curl ";
    my $url = $request->uri();
    if ($url =~ /[=&;?]/) {
        $cmd .= "\"$url\" ";
    }
    else {
        $cmd .= "$url "
    }
    if ($opts{options}) {
        $cmd .= "$opts{options} ";
    }
    if ($request->method() && ($request->method() ne "GET" || $request->content_length())) {
        $cmd .= "-X " . $request->method() . " ";
    }
    for my $header ($request->header_field_names) {
        if ($header =~ /^(Content-Length|User-Agent)$/i) {
            next;
        }
        my $value = $request->header($header);
        $value =~ s{([\\\$"])}{\\$1}g;
        $cmd .= "-H \"$header: $value\" ";
    }
    if ($request->header("Content-Length")) {
        my $content = $request->decoded_content();
        $content =~ s{([\\\$"])}{\\$1}g;
        $cmd .= "-d \"$content\" ";
    }
    $cmd =~ s/\s*$//;

    print {$opts{fh}} "# " . localtime() . " LWP request\n";
    print {$opts{fh}} "$cmd\n";
    my $time1 = time();
    my $response = $orig_sub->(@_);
    my $time2 = time();

    if ($opts{response}) {
        print {$opts{fh}} "\n# " . localtime() . " LWP response\n";
        my $response2 = $response->as_string;
        $response2 =~ s/\s*$//g;
        print {$opts{fh}} "$response2\n";
    }
    if ($opts{timing}) {
        my $diff = $time2 - $time1;
        print {$opts{fh}} "# ${diff}s\n";
    }

    print {$opts{fh}} "\n";

    return $response;
};

1;

__END__

=encoding utf8

=head1 NAME

LWP::CurlLog - Log LWP requests as curl commands

=head1 SYNOPSIS

    use LWP::CurlLog;

=head1 DESCRIPTION

This module can be used to log LWP requests as curl commands so you
can redo requests the perl script makes, manually, on the command
line. Just include a statement "use LWP::CurlLog;" to the top of
your perl script and then check the output for curl commands.

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

