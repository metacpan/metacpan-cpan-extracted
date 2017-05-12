package IO::SigGuard;

=encoding utf-8

=head1 NAME

IO::SigGuard - Signal protection for sysread/syswrite

=head1 SYNOPSIS

    IO::SigGuard::sysread( $fh, $buf, $size );
    IO::SigGuard::sysread( $fh, $buf, $size, $offset );

    IO::SigGuard::syswrite( $fh, $buf );
    IO::SigGuard::syswrite( $fh, $buf, $len );
    IO::SigGuard::syswrite( $fh, $buf, $len, $offset );

=head1 DESCRIPTION

C<perldoc perlipc> describes how Perl versions from 5.8.0 onward disable
the OS’s SA_RESTART flag when installing Perl signal handlers.

This module restores that pattern: it does an automatic restart
when a signal interrupts an operation, so you can entirely avoid
the generally-useless C<EINTR> error when using
C<sysread()> and C<syswrite()>.

Other than that you’ll never see C<EINTR>, then, and that
there are no function prototypes used, this module’s functions exactly
match Perl’s equivalent built-ins.

=cut

use strict;
use warnings;

our $VERSION = '0.013';

#As light as possible …

my $read;

sub sysread {
  READ: {
        $read = ( (@_ == 3) ? CORE::sysread( $_[0], $_[1], $_[2] ) : (@_ == 4) ? CORE::sysread( $_[0], $_[1], $_[2], $_[3] ) : die "Wrong args count! (@_)" ) or do {
            if ($!) {
                redo READ if $!{'EINTR'};
            }
        };
    }

    return $read;
}

my $wrote;

sub syswrite {
    $wrote = 0;

  WRITE: {
        $wrote += ( (@_ == 2) ? CORE::syswrite( $_[0], $_[1], length($_[1]) - $wrote, $wrote ) : (@_ == 3) ? CORE::syswrite( $_[0], $_[1], $_[2] - $wrote, $wrote ) : (@_ == 4) ? CORE::syswrite( $_[0], $_[1], $_[2] - $wrote, $_[3] + $wrote ) : die "Wrong args count! (@_)" ) || do {
            if ($!) {
                redo WRITE if $!{'EINTR'};  #EINTR => file pointer unchanged
                return undef;
            }

            die "empty write without error??";  #unexpected!
        };
    }

    return $wrote;
}

=head1 REPOSITORY

L<https://github.com/FGasper/p5-IO-SigGuard>

=head1 AUTHOR

Felipe Gasper (FELIPE)

… with special thanks to Mario Roy (MARIOROY) for extra testing
and a few fixes/improvements.

=head1 COPYRIGHT

Copyright 2017 by L<Gasper Software Consulting, LLC|http://gaspersoftware.com>

=head1 LICENSE

This distribution is released under the same license as Perl.

=cut

1;
