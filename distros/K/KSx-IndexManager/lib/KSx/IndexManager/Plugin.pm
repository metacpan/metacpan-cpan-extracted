use strict;
use warnings;

package KSx::IndexManager::Plugin;

use base qw(Class::Accessor::Grouped);

sub new { bless $_[1] => $_[0] }

sub before_new { }
sub after_new  { }

sub alter_path { }

sub before_add_doc { }
sub after_add_doc { }

1;
__END__

=head1 NAME

KSx::IndexManager::Plugin - base class for IndexManager plugins

=head1 SYNOPSIS

  package KSx::IndexManager::Plugin::Mine;
  use base qw(KSx::IndexManager::Plugin);

  sub after_new {
    my ($plugin, $self) = @_;
    # do something with $self
  }

=head1 METHODS

=head2 new

Create a new plugin.  This is called for you automatically and you should not
need to use it.

=head2 before_new

=head2 after_new

Called when creating a new Manager.  C<before_new> is passed the hashref
argument to C<new>, and C<after_new> is passed the newly created Manager.

=head2 alter_path

Called with the Manager object and a reference to the path as a string.

=head2 before_add_doc

=head2 after_add_doc

Called when adding a document to the invindex.  Both methods are passed the
Manager and the object being added.

=cut
