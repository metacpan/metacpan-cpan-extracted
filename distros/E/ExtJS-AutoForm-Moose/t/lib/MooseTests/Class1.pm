package MooseTests::Class1;

use Moose;
use JSON::Any;

our $VERSION = "0.1";
# test with module versioning too since i wasn't sure version was returned on some moose introspection apis

with "ExtJS::AutoForm::Moose";

has attr1 => ( is => "ro", isa => "Str" );

sub results {
    my @fields = (
        { name => "attr1", fieldLabel => "attr1", xtype => "textfield" },
    );

    my @obj_fields = (
        { name => "attr1", fieldLabel => "attr1", xtype => "textfield", readOnly => JSON::Any::true },
    );

    return {
        simple => [ @fields ],
        obj_simple => [ @obj_fields ],
        hierarchy => [
            {
                'items' => [ @fields ],
                'title' => 'MooseTests::Class1',
                'xtype' => 'fieldset'
            },
        ],
        obj_hierarchy => [
            {
                'items' => [ @obj_fields ],
                'title' => 'MooseTests::Class1',
                'xtype' => 'fieldset'
            },
        ],
    };
}

1;
