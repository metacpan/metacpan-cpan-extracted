=head1 NAME

HTML::Tested::Value::Upload - Upload widget.

=head1 DESCRIPTION

Provides <input type="file"> widget.

In C<POST> context holds upload's filehandle. If C<object> option is given
returns C<Apache::Upload> object.

=cut
use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Upload;
use base 'HTML::Tested::Value';

sub absorb_one_value {
	my ($self, $root, $val, @path) = @_;
	$val = $val->fh unless $self->options->{object};
	$root->{ $self->name } = $val;
}

sub prepare_value { return ''; }

sub value_to_string {
	my ($self, $name, $val) = @_;
	return <<ENDS
<input type="file" id="$name" name="$name" />
ENDS
}

1;

=head1 AUTHOR

	Boris Sukholitko
	CPAN ID: BOSU
	
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

