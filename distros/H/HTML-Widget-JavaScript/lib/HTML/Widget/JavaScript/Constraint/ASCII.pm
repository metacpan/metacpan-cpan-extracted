package HTML::Widget::JavaScript::Constraint::ASCII;

use warnings;
use strict;

use base 'HTML::Widget::Constraint::ASCII';

=head1 NAME

HTML::Widget::JavaScript::Constraint::ASCII - JavaScript ASCII Constraint

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

JavaScript ASCII Constraint.

=head1 METHODS

See L<HTML::Widget::Constraint::ASCII>.

=head2 $self->emit_javascript($var_name)

Emits this constraint's JavaScript validation code.

=cut

sub emit_javascript {
	my ($self, $var_name) = @_;
	
	my @js_constraints;

	my $not = $self->not ? '' : '!';
	
	for my $param (@{$self->names}) {
		push(@js_constraints, qq[ (${var_name}.${param}.value != '' && $not /^[\\x20-\\x7E]*\$/.test(${var_name}.${param}.value)) ]);	
	}
	
	return @js_constraints;
}

=head1 AUTHOR

Nilson Santos Figueiredo Júnior, C<< <nilsonsfj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests directly to the author.
If you ask nicely it will probably get fixed or implemented.

=head1 COPYRIGHT & LICENSE

Copyright 2006, 2009 Nilson Santos Figueiredo Júnior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::Widget::JavaScript::Constraint
