package EntityModel::Plugin;
{
  $EntityModel::Plugin::VERSION = '0.102';
}
sub import; # forward ref due to the way the class is set up
use EntityModel::Class {
	model => { type => 'EntityModel' }
};

=head1 NAME

EntityModel::Plugin - base class for plugin handling

=head1 VERSION

version 0.102

=head1 SYNOPSIS

see L<EntityModel>.

=head1 DESCRIPTION

see L<EntityModel>.

=cut

use EntityModel;
use Scalar::Util qw(weaken);

=head1 METHODS

=cut

=pod

(the following is likely to be very inaccurate)

Each plugin can register for a type:

->registerForType('table') - registers as a handler for 'table' content, e.g.

 <table>...</table>

in XML definitions.

=cut

sub import {
	my $class = shift;
	my $pkg = caller;

#	EntityModel->registerPlugin($pkg) if eval { $pkg->isa('EntityModel::Plugin'); };

	1;
}

=pod

Provides import and export for entity model definitions to a given interface.

=cut

sub new {
	my $class = shift;
	my $model = shift;
	my $self = bless {
		model => $model
	}, $class;

	weaken $self->{model};
#	$self->setup(@_);
	return $self;
}

sub setup { die "Virtual method setup called for " . $_[0]; }

sub unload { $_[0]; }

sub publish {
	my $self = shift;
	my $name = shift;
	my $value = shift;
	die "Key $name already present" if exists $self->model->{$name};
	$self->model->{$name} = $value;
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
