use strict;
use warnings;

package KSx::IndexManager::Plugin::Partition;

use base qw(KSx::IndexManager::Plugin);
__PACKAGE__->mk_group_accessors(simple => qw(key value));

use File::Spec;
use Carp::Clan qw(^KSx::IndexManager);

sub _value { 
  my ($plugin, $arg) = @_;
  defined $arg->{$plugin->key} or
    croak "missing partition key: " . $plugin->key;
  return $arg->{$plugin->key};
}

sub _value_method {
  my ($plugin, $arg) = @_;
  my $meth = $arg->can($plugin->key) or
    croak "$arg is missing partition method: " . $plugin->key;
  return $arg->$meth;
}

sub new {
  my ($class, $arg) = @_;
  if ($arg->{method}) {
    $arg->{key} = delete $arg->{method};
    $arg->{value} ||= \&_value_method;
  } else {
    $arg->{value} ||= \&_value;
  }
  my $self = shift->SUPER::new(@_);
  return $self;
}

sub alter_path {
  my ($plugin, $self, $path_ref) = @_;
  $$path_ref = File::Spec->catdir(
    $$path_ref,
    $plugin->value->($plugin, $self->context),
  );
} 

1;
__END__

=head1 NAME

KSx::IndexManager::Plugin::Partition

=head1 SYNOPSIS

  package MyManager;
  use base qw(KSx::IndexManager);
  __PACKAGE__->add_plugins(
    Partition => { key => 'type' },
    Partition => { key => 'id' },
  );

  package main;
  my $mgr = MyManager->new({
    path => "/path/to/dir",
    context => { type => 'animal', id => 17 },
  });

  # both now look in /path/to/dir/animal/17
  my $invindexer = $mgr->invindexer;

  my $searcher = $mgr->searcher;

=head1 METHODS

=head2 new

Takes a hashref with one of three keys:

=over 4

=item key

uses the context as a hashref and looks up the given key

=item method

uses the context as an object and calls the given method

=item code

passes the context to the given subref

=back

=head2 alter_path

Changes the path with data from C<< $mgr->context >>.

=cut
