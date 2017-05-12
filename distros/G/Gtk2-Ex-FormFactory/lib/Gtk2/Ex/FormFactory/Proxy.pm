package Gtk2::Ex::FormFactory::Proxy;

use strict;
use Carp;

my $NAME_CNT = 0;

sub get_context			{ shift->{context}			}
sub get_name			{ shift->{name}				}
sub get_aggregated_by		{ shift->{aggregated_by}		}
sub get_set_prefix		{ shift->{set_prefix}			}
sub get_get_prefix		{ shift->{get_prefix}			}
sub get_attr_activity_href	{ shift->{attr_activity_href}		}
sub get_attr_accessors_href	{ shift->{attr_accessors_href}		}
sub get_attr_aggregate_href	{ shift->{attr_aggregate_href}		}
sub get_accessor		{ shift->{accessor}			}
sub get_changes_attr_filter     { shift->{changes_attr_filter}          }

sub get_buffered		{ 0 }

sub get_object_changed          { shift->{object_changed}               }
sub set_object_changed          { shift->{object_changed}       = $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my  ($context, $object, $name, $set_prefix, $get_prefix) =
	@par{'context','object','name','set_prefix','get_prefix'};
	my  ($attr_accessors_href, $attr_activity_href, $aggregated_by) =
	@par{'attr_accessors_href','attr_activity_href','aggregated_by'};
	my  ($accessor, $changes_attr_filter) =
	@par{'accessor','changes_attr_filter'};

	$attr_accessors_href ||= {},
	$attr_activity_href  ||= {};
	$name                ||= "object_".$NAME_CNT++; 

	my $self = bless {
		context			=> $context,
		object			=> $object,
		name			=> $name,
		aggregated_by		=> $aggregated_by,
		set_prefix		=> $set_prefix,
		get_prefix		=> $get_prefix,
		attr_activity_href	=> $attr_activity_href,
		attr_accessors_href	=> $attr_accessors_href,
		accessor		=> $accessor,
                changes_attr_filter     => $changes_attr_filter,
		attr_aggregate_href	=> {},
	}, $class;

	return $self;
}

sub get_object {
	my $self = shift;
	my $object = $self->{object};
	ref $object eq 'CODE' ? &$object() : $object;
}

sub update_by_aggregation {
	my $self = shift;
	
	my $aggregated_by = $self->get_aggregated_by;
	
	my $object = $self->get_attr($aggregated_by);
	
	$self->set_object($object);
	
	1;
}

sub set_object {
	my $self = shift;
	my ($object) = @_;

	#-- nothing to do if it's the same object
	#-- (eval{} is for catching Class::DBI exceptions if
	#-- $self->{object} was deleted in the meantime)
	return if eval { $object eq $self->{object} };

        #-- reset changed status
        $self->set_object_changed(0);

        #-- set object
	$self->{object} = $object;
	
        #-- Update all object widgets
	my $context = $self->get_context;
	$context->update_object_widgets ($self->get_name);

        #-- Update aggregated objects
	my $attr_aggregate_href = $self->get_attr_aggregate_href;
	my ($attr, $child_object_name, $child_object);

	while ( ($attr, $child_object_name) = each %{$attr_aggregate_href} ) {
		$child_object = $self->get_attr($attr);
		$context->set_object($child_object_name, $child_object);
	}

	return $object;
}

sub get_attr {
	my $self = shift;
	my ($attr_name) = @_;
	
	if ( $attr_name =~ /^([^.]+)\.(.*)$/ ) {
		$self      = $self->get_context->get_proxy($1);
		$attr_name = $2;
	}

	my $accessor = $self->get_accessor;
	my $object   = $self->get_object;

	return &$accessor($object, $attr_name) if $accessor;
	
	my $method = $self->get_get_prefix.$attr_name;
	$accessor  = $self->get_attr_accessors_href->{$method};

	return if not $object;
	return &$accessor($object) if $accessor;
	return $object->$method();
}

sub set_attr {
	my $self = shift;
	my ($attr_name, $attr_value, $no_widget_update) = @_;

	if ( $attr_name =~ /^([^.]+)\.(.*)$/ ) {
		$self      = $self->get_context->get_proxy($1);
		$attr_name = $2;
	}

        $self->object_changed($attr_name);

	my $accessor = $self->get_accessor;
	my $object   = $self->get_object;
	my $name     = $self->get_name;

	my $rc;
	if ( $accessor ) {
		$rc = &$accessor($object, $attr_name, $attr_value);
	} else {
		my $set_prefix = $self->get_set_prefix;
		my $method     = $set_prefix.$attr_name;
		$accessor      = $self->get_attr_accessors_href->{$method};
		$rc = $accessor ?
			&$accessor($object, $attr_value) :
			$object->$method($attr_value);
	}

	return $rc if $no_widget_update;

	$self->get_context
	     ->update_object_attr_widgets($name, $attr_name, $object);
	
	my $child_object_name = $self->get_attr_aggregate_href->{$attr_name};

	$self->get_context->set_object($child_object_name, $attr_value)
		if $child_object_name;
	
	return $rc;
}

sub set_attrs {
	my $self = shift;
	my ($attrs_href, $no_widget_update) = @_;
	
	my $set_prefix  = $self->get_set_prefix;
	my $object      = $self->get_object;
	my $name        = $self->get_name;
	my $context     = $self->get_context;
	my $accessors   = $self->get_attr_accessors_href;
	
	my ($method, $attr_name, $attr_value, $accessor, $child_object_name);
	
	$accessor = $self->get_accessor;
	
	while ( ($attr_name, $attr_value) = each %{$attrs_href} ) {
                $self->object_changed($attr_name);
		if ( $accessor ) {
			&$accessor($object, $attr_name, $attr_value);
		} else {
			$method = $set_prefix.$attr_name;
			$accessor = $accessors->{$method};
			$accessor ?
				&$accessor($object, $attr_value) :
				$object->$method($attr_value);
		}
		$accessor = undef;
		next if $no_widget_update;
		$context->update_object_attr_widgets(
			$name, $attr_name, $object
		);
		$child_object_name = $self->get_attr_aggregate_href->{$attr_name};
		$context->set_object($child_object_name, $attr_value)
			if $child_object_name;
	}
	
	1;
}

sub get_attr_presets {
	my $self = shift;
	my ($attr_name) = @_;
	
	my $method  = $self->get_get_prefix.$attr_name."_presets";
	my $object  = $self->get_object;
	my $accessor = $self->get_attr_accessors_href->{$method};

	return &$accessor($object) if ref $accessor eq 'CODE';
	return $accessor if $accessor;
	return $object->$method();
}

sub get_attr_rows {
	my $self = shift;
	my ($attr_name) = @_;
	
	my $method  = $self->get_get_prefix.$attr_name."_rows";
	my $object  = $self->get_object;
	my $accessor = $self->get_attr_accessors_href->{$method};

	return &$accessor($object) if ref $accessor eq 'CODE';
	return $accessor if $accessor;
	return $object->$method();
}

sub get_attr_list {
	my $self = shift;
	my ($attr_name, $widget_name) = @_;
	
	my $method  = $self->get_get_prefix.$attr_name."_list";
	my $object  = $self->get_object;
	my $accessor = $self->get_attr_accessors_href->{$method};

	return &$accessor($object, $widget_name) if ref $accessor eq 'CODE';
	return $accessor if $accessor;
	return $object->$method($widget_name);
}

sub get_attr_presets_static {
	my $self = shift;
	my ($attr_name) = @_;
	
	my $method  = $self->get_get_prefix.$attr_name."_presets_static";
	my $object  = $self->get_object;
	my $accessor = $self->get_attr_accessors_href->{$method};

	return &$accessor($object) if ref $accessor eq 'CODE';
	return $accessor if $accessor;
	return 1 if not $object->can($method);
	return $object->$method();
}

sub get_attr_rows_static {
	my $self = shift;
	my ($attr_name) = @_;
	
	my $method  = $self->get_get_prefix.$attr_name."_rows_static";
	my $object  = $self->get_object;
	my $accessor = $self->get_attr_accessors_href->{$method};

	return &$accessor($object) if ref $accessor eq 'CODE';
	return $accessor if $accessor;
	return 1 if not $object->can($method);
	return $object->$method();
}

sub get_attr_list_static {
	my $self = shift;
	my ($attr_name) = @_;
	
	my $method  = $self->get_get_prefix.$attr_name."_list_static";
	my $object  = $self->get_object;
	
	return 1 if not $object->can($method);
	return $object->$method();
}

sub get_attr_activity {
	my $self = shift;
	my ($attr_name) = @_;

	$Gtk2::Ex::FormFactory::DEBUG &&
	    print "    proxy->get_attr_activity($attr_name)\n";

	my $object = $self->get_object;
	return 0 if not defined $object;

	my $attr_activity_href = $self->get_attr_activity_href;

	return 1 if not $attr_activity_href or
		    not exists $attr_activity_href->{$attr_name};

	my $attr_activity = $attr_activity_href->{$attr_name};

	return $attr_activity if not ref $attr_activity eq 'CODE';
	return &$attr_activity($object);
}

sub object_changed {
        my $self = shift;
        my ($attr_name) = @_;
        
        my $changes_attr_filter = $self->get_changes_attr_filter;

        if ( !$changes_attr_filter ||
             $attr_name !~ $changes_attr_filter ) {
            $self->set_object_changed(1);
            my $aggregated_by = $self->get_aggregated_by;
            if ( $aggregated_by ) {
                my $context = $self->get_context;
                my ($object, $attr) = $context->norm_object_attr($aggregated_by);
                $context->get_proxy($object)->object_changed($attr);
            }
        }
        
        1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Proxy - Proxy class for application objects

=head1 SYNOPSIS

  #-- Proxies are always created through
  #-- Gtk2::Ex::FormFactory::Context, never
  #-- directly by the application.

  Gtk2::Ex::FormFactory::Proxy->new (
    context              => Gtk2::Ex::FormFactory::Context,
    object               => Object instance or CODEREF,
    name                 => Name of this proxy,
    set_prefix           => Method prefix for write accessors,
    get_prefix           => Method prefix for read accessors,
    attr_accessors_href  => Hashref with accessor callbacks,
    attr_activity_href   => Hashref with activity callbacks,
    aggregated_by        => Fully qualified attribute of the parent,
    changes_attr_filter  => Regex for attributes which should not trigger
                            the object's 'changed' status
  );

=head1 DESCRIPTION

This class implements a generic proxy mechanism for accessing
application objects and their attributes. It defines attributes
of the associated object are accessed. You never instantiate
objects of this class by yourself; they're created internally by
Gtk2::Ex::FormFactory::Context when adding objects with the
Context->add_object() method.

But you may use the proxy objects e.g. for updates which affect the
application object and the GUI as well.

You can receive Proxy objects using the Gtk2::Ex::FormFactory::Context->get_proxy()
method.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors.

=over 4

=item B<context> = Gtk2::Ex::FormFactory::Context [mandatory]

The Context this proxy belongs to.

=item B<object> = Object instance | CODEREF

The application object itself or a code reference, which returns
the object instance.

=item B<name> = SCALAR [mandatory]

The Context wide unique name of this Proxy.

=item B<set_prefix> = SCALAR [optional]

This is the method prefix for write accessors. Defaults to B<set_>.

=item B<get_prefix> = SCALAR [optional]

This is the method prefix for read accessors. Defaults to B<get_>.

=item B<attr_accessors_href> = HASHREF [optional]

With this hash you can override specific accessors with a code
reference, which is called instead of the object's own accessor.

Refer to Gtk2::Ex::FormFactory::Context->add_object for details.

=item B<attr_activity_href> = HASHREF [optional]

This hash defines callbacks for attributes which return the
activity state of the corresonding attribute.

Refer to Gtk2::Ex::FormFactory::Context->add_object for details.

=item B<aggregated_by> = "object.attr" [optional]

Fully qualified attribute of the parent aggregating this object

Refer to Gtk2::Ex::FormFactory::Context->add_object for details.

=item B<changes_attr_filter> = REGEX [optional]

Refer to Gtk2::Ex::FormFactory::Context->add_object for details.

=item B<object_changed> = BOOLEAN

This flag indicates whether the object represented by this Proxy
was changed. You may set this attribute to reset the object's
changed state.

=back

=head1 METHODS

=over 4

=item $app_object = $proxy->B<get_object> ()

This returns the actual application object of this Proxy,
either the statical assigned instance or a dynamicly retrieved
instance.

=item $proxy->B<set_object> ($object)

Changes the application object instance in this Proxy. All dependend
Widgets on the GUI are updated accordingly.

=item $app_object_attr_value = $proxy->B<get_attr> ($attr)

Returns the application object's attribute B<$attr> of this Proxy.

If $attr has the form "object.attr" the attribute of the
correspondent object is retreived, instead of the object associated
with this proxy.

=item $proxy->B<set_attr> ($attr => $value)

Changes the application object's attribute B<$attr> to B<$value> and
updates all dependend Widgets on the GUI accordingly.

If $attr has the form "object.attr" the correspondent object
will be updated, instead of the object associated with this proxy.

=item $proxy->B<set_attrs> ( { $attr => $value, ... } )

Changes a bunch of application object's attributes, which is passed
as a hash reference with B<$attr =&gt; $value> pairs and
updates all dependend Widgets on the GUI accordingly.

=item $activity = $proxy->B<get_attr_activity> ($attr)

Returns the current activity state of B<$attr>.

=item 

=back

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
