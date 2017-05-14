package Devel::TypeCheck::Type::Zeta;

use strict;
use Carp;

use Devel::TypeCheck::Type;
use Devel::TypeCheck::Type::TSub;
use Devel::TypeCheck::Type::TVar;
use Devel::TypeCheck::Util;

=head1 NAME

Devel::TypeCheck::Type::Zeta - Code values (CVs)

=head1 SYNOPSIS

 use Devel::TypeCheck::Type::Zeta;

=head1 DESCRIPTION

Zeta represents code values (CVs).  A CV takes a list as an argument
and returns a value.  Thus, Zeta is typed as a tuple of a parameter
list and a return value.

=cut
our @ISA = qw(Devel::TypeCheck::Type);

# **** CLASS ****

sub type {
    return Devel::TypeCheck::Type::Z();
}

# **** INSTANCE ****

sub new {
    my ($name, $param, $return) = @_;

    my $this = {};

#     if (defined($param) &&
# 	($param->type != Devel::TypeCheck::Type::M() ||
# 	 ($param->type == Devel::TypeCheck::Type::M() &&
# 	  $param->subtype->type != Devel::TypeCheck::Type::O()))) {
# 	confess("Impossible type ", $param->type, " for parameter part of Zeta");
#     }

    $this->{'param'} = $param;
    $this->{'return'} = $return;

    return bless($this, $name);
}

sub str {
    my ($this, $env) = @_;
    return "Z:(" . $this->derefParam->str($env) . ")->(" . $this->derefReturn->str($env) . ")";
}

sub pretty {
    my ($this, $env) = @_;
    return "FUNCTION: (" .
      $this->derefParam->pretty($env) .
	") -> (" .
	  $this->derefReturn->pretty($env) .
	    ")";
}

sub derefParam {
    my ($this) = @_;
    return $this->{'param'};
}

sub derefReturn {
    my ($this) = @_;
    return $this->{'return'};
}

sub unify {
    my ($this, $that, $env) = @_;

    $this = $env->find($this);
    $that = $env->find($that);

    if ($this->type == $that->type) {
	my $param = $env->unify($this->derefParam, $that->derefParam);

	if (defined($param)) {
	    my $return = $env->unify($this->derefReturn, $that->derefReturn);

	    if (defined($return)) {
		return $this;
	    }
	}
    }

    return undef;
}

sub subtype {
    return undef;
}

sub occurs {
    my ($this, $that, $env) = @_;

    return ($this->derefParam->occurs($that, $env) ||
	    $this->derefReturn->occurs($that, $env));
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
