package Devel::TypeCheck::Type::Eta;

=head1 NAME

Devel::TypeCheck::Type::Eta - Glob type representation

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Eta;

=head1 DESCRIPTION

Eta represents a glob type in Perl.  This inherits from the
Devel::TypeCheck::Type class.

=cut

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Util;
use Devel::TypeCheck::Type::TRef;

our @ISA = qw(Devel::TypeCheck::Type);

# **** INSTANCE ****

sub new {
    my ($name, $kappa, $omicron, $chi, $zeta) = @_;

    if ($kappa->type != Devel::TypeCheck::Type::M() &&
        $kappa->subtype->type != Devel::TypeCheck::Type::K()) {
	carp("Impossible included type ", $kappa->type, " for scalar (kappa) part of Eta\n");
    }

    if (defined($omicron) && $omicron->type != Devel::TypeCheck::Type::M() &&
        $omicron->subtype->type != Devel::TypeCheck::Type::O()) {
	carp("Impossible included type ", $omicron->type, " for array (omicron) part of Eta\n");
    }

    if (defined($chi) && $chi->type != Devel::TypeCheck::Type::M() &&
        $chi->subtype->type != Devel::TypeCheck::Type::X()) {
	carp("Impossible included type ", $chi->type, " for hash (chi) part of Eta\n");
    }

    if (defined($zeta) && $zeta->type != Devel::TypeCheck::Type::M() &&
	$zeta->subtype->type != Devel::TypeCheck::Type::Z()) {
	carp("Impossible included type ", $zeta->type, " for CV (zeta) part of Eta\n");
    }

    my $this = {};

    bless($this, $name);

    $this->{'K'} = $kappa;   $this->setSV;
    $this->{'O'} = $omicron; $this->setAV;
    $this->{'X'} = $chi;     $this->setHV;
    $this->{'Z'} = $zeta;    $this->setCV;

    $this->{'subtype'} = undef;

    return $this;
}

sub type {
    return Devel::TypeCheck::Type::H();
}

sub str {
    my ($this, $env) = @_;

    my @str;
    
    for my $i ('IO') {
	if ($this->_getGeneric($i)) {
	    push(@str, "<$i>");
	}
    }

    my $str;
    
    if ($#str >= 0) {
	$str = join(";", @str);
    } else {
	$str = "...";
    }

    return ("H:$str;" . $this->derefKappa->str($env) . ";" . $this->derefOmicron->str($env) . ";" . $this->derefChi->str($env) . ";" . $this->derefZeta->str($env));
}

sub derefKappa {
    my ($this) = @_;
    return $this->{'K'};
}

sub derefOmicron {
    my ($this) = @_;
    return $this->{'O'};
}

sub derefChi {
    my ($this) = @_;
    return $this->{'X'};
}

sub derefZeta {
    my ($this) = @_;
    return $this->{'Z'};
}

sub deref {
    confess("This is an error, and should be converted to a derefKappa (probably)");
}

sub _setGeneric {
    my ($this, $value) = @_;
    $this->{$value} = TRUE;
}

sub _getGeneric {
    my ($this, $value) = @_;
    if (exists($this->{$value})) {
	return $this->{$value};
    } else {
	return FALSE;
    }
}

sub setSV {
    return $_[0]->_setGeneric('SV');
}

sub getSV {
    return $_[0]->_getGeneric('SV');
}

sub setAV {
    return $_[0]->_setGeneric('AV');
}

sub getAV {
    return $_[0]->_getGeneric('AV');
}

sub setHV {
    return $_[0]->_setGeneric('HV');
}

sub getHV {
    return $_[0]->_getGeneric('HV');
}

sub setCV {
    return $_[0]->_setGeneric('CV');
}

sub getCV {
    return $_[0]->_getGeneric('CV');
}

sub setIO {
    return $_[0]->_setGeneric('IO');
}

sub getIO {
    return $_[0]->_getGeneric('IO');
}

sub occurs {
    my ($this, $that, $env) = @_;

    return (($this->derefKappa->occurs($that, $env) ||
	     $this->derefOmicron->occurs($that, $env) ||
	     $this->derefChi->occurs($that, $env)));
}

sub unify {
    my ($this, $that, $env) = @_;

    if ($this->type == $that->type) {
	if ($env->unify($this->derefKappa, $that->derefKappa) &&
	    $env->unify($this->derefOmicron, $that->derefOmicron) &&
	    $env->unify($this->derefChi, $that->derefChi)) {
	    return $this;
	}
    }

    # Failure
    return undef;
}

sub pretty {
    my ($this, $env) = @_;
    my @str;
    
    if ($this->_getGeneric('IO')) {
	push (@str, "IO HANDLE");
    }

    my $str;
    
    if ($#str >= 0) {
	$str = join("; ", @str);
    } else {
	$str = "...";
    }

    return ("GLOB of ($str; " .
	    $this->derefKappa->pretty($env) . "; " .
	    $this->derefOmicron->pretty($env) . "; " .
	    $this->derefChi->pretty($env) . "; " .
	    $this->derefZeta->pretty($env) .
	    ")");
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
