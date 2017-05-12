package Mail::Decency::Helper::IP;

use strict;
use warnings;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use base qw/ Exporter /;
our @EXPORT_OK = qw/
    is_local_host
/;

=head1 NAME

Mail::Decency::Helper::IP

=head1 DESCRIPTION

Helper for everything about ips ..

=cut

sub is_local_host {
    my ( $ip ) = @_;
    return index( $ip, '127.' ) == 0 || $ip eq '::1';
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
