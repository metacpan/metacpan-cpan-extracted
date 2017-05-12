package MooseTests::Class3;

use Moose;
use JSON::Any;

extends "MooseTests::Class1";
with "MooseTests::Role1";

with "ExtJS::AutoForm::Moose";

has attr3 => ( is => "ro", isa => "Str" );

sub results {
    my @fields = (
            { name => "attr3", fieldLabel => "attr3", xtype => "textfield" },
    );
    my @obj_fields = (
            { name => "attr3", fieldLabel => "attr3", xtype => "textfield", readOnly => JSON::Any::true },
    );
    return {
        simple => [
            @{ MooseTests::Class1->results()->{simple} },
            @{ MooseTests::Role1->results()->{simple} },
            @fields 
        ],
        obj_simple => [
            @{ MooseTests::Class1->results()->{obj_simple} },
            @{ MooseTests::Role1->results()->{obj_simple} },
            @obj_fields 
        ],
        hierarchy => [
            @{ MooseTests::Class1->results()->{hierarchy} },
            @{ MooseTests::Role1->results()->{hierarchy} },
            {
                'items' => [ @fields ],
                'title' => 'MooseTests::Class3',
                'xtype' => 'fieldset'
            }
        ],
        obj_hierarchy => [
            @{ MooseTests::Class1->results()->{obj_hierarchy} },
            @{ MooseTests::Role1->results()->{obj_hierarchy} },
            {
                'items' => [ @obj_fields ],
                'title' => 'MooseTests::Class3',
                'xtype' => 'fieldset'
            }
        ],
    };
}

1;
