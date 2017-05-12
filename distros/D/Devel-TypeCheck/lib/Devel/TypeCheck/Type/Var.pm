package Devel::TypeCheck::Type::Var;

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type::Var - Type variable.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Var;

=head1 DESCRIPTION

Var represents type variables.  When instantiated, a Var is unbound in
the type environment.  After unification, a Var might be bound to a
complete and fully qualified type, or to another type variable.

Inherits from Devel::TypeCheck::Type::Type.

=over 4

=cut
our @ISA = qw(Devel::TypeCheck::Type);

# **** INSTANCE ****

sub new {
    my ($name, $index) = @_;

    my $this = {};

    $this->{'index'} = $index;
    $this->{'rank'} = 0;
    $this->{'parent'} = undef;

    return bless($this, $name);
}

sub type {
    return Devel::TypeCheck::Type::VAR();
}

sub subtype {
    abstract("subtype", "Devel::TypeCheck::Type::Var");
}

sub unify {
    my ($this, $that, $env) = @_;

    $this = $env->find($this);
    $that = $env->find($that);

    return $env->unify($this, $that);
}

sub occurs {
    my ($this, $that, $env) = @_;
    
    if ($that->type != Devel::TypeCheck::Type::VAR()) {
	die("Invalid type ", $that->str, " for occurs check");
    }

    my $f = $env->find($this);
    my $g = $env->find($that);

    if ($f->type != Devel::TypeCheck::Type::VAR()) {
	return ($f->occurs($g, $env));
    } else {
	return ($f == $g);
    }
}

sub letters {
    use integer;

    my ($int) = @_;
    my $d = $int / 26;
    my $r = $int % 26;
    my $l = "";

    if ($d != 0) {
        $l = letters($d);
    }

    return $l . chr(ord('a') + $r);
}

sub str {
    my ($this, $env) = @_;

    my $that = $this;

    if (defined($env)) {
	$that = $env->find($this);
    }

    if ($this == $that) {
	return letters($this->{'index'});
    } else {
	return $that->str($env);
    }
}

sub pretty {
    my ($this, $env) = @_;
    my $that = $this;

    if (defined($env)) {
	$that = $env->find($this);
    }

    if ($this == $that) {
	return "TYPE VARIABLE " . letters($this->{'index'});
    } else {
	return $that->pretty($env);
    }
}

=item B<getParent>

Return the immediate parent of this type in the union-find data structure.

=cut
sub getParent {
    my ($this) = @_;
    return $this->{'parent'};
}

=item B<setParent>($parent)

Set the parent for this instance in the union-find data structure.

=cut
sub setParent {
    my ($this, $parent) = @_;

    die ("Devel::TypeCheck::Type::Var cannot be it's own parent") if ($this == $parent);

    $this->{'parent'} = $parent;
}

sub is {
    my ($this, $type) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->is($type);
    } else {
	return TRUE if ($type == $this->type);
    }

    return FALSE;
}

sub complete {
    return FALSE;
}

# Garbage to support dereferencing and stuff through vars:

sub derefKappa {
    my ($this) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->derefKappa();
    } else {
	return undef;
    }
}

sub derefOmicron {
    my ($this) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->derefOmicron();
    } else {
	return undef;
    }
}

sub derefChi {
    my ($this) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->derefChi();
    } else {
	return undef;
    }
}

sub derefIndex {
    my ($this, $index, $env) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->derefIndex($index, $env);
    } else {
	return undef;
    }
}

sub derefHomogeneous {
    my ($this) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->derefHomogeneous();
    } else {
	return undef;
    }
}

sub homogeneous {
    my ($this) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->homogeneous();
    } else {
	return undef;
    }
}

sub referize {
    my ($this, $env) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->referize($env);
    } else {
	return undef;
    }
}

sub append {
    my ($this, $that, $env) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->append($that, $env, $this);
    } else {
	return undef;
    }
}

sub ary {
    my ($this) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->ary();
    } else {
	return undef;
    }
}

sub listCoerce {
    my ($this, $env) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->listCoerce($env);
    } else {
	return undef;
    }
}

sub bindUp {
    my ($this, $env) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->bindUp($env);
    } else {
	return undef;
    }
}

sub deref {
    my ($this) = @_;
    my $parent = $this->getParent;
    if ($this->getParent) {
	return $parent->deref();
    } else {
	return undef;
    }
}

sub arity {
    my ($this) = @_;
    my $parent = $this->getParent;
    if ($parent) {
	return $parent->arity();
    } else {
	return undef;
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
