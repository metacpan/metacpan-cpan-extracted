package Log::Any::For::LWP;

our $DATE = '2015-08-17'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Net::HTTP::Methods::Patch::LogRequest    qw();
use LWP::UserAgent::Patch::LogRequestContent qw();
use LWP::UserAgent::Patch::LogResponse       qw();

my %opts;

sub import {
    my $self = shift;
    %opts = @_;
    $opts{-log_request_header}   //= 1;
    $opts{-log_request_body}     //= 0;
    $opts{-log_response_header}  //= 1;
    $opts{-log_response_body}    //= 0;
    $opts{-decode_response_body} //= 1;

    Net::HTTP::Methods::Patch::LogRequest->import()
          if $opts{-log_request_header};
    LWP::UserAgent::Patch::LogRequestContent->import()
          if $opts{-log_request_body};
    LWP::UserAgent::Patch::LogResponse->import(
        -warn_target_loaded   => 0,
        -log_response_header  => $opts{-log_response_header},
        -log_response_body    => $opts{-log_response_body},
        -decode_response_body => $opts{-decode_response_body},
    );
}

sub unimport {
    LWP::UserAgent::Patch::LogResponse->unimport();
    LWP::UserAgent::Patch::LogRequestContent->unimport()
          if $opts{-log_request_body};
    Net::HTTP::Methods::Patch::LogRequest->unimport()
          if $opts{-log_request_header};
}

1;
# ABSTRACT: Add logging to LWP

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::For::LWP - Add logging to LWP

=head1 VERSION

This document describes version 0.06 of Log::Any::For::LWP (from Perl distribution Log-Any-For-LWP), released on 2015-08-17.

=head1 SYNOPSIS

 use Log::Any::For::LWP
     -log_request_header   => 1, # optional, default 1 (turn on Net::HTTP::Methods::Patch::LogRequest)
     -log_request_body     => 1, # optional, default 0 (turn on LWP::UserAgent::Patch::LogRequestContent)
     -log_response_header  => 1, # optional, default 1 (turn on LWP::UserAgent::Patch::LogResponse)
     -log_response_body    => 1, # optional, default 0 (turn on LWP::UserAgent::Patch::LogResponse)
     -decode_response_body => 1, # optional, default 1 (passed to LWP::UserAgent::Patch::LogResponse)
 ;

Sample script and output:

 % TRACE=1 perl -MLog::Any::App -MLog::Any::For::LWP -MLWP::Simple \
   -e'get "http://www.google.com/"'
 [36] HTTP request (proto=http, len=134):
 GET / HTTP/1.1
 TE: deflate,gzip;q=0.3
 Connection: TE, close
 Host: www.google.com
 User-Agent: LWP::Simple/6.00 libwww-perl/6.04

 [79] HTTP response header:
 302 Moved Temporarily
 Cache-Control: private
 Connection: close
 Date: Tue, 17 Jul 2012 04:39:10 GMT
 ...

 [81] HTTP request (proto=http, len=136):
 GET / HTTP/1.1
 TE: deflate,gzip;q=0.3
 Connection: TE, close
 Host: www.google.co.id
 User-Agent: LWP::Simple/6.00 libwww-perl/6.04

 [190] HTTP response header:
 200 OK
 Cache-Control: private, max-age=0
 Connection: close
 Date: Tue, 17 Jul 2012 04:39:10 GMT
 ...

=head1 DESCRIPTION

This module just bundles L<Net::HTTP::Methods::Patch::LogRequest>,
L<LWP::UserAgent::Patch::LogRequestContent>, and
L<LWP::UserAgent::Patch::LogResponse> together.

Response body is dumped to a separate category. It is recommended that you dump
this to a directory, for convenience. See the documentation of
L<LWP::UserAgent::Patch::LogResponse> for more details.

=for Pod::Coverage ^(unimport)$

=head1 SEE ALSO

L<Log::Any>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-For-LWP>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Log-Any-For-LWP>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-For-LWP>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
