use strict;
use warnings;
use Test::More tests => 28;
use Test::Differences;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Worker::AttributeParser;
use Moose::Util qw(apply_all_roles);
use Gearman::Driver::Test::Live::BeginEnd;
use Gearman::Driver::Test::Live::Console;
use Gearman::Driver::Test::Live::DefaultAttributes;
use Gearman::Driver::Test::Live::EncodeDecode;
use Gearman::Driver::Test::Live::MaxIdleTime;
use Gearman::Driver::Test::Live::OverrideAttributes;
use Gearman::Driver::Test::Live::Prefix;
use Gearman::Driver::Test::Live::ProcessGroup;
use Gearman::Driver::Test::Live::Quit;
use Gearman::Driver::Test::Live::WithBaseClass;

my %expected = (
    'Gearman::Driver::Test::Live::BeginEnd' => {
        'job1' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
        'job2' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
    },

    'Gearman::Driver::Test::Live::Console' => {
        'ping' => {
            'Job'          => 1,
            'MinProcesses' => '0',
            'MaxProcesses' => '1'
        },
        'pong' => {
            'Job'          => 1,
            'MinProcesses' => '0',
            'MaxProcesses' => '1'
        },
    },

    'Gearman::Driver::Test::Live::DefaultAttributes' => {
        'job1' => {
            'Decode'       => 'dec',
            'Encode'       => 'enc',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job2' => {
            'Decode'       => 'dec',
            'Encode'       => 'enc',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job3' => {
            'Decode'       => 'dec',
            'Encode'       => 'enc',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job4' => {
            'Decode'       => 'dec',
            'Encode'       => 'enc',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
    },

    'Gearman::Driver::Test::Live::EncodeDecode' => {
        'job1' => {
            'Decode'       => 'decode',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job2' => {
            'Decode'       => 'custom_decode',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job3' => {
            'Encode'       => 'encode',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job4' => {
            'Encode'       => 'custom_encode',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job5' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job6' => {
            'Decode'       => 'decode',
            'Encode'       => 'encode',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
        'job7' => {
            'Decode'       => 'custom_decode',
            'Encode'       => 'custom_encode',
            'Job'          => 1,
            'ProcessGroup' => 'group1',
        },
    },

    'Gearman::Driver::Test::Live::MaxIdleTime' => {
        'get_pid' => {
            'Job'          => 1,
            'MinProcesses' => '0'
        },
    },

    'Gearman::Driver::Test::Live::OverrideAttributes' => {
        'job1' => {
            'Decode'       => 'decode',
            'Encode'       => 'encode',
            'Job'          => 1,
            'MinProcesses' => '0'
        },
        'job2' => {
            'Decode'       => 'decode',
            'Encode'       => 'encode',
            'Job'          => 1,
            'MinProcesses' => '0'
        },
    },

    'Gearman::Driver::Test::Live::Prefix' => { 'ping' => { 'Job' => 1 } },

    'Gearman::Driver::Test::Live::ProcessGroup' => {
        'job1' => {
            'Job'          => 1,
            'MinProcesses' => '1',
            'ProcessGroup' => 'group1'
        },
        'job2' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
        'job3' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
        'job4' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
        'job5' => { 'Job' => 1 },
    },

    'Gearman::Driver::Test::Live::Quit' => {
        'quit1' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
        'quit2' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
    },

    'Gearman::Driver::Test::Live::WithBaseClass' => {
        'job1' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
        'job2' => {
            'Job'          => 1,
            'ProcessGroup' => 'group1'
        },
    },

);

foreach my $class ( keys %expected ) {
    my $worker = $class->new();
    foreach my $method ( $worker->meta->get_nearest_methods_with_attributes ) {
        apply_all_roles( $method => 'Gearman::Driver::Worker::AttributeParser' );
        $method->default_attributes( $worker->default_attributes );
        $method->override_attributes( $worker->override_attributes );
        eq_or_diff(
            $method->parsed_attributes,
            $expected{$class}{ $method->name },
            "Class: $class Method: " . $method->name
        );
    }
}
