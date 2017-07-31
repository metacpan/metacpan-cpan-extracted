=head1 NAME

Devel::GoFaster - optimise executable Perl ops

=head1 SYNOPSIS

    use Devel::GoFaster;

    use Devel::GoFaster "global";

=head1 DESCRIPTION

This module implements some optimisations in compiled Perl code, which
should make it run slightly faster without visibly affecting behaviour.
The optimisations are applied at the peephole optimisation step,
augmenting Perl's built-in optimisations.

Code to be made faster does not need to be written in any special way;
this module can generally be applied to code that was not written with it
in mind.  However, to help with situations where the op munging causes
trouble (such as with the deparser), there is some selectivity in which
code gets the optimisations.  Whether to apply these optimisations is
decided for each subroutine as a whole: it cannot be enabled or disabled
for just part of a subroutine.  There is a global control, defaulting
to off, and lexically-scoped local control which takes precedence over
the global control.

Because the optimisations are applied in the peephole optimiser, not
affecting primary compilation, they are invisible to most modules that
muck around with op trees during compilation.  So this module should play
nicely with modules that use custom ops and the like.  However, anything
that examines the ops of a complete compiled subroutine is liable to see
the non-standard optimised ops from this module, and may have a problem.
In particular, the deparser can't correctly deparse code that has been
affected by this module.  If such problems affect a particular subroutine,
the lexical control can be used to disable non-standard optimisation of
that subroutine alone.

This module tries quite hard to not visibly fail, so that it should be
generally safe to use its pragmata.  If circumstances make it impossible
to apply optimisations that would sometimes be available, the module
will silently leave code unoptimised.  In particular, because all the
optimisations are necessarily implemented using XS code, on any system
that can't build or load XS modules this module's pragmata effectively
become no-ops.  No particular optimisations are guaranteed by invoking
this module.

=cut

package Devel::GoFaster;

{ use 5.006; }
use Lexical::SealRequireHints 0.008;
use warnings;
use strict;

our $VERSION = "0.001";

eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load("Devel::GoFaster", $VERSION);
};

our $global_on = 0;

sub _croak {
	require Carp;
	goto &Carp::croak;
}

=head1 PRAGMATA

=over

=item use Devel::GoFaster

Locally enable the optimisations of this module.  Subroutines compiled in
the lexical scope of this pragma will get the non-standard optimisations,
regardless of the global pragma state.

=item no Devel::GoFaster

Locally disable the optimisations of this module.  Subroutines compiled
in the lexical scope of this pragma will not get the non-standard
optimisations, regardless of the global pragma state.

=item use Devel::GoFaster "global"

Globally enable the optimisations of this module.  Subroutines compiled
after this pragma has been encountered will get the non-standard
optimisations, except where locally overridden.

=item no Devel::GoFaster "global"

Globally disable the optimisations of this module (which is the default
state).  Subroutines compiled after this pragma has been encountered will
not get the non-standard optimisations, except where locally overridden.

=back

=cut

sub import {
	if(@_ == 1) {
		$^H{"Devel::GoFaster/on"} = 1;
	} elsif(@_ == 2 && $_[1] eq "global") {
		$global_on = 1;
	} else {
		_croak "bad arguments for $_[0] import";
	}
}

sub unimport {
	if(@_ == 1) {
		$^H{"Devel::GoFaster/on"} = 0;
	} elsif(@_ == 2 && $_[1] eq "global") {
		$global_on = 0;
	} else {
		_croak "bad arguments for $_[0] unimport";
	}
}

=head1 BUGS

As noted L<above|/DESCRIPTION>, this module is liable to break anything
that examines the ops of a complete compiled subroutine, such as the
deparser.

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2015, 2017 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
