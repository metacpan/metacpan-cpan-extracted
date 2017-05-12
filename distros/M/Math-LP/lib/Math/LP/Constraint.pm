package Math::LP::Constraint;
use strict;
use vars qw($LE $GE $EQ %SYMBOL @EXPORT %EXPORT_TAGS @EXPORT_OK);
use Math::LP::LinearCombination;
use Math::LP::Solve;
use Exporter;
use base qw(Math::LP::Object Exporter);
use fields (
    'lhs',         # Math::LP::LinearCombination at left hand side
    'rhs',         # constant number at right hand side
    'type',        # $LE, $GE or $EQ
    'name',        # name of the constraint
    'row_index',   # row index of the constraint in the LP
    'slack',       # slack found after solving the LP
    'dual_value',  # dual value for the constraint after solving the LP
);

# the constraint types are exportable
@EXPORT = qw();
%EXPORT_TAGS = (types => [qw($LE $GE $EQ)]);
@EXPORT_OK = qw($LE $GE $EQ);

BEGIN {
    # constraint types
    *LE = \$Math::LP::Solve::LE;
    *GE = \$Math::LP::Solve::GE;
    *EQ = \$Math::LP::Solve::EQ;
    
    # constraint symbols
    %SYMBOL = ($LE => '<=', $GE => '>=', $EQ => '=');
}

sub initialize {
    my Math::LP::Constraint $this = shift;
    defined($this->{lhs}) or 
	$this->croak("No lhs given for Math::LP::Constraint");
    $this->{rhs} ||= 0.0;
    defined($this->{type}) or
	$this->croak("No type given for Math::LP::Constraint");
    $this->{type} == $LE or $this->{type} == $GE or $this->{type} == $EQ
	or $this->croak("No valid type given for Math::LP::Constraint");
}

sub stringify {
    my Math::LP::Constraint $this = shift;
    my $str = '';
    $str .= $this->{lhs}->stringify() . ' ' . $this->symbol() . ' ' . $this->{rhs};
    $str .= ' [' . $this->{name} . ']' if defined $this->{name};
    return $str;
}

sub symbol {
    my Math::LP::Constraint $this = shift;
    my $type = $this->{type};
    return $SYMBOL{$type};
}

1;

__END__

=head1 NAME

Math::LP::Constraint - representation of constraints in Math::LP objects

=head1 SYNOPSIS

    use Math::LP::Constraints qw(:types); # imports constraint types

    # make the constraint x1 + 2 x2 <= 3
    $x1 = new Math::LP::Variable(name => 'x1');
    $x2 = new Math::LP::Variable(name => 'x2');
    $constraint = new Math::LP::Constraint(
	lhs  => make Math::LP::LinearCombination($x1,1.0,$x2,2.0),
        rhs  => 3.0,
        type => $LE,
    );

=head1 DESCRIPTION

A Math::LP::Constraint object has the following fields:

=over 4

=item lhs

a Math::LP::LinearCombination object forming the left hand side of the
(in)equality (Required)

=item rhs

a constant number for the right hand side of the (in)equality (Defaults to 0)

=item type

the (in)equality type, either $LE (<=), $GE (>=) or $EQ (=) (Required)

=item name

a string with a name for the constraint (Optional, set by 
Math::LP::add_constraint if not specified)

=item row_index

the index of the constraint in the LP (Set by Math::LP::add_constraint)

=item slack

the slack of the row in the LP (Set after solving the LP)

=item dual_value

the dual value of the row in the LP (Set after solving the LP)

=back

=head1 SEE ALSO

L<Math::LP>, L<Math::LP::Variable>, L<Math::LP::LinearCombination> and
L<Math::LP::Object>

=head1 AUTHOR

Wim Verhaegen E<lt>wimv@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright(c) 2000-2001 Wim Verhaegen. All rights reserved. 
This program is free software; you can redistribute
and/or modify it under the same terms as Perl itself.

=cut
