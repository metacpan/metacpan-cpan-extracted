package Hopkins::TaskOption;

use strict;

=head1 NAME

Hopkins::TaskOption - task object

=head1 DESCRIPTION

Hopkins::TaskOption represents a task option.

=cut

use base 'Class::Accessor::Fast';

use Hopkins::TaskOptionChoices;

__PACKAGE__->mk_accessors(qw(name type value choices));

sub choices
{
	my $self = shift;

	return $self->set(choices => @_) if @_;

	my $choices = $self->get('choices');

	$choices->fetch if $choices;

	return $choices;
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

=cut

1;

