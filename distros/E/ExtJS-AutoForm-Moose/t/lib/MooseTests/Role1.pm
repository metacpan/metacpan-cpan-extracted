package MooseTests::Role1;

use Moose::Role;
use JSON::Any;

has rattr1 => ( is => "ro", isa => "Str" );

sub results {
    my @fields = (
            { name => "rattr1", fieldLabel => "rattr1", xtype => "textfield" },
    );
    my @obj_fields = (
            { name => "rattr1", fieldLabel => "rattr1", xtype => "textfield", readOnly => JSON::Any::true },
    );
    return {
        simple => [ @fields ],
        obj_simple => [ @obj_fields ],
        hierarchy => [
            {
                'items' => [ @fields ],
                'title' => 'MooseTests::Role1',
                'xtype' => 'fieldset'
            },
        ],
        obj_hierarchy => [
            {
                'items' => [ @obj_fields ],
                'title' => 'MooseTests::Role1',
                'xtype' => 'fieldset'
            },
        ],
    };
}

1;
