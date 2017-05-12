package EntityModel::StorageClass::KVStore::Layer::Fake;
{
  $EntityModel::StorageClass::KVStore::Layer::Fake::VERSION = '0.102';
}
use strict;
use warnings;
use parent qw(EntityModel::StorageClass::KVStore::Layer);

sub retrieve {
	my $self = shift;
	my %args = @_;
	$args{on_success}->('rslt:' . reverse $args{query}) if $args{on_success};
	$self;
}

1;

