package Example::Comb::Mailer::Stub;
# ABSTRACT: Example stub: a Mailpit instead of the SMTP relay

# A stub is a subclass: it inherits the contract of the Mailer -- the
# endpoint smtp, which the contract check at construction insists on -- and
# swaps the implementation. Here the implementation is a .pk8s file next to
# this module, loaded by Kubernetes::Comb::Role::Static; a distribution of
# Comb classes would keep it in its share dir (File::ShareDir's dist_dir).

use Moo;
extends 'Example::Comb::Mailer';
with 'Kubernetes::Comb::Role::Static';

use Path::Tiny qw( path );
use namespace::autoclean;

sub manifest_dir   { path(__FILE__)->absolute->parent }
sub manifest_files { 'Stub.pk8s' }

# Mailpit catches every mail: no relay, nothing to configure.
sub check { return }

# A stub may offer more than its original: Mailpit's web interface.
around endpoints => sub {
  my ( $orig, $self ) = @_;
  return ( $self->$orig, { name => 'web', port => 8025 } );
};

1;
