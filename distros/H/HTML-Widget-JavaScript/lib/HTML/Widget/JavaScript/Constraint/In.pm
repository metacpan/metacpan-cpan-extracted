package HTML::Widget::JavaScript::Constraint::In;

use warnings;
use strict;

use base 'HTML::Widget::Constraint::In';

=head1 NAME

HTML::Widget::JavaScript::Constraint::In - JavaScript In Constraint

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

JavaScript In Constraint.

=head1 METHODS

See L<HTML::Widget::Constraint::In>.

=head2 $self->emit_javascript($var_name)

Emits this constraint's JavaScript validation code.

=cut

sub emit_javascript {
	my ($self, $var_name) = @_;
	
	my @js_constraints;

	my $not = $self->not ? '' : '!';

	for my $param (@{$self->names}) {
		push(@js_constraints, "($not(${var_name}.${param}.value != '' && (" . join(' || ', map {"${var_name}.${param}.value == '$_'"} @{$self->in}) . ")))");
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
