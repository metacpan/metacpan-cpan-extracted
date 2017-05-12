package Gtk2::Ex::FormFactory::ProxyBuffered;

use base qw(Gtk2::Ex::FormFactory::Proxy);

use strict;
use Carp;

sub get_attr_buffer		{ shift->{attr_buffer}			}
sub set_attr_buffer		{ shift->{attr_buffer}		= $_[1]	}

sub get_buffered		{ 1 }

my $DEBUG = 0;

sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new(@_);
	
	$self->set_attr_buffer({});
	
	return $self;
}

sub discard_buffer {
	my $self = shift;
	$self->set_attr_buffer({});
	1;
}

sub commit_buffer {
	my $self = shift;
	
	while ( my ($attr, $value) = each %{$self->get_attr_buffer} ) {
		$self->SUPER::set_attr($attr, $value);
	}
	
	1;
}

sub set_object {
	my $self = shift;
	my ($object) = @_;
$DEBUG && print "set_object: $self->{name} = $object\n";

	if ( $self->{object} ne $object ) {
		$self->discard_buffer;
	}

	$self->SUPER::set_object($object);

	1;
}

sub get_attr {
	my $self = shift;
	my ($attr_name) = @_;

	if ( $attr_name =~ /^([^.]+)\.(.*)$/ ) {
		$self      = $self->get_context->get_proxy($1);
		$attr_name = $2;
	}
$DEBUG && print "get_attr: ".$self->get_name.".$attr_name ";
$DEBUG && print "FROM BUFFER\n" if exists $self->{attr_buffer}->{$attr_name};
	return $self->{attr_buffer}->{$attr_name}
	       if exists $self->{attr_buffer}->{$attr_name};
$DEBUG && print "FROM OBJECT\n";
	return $self->SUPER::get_attr($attr_name);
}

sub set_attr {
	my $self = shift;
	my ($attr_name, $attr_value) = @_;

	if ( $attr_name =~ /^([^.]+)\.(.*)$/ ) {
		$self      = $self->get_context->get_proxy($1);
		$attr_name = $2;
	}

	my $object   = $self->get_object;
	my $name     = $self->get_name;

$DEBUG && print "set_attr: $name.$attr_name => $attr_value\n";
use Data::Dumper;print Dumper($attr_value) if ref $attr_value;
	$self->{attr_buffer}->{$attr_name} = $attr_value;

	$self->get_context
	     ->update_object_attr_widgets($name, $attr_name, $object);

	my $child_object_name = $self->get_attr_aggregate_href->{$attr_name};

	$self->get_context->set_object($child_object_name, $attr_value)
		if $child_object_name;

	return $attr_value;
}

sub set_attrs {
	my $self = shift;
	my ($attrs_href) = @_;
	
	my $object   = $self->get_object;
	my $name     = $self->get_name;
	my $context  = $self->get_context;

	my ($attr_name, $attr_value, $child_object_name);
	while ( ($attr_name, $attr_value) = each %{$attrs_href} ) {
		$self->{attr_buffer}->{$attr_name} = $attr_value;
		$context->update_object_attr_widgets(
			$name, $attr_name, $object
		);
		$child_object_name = $self->get_attr_aggregate_href->{$attr_name};
		$context->set_object($child_object_name, $attr_value)
			if $child_object_name;
	}
	
	1;
}

sub commit_attr {
	my $self = shift;
	my ($attr) = @_;

	my $attr_buffer = $self->get_attr_buffer;
	return unless exists $attr_buffer->{$attr};

	my $value = $attr_buffer->{$attr};
$DEBUG && print "commit attr: $attr => $value\n";
	$self->SUPER::set_attr($attr, $value, 1);
	
	1;
}

sub discard_attr {
	my $self = shift;
	my ($attr) = @_;

$DEBUG && print "discard attr: $attr";
	delete $self->get_attr_buffer->{$attr};

	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::ProxyBuffered - Buffering object proxy

=head1 SYNOPSIS

  #-- Proxies are always created through
  #-- Gtk2::Ex::FormFactory::Context, never
  #-- directly by the application.

  Gtk2::Ex::FormFactory::ProxyBuffered->new (
    Gtk2::Ex::FormFactory::Proxy attributes
  );

=head1 DESCRIPTION

This class is derived from Gtk2::Ex::FormFactory::Proxy and
buffers all changes made to object through the proxy.
For details about buffering please refer to the chapter
BUFFERED CONTEXT OBJECTS in Gtk2::Ex::FormFactory::Context.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Proxy
  +-- Gtk2::Ex::FormFactory::ProxyBuffered

=head1 ATTRIBUTES

This module has no additional attributes over those derived
from Gtk2::Ex::FormFactory::Proxy.

=back

=head1 METHODS

=over 4

=item $proxy->B<commit_buffer> ()

Commits all changes buffered in the $proxy object to the
corresponding application object.

=item $proxy->B<discard_buffer> ()

Discards all buffered changes.

=back

For more methods refer to L<Gtk2::Ex::FormFactory::Proxy>.

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
