package MooseTests::Class2;

use Moose;
use JSON::Any;

extends "MooseTests::Class1" => { -version => "0.1" };
# test with module versioning too since i wasn't sure version was returned on some moose introspection apis

with "ExtJS::AutoForm::Moose";

has attr2 => ( is => "ro", isa => "Str" );

sub results {
    my @fields = (
            { name => "attr2", fieldLabel => "attr2", xtype => "textfield" },
    );
    my @obj_fields = (
            { name => "attr2", fieldLabel => "attr2", xtype => "textfield", readOnly => JSON::Any::true },
    );
    return {
        simple => [
            @{ MooseTests::Class1->results()->{simple} },
            @fields
        ],
        obj_simple => [
            @{ MooseTests::Class1->results()->{obj_simple} },
            @obj_fields
        ],
        hierarchy => [
            @{ MooseTests::Class1->results()->{hierarchy} },
            {
                'items' => [ @fields ],
                'title' => 'MooseTests::Class2',
                'xtype' => 'fieldset'
            }
        ],
        obj_hierarchy => [
            @{ MooseTests::Class1->results()->{obj_hierarchy} },
            {
                'items' => [ @obj_fields ],
                'title' => 'MooseTests::Class2',
                'xtype' => 'fieldset'
            }
        ],
    };
}

1;
