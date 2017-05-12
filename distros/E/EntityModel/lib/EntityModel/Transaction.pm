package EntityModel::Transaction;
{
  $EntityModel::Transaction::VERSION = '0.102';
}
use EntityModel::Class;
use overload '&{}' => sub {
	my $self = shift;
	sap($self, 'apply');
}, fallback => 1;
use Try::Tiny;

=head1 NAME

EntityModel::Transaction - transaction co-ordinator

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

Contacts each L<EntityModel::Storage> instance and requests that they join a new
transaction.

See L<EntityModel>.

=head2 apply

Applies the current transaction. Typically called as the last
step in the transaction codeblock. The &{} overload will call
this method (so you can use C< $tran->() > or C< $tran->apply >
interchangeably).

Takes no parameters.

Returns $self.

=cut

sub apply {
	my $self = shift;

	return $self if $self->{rolled_back};
	return $self unless try {
		# commit
		1;
	} catch {
		$self->mark_failure;
		$self->mark_goodbye;
		0
	};
	$self->mark_success;
	$self->mark_goodbye;
	$self;
}

=head2 mark_failure

Mark this transaction as failed, applying rollback if required, and
calls the failure coderef.

Takes no parameters.

Returns $self.

=cut

sub mark_failure {
	my $self = shift;
	# rollback here
	$self->{rolled_back} = 1;
	$self->{on_failure}->($self) if exists $self->{on_failure};
	$self
}

=head2 mark_success

Mark this transaction as successful, committing if required, and
calls the success coderef.

Takes no parameters.

Returns $self.

=cut

sub mark_success {
	my $self = shift;
	$self->{on_success}->($self) if exists $self->{on_success};
	$self
}

=head2 mark_goodbye

Mark this transaction as completed. Calls the C<goodbye> coderef
if available.

Takes no parameters.

Returns $self.

=cut

sub mark_goodbye {
	my $self = shift;
	$self->{on_goodbye}->($self) if exists $self->{on_goodbye};
	$self
}

=head2 run

Takes the following (named) parameters:

=over 4

=item *

=back

Returns $self.

=cut

sub run {
	my $self = shift;
	my $code = shift;
	my %args = @_;
	$self->{"on_$_"} = delete $args{$_} for grep exists $args{$_}, qw(success failure goodbye);
	# Attempt the transaction bit, normally we'd expect
	# this to set up a few deferred events and return
	# quickly
	return $self unless try {
		sap($self, $code)->();
		1;
	} catch {
		# Something went wrong, bail
		$self->mark_failure;
		$self->mark_goodbye;
		0;
	};
	$self;
}

sub commit {
	my $self = shift;
	return $self if $self->{rolled_back};
	$self->{committed} = 1;
	$self
}

sub DESTROY {
	my $self = shift;
	warn "did not finish" unless $self->{committed} || $self->{rolled_back};
}

sub sap {
	my ($self, $sub) = @_;
	Scalar::Util::weaken $self;
	return sub {
		$self->$sub(@_);
	};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
