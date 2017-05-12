package EntityModel::Field::Refer;
{
  $EntityModel::Field::Refer::VERSION = '0.102';
}
use EntityModel::Class {
	'entity'	=> { type => 'EntityModel::Entity' },
	'table'		=> { type => 'string' },
	'field'		=> { type => 'string' },
	'delete'	=> { type => 'string' },
	'update'	=> { type => 'string' },
};

=head1 NAME

EntityModel::Field::Refer - foreign key support for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=cut

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
