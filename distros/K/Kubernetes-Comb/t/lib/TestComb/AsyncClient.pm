package TestComb::AsyncClient;
# Whether the async client can be used on this machine. Plain POD: t/lib is
# not woven.

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw( async_client_refusal );

=head1 FUNCTIONS

=head2 async_client_refusal

  my $refusal = async_client_refusal;
  plan skip_all => $refusal if defined $refusal;

Loads L<Kubernetes::Comb::Client::Async>. Returns nothing when that worked,
and the reason when the client refused to load over an optional dependency
that is missing or too old -- which one, and which version it needs, is the
client's knowledge and is not repeated here. Any other failure to load is a
bug and is thrown as it is.

=cut

sub async_client_refusal {
  return if eval { require Kubernetes::Comb::Client::Async; 1 };
  my $error = $@;
  die $error
    unless $error =~ /\AKubernetes::Comb::Client::Async needs \S+(?: \S+ or newer)?, an optional dependency of Kubernetes::Comb/;
  $error =~ s/(?:: Can't locate | at .+? line \d+\.).*//s;
  return $error;
}

1;
