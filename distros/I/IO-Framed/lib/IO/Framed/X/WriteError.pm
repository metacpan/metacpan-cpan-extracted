package IO::Framed::X::WriteError;

=encoding utf-8

=head1 NAME

IO::Framed::X::WriteError

=head1 SYNOPSIS

    use Try::Tiny;
    use IO::Framed::Write::Blocking;

    my $iof = IO::Framed::Write::Blocking->new( $some_socket );

    try { $iof->write('blahblah') }
    catch {
        $_->get('OS_ERROR');        #gets $!
        $_->errno_is('EAGAIN');     #should always be false
    };

=head1 DESCRIPTION

Thrown on write errors. Subclasses L<X::Tiny::Base>.

=cut

use strict;
use warnings;

use parent qw( IO::Framed::X::ErrnoBase );

sub _new {
    my ($class, $err) = @_;

    return $class->SUPER::_new( "Write error: $err", OS_ERROR => $err );
}

1;
