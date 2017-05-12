package EntityModel::Query::Delete;
{
  $EntityModel::Query::Delete::VERSION = '0.102';
}
use EntityModel::Class {
	_isa => [qw{EntityModel::Query}],
};

=head1 NAME

EntityModel::Query::Delete - support for SQL DELETE statements

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<Entitymodel::Query>.

=head1 DESCRIPTION

See L<Entitymodel::Query>.

=cut

=head1 METHODS

=cut

=head2 type

=cut

sub type { 'delete'; }

=head2 keyword_order

=cut

sub keyword_order { qw{type from where order offset limit}; }

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
