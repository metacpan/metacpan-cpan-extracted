package Devel::NoGlobalSig;
$VERSION = v0.0.1;

use warnings;
use strict;
use Carp;

=head1 NAME

Devel::NoGlobalSig - croak when a global %SIG is installed

=head1 SYNOPSIS

This is a diagnostic tool for detecting where some code has over-written
a singnal handler (in the global %SIG) without using local().

  perl -MDevel::NoGlobalSig=die your_program

=head1 ABOUT

The installation of global signal handlers by some distant code can be
rather surprising.  This gives you a way to detect where this happened
by installing an exploding subroutine in the handler slot.

This is a diagnostic tool.  It is not recommended to employ this in
production code (but if you find a good reason to do that, please drop
me a note.)

=head1 USAGE

Typically, you will simply want to import this from the command line,
e.g. when running some test which is mysteriously failing after
integrating two pieces of previously working code.

  perl -MDevel::NoGlobalSig=die t/never_failed_before.t

If your frontend code installs its own global handler for good reason,
you'll want to import this after that happens (your handler will be
wrapped in a protective exploding shell.)

  BEGIN {$SIG{__DIE__} = \&my_die_handler};
  use Devel::NoGlobalSig qw(die warn hup);

=head2 Signal Names

The arguments to import() may be a list of upper-case or lower-case
versions of the handler names.  The special signals __WARN__ and __DIE__
may be passed as simply 'warn' and 'die', respectively.

See L<perlipc> for details.

=cut

use overload '&{}' => sub { shift->{'sub'} }, fallback => 1;

sub import {
  my $package = shift;
  my (@args) = @_;

  @args or return; # XXX croak?

  foreach my $name (@args) {
    $name = '__' . $name . '__' if($name eq 'warn' or $name eq 'die');
    $name = uc($name);

    my $self = {
      name => $name,
      'sub'=> $SIG{$name} || sub {},
    };
    $SIG{$name} = bless($self, $package);
  }
}

my $ended = 0; END {$ended = 1};
sub DESTROY {
  return if($ended);

  my $self = shift;

  Carp::carp("BZZT:  non-localized \$SIG{$self->{name}} assignment");
  exit(1);
}


=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2009 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
