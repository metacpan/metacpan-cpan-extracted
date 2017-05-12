package Device::Hue::Light;
{
  $Device::Hue::Light::VERSION = '0.4';
}

use common::sense;
use Class::Accessor;
use JSON::XS;
use Hash::Merge::Simple qw/ merge /;
use Data::Dumper;

use base qw(Class::Accessor);

__PACKAGE__->mk_accessors( qw / id hue _trx params data / );

sub begin
{
        my ($self) = @_;

	$self->_trx(1);
	return $self;
}

sub commit
{
        my ($self) = @_;

	$self->_trx(0);

	my $r = $self->hue->put($self->hue->path_to('lights', $self->id, 'state'), $self->params);

	$self->params({});
	return $r;
}

sub in_transaction
{
	return (shift)->_trx;
}

sub merge_param
{
        my ($self, $param) = @_;
	$self->params(merge($self->params || {}, $param));
	return $self;
}

sub set_state
{
        my ($self, $param) = @_;

	if (exists $param->{'on'}) {
		$param->{'on'} = (defined $param->{'on'} && $param->{'on'}) ? JSON::XS::true : JSON::XS::false;
	}

	$self->merge_param($param);

	if ($self->_trx) {
	} else {
#		say Dumper($param);
		$self->commit;
#		say Dumper($r->data);
	}

	return $self;
}

sub on
{
	return (shift)->set_state({ 'on' => 1 }); 
}

sub off
{
	return (shift)->set_state({ 'on' => 0 }); 
}

sub bri
{
	return (shift)->set_state({ 'bri' => int shift });
}

# 150-500
sub ct
{
	return (shift)->set_state({ 'ct' => int shift });
}

# 2000-6500
sub ct_k
{
	return (shift)->ct(1_000_000 / shift);
}

sub transitiontime
{
	return (shift)->merge_param({ 'transitiontime' => int shift });
}

sub name { return (shift)->data->{'name'}; }
sub type { return (shift)->data->{'type'}; }
sub modelid { return (shift)->data->{'modelid'}; }
sub swversion { return (shift)->data->{'swversion'}; }


1;

__END__

=pod

=head1 NAME

Device::Hue::Light

=head1 VERSION

version 0.4

=head1 AUTHOR

Alessandro Zummo <a.zummo@towertech.it>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Alessandro Zummo.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
