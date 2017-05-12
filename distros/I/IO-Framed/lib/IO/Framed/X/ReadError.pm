package IO::Framed::X::ReadError;

=encoding utf-8

=head1 NAME

IO::Framed::X::ReadError

=head1 SYNOPSIS

    use Try::Tiny;
    use IO::Framed::Read;

    my $iof = IO::Framed::Read->new( $some_socket );

    try { $iof->read(20) }
    catch {
        $_->get('OS_ERROR');        #gets $!
        $_->errno_is('EAGAIN');     #should always be false
    };

=head1 DESCRIPTION

Thrown on read errors. Subclasses L<X::Tiny::Base>.

=cut

use strict;
use warnings;

use parent qw( IO::Framed::X::ErrnoBase );

sub _new {
    my ($class, $err) = @_;

    return $class->SUPER::_new( "Read error: $err", OS_ERROR => $err );
}

1;
