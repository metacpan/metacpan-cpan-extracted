package FormValidator::Simple::Plugin::Math;

use warnings;
use strict;
use FormValidator::Simple::Constants;
use Math::Expression;

=head1 NAME

FormValidator::Simple::Plugin::Math - Math evaluation for FormValidator::Simple

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

You can evalute the form data with math expression.

    use FormValidator::Simple qw/Math/;
    
    my $result = FormValidator::Simple->check( $req => [
        category => [ 'NOT_BLANK', ['MATH', 'x % 100', '!0']],
        ### valid if category % 100 != 0
    ]);

=head1 EVALUATION

    ['MATH', some_math_expression, is_what]

=head2 some_math_expression

C<x> is the value to be passed. e.g. C<x**3>

=head2 is_what

Sets some number.

Switches the true-false evaluation if C<is_what> starts with C<!>.

=cut

sub MATH{
	my ($self, $params, $args) = @_;
	my $calc = $args->[0] || 0;
	my $equals = $args->[1] || 0;
	my $data = $params->[0];
	my $is     = TRUE;
	my $is_not = FALSE;
	if ($equals =~ /^\!(\d+?)$/){
		$equals = $1;
		$is     = FALSE;
		$is_not = TRUE;
	}
	elsif ($equals eq '!'){
		$equals = 0;
		$is     = FALSE;
		$is_not = TRUE;
	}
	if ($equals =~ /[^\d]/ || $data =~ /[^\d]/){
		return TRUE;
	}
	my $m = new Math::Expression;
	$m->VarSetScalar('x',$data);
	my $mtree = $m->Parse($calc);
	my $value = $m->EvalToScalar($mtree);
	return ($value == $equals) ? $is : $is_not;
}

=head1 AUTHOR

Yusuke Sugiyama, C<< <ally at blinkingstar.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-formvalidator-simple-plugin-math at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FormValidator-Simple-Plugin-Math>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FormValidator::Simple::Plugin::Math

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FormValidator-Simple-Plugin-Math>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FormValidator-Simple-Plugin-Math>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FormValidator-Simple-Plugin-Math>

=item * Search CPAN

L<http://search.cpan.org/dist/FormValidator-Simple-Plugin-Math>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Yusuke Sugiyama, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of FormValidator::Simple::Plugin::Math
