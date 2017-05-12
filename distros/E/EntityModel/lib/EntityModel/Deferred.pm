package EntityModel::Deferred;
{
  $EntityModel::Deferred::VERSION = '0.102';
}
use EntityModel::Class {
	_isa	=> [qw(Mixin::Event::Dispatch)],
	event_queue	=> { type => 'array', subclass => 'arrayref' },
};

=head1 NAME

EntityModel::Deferred - value which is not yet ready

=head1 VERSION

version 0.102

=head1 SYNOPSIS

 use EntityModel::Deferred;
 my $deferred = EntityModel::Deferred->new;

=head1 DESCRIPTION


=head1 METHODS

=cut

=head2 value

=cut

sub new {
	my $self = shift->SUPER::new;
	my %args = @_;
	$self->provide_value(delete $args{value}) if exists $args{value};
	return $self;
}
sub value {
	my $self = shift;
	die "Value is not yet ready" unless exists $self->{value};
	return $self->{value};
}

=head2 provide_value

=cut

sub provide_value {
	my $self = shift;
	$self->{value} = shift;
	$self->invoke_event('ready' => $self->{value});
	return $self;
}

=head2 raise_error

=cut

sub raise_error {
	my $self = shift;
	$self->invoke_event('error' => @_);
}

sub add_handler {
	my $self = shift;
	my $rslt = $self->SUPER::add_handler_for_event(@_);
	$self->invoke_event('ready' => $self->{value}) if exists $self->{value};
	return $rslt;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
