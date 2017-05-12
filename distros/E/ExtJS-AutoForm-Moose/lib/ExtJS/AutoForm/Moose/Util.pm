package ExtJS::AutoForm::Moose::Util;

use warnings;
use strict;

use Carp qw(carp);
use ExtJS::AutoForm::Moose::Types;

#
# This module contains pure functional code that recurses the mop hierarchy
# to generate the output.
#

#IDEA: We should allow memoizing this shit since in most cases, classes do not dynamically change
#      at runtime, and recursion cost is really unnecessary.
#      Yet, check memory usage and consider implementing some kind of specific caching instead
sub _recursive_reflect {
    my ($meta, $obj, $options, $done, $tlmeta) = @_;
    my @extjs = ();
    $done ||= {pkgs => {}, attributes => {}};
    $tlmeta ||= $meta;

    $done->{pkgs}{$meta->name} = 1;

    # Recurse superclasses when possible
    if($meta->isa("Class::MOP::Class")) {
        foreach my $pkg ($meta->superclasses) {
            my $meta = Class::MOP::Class->initialize($pkg);
            next if $done->{pkgs}{$meta->name};
            push @extjs, _recursive_reflect($meta, $obj, $options, $done, $tlmeta);
            $done->{pkgs}{$meta->name} = 1;
        }
    }

    # Recurse roles
    foreach my $pkg ($meta->calculate_all_roles) {
        next if $done->{pkgs}{$pkg->name};
        push @extjs, _recursive_reflect($pkg, $obj, $options, $done, $tlmeta);
        $done->{pkgs}{$pkg->name} = 1;
    }

    # Parse class attributes
    my @atts = ();
    foreach my $at ( sort { $a->insertion_order <=> $b->insertion_order } map { $meta->get_attribute($_) } $meta->get_attribute_list ) {
        next if $done->{attributes}{$at->name};
        my $final_attribute = $tlmeta->find_attribute_by_name($at->name);
        push @atts, _attribute_to_extjs($final_attribute, $obj, $options);
        $done->{attributes}{$at->name} = 1;
    }

    if( $options->{hierarchy} ) {
        # If any, wrap them up in a field group with class/role name
        if(@atts) {
            push @extjs, {
                xtype => "fieldset",
                title => _cleanup_package_name($meta->name, $options),
                items => [@atts],
            };
        }
    } else {
        push @extjs, @atts;
    }

    return @extjs;
}

sub _recursive_reflect_type {
    my $type_constraint = shift;

    # Registered type
    return $ExtJS::AutoForm::Moose::Types::REGISTRY{$type_constraint->name}
        if defined $ExtJS::AutoForm::Moose::Types::REGISTRY{$type_constraint->name};

    # Enum hack
    return $ExtJS::AutoForm::Moose::Types::REGISTRY{__ENUM__}
        if $type_constraint->isa("Moose::Meta::TypeConstraint::Enum");

    # TypeConstraint recursion
    return _recursive_reflect_type($type_constraint->parent) if $type_constraint->has_parent;

    # Unknown TypeConstraint
    return sub { {} };
}

sub _attribute_to_extjs {
    my ($attribute, $obj, $options) = @_;
    my $extjs;

    if($attribute->has_type_constraint) {
        $extjs = _recursive_reflect_type($attribute->type_constraint)->();

        $extjs->{fieldLabel} = _cleanup_attribute_name($attribute->name, $options)
            unless exists $extjs->{fieldLabel};

        $extjs->{name} = $attribute->name
            unless exists $extjs->{name};

        # Set attribute to readonly when invoked on an object instance and the attribute has no writer
        $extjs->{readOnly} = JSON::Any::true
            if( (!exists $extjs->{readOnly}) and !$options->{no_readonly} and !$attribute->has_write_method );
        
        # Execute any subs on the template.. IDEA: DEEP recursion!
        for ( grep { ref($extjs->{$_}) eq "CODE" } keys(%$extjs) ) {
            my $val = $extjs->{$_}->($obj,$attribute);

            if ( $val ) { $extjs->{$_} = $val; }
            else        { delete $extjs->{$_}; }
        }
    } else {
        carp("Attribute has no type constraint to use for reflection");
    }

    return $extjs;
}

sub _cleanup_package_name($$) {
    my ($name, $options) = @_;
    my $n = $name; # Does this really affect on inlining decision?

    if($options->{strip}) {
        $n =~ s#^$options->{strip}##;
    }

    if($options->{classname_cleanup} && $options->{classname_cleanup} eq "cute") {
        $n =~ s#::# #g;
    } elsif(ref($options->{cleanup}) eq "CODE")  {
        $n = $options->{cleanup}->($n);
    }

    return $n;
}

sub _cleanup_attribute_name($$) {
    my ($name, $options) = @_;
    my $n = $name;

    if($options->{attribute_cleanup} && $options->{attribute_cleanup} eq "cute") {
        $n =~ s#_# #g;
    } elsif(ref($options->{cleanup}) eq "CODE")  {
        $n = $options->{cleanup}->($n);
    }

    return $n;
}

1; # End of ExtJS::AutoForm::Moose::Util
