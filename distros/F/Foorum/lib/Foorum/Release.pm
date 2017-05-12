package Foorum::Release;

use strict;
use warnings;

our $VERSION = '1.001000';

use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/get_version bump_up_version/;

sub get_version {
    return $VERSION;
}

sub bump_up_version {
    my ($version) = shift;

    $version = get_version() unless ( defined $version );

    # like 0.003001
    my ( $v1, $v2, $v3 ) = ( $version =~ /^(\d+)\.00(\d)00(\d)$/ );
    my $num = $v1 * 100 + $v2 * 10 + $v3;
    $num++;
    $v3 = chop($num);
    $v2 = chop($num);
    $v1 = $num || 0;
    return sprintf( "%d.%03d%03d", $v1, $v2, $v3 );
}

1;
__END__

=pod

=head1 NAME

Foorum::Release - Utils for Release

=head1 FUNCTIONS

=over 4

=item get_version

get the recent $VERSION for Foorum

=item bump_up_version

return the value of $VERSION++

=back

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
