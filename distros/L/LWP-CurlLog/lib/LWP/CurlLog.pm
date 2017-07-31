package LWP::CurlLog;
use strict;
use warnings;
use LWP::UserAgent ();

our $VERSION = "0.02";
our $log_file ||= "~/curl.log";
our $log_output = defined $log_output ? $log_output : 1;
our $curl_options = defined $curl_options ? $curl_options : "-k";
our $logfh = undef;

no strict "refs";
no warnings "redefine";

my $orig_sub = \&LWP::UserAgent::send_request;
*{"LWP::UserAgent::send_request"} = sub {
    my ($self, $request) = @_;

    open_log();
    my $cmd = "curl ";
    my $url = $request->uri();
    if ($url =~ /[=&;?]/) {
        $cmd .= "\"$url\" ";
    }
    else {
        $cmd .= "$url "
    }
    if ($curl_options) {
        $cmd .= "$curl_options ";
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

    print $logfh "# " . localtime() . " LWP request\n";
    print $logfh "$cmd\n";
    my $response = $orig_sub->(@_);

    if ($log_output) {
        print $logfh "# " . localtime() . " LWP response\n";
        print $logfh $response->as_string . "\n";
    }

    return $response;
};

sub open_log {
    if ($logfh) {
        return;
    }
    if ($log_file eq "STDOUT") {
        $logfh = \*STDOUT;
    }
    elsif ($log_file eq "STDERR") {
        $logfh = \*STDERR;
    }
    elsif ($log_file =~ m{^~/}) {
        my $home = (getpwuid($>))[7];
        $log_file =~ s{^~/}{$home/};
        open $logfh, ">>", $log_file or die "Can't open $log_file: $!";
    }
    else {
        open $logfh, ">>", $log_file or die "Can't open $log_file: $!";
    }
    select($logfh);
    $| = 1;
    select(STDOUT);
}

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
your perl script and then check the log file for curl commands. The
default log file location is in ~/curl.log, but you can change it
by setting the $log_file package variable in a begin block before
including the library.

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

