package Devel::TypeCheck::Type::Omicron;

=head1 NAME

Devel::TypeCheck::Type::Omicron - Type representing arrays.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Omicron;

=head1 DESCRIPTION

This class represents the Omicron (capital 'O') terminal in the type
language.  As such, it maintains type information for arrays.  This
class is a little bit different than the others, because it can
represent two essentially different types: lists of homogeneous typed
values, or tuples of heterogeneous types.  This has an adaptation to
the unify() algorithm where a tuple can be unified with a list through
promotion to a list if all elements of the tuple can be unified with
the list element type.  Lists cannot be demoted to tuples.

Inherits from Devel::TypeCheck::Type and Devel::TypeCheck::TSub.

=cut

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Util;

our @ISA = qw(Devel::TypeCheck::Type Devel::TypeCheck::Type::TSub);

# **** CLASS ****

our @SUBTYPES;
our @subtypes;

BEGIN {
    @SUBTYPES = (Devel::TypeCheck::Type::K());

    for my $i (@SUBTYPES) {
        $subtypes[$i] = 1;
    }
}

sub hasSubtype {
    my ($this, $index) = @_;
    return ($subtypes[$index]);
}

# **** INSTANCE ****

sub new {
    my ($name, $type) = @_;

    my $this = {};

    $this->{'ref'} = newRef($type);

    return bless($this, $name);
}

sub newRef {
    my ($type) = @_;

    my $ref = {};

    if (defined($type)) {
	$ref->{'ary'} = undef;
	$ref->{'homogeneous'} = TRUE;
	$ref->{'subtype'} = $type;
    } else {
	$ref->{'ary'} = [];
	$ref->{'homogeneous'} = FALSE;
	$ref->{'subtype'} = undef;
    }

    return $ref;
}

sub derefIndex {
    my ($this, $index, $env) = @_;

    if (!defined($env)) {
	confess("null environment");
    }

    if ($this->homogeneous) {
	return $this->derefHomogeneous;
    } else {
	confess("index is negative") if ($index < 0);

	if (!exists($this->ary->[$index])) {
	    $this->ary->[$index] = $env->freshKappa();
	}
	
	return $this->ary->[$index];
    }
}

sub ary {
    my ($this) = @_;
    return $this->{'ref'}->{'ary'};
}

sub subtype {
    return undef;
}

sub derefHomogeneous {
    my ($this) = @_;
    if ($this->homogeneous) {
	return $this->{'ref'}->{'subtype'};
    } else {
	confess("type is not homogeneous");
    }
}

sub homogeneous {
    my ($this) = @_;
    return $this->{'ref'}->{'homogeneous'};
}

sub str {
    my ($this, $env) = @_;

    if ($this->homogeneous) {
	return "(" . $this->derefHomogeneous->str($env) . ", ...)";
    } else {
	my $str = "(";

	my @str = ();
	for (my $i = 0; $i <= $#{$this->ary}; $i++) {
	    push(@str, $this->derefIndex($i, $env)->str($env));
	}
    
	$str .= join(",", @str);

	return $str . ")";
    }
}

sub pretty {
    my ($this, $env) = @_;

    if ($this->homogeneous) {
	return "LIST of (" . $this->derefHomogeneous->pretty($env) . ", ...)";
    } else {
	my $str = "TUPLE of (";

	my @str = ();
	for (my $i = 0; $i <= $#{$this->ary}; $i++) {
	    push(@str, $this->derefIndex($i, $env)->pretty($env));
	}
    
	$str .= join(",", @str);

	return $str . ")";
    }
}

sub copyFrom {
    my ($this, $that) = @_;

    $this->{'ref'} = $that->{'ref'};
}

sub bindUp {
    my ($this, $that, $env) = @_;

    if (!defined($env)) {
	confess("null environment");
    }

    if (! $this->homogeneous) {
	confess("Can not bind up against non-homogeneous array");
    }

    if ($that->homogeneous) {
	confess("Can not bind up homogeneous array to homogeneous array, unify instead");
    }

    for (my $i = 0; $i <= $#{$that->ary}; $i++) {
	if (!defined($env->unify($that->derefIndex($i, $env), $this->derefHomogeneous))) {
	    return undef;
	}
    }

    $that->copyFrom($this);

    return $this;
}

sub tupleUnify {
    my ($this, $that, $env) = @_;
    
    if (!defined($env)) {
	confess("null environment");
    }

    if ($this->homogeneous || $that->homogeneous) {
	confess("Both inputs must not be homogeneous for tupleUnify");
    }

    my $max = $this;
    my $min = $that;

    if ($#{$that->ary} > $#{$this->ary}) {
	$max = $that;
	$min = $this;
    }
    
    for (my $i = 0; $i <= ($#{$max->ary}); $i++) {
	if (!defined($env->unify($max->derefIndex($i, $env), $min->derefIndex($i, $env)))) {
	    return undef;
	}
    }

    $that->copyFrom($this);
	
    return $this;
}
      
sub unify {
    my ($this, $that, $env) = @_;

    $this = $env->find($this);
    $that = $env->find($that);

    if ($this->type == $that->type) {
	if ($this->homogeneous) {
	    if ($that->homogeneous) {
		if ($env->unify($this->derefHomogeneous, $that->derefHomogeneous)) {
		    return $this;
		} else {
		    return undef;
		}
	    } else {
		return $this->bindUp($that, $env);
	    }
	} else {
	    if ($that->homogeneous) {
		return $that->bindUp($this, $env);
	    } else {
		return $this->tupleUnify($that, $env);
	    }
	}
    } else {
	return undef;
    }
}

sub type {
    return Devel::TypeCheck::Type::O();
}

# Do the occurs check against $that with the given environment $env.
sub occurs {
    my ($this, $that, $env) = @_;
    
    if ($that->type != Devel::TypeCheck::Type::VAR()) {
	die("Invalid type ", $that->str, " for occurs check");
    }

    if ($this->homogeneous) {
	return $this->derefHomogeneous->occurs($that, $env);
    } else {
	for (my $i = 0; $i <= $#{$this->ary}; $i++) {
	    my $occurs = $this->derefIndex($i, $env)->occurs($that, $env);
	    return $occurs if ($occurs);
	}

	return FALSE();
    }
}

sub referize {
    my ($this, $env) = @_;

    if ($this->homogeneous) {
	return $env->genOmicron($env->genRho($this->derefHomogeneous()));
    } else {
	my @ary;
	for (my $i = 0; $i <= $#{$this->ary}; $i++) {
	    push(@ary, $env->genRho($this->derefIndex($i, $env)));
	}

	return $env->genOmicronTuple(@ary);
    }
}

# Append $that to $this: ($this, $that).  Unify and promote to list where neccessary.
sub append {
    my ($this, $that, $env, $root) = @_;

    $that = $env->find($that);

    if ($that->isa("Devel::TypeCheck::Type::Var")) {
	$that = $env->unify($that, $env->genOmicron());
    }

    if ($that->is(Devel::TypeCheck::Type::VAR())) {
	$that = $env->unify($that, $env->freshKappa());
	return undef if (!defined($that));
    }

    my $ret;
    if ($this->homogeneous) {
	if ($that->is(Devel::TypeCheck::Type::O())) {
	    $ret = $env->unify($that, $root);
	} elsif ($that->is(Devel::TypeCheck::Type::X())) {
	    my $list = $that->listCoerce($env);
	    if ($list) {
		$ret = $env->unify($list, $root);
	    } else {
		$ret = undef;
	    }
	} elsif ($that->is(Devel::TypeCheck::Type::K()) ||
		 $that->is(Devel::TypeCheck::Type::Z())) {
	    $ret = $env->unify($env->genOmicron($that), $root);
	} else {
	    confess("Unknown type in append");
	}
    } else {
	if ($that->is(Devel::TypeCheck::Type::O())) {
	    if ($that->homogeneous) {
		$ret = $env->unify($root, $that);
	    } else {
		my $list = $env->genOmicron($env->freshKappa);
		my $tl = $env->unify($that, $list);
		if ($tl) {
		    $ret = $env->unify($root, $tl);
		} else {
		    $ret = undef;
		}
	    }
	} elsif ($that->is(Devel::TypeCheck::Type::X())) {
	    my $list = $that->listCoerce($env);
	    if ($list) {
		$ret = $env->unify($list, $root);
	    } else {
		$ret = undef;
	    }
	} elsif ($that->is(Devel::TypeCheck::Type::K()) ||
		 $that->is(Devel::TypeCheck::Type::Z())) {
	    $ret = $env->genOmicronTuple((@{$this->ary}, $that));
	} else {
	    confess("Unknown type in append");
	}
    }

    return $ret;
}

sub arity {
    my ($this) = @_;

    if ($this->homogeneous) {
	confess("Omicron is homogeneous");
    } else {
	return ($#{$this->ary} + 1);
    }
}

TRUE;

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
