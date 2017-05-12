package Devel::TypeCheck::Environment;

use strict;

use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Type::Var;
use Devel::TypeCheck::Type::Mu;
use Devel::TypeCheck::Type::Eta;
use Devel::TypeCheck::Type::Kappa;
use Devel::TypeCheck::Type::Rho;
use Devel::TypeCheck::Type::Nu;
use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Environment - class for managing the type
environment in B::TypeCheck

=head1 SYNOPSIS

Objects of this type are instantiated with the C<<new>> method.

=head1 DESCRIPTION

The data structure is essentially a linked list from Mu at the head of
the list to terminal or variable types at the end.  Thus, most of the
functions defined here support that by relaying the request to the
subtype member (the next link in the linked list) instead of actually
doing anything themselves.

=over 4

=cut

=item B<new>

Create a new type environment.

=cut
sub new {
    my ($name) = @_;
    my $this = {};

    $this->{'typeVars'} = [];

    return bless($this, $name);
}

=item B<fresh>

Create a new type variable in the context of the environment.  This
is so we can find unbound type variables later.

=cut
sub fresh {
    my ($this) = @_;

    my $id = $#{$this->{'typeVars'}} + 1;
    my $var = Devel::TypeCheck::Type::Var->new($id);

    push(@{$this->{'typeVars'}}, $var);

    return $var;
}

=item B<fresh>

Return a fully qualified incomplete Kappa instance

=cut

sub freshKappa {
    my ($this) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Kappa->new($this->fresh()));
}

=item B<freshEta>

Return a fully qualified incomplete Eta instance

=cut
sub freshEta {
    my ($this) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Eta->new($this->freshKappa, $this->genOmicron, $this->genChi, $this->freshZeta));
}

=item B<freshNu>

Return a fully qualified incomplete Nu instance

=cut
sub freshNu {
    my ($this) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Kappa->new(Devel::TypeCheck::Type::Upsilon->new(Devel::TypeCheck::Type::Nu->new($this->fresh()))));
}

=item B<freshRho>

Return a fully qualified incomplete Rho instance

=cut
sub freshRho {
    my ($this) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Kappa->new(Devel::TypeCheck::Type::Rho->new($this->fresh())));
}

=item B<freshUpsilon>

Return a fuly qualified incomplete Upsilon instance

=cut
sub freshUpsilon {
    my ($this) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Kappa->new(Devel::TypeCheck::Type::Upsilon->new($this->fresh())));
}

=item B<freshZeta>

Return a fully qualified incomplete Zeta instance

=cut
sub freshZeta {
    my ($this) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Zeta->new($this->genOmicron, $this->fresh));
}

=item B<genRho>

Encapsulate something in a fully qualified reference

=cut
sub genRho {
    my ($this, $referent) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Kappa->new(Devel::TypeCheck::Type::Rho->new($referent)));
}

=item B<genEta>

Encapsulate something in a fully qualified glob

=cut
sub genEta {
    my ($this, $referent) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Eta->new($referent));
}

=item B<genOmicron>

Generate a fully quialified incomplete Omicron instance.

=item B<genOmicron>($subtype)

Generate a fully qualified Omicron instance with the given type as the homogeneous type.

=cut

sub genOmicron {
    my ($this, $subtype) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Omicron->new($subtype));
}

=item B<genOmicronTuple>(@types)

Create a new tuple-type list given a list of types.

=cut

sub genOmicronTuple {
    my ($this, @ary) = @_;

    my $fresh = $this->genOmicron();

    $fresh->subtype->{'ref'}->{'ary'} = \@ary;

    return $fresh;
}

=item B<genChi>

Generate a fully qualified incomplete Chi instance

=item B<genChi>($subtype)

Generate a homogeneous Chi type with the given subtype as the homogeneous type.

=cut

sub genChi {
    my ($this, $subtype) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Chi->new($subtype));
}

=item B<genZeta>($params, $return)

Generate a Zeta type with the given params and return value.

=cut
sub genZeta {
    my ($this, $params, $return) = @_;
    return Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Zeta->new($params, $return));
}

# Union two types, as per union-find data structure
sub union {
    my ($this, $t1, $t2) = @_;
    
    # Union two type variables
    if ($t1->type == Devel::TypeCheck::Type::VAR() &&
        $t2->type == Devel::TypeCheck::Type::VAR()) {
	if ($t1->{'rank'} > $t2->{'rank'}) {
	    $t2->{'parent'} = $t1;
	    return $t1;
	} elsif ($t1->{'rank'} < $t1->{'rank'}) {
	    $t1->{'parent'} = $t2;
	    return $t2;
	} else {
	    # $t1->{'rank'} == $t2->{'rank'}
	    if ($t1 != $t2) {
		$t1->{'parent'} = $t2;
		$t2->{'rank'}++;
	    }

	    return $t2;
	}
    
    # The next two clauses handle the union of a type variable with a
    # concrete type
    } elsif ($t1->type == Devel::TypeCheck::Type::VAR() &&
	     $t2->type != Devel::TypeCheck::Type::VAR()) {
	$t1->{'parent'} = $t2;
	return $t2;
    } elsif ($t1->type != Devel::TypeCheck::Type::VAR() &&
	     $t2->type == Devel::TypeCheck::Type::VAR()) {
	$t2->{'parent'} = $t1;
	return $t1;

    # There cannot be a union between two concrete types.  If two
    # types contain types that can be unioned, this happens in unify.
    } else {
	# $t1->type != VAR && $t2->type != VAR
	return undef;
    }
}

=item B<unify>($t1, $t2)

Unify the two given types.  If unsuccessful, this returns undef.

=cut
sub unify {
    my ($this, $t1, $t2) = @_;
    
    $t1 = $this->find($t1);
    $t2 = $this->find($t2);

    # The buck stops here if at least one is a VAR
    if ($t1->type == Devel::TypeCheck::Type::VAR() &&
	$t2->type == Devel::TypeCheck::Type::VAR()) {

	# The unification of two variable types is trivially their
	# union.
	return $this->union($t1, $t2);


    # The next two clauses handle the case where a type variable needs
    # to be unified with a concrete type.  In both cases, we need to
    # make sure that the type variable does not appear in the concrete
    # type.
    } elsif ($t1->type == Devel::TypeCheck::Type::VAR() &&
	     $t2->type != Devel::TypeCheck::Type::VAR()) {

	if (!$t2->occurs($t1, $this)) {
	    $t1->{'parent'} = $t2;
	    return $t2;
	} else {
	    die("Failed occurs check");
	}

    } elsif ($t1->type != Devel::TypeCheck::Type::VAR() &&
	     $t2->type == Devel::TypeCheck::Type::VAR()) {

	if (!$t1->occurs($t2, $this)) {
	    $t2->{'parent'} = $t1;
	    return $t1;
	} else {
	    die("Failed occurs check");
	}

    # In this clause, both t1 and t2 are concrete types
    } else {

	# Call the type-specific unify.  This handles the case where
	# incomplete types need to be unified.
	if ($t1->unify($t2, $this)) {
	    return $t1;
	} else {
	    return undef;
	}
    }
}

=item B<find>($elt)

Find the representative element of the set that C<<$elt>> belongs to.
For fully qualified types that end in a terminal, this is themselves.

=cut
sub find {
    my ($this, $elt) = @_;

    confess ("null find") if (!defined($elt));

    if (defined($elt->getParent)) {
	return $elt->setParent($this->find($elt->getParent));
    } else {
	return $elt;
    }
}

TRUE;

=back

=head1 AUTHOR

Gary Jackson, C<< <bargle at umiacs.umd.edu> >>

=head1 BUGS

This version is specific to Perl 5.8.1.  It may work with other
versions that have the same opcode list and structure, but this is
entirely untested.  It definitely will not work if those parameters
change.

Please report any bugs or feature requests to
C<bug-devel-typecheck at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-TypeCheck>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Gary Jackson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
