package EntityModel::Util;
{
  $EntityModel::Util::VERSION = '0.102';
}
use EntityModel::Class {};
use parent qw(Exporter);
our @EXPORT = qw(as_transaction);
our @EXPORT_OK = qw(as_transaction);

=head1 NAME

EntityModel::Util - helper functions for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

=cut

use EntityModel::Transaction;

=head1 METHODS

=cut

=head2 as_transaction

Helper function to run the given block as a transaction.

Takes a block, which will be run under a transaction, and the
following optional named parameters:

=over 4

=item * success - coderef to call on successful completion. The transaction will be committed
before this is called.

=item * failure - coderef to call on failure. This will be called after the transaction has
been rolled back.

=item * goodbye - coderef to call after success/failure. This will always be called regardless
of status, and can be used to chain events similar to L<CPS>.

=back

Returns the transaction in list or scalar context, and in void
context will clean up the transaction automatically.

=cut

sub as_transaction(&;@) {
	my $code = shift;
	my %args = @_;
	my $tran = EntityModel::Transaction->new;
	$tran->run($code, %args);
	# unless we're in void context, pass the transaction back for something else
	# to take a crack at it
	return $tran if defined wantarray;
	$tran->commit;
	undef;
}

1;
