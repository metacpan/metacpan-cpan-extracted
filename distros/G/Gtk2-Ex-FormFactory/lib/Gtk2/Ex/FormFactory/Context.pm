package Gtk2::Ex::FormFactory::Context;

use strict;
use Carp;

use Gtk2::Ex::FormFactory::ProxyBuffered;

sub get_proxies_by_name		{ shift->{proxies_by_name}		}
sub get_widgets_by_attr		{ shift->{widgets_by_attr}		}
sub get_widgets_by_object	{ shift->{widgets_by_object}		}
sub get_depend_trigger_href	{ shift->{depend_trigger_href}		}
sub get_aggregated_by_href	{ shift->{aggregated_by_href}		}
sub get_update_hooks_by_object	{ shift->{update_hooks_by_object}	}
sub get_widget_activity_href	{ shift->{widget_activity_href}		}

sub get_default_set_prefix	{ shift->{default_set_prefix}		}
sub get_default_get_prefix	{ shift->{default_get_prefix}		}

sub set_default_set_prefix	{ shift->{default_set_prefix}	= $_[1]	}
sub set_default_get_prefix	{ shift->{default_get_prefix}	= $_[1]	}

sub new {
	my $class = shift;
	my %par = @_;
	my  ($default_set_prefix, $default_get_prefix) =
	@par{'default_set_prefix','default_get_prefix'};

	$default_set_prefix = "set_" if not defined $default_set_prefix;
	$default_get_prefix = "get_" if not defined $default_get_prefix;

	my $self = bless {
		default_set_prefix	=> $default_set_prefix,
		default_get_prefix	=> $default_get_prefix,

		proxies_by_name		=> {},  # ->{"$object"} = $proxy
		widgets_by_attr		=> {},  # ->{"$object.$attr"}->{"$widget_ff_name.$widget_name"} = $widget
		widgets_by_object	=> {},  # ->{"$object"} = $widget
		update_hooks_by_object  => {},  # ->{"$object"} = CODEREF
		depend_trigger_href	=> {},  # ->{"$master_object.$master_attr"}->{"$slave_object.$slave_attr"} = 1
		aggregated_by_href	=> {},  # ->{"$object.$attr"}->{"$object"} = 1
		widget_activity_href	=> {},  # ->{"$object.$attr"}->{"$widget_name"} = $widget

	}, $class;
	
	$self->add_object(
		name   => "__dummy",
		object => bless {}, "Gtk2::Ex::FormFactory::Dummy",
	);
	
	return $self;
}

sub norm_object {
        my $self = shift;
        my ($object) = @_;
        my ($o, $a) = split(/\./, $object);
        return $o;
}

sub norm_object_attr {
        my $self = shift;
        my ($object, $attr) = @_;

        $object = '' if ! defined $object;
        $attr   = '' if ! defined $attr;

        return ""      if $object eq '' && $attr eq '';
        return $attr   if defined $attr && $attr =~ /\./;
        return $object if !defined $attr || $attr eq '';

        if ( $object =~ /\./ ) {
            my ($o, $a) = split(/\./, $object);
            return "$o.$attr";
        }

        die "Illegal object.attr definition object='$object' attr='$attr'"
            if $object eq '';

        return ($object, $attr) if wantarray;
        return "$object.$attr";
}

sub add_object {
	my $self = shift;
	my %par = @_;
	my  ($name, $object, $set_prefix, $get_prefix, $attr_activity_href) =
	@par{'name','object','set_prefix','get_prefix','attr_activity_href'};
	my  ($attr_depends_href, $attr_accessors_href, $update_hook) =
	@par{'attr_depends_href','attr_accessors_href','update_hook'};
	my  ($aggregated_by, $accessor, $buffered, $changes_attr_filter) =
	@par{'aggregated_by','accessor','buffered','changes_attr_filter'};

        $set_prefix = $self->get_default_set_prefix if ! defined $set_prefix;
        $get_prefix = $self->get_default_get_prefix if ! defined $get_prefix;

	if ( $attr_depends_href ) {
		my $depend_trigger_href = $self->get_depend_trigger_href;
		foreach my $attr ( keys %{$attr_depends_href} ) {
			if ( not ref $attr_depends_href->{$attr} ) {
				my $depends_attr = $attr_depends_href->{$attr};
                                $depends_attr = $self->norm_object_attr($name, $depends_attr);
				$depend_trigger_href->{$depends_attr}->{"$name.$attr"} = 1;
			} elsif ( ref $attr_depends_href->{$attr} eq 'ARRAY' ) {
				foreach my $depends_attr ( @{$attr_depends_href->{$attr}} ) {
                                        $depends_attr = $self->norm_object_attr($name, $depends_attr);
					$depend_trigger_href->{$depends_attr}->{"$name.$attr"} = 1;
				}
			} else {
				croak "Illegal attr_depends_href value for attribute '$attr'";
			}
		}
	}

	my $proxies_by_name = $self->get_proxies_by_name;

	die "Object with name '$name' already registered to this context"
		if $proxies_by_name->{$name};

	$self->get_update_hooks_by_object->{$name} = $update_hook
		if $update_hook;

	if ( $aggregated_by ) {
		my ($parent_object, $parent_attr) = split(/\./, $aggregated_by);
                die "aggregated_by definition of object '$name' needs an attr"
                    unless $parent_attr;
		my $parent_proxy = $self->get_proxy($parent_object);
		$parent_proxy->get_attr_aggregate_href->{$parent_attr} = $name;
		$self->get_aggregated_by_href->{$aggregated_by}->{$name} = 1;
	}

	my $proxy_class = $buffered ? "Gtk2::Ex::FormFactory::ProxyBuffered" :
				      "Gtk2::Ex::FormFactory::Proxy";

	return $proxies_by_name->{$name} = $proxy_class->new (
		    context       	=> $self,
		    name          	=> $name,
		    object        	=> $object,
		    set_prefix    	=> $set_prefix,
		    get_prefix    	=> $get_prefix,
		    attr_activity_href	=> $attr_activity_href,
		    attr_accessors_href	=> $attr_accessors_href,
		    aggregated_by	=> $aggregated_by,
		    accessor		=> $accessor,
                    changes_attr_filter => $changes_attr_filter,
	);
}

sub remove_object {
	my $self = shift;
	my ($name) = @_;

	my $proxies_by_name = $self->get_proxies_by_name;
	
	die "Object with name '$name' not registered to this context"
		unless $proxies_by_name->{$name};

	$proxies_by_name->{$name}->set_object(undef);
	delete $proxies_by_name->{$name};

	1;
}

sub register_widget {
	my $self = shift;
	my ($widget) = @_;
	
        my $object = $widget->get_object;

	if ( $widget->get_active_depends ) {
	    my $dep = $widget->get_active_depends;
	    $dep = [ $dep ] unless ref $dep eq 'ARRAY';
	    for my $oa ( @{$dep} ) {
                my $norm_oa = $self->norm_object_attr($oa);
                my $norm_o  = $self->norm_object($oa);
		$self->get_widget_activity_href
		     ->{$self->norm_object_attr($norm_oa)}
		     ->{$widget->get_name} = $widget;
                if ( $norm_oa ne $norm_o ) {
		    $self->get_widget_activity_href
			 ->{$self->norm_object_attr($norm_o)}
			 ->{$widget->get_name} = $widget;
                }
	    }
	}
	
	my $object_attr = $self->norm_object_attr($widget->get_object, $widget->get_attr);

	return if $object_attr eq '';

	my $widget_full_name =
		$widget->get_form_factory->get_name.".".
		$widget->get_name;

	$Gtk2::Ex::FormFactory::DEBUG &&
	    print "REGISTER: $object_attr => $widget_full_name\n";

	$self->get_widgets_by_attr
	     ->{$object_attr}
	     ->{$widget_full_name} = $widget;
	
	if ( $widget->has_additional_attrs ) {
		my $add_attrs = $widget->has_additional_attrs;
		my $object = $widget->get_object;
		foreach my $add_attr ( @{$add_attrs} ) {
			my $get_attr_name_method = "get_attr_$add_attr";
			my $attr = $widget->$get_attr_name_method();
			$self->get_widgets_by_attr
			     ->{$self->norm_object_attr($object, $attr)}
			     ->{$widget_full_name} = $widget;
		}
	}	
	
	$self->get_widgets_by_object
	     ->{$widget->get_object}
	     ->{$widget_full_name} = $widget;

	1;
}

sub deregister_widget {
	my $self = shift;
	my ($widget) = @_;

	$Gtk2::Ex::FormFactory::DEBUG &&
	    print "DEREGISTER ".$widget->get_name."\n";

        my $object      = $widget->get_object;
	my $object_attr = $self->norm_object_attr($widget->get_object, $widget->get_attr);
        return if $object_attr eq '';
	
	my $widget_full_name =
		$widget->get_form_factory->get_name.".".
		$widget->get_name;

	$Gtk2::Ex::FormFactory::DEBUG &&
	    print "DEREGISTER: $object_attr => $widget_full_name\n";

	warn "Widget not registered ($object_attr => $widget_full_name)"
		unless $self->get_widgets_by_attr
			    ->{$object_attr}
			    ->{$widget_full_name};

	delete $self->get_widgets_by_attr
		    ->{$object_attr}
		    ->{$widget_full_name};

        delete $self->get_widgets_by_attr->{$object_attr}
            if keys %{$self->get_widgets_by_attr->{$object_attr}} == 0;

	if ( $widget->get_active_depends ) {
	    my $dep = $widget->get_active_depends;
	    $dep = [ $dep ] unless ref $dep eq 'ARRAY';
	    for my $oa ( @{$dep} ) {
                my $norm_oa = $self->norm_object_attr($oa);
                my $norm_o  = $self->norm_object($oa);
		delete $self->get_widget_activity_href
		            ->{$self->norm_object_attr($norm_oa)}
		            ->{$widget->get_name};
                if ( $norm_oa ne $norm_o ) {
		    delete $self->get_widget_activity_href
			        ->{$self->norm_object_attr($norm_o)}
			        ->{$widget->get_name};
                }
	    }
	}

	if ( $widget->has_additional_attrs ) {
		my $add_attrs = $widget->has_additional_attrs;
		my $object = $widget->get_object;
		foreach my $add_attr ( @{$add_attrs} ) {
			my $get_attr_name_method = "get_attr_$add_attr";
			my $attr = $widget->$get_attr_name_method();
                        my $norm_attr = $self->norm_object_attr($object, $attr);
			delete $self->get_widgets_by_attr
				    ->{$norm_attr}
				    ->{$widget_full_name};
                        delete $self->get_widgets_by_attr->{$norm_attr}
                            if keys %{$self->get_widgets_by_attr->{$norm_attr}} == 0;
		}
	}	

	delete $self->get_widgets_by_object
		    ->{$widget->get_object}
		    ->{$widget_full_name};

	1;
}

sub get_proxy {
	my $self = shift;
	my ($name) = @_;

        $name = $self->norm_object($name);

	my $proxy = $self->get_proxies_by_name->{$name};

	croak "Object '$name' not added to this context"
		unless $proxy;
		
	return $proxy;
}

sub get_object {
	my $self = shift;
	my ($name) = @_;

        $name = $self->norm_object($name);

	my $proxy = $self->get_proxies_by_name->{$name};

	croak "Object '$name' not added to this context"
		unless $proxy;
	
	return $proxy->get_object;
}

sub set_object {
	my $self = shift;
	my ($name, $object) = @_;

        $name = $self->norm_object($name);

	my $proxy = $self->get_proxies_by_name->{$name};

	croak "Object $name not added to this context"
		unless $proxy;

	$proxy->set_object($object);
	
	return $object;
}

sub set_object_attr {
	my $self = shift;
	my ($object_name, $attr_name, $value);
	if ( @_ == 2 ) {
		($object_name, $attr_name) = split(/\./, $_[0]);
		$value = $_[1];
	} elsif ( @_ == 3 ) {
		($object_name, $attr_name, $value) = @_;
	} else {
		croak qq[Usage: set_object_attr("object.attr","value")].
		      qq[       set_object_attr("object","attr","value")];
		            
	}

	my $proxy = $self->get_proxies_by_name->{$object_name}
		or die "Object '$object_name' not registered";

	$proxy->set_attr($attr_name, $value);
	
	return $value;
}

sub get_object_attr {
	my $self = shift;
	my ($object_name, $attr_name);
	if ( @_ == 1 ) {
		($object_name, $attr_name) = split(/\./, $_[0]);
	} elsif ( @_ == 2 ) {
		($object_name, $attr_name) = @_;
	} else {
		croak qq[Usage: get_object_attr("object.attr")].
		      qq[       get_object_attr("object","attr")];
		            
	}

	my $proxy = $self->get_proxies_by_name->{$object_name}
		or die "Object '$object_name' not registered";

	return $proxy->get_attr($attr_name);
}

sub update_object_attr_widgets {
	my $self = shift;
	my ($object, $attr) = @_;

        my $object_attr = $self->norm_object_attr($object, $attr);

	$Gtk2::Ex::FormFactory::DEBUG &&
	    print "update_object_attr_widgets($object, $attr)\n";

	my $widgets_by_attr      = $self->get_widgets_by_attr;
	my $depend_trigger_href  = $self->get_depend_trigger_href;
	my $widget_activity_href = $self->get_widget_activity_href;

        foreach my $w ( values %{$widgets_by_attr->{$object_attr}} ) {
            $w->update;
        }
        foreach my $w ( values %{$widget_activity_href->{$object_attr}} ) {
            $w->update;
        }

	foreach my $update_object_attr ( keys %{$depend_trigger_href->{$object_attr}} ) {
                foreach my $w ( values %{$widgets_by_attr->{$update_object_attr}} ) {
                    $w->update;
                }
                foreach my $name ( keys %{$self->get_aggregated_by_href->{$update_object_attr}} ) {
                    $self->get_proxy($name)->update_by_aggregation;
                }
	}

	1;
}

sub update_object_widgets {
	my $self = shift;
	my ($name) = @_;

	$Gtk2::Ex::FormFactory::DEBUG &&
	    print "update_object_widgets($name)\n";

        $name = $self->norm_object_attr($name);

	my $object       = $self->get_object($name);
	my $change_state = defined $object ? '' : 'empty,inactive';

	my $widgets_by_object = $self->get_widgets_by_object;
        
        foreach my $w ( values %{$widgets_by_object->{$name}} ) {
            $w->update($change_state);
        }

	my $widget_activity_href = $self->get_widget_activity_href;
        foreach my $w ( values %{$widget_activity_href->{$name}} ) {
            $w->update($change_state);
        }

	my $update_hook = $self->get_update_hooks_by_object->{$name};
	&$update_hook($object) if $update_hook;

	1;
}

sub update_object_widgets_activity {
	my $self = shift;
	my ($name, $activity) = @_;

	warn "activity !(empty|inactive|active)"
		unless $activity =~ /^empty|inactive|active$/;

	$Gtk2::Ex::FormFactory::DEBUG &&
	    print "update_object_activity($name)\n";

	my $widgets_by_object = $self->get_widgets_by_object;

        foreach my $w ( values %{$widgets_by_object->{$name}} ) {
            $w->update;
        }

	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Context - Context in a FormFactory framework

=head1 SYNOPSIS

  my $context = Gtk2::Ex::FormFactory::Context->new (
    default_get_prefix => Default prefix for read accessors,
    default_set_prefix => Default prefix for write accessors,
  );
  
  $context->add_object (
    name                => Name of the application object in
    			   this Context,
    aggregated_by       => Object.Attribute of the parent object
                           aggregating this object
    object              => The application object itself or a
    			   callback which returns the object,
			   or undef if aggregated or set later
    get_prefix          => Prefix for read accessors,
    set_prefix          => Prefix for write accessors,
    accessor            => CODEREF which handles access to all object
    			   attributes
    attr_activity_href  => Hash of CODEREFS for attributes which return
			   activity of the corresponding attributes,
    attr_depends_href   => Hash defining attribute dependencies,
    attr_accessors_href => Hash of CODEREFS which override correspondent
    			   accessors in this Context,
    buffered            => Indicates whether changes should be buffered,
    changes_attr_filter => Regex for attributes which should not trigger
                           the object's 'changed' status
  );

=head1 DESCRIPTION

This module implements a very importent concept of the
Gtk2::Ex::FormFactory framework.

The Context knows of all
your application objects, how attributes of the objects
can be accessed (for reading and writing), which attributes
probably depend on other attributes and knows of how to control
the activity state of attributes resp. of the Widgets which
represent these attributes.

So the Context is a layer between your application objects and
the GUI which represents particular attributes of your objects.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Context

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors, but they are mostly passed once to the object
constructor and must not be altered after associated FormFactory's
were built.

=over 4

=item B<default_get_prefix> = SCALAR [optional]

Usually your application's objects use a common prefix for all
attribute accessors. This defines the default prefix for read
accessors and defaults to "B<get_>".

=item B<default_set_prefix> = SCALAR [optional]

Usually your application's objects use a common prefix for all
attribute accessors. This defines the default prefix for write
accessors and defaults to "B<set_>".

=back

=head1 METHODS

=over 4

=item $context->B<add_object> (...)

All your application objects must be added to the Context using
this method. Parameters are passed to the method as a hash:

=over 4

=item B<name> = SCALAR [mandatory]

Each object in a Context need a unique name, so this parameter
is mandatory. You refer to this name when you create Widgets and
want to associate these with your application object's attributes.

=item B<object> = BLESSED REF|CODEREF [optional]

This is the application object itself, or a code reference which
returns the object. Using the code reference option gives you
very flexible control of what this object actually is. But also
note that this may have some impact on performance, because this
code reference will be called quite often.

Often objects are aggregated by other objects, in that case don't
set the object reference here but use the B<aggregate_by> option
described below.

An application object in terms of the Context may become undef,
that's why the B<object> parameter is optional here. Also the
code reference may return undef.

Once an object gets undef, all
associated widgets will be set inactive automatically. You can
control per widget if it should render invisible or insensitive
in that case. Refer to L<Gtk2::Ex::FormFactory::Widget> for
details.

=item B<aggregated_by> = "object.attr" [optional]

If this object has a parent object set this option to the
fully qualified attribute holding the object reference, using
the object dot attribute notation:

  object.attr

where B<object> is the name of the parent object used to register
it to this Context, and B<attr> the attribute holding
the reference to the object currently added to the Context.

Once this attribute resp. the parent object change, the Context
will be updated automatically, including all widgets depending
on this widget.

This way you can define your full object aggregation hierarchy
and Gtk2::Ex::FormFactory takes care of all resulting dependencies
on the GUI.

=item B<get_prefix> = SCALAR [optional]

With this parameter you can override the B<default_get_prefix>
setting of this Context for this object.

=item B<set_prefix> = SCALAR [optional]

With this parameter you can override the B<default_set_prefix>
setting of this Context for this object.

=item B<accessor> = CODEREF(object,attr[,value]) [optional]

If B<accessor> is set this code reference is used as a generic
accessor callback for all attributes. It handles getting and
setting as well.

Called with two arguments the passed attribute is to be read,
with three arguments, the third argument is the value which
is to be assigned to the attribute.

This overrides B<attr_accessors_href> described beyond.

=item B<attr_accessors_href> = HASHREF [optional]

Often your application object attribute values doesn't fit the
data type a particular Widget expects, e.g. in case of the
Gtk2::Ex::FormFactory::List widget, which expects a two dimensional
array for its content.

Since you need this conversion only for a particular GUI task it
makes sense to implement the conversion routine in the Context
instead of adding such GUI specific methods to your underlying
classes, which should be as much GUI independent as possible.

That's why you can override arbitrary accessors (read and write)
using the B<attr_accessors_href> parameter. Key is the name of method to
be overriden and constant scalar value or a code reference, which
is called instead of the real method.

The code reference gets your application object as the first parameter,
as usual for object methods, and additionally the new value in case of
write access.

A short example. Here we override the accessors B<get_tracks> and
B<set_tracks> of an imagnary B<disc> object, which represents an
audio CD. The track title is stored as a simple array and needs
to be converted to a two dimensional array as expected by
Gtk2::Ex::FormFactory::List. Additionally an constant accessor
is defined for a Gtk2::Ex::FormFactory::Popup showing a bunch
of music genres:

  $context->add_object (
    name => "disc",
    attr_accessors_href => {
      get_tracks => sub {
        my $disc = shift;
	#-- Convert the one dimensional array of disc
	#-- tracks to the two dimensional array expected
	#-- by Gtk2::Ex::FormFactory::List. Also the number
	#-- of the track is added to the first column here
	my @list;
	my $nr = 1;
	foreach my $track ( @{$disc->get_tracks} ) {
	  push @list, [ $nr++, $track ];
	}
	return\@list;
      },
      set_tracks => sub {
        my $disc = shift;
	my ($list_ref) = @_;
	#-- Convert the array back (the List is editable in
	#-- our example, so values can be changed).
	my @list;
	foreach my $row ( @{$list_ref} ) {
		push @list, $row->[1];
	}
	$disc->set_tracks(\@list);
	return \@list;
      },
      genre_list => {
        "rock" => "Rock",
	"pop"  => "Pop",
	"elec" => "Electronic",
	"jazz" => "Jazz",
      },
    },
  );


=item B<attr_activity_href> = HASHREF [OPTIONAL]

As mentioned earlier activity of Widgets is controlled by
the Gtk2::Ex::FormFactory framework. E.g. if the an object
becomes undef, all associated widgets render inactive.

With the B<attr_activity_href> setting you can handle
activity on attribute level, not only on object level.

The key of the hash is the attribute name and value is
a code reference, which returns TRUE or FALSE and control
the activity this way.

Again an example: imagine a text entry which usually is
set with a default value controlled by your application.
But if the user wants to override the entry he first has
to press a correpondent checkbox to activate this.

  $context->add_object (
    name => "person",
    attr_activity_href => {
      ident_number => sub {
        my $person = shift;
	return $person->get_may_override_ident_number;
      },
    },
    attr_depends_href => {
      ident_number => "person.may_override_ident_number",
    },
  );

For details about the B<attr_depends_href> option read on.

=item B<attr_depends_href> = HASHREF [OPTIONAL]

This hash defines dependencies between attributes. If you
look at the example above you see why this is necessary.
The B<ident_number> of a person may be overriden only if
the B<may_override_ident_number> attribute of this person
is set. Since this dependency is coded inside the code
reference, Gtk2::Ex::FormFactory isn't aware of it until
you add a corresponding B<attr_depends_href> entry.

Now the GUI will automatically activate the Widget for
the B<ident_number> attribute once B<may_override_ident_number>
is set, e.g. by a CheckBox the user clicked.

If an attribute depends on more than one other attributes
you can use a list reference:

  attr_depends_href => sub {
      ident_number => [
        "person.may_override_ident_number",
	"foo.bar",
      ],
  },

=item B<buffered> = BOOL [OPTIONAL]

If set to TRUE this activates buffering for this object. Please
refer to the BUFFERED CONTEXT OBJECTS chapter for details.

=item B<changes_attr_filter> = REGEX [OPTIONAL]

Gtk2::Ex::FormFactory maintains a flag indicating whether an
object was changed. Under special circumstances you want
specific attributes not affecting this "changed" state of
an object. You can specify an regular expression here. Changes
of attributes matching this expression won't touch the
changes state of the object.

To receive or change the object's changed state refer to
the B<object_changed> attribute of Gtk2::Ex::FormFactory::Proxy.

=back

=item $context->B<remove_object> ( $name )

Remove the object $name from this context.

=item $app_object = $context->B<get_object> ( $name )

This returns the application object registered as B<$name>
to this context.

=item $context->B<set_object> ( $name => $object )

This sets a new object, which was registered as B<$name>
to this context.

=item $context->B<get_object_attr> ( "$object.$attr" )

Retrieves the attribute named B<$attr> of the object B<$object>.

=item $context->B<set_object_attr> ( "$object.$attr", $value )

Set the attribute named B<$attr> of the object B<$object>
to B<$value>. Dependent widgets update automatically.

=item $context->B<update_object_attr_widgets> ( $object_name, $attr_name )

Triggers updates on all GUI widgets which are associated with
the attribute B<$attr_name> of the object registered as B<$object_name>
to this context.

You may omit B<$attr_name> and pass a fully qualified "object.attr"
noted string as the first argument instead.

=item $context->B<update_object_widgets> ( $object_name )

Triggers updates on all GUI widgets which are associated with
the object registered as B<$object_name> to this context.

=item $context->B<update_object_widgets_activity> ( $object_name, $activity )

This updates the activity state of all GUI widgets which are
associated with the object registered as B<$object_name> to
this context.

B<$activity> is 'inactive' or 'active'.

=item $proxy = $context->B<get_proxy> ( $object_name )

This returns the Gtk2::Ex::FormFactory::Proxy instance which was
created for the object registered as B<$name> to this context.
With the proxy you can do updates on object attributes which
trigger the correspondent GUI updates as well.

=back

=head1 BUFFERED CONTEXT OBJECTS

This feature was introduced in version 0.58 and is marked experimental
so please use with care.

If you set B<buffered> => 1 when adding an object to the Context
a buffering Proxy will be used for this object. That means that
all GUI changes in a synchronized FormFactory dialog are buffered
in the proxy object. Normally all changes are commited immediately
to the object, which is Ok in many situations, but makes implementing
a Cancel button difficult resp. you need to care about this yourself by
using a copy of the object or something like that.

A FormFactory gets "buffered" if B<all> its widgets are connected to
a buffered object. In that case Gtk2::Ex::Form::DialogButtons show
a Cancel button automatically, even in a synchronized dialog.

=head2 What's this good for?

If your FormFactory doesn't has the B<sync> flag set you get Cancel
button as well, since no changes are applied to the objects until
the user hit the Ok button. All changes are kept in the "GUI". But
such a dialog lacks of all dynamic auto-widget-updating features,
e.g. setting widgets inactive under specific conditions. For very
simple dialogs this is Ok, but if you need these features you need
the buffering facility as well.

But take care when implementing your closures for widget activity
checking: they must not use the original objects! They need to access
the attributes through the Context, because your original object doesn't
see any GUI changes until the FormFactory is applied! All changes
are buffered in the Context. If you access your objects through
the Context anything works as expected.

Buffering is useful as well in other situations e.g. if you're
accessing remote objects over a network (for example with Event::RPC)
where a method call is somewhat expensive.

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
