package EntityModel::Web::Page::Pathinfo;
{
  $EntityModel::Web::Page::Pathinfo::VERSION = '0.004';
}
use EntityModel::Class {
	name		=> 'string',
};

=head1 NAME



=head1 SYNOPSIS

=head1 VERSION

version 0.004

=head1 DESCRIPTION

=cut

use Data::Dumper;

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new;
	my %args = %{$_[0]};
	if(defined(my $name = delete $args{name})) {
		$self->{name} = $name;
	}
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.
