package Mail::Decency::ContentFilter::Core::Constants;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use strict;
use warnings;


=head1 NAME

Mail::Decency::ContentFilter::Core::Constants

=head1 DESCRIPTION

Constants for usage in conten filter API

=cut

use base qw/ Exporter /;
our @EXPORT = qw/
    CF_FILTER_OK
    CF_FILE_TO_BIG
    CF_FILTER_DONT_HANDLE
    CF_FOUND_SPAM
    CF_FOUND_VIRUS
    CF_FINAL_OK
    CF_FINAL_BOUNCE
    CF_FINAL_ERROR
    CF_FINAL_DELETED
    CRLF
/;


=head1 CONSTANTS

=head2 CF_FILTER_OK

=head2 CF_FILE_TO_BIG

=head2 CF_FILTER_DONT_HANDLE

=head2 CF_FOUND_SPAM

=head2 CF_FOUND_VIRUS

=head2 CF_FINAL_OK

=head2 CF_FINAL_ERROR

=head2 CF_FINAL_DELETED

=head2 CRLF

=cut

use constant CF_FILTER_OK => 100;
use constant CF_FILE_TO_BIG => 101;
use constant CF_FILTER_DONT_HANDLE => 102;
use constant CF_FOUND_SPAM => 103;
use constant CF_FOUND_VIRUS => 104;
use constant CF_FINAL_OK => 105;
use constant CF_FINAL_BOUNCE => 106;
use constant CF_FINAL_ERROR => 106;
use constant CF_FINAL_DELETED => 107;
use constant CRLF => qq[\x0D\x0A]; # RFC 2821, 2.3.7



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut



1;
