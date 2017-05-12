package Hook::Queue;
use strict;
use warnings;
use Devel::Peek qw(CvGV);
our $VERSION = 1.21;

=head1 NAME

Hook::Queue - define a queue of handlers

=head1 SYNOPSIS

  # define a Liar class which always claims to be what you're asking
  # about
  package Liar;
  use Hook::Queue 'UNIVERSAL::isa' => sub {
      my $what  = shift;
      my $class = shift;
      return 1 if (ref $what || $what) eq "Liar";
      # it's not my call, pass it down the chain
      return Hook::Queue->defer;
  };

=head1 DESCRIPTION

Hook::Queue provides a mechanism for stacking global handlers in a
queue of routines that will take an attempt at answering the
subroutine call addressed to it.

For each subroutine that joins the queue, it can either return a
canonical answer, or indicate that it's deferring along the queue by
calling the C<Hook::Queue->defer> method and returning.

When you say C<use Hook::Queue> you join the queue at its current
head, and as such your position may very, depending on compilation
order of the Perl program.  As such you should remember to C<defer>
even if your testing shows you to be at the end of the queue in test
circumstances.

=cut

my ($Defer, %Hooks);
sub defer { $Defer = 1 }

sub import {
    my $class = shift;
    my %hooks = @_;
    for my $hook (keys %hooks) {
        my $hooked = do { no strict 'refs'; \&$hook };
        if (CvGV($hooked) ne $hook) {
            # something already lives there, save at the head of the
            # queue and install
            unshift @{ $Hooks{$hook} }, $hooked;
            my $sub = sub {
                for my $segment (@{ $Hooks{ $hook } }) {
                    $Defer = 0;
                    my $ret = $segment->( @_ );
                    next if $Defer;
                    return $ret;
                }
                die "Deferred past the end of the queue of $hook!";
            };

            no strict 'refs';
            no warnings 'redefine';
            *$hook = $sub;
        }
        unshift @{ $Hooks{$hook} }, $hooks{ $hook };
    }
}


1;

__END__

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

Copyright Richard Clamp 2004.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hook::Queue>.

=head1 SEE ALSO

L<SUPER>, L<NEXT> - for similar idioms for OO programming

=cut
