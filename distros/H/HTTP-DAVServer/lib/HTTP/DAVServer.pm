#!/Applications/Alloy/Library/bin/perl 

use strict;
use warnings;

package HTTP::DAVServer;

our $VERSION=0.1;

=head1 NAME

HTTP::DAVServer - allows you to write server-side functions to accept, process and respond to WebDAV client requests. WebDAV - RFC 2518 - is a protocol which allows clients to manipulate files on a remote server using HTTP.

=head1 SYNOPSIS

In your favorite NPH CGI script ( for now )

      use HTTP::DAVServer;
      HTTP::DAVServer->handle;

You will need to add directives to Apache to request that certain methods be
handled by the CGI script:

      Script PROPFIND /cgi-bin/nph-webdav
      Script PUT      /cgi-bin/nph-webdav
    
See INSTALL for more details.  See INSTALL for important warning!

=head1 MODULE STATUS

This module is a prototype. Please see INSTALL for important warnings. You should try this module
if you're interested in developing a customized WebDAV server and you want to use Perl to do
most or all of fancy footwork behind the scenes.

My short term goal is to provide a reference implementation of a WebDAV server which can be subclassed
for specific implementation features. Information to resolve any of the following bugs is most welcome! I will
be fixing all the failed items in copymove next.

Litmus test results:

    http and basic tests are good, some errors on copymove and propfind. proppatch not done so skips lots of tests.

    -> running `http':
    0. init.................. pass
    1. begin................. pass
    2. expect100............. pass
    3. finish................ pass
    <- summary for `http': of 4 tests run: 4 passed, 0 failed. 100.0%

    -> running `basic':
    0. init.................. pass
    1. begin................. pass
    2. options............... WARNING: server does not claim Class 2 compliance
     ...................... pass (with 1 warning)
    3. put_get............... pass
    4. put_get_utf8_segment.. pass
    5. mkcol_over_plain...... pass
    6. delete................ pass
    7. delete_null........... pass
    8. mkcol................. pass
    9. mkcol_again........... pass
    10. delete_coll........... pass
    11. mkcol_no_parent....... pass
    12. mkcol_with_body....... pass
    13. finish................ pass
    <- summary for `basic': of 14 tests run: 14 passed, 0 failed. 100.0%
    -> 1 warning was issued.

    -> running `copymove':
     0. init.................. pass
     1. begin................. pass
     2. copy_init............. pass
     3. copy_simple........... FAIL 
     4. copy_overwrite........ WARNING: COPY-on-existing fails with 412
        ...................... FAIL 
     5. copy_cleanup.......... pass
     6. copy_coll............. FAIL 
     7. move.................. FAIL 
     8. move_coll............. FAIL 
     9. move_cleanup.......... pass
    10. finish................ pass
    <- summary for `copymove': of 11 tests run: 6 passed, 5 failed. 54.5%
    -> 1 warning was issued.

    -> running `props':
     0. init.................. pass
     1. begin................. pass
     2. propfind_invalid...... pass
     3. propfind_invalid2..... pass
     4. propfind_d0........... FAIL (No responses returned)
     5. propinit.............. pass
     6. propset............... FAIL (PROPPATCH on `/litmus/litmus/prop': 400 Bad Request)
     7. propget............... SKIPPED
     8. propmove.............. SKIPPED
     9. propget............... SKIPPED
    10. propdeletes........... SKIPPED
    11. propget............... SKIPPED
    12. propreplace........... SKIPPED
    13. propget............... SKIPPED
    14. propnullns............ SKIPPED
    15. propget............... SKIPPED
    16. prophighunicode....... SKIPPED
    17. propget............... SKIPPED
    18. propvalnspace......... SKIPPED
    19. propwformed........... pass
    20. propinit.............. pass
    21. propmanyns............ FAIL (PROPPATCH on `/litmus/litmus/prop': 400 Bad Request)
    22. propget............... FAIL (PROPFIND on `/litmus/litmus/prop': 400 Bad Request)
    23. propcleanup........... pass
    24. finish................ pass
    -> 12 tests were skipped.
    <- summary for `props': of 13 tests run: 9 passed, 4 failed. 69.2%

=head1 DEPENDENCIES

This code requires:

  XML::Simple
  XML::SAX     (for namespace support in XML::Simple)
  DateTime     (THE new Date and Time support in Perl)

=cut


use CGI         qw();

use XML::Simple qw(); 
use DateTime    qw();

sub dateEpoch { DateTime->from_epoch( epoch =>$_[0] )->iso8601 }

    our $WARN  =1;
    our $TRACE =1;
    our $PUBLIC=1;

use HTTP::DAVServer::AuthDigest qw();

our ($ROOT, $HOST) = ("", "");

sub handle {

    my $self=shift;

    if ($TRACE) {
        eval "use Data::Dumper;";
        no warnings;
        $Data::Dumper::Indent=1;
        $Data::Dumper::Sortkeys=1;
    }

    $ROOT=$ENV{'DOCUMENT_ROOT'};
    $ROOT  =~ s#/+$##;
    $HOST  =$ENV{'HTTP_HOST'};

    my $r=new CGI;
    my $method =$r->request_method;
    my $contLen=$ENV{'CONTENT_LENGTH'} || 0;

    my $responder="${self}::Respond";
    eval "use $responder";
    die "LOADRESPOND error $@\n" if $@;

    $responder->badRequest($r, "NOHANDLE", $method) unless $responder->handles( $method );

    $responder->badRequest($r, "MISSCONT") if $responder->hasContent( $method ) == 1 && $contLen == 0;
    if ($responder->hasContent( $method ) == 0 && $contLen != 0) {
        $method eq "MKCOL" && $responder->unsupported($r);
        $responder->badRequest($r, "HASCONT" );
    }

    $responder->challenge($r)  unless $PUBLIC 
                                      || $ENV{'REMOTE_USER'} 
                                      || HTTP::DAVServer::AuthDigest::authenticate( sub { return $_[0] } ); 

    my $request={};
    if ($contLen && $method ne "PUT") {

        $responder->badRequest($r) unless $r->content_type eq "text/xml";

        $request = eval {

            if ($TRACE) {
                local undef $/;
                my $xmlin=<>;
                warn "REQUEST XML:\n$xmlin\n";
                XML::Simple::XMLin( $xmlin, nsexpand => 1 );
            } else {
                XML::Simple::XMLin( "-", nsexpand => 1 );
            }

        };

        $responder->badRequest($r, "BADXML", $@) if $@;


    }

    warn ("ENV: ", Dumper (\%ENV), "METHOD: $method\nSUBMITTED XML: ", Dumper ($request)) if $TRACE;

    my $url=CGI::Util::unescape($ENV{'REQUEST_URI'});
    $url=~s#/+$##;

    eval "use ${self}::$method";
    $responder->serverError( $r, "LOAD$method", $@ ) if $@;
    "${self}::$method"->handle( $r, $url, $responder, $request ); 

}

=head1 SUPPORT

For technical support please email to jlawrenc@cpan.org ... 
for faster service please include "HTTP::DAVServer" and "help" in your subject line.

=head1 AUTHOR

 Jay J. Lawrence - jlawrenc@cpan.org
 Infonium Inc., Canada
 http://www.infonium.ca/

=head1 COPYRIGHT

Copyright (c) 2003 Jay J. Lawrence, Infonium Inc. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

Thank you to the authors of my prequisite modules. With out your help this code
would be much more difficult to write!

 XML::Simple - Grant McLean
 XML::SAX    - Matt Sergeant
 DateTime    - Dave Rolsky

Also the authors of litmus, a very helpful tool indeed!

=head1 SEE ALSO

HTTP::DAV, HTTP::Webdav, http://www.webdav.org/, RFC 2518

=cut

1;
