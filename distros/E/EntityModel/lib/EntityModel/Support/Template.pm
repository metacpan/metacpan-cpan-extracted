package EntityModel::Support::Template;
{
  $EntityModel::Support::Template::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Support}],
	namespace	=> { type => 'string' },
	baseclass	=> { type => 'string' },
};

=head1 NAME

EntityModel::Support::Template - generic language support via L<Template> output.

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=cut

use EntityModel::Template;

=head1 METHODS

=cut

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
