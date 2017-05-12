package Devel::TypeCheck::Type::Chi;

=head1 NAME

Devel::TypeCheck::Type::Chi - Represents hashes.

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Chi;

=head1 DESCRIPTION

This class represents the Chi (capital 'X') terminal in the type
language.  As such, it maintains type information for hashes.  This
class is similar to Omicron.  This class inherits from the
Devel::TypeCheck::Type and Devel::TypeCheck::TSub classes.

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
	$ref->{'hsh'} = undef;
	$ref->{'homogeneous'} = TRUE;
	$ref->{'subtype'} = $type;
    } else {
	$ref->{'hsh'} = {};
	$ref->{'homogeneous'} = FALSE;
	$ref->{'subtype'} = undef;
    }

    return $ref;
}

sub derefIndex {
    my ($this, $index, $env) = @_;

    if ($this->homogeneous) {
	return $this->derefHomogeneous;
    } else {
	if (!exists($this->hsh->{$index})) {
	    $this->hsh->{$index} = $env->freshKappa();
	}

	return $this->hsh->{$index};
    }
}

sub hsh {
    my ($this) = @_;
    return $this->{'ref'}->{'hsh'};
}

sub subtype {
    return undef;
}

sub derefHomogeneous {
    my ($this) = @_;
    return $this->{'ref'}->{'subtype'};
}

sub homogeneous {
    my ($this) = @_;
    return $this->{'ref'}->{'homogeneous'};
}

sub str {
    my ($this, $env) = @_;

    if ($this->homogeneous) {
	return "{* => " . $this->derefHomogeneous->str($env) . "}";
    } else {
	my $str = "{";

	my @str = ();
	foreach my $i (keys %{$this->hsh}) {
	    push(@str, "\"" . $i . "\" => " . $this->derefIndex($i, $env)->str($env));
	}
    
	$str .= join(",", @str);

	return $str . "}";
    }
}

sub pretty {
    my ($this, $env) = @_;

    if ($this->homogeneous) {
	return "ASSOCIATIVE ARRAY of {" . $this->derefHomogeneous->pretty($env) . "}";
    } else {
	my $str = "RECORD of {";

	my @str = ();
	foreach my $i (keys %{$this->hsh}) {
	    push(@str, "\"" . $i . "\" => " . $this->derefIndex($i, $env)->pretty($env));
	}
    
	$str .= join(", ", @str);

	return $str . "}";
    }
}

sub copyFrom {
    my ($this, $that) = @_;

    $this->{'ref'} = $that->{'ref'};
}

sub bindUp {
    my ($this, $that, $env) = @_;

    if (! $this->homogeneous) {
	confess("Can not bind up against non-homogeneous hash");
    }

    if ($that->homogeneous) {
	confess("Can not bind up homogeneous hash to homogeneous hash, unify instead");
    }

    foreach my $i (keys(%{$that->hsh})) {
	if (!defined($env->unify($this->derefIndex($i, $env), $this->derefHomogeneous))) {
	    return undef;
	}
    }
    
    $that->copyFrom($this);

    return $this;
}

sub recordUnify {
    my ($this, $that, $env) = @_;
    
    if ($this->homogeneous || $that->homogeneous) {
	confess("Both inputs must not be homogeneous for recordUnify");
    }

    my %keys;

    foreach my $i (keys(%{$this->hsh})) {
	$keys{$i} = TRUE;
    }

    foreach my $i (keys(%{$that->hsh})) {
	$keys{$i} = TRUE;
    }
    
    foreach my $i (keys(%keys)) {
	if (!defined($env->unify($this->derefIndex($i, $env), ($that->derefIndex($i, $env))))) {
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
		return $env->unify($this->derefHomogeneous, $that->derefHomogeneous);
	    } else {
		return $this->bindUp($that, $env);
	    }
	} else {
	    if ($that->homogeneous) {
		return $that->bindUp($this, $env);
	    } else {
		return $this->recordUnify($that, $env);
	    }
	}
    } else {
	return undef;
    }
}

sub type {
    return Devel::TypeCheck::Type::X();
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
	foreach my $i (keys %{$this->hsh}) {
	    my $occurs = $this->derefIndex($i, $env)->occurs($that, $env);
	    return $occurs if ($occurs);
	}

	return FALSE();
    }
}

sub listCoerce {
    my ($this, $env) = @_;

    my $t;
    if (!$this->homogeneous) {
	my $t0 = $env->genChi($env->freshKappa);
	$t = $t0->subtype->bindUp($this, $env);

	return undef if (!$t);
    } else {
	$t = $this;
    }

    my $type = $env->unify($t->derefHomogeneous, $env->freshUpsilon);
    return undef if (!$type);
    
    return $env->genOmicron($type);
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
