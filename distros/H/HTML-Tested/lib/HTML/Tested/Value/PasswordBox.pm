=head1 NAME

HTML::Tested::Value::PasswordBox - password input.

=head1 DESCRIPTION

Provides <input type="password" /> html tag.

=head1 METHODS

=cut

use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::PasswordBox;
use base 'HTML::Tested::Value';

=head2 $class->new($parent, $name, %opts)

Overloads C<HTML::Tested::Value> C<new> function to handle C<check_mismatch>
option.

=cut
sub new {
	my ($class, $parent, $name, %opts) = @_;
	my $other = $opts{check_mismatch};
	push @{ $opts{constraints} }, [ mismatch => sub {
		my ($v, $root) = @_;
		return ($v // '') eq ($root->$other // '');
	} ] if $other;
	return $class->SUPER::new($parent, $name, %opts);
}

sub value_to_string {
	my ($self, $name, $val) = @_;
	return <<ENDS;
<input type="password" name="$name" id="$name" value="$val" />
ENDS
}

1;

=head1 OPTIONS

=over

=item check_mismatch

Checks mismatch between two passwords during validate phase. The parameter
should be the name of another password box.

E.g. check_mismatch => 'another_password'.

On failure produces C<mismatch> result for validate function.

=back

=head1 AUTHOR

Boris Sukholitko (boriss@gmail.com)
	
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
