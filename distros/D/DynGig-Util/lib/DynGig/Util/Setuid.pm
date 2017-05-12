=head1 NAME

DynGig::Util::Setuid - Become a user by Setting uid/gid or invoking sudo

=cut
package DynGig::Util::Setuid;

use warnings;
use strict;
use Carp;

=head1 SYNOPSIS

 use DynGig::Util::Setuid;

 my ( $uid, $gid ) = DynGig::Util::Setuid->setuidgid( 'joe' );

 DynGig::Util::Setuid->sudo( 'root' );

=head1 DESCRIPTION

=head2 setuidgid( user )

(As superuser) sets uid, gid, effective uid, and effective gid as those
of 'user'. Returns an the uid and gid of the target user in list context,
or an ARRAY reference in scalar context.

=cut
sub setuidgid
{
    my ( $class, $user ) = @_;

    return undef unless my @pw = getpwnam( $user ||= 'root' );

    my @id = map { sprintf '%d', $_ } @pw[2,3];
    my $self = ( getpwuid $< )[0];

    if ( $user ne $self )
    {
        ( $<, $>, $(, $) ) = ( $id[0], @id, join ' ', $id[1], $id[1] );
        return undef if $> != $id[0];
    }

    return wantarray ? @id : \@id;
}

=head2 sudo( user )

Invokes system sudo. Becomes 'root' if user is not specified.

=cut
sub sudo
{
    my ( $class, $user ) = @_;
    my $self = ( getpwuid $< )[0];
 
    return $self if $self eq ( $user ||= 'root' );

    warn "$self: need '$user' priviledge, invoking sudo.\n";
    croak "exec $0: $!" unless exec 'sudo', '-u', $user, $0, @ARGV;
}

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
