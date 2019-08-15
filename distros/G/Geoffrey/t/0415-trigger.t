use Test::More tests => 33;

use strict;
use FindBin;
use warnings;
use Data::Dumper;
use Test::Exception;

{

    package Test::Mock::Geoffrey::Converter::Trigger;
    use parent 'Geoffrey::Role::ConverterType';

    sub alter {
        'CREATE TRIGGER {0} AS {1}
            {2}, {3}, {4}, {5}
        END';
    }
    sub list {'SELECT * FROM trigger'}

    sub find_by_name_and_table {
        'SELECT * FROM trigger WHERE table=?, AND name=?, AND schema=?';
    }
    sub nextval {'{0}'}

}

use_ok 'DBI';

require_ok('Geoffrey::Action::Trigger');
use_ok 'Geoffrey::Action::Trigger';

require_ok('Geoffrey::Converter::SQLite');
use_ok 'Geoffrey::Converter::SQLite';

my $dbh       = DBI->connect("dbi:SQLite:database=.tmp.sqlite");
my $converter = Geoffrey::Converter::SQLite->new();
my $object    = new_ok('Geoffrey::Action::Trigger', ['converter', $converter, 'dbh', $dbh]);

can_ok('Geoffrey::Action::Trigger', @{['add', 'alter', 'drop']});
isa_ok($object, 'Geoffrey::Action::Trigger');

throws_ok { $object->add(); } 'Geoffrey::Exception::RequiredValue::TriggerName', 'Throw missing trigger name on add';

throws_ok { $object->alter(); }
'Geoffrey::Exception::NotSupportedException::ConverterType', 'Alter trigger not supportet thrown';

throws_ok { $object->drop(); }
'Geoffrey::Exception::RequiredValue::TriggerName', 'Throw missing trigger name on drop';

throws_ok { $object->add(); } 'Geoffrey::Exception::RequiredValue::TriggerName', 'Not supportet thrown';

throws_ok { $object->add({event_object_table => 'test_table'}); }
'Geoffrey::Exception::RequiredValue::TriggerName', 'Trigger name missing';

throws_ok { $object->add({name => 'trigger_name'}); }
'Geoffrey::Exception::RequiredValue::TableName', 'Required event_object_table value thrown';

throws_ok {
    $object->add({name => 'trigger_name', event_object_table => 'test_table'}, 1);
}
'Geoffrey::Exception::RequiredValue', 'Required event_manipulation value thrown';

throws_ok {
    $object->add({name => 'trigger_name', event_object_table => 'test_table', event_manipulation => q~~}, 1);
}
'Geoffrey::Exception::RequiredValue', 'Required action_timing value thrown';

throws_ok {
    $object->add(
        {name => 'trigger_name', event_object_table => 'test_table', event_manipulation => q~~, action_timing => q~~},
        1
    );
}
'Geoffrey::Exception::RequiredValue', 'Required value thrown';

throws_ok {
    $object->add({
            name               => 'trigger_name',
            event_object_table => 'test_table',
            event_manipulation => q~~,
            action_timing      => q~~,
            action_orientation => q~~
        },
        1
    );
}
'Geoffrey::Exception::RequiredValue', 'Required value thrown';

is(
    $object->dryrun(1)->add({
            name               => 'trigger_name',
            event_object_table => 'test_table',
            event_manipulation => 'event_manipulation',
            action_timing      => 'action_timing',
            action_orientation => 'action_orientation',
            action_statement   => 'action_statement'
        }
    ),
    'CREATE TRIGGER trigger_name UPDATE OF action_timing ON event_manipulation
BEGIN
    action_orientation
END
',
    'Add trigger test'
);

is(
    $object->dryrun(1)->add({
            name               => 'trigger_name',
            event_object_table => 'test_table',
            event_manipulation => 'event_manipulation',
            action_timing      => 'action_timing',
            action_orientation => 'action_orientation',
            action_statement   => 'action_statement'
        },
        {for_view => 1}
    ),
    'CREATE TRIGGER trigger_name INSTEAD OF UPDATE OF action_timing ON event_manipulation
BEGIN
    action_orientation
END
',
    'Add trigger test'
);
throws_ok { $object->dryrun(0)->drop(); }
'Geoffrey::Exception::RequiredValue::TriggerName', 'Not supportet thrown';

throws_ok { $object->dryrun(0)->drop('trigger_name'); }
'Geoffrey::Exception::RequiredValue::TableName', 'Not supportet thrown';

is($object->dryrun(1)->drop('trigger_name', 'test_table'), 'DROP TRIGGER IF EXISTS test_table', 'Drop trigger test');

throws_ok { $object->add({name => 'trigger_name',}); }
'Geoffrey::Exception::RequiredValue::TableName', 'Required table name thrown';

throws_ok {
    $object->add({name => 'trigger_name', event_object_table => 'test_table',});
}
'Geoffrey::Exception::RequiredValue', 'Required value thrown';

throws_ok {
    $object->add({name => 'trigger_name', event_object_table => 'test_table', event_manipulation => q~~,});
}
'Geoffrey::Exception::RequiredValue', 'Required value thrown';

throws_ok {
    $object->add(
        {name => 'trigger_name', event_object_table => 'test_table', event_manipulation => q~~, action_timing => q~~,}
    );
}
'Geoffrey::Exception::RequiredValue', 'Required value thrown';

$converter->trigger(Test::Mock::Geoffrey::Converter::Trigger->new);

throws_ok { $object->alter({}); }
'Geoffrey::Exception::RequiredValue::TriggerName', 'Alter trigger not supportet thrown';
throws_ok { $object->alter({name => 'test'}); }
'Geoffrey::Exception::RequiredValue::TableName', 'Alter trigger not supportet thrown';
throws_ok { $object->alter({name => 'test', event_object_table => 'event_object_table'}); }
'Geoffrey::Exception::RequiredValue', 'Alter trigger not supportet thrown';
throws_ok {
    $object->alter(
        {name => 'test', event_object_table => 'event_object_table', event_manipulation => 'event_manipulation'});
}
'Geoffrey::Exception::RequiredValue', 'Alter trigger not supportet thrown';
throws_ok {
    $object->alter({
        name               => 'test',
        event_object_table => 'event_object_table',
        event_manipulation => 'event_manipulation',
        action_timing      => 'action_timing'
    });
}
'Geoffrey::Exception::RequiredValue', 'Alter trigger not supportet thrown';
throws_ok {
    $object->alter({
        name               => 'test',
        event_object_table => 'event_object_table',
        event_manipulation => 'event_manipulation',
        action_timing      => 'action_timing',
        action_orientation => 'action_orientation'
    });
}
'Geoffrey::Exception::RequiredValue', 'Alter trigger not supportet thrown';
