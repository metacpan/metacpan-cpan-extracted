package Device::Hue::LightSet;
{
  $Device::Hue::LightSet::VERSION = '0.4';
}

use common::sense;
use Class::Accessor;

use base qw(Class::Accessor);
use vars qw($AUTOLOAD);

__PACKAGE__->mk_accessors( qw / _group _trx / );

sub create
{
	my ($self, @lights) = @_;

	$self = ref($self) || $self->new;

	$self->_group([ @lights ]);
	
	return $self;
}

sub begin
{
	my ($self) = @_;

	$self->_trx(1);
	do { $_->begin; } for @{$self->_group};	
}

sub commit
{
	my ($self) = @_;

	do { $_->commit; } for @{$self->_group};	
	$self->_trx(0);
}

sub in_transaction
{
	return (shift)->_trx;
}

sub AUTOLOAD
{
	my ($self, @args) = @_;

	(my $method = $AUTOLOAD) =~ s/.*:://;

	return if $method eq 'DESTROY';

	foreach (@{$self->_group}) {
		my $rc = $_->$method(@args);
	}
} 

1;

__END__

=pod

=head1 NAME

Device::Hue::LightSet

=head1 VERSION

version 0.4

=head1 AUTHOR

Alessandro Zummo <a.zummo@towertech.it>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Alessandro Zummo.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
