package IPC::Door::Client;

#$Id: Client.pm 31 2005-06-04 22:33:42Z asari $

use 5.006;
use strict;
use warnings;

use POSIX qw[ :fcntl_h ];
use IPC::Door;

our @ISA = qw[ IPC::Door ];

my $ans;

sub call {
    my $self = shift;
    my $path = $self->{'path'};

    my $arg  = shift;
    my $attr = shift || O_RDWR;

    if ( ( $self->info() )[0] > 0 ) {
        eval { $ans = $self->__call( $path, scalar( $arg ), $attr ) };
    }

    if ($@) {
       warn "$self->call() failed: $@\n";
       $ans = undef;
    }
    return $ans;

}

1;    # end of IPC::Door::Client

__END__

=head1 NAME

IPC::Door::Client - door client for Solaris (>= 2.6)

=head2 SYNOPSIS

    use IPC::Door::Client;

    $door='/path/to/door';

    $dclient = new IPC::Door::Client($door);

    $dclient->call($arg[, $attr]);

=head2 DESCRIPTION

C<IPC::Door::Client> is a Perl object class that speaks to
an C<IPC::Door::Server> object that is listening to the door
associated with the object.

It is a subclass of C<IPC::Door>.

The only unique method, C<call> implicitly calls C<open>(2)
(not to be confused with the Perl function L<open>),
and you can optionally pass flags for that call.
Note that the standard module L<Fcntl> exports useful ones.
The default is C<O_RDWR>.

The argument will be evaluated in the scalar context.

=head1 SEE ALSO

L<IPC::Door>

=head1 AUTHOR

ASARI Hirotsugu <asarih at cpan dot org>

L<http://www.asari.net/perl>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by ASARI Hirotsugu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

