use strict;
use warnings;

use lib 't/lib';

use Test::Requires {
    'MooseX::Role::Parameterized' => '1.09',
};

use Test2::Bundle::Extended '!meta';
use Meta::Grapher::Moose;
use Meta::Grapher::Moose::Renderer::Test;

my $renderer = Meta::Grapher::Moose::Renderer::Test->new;
my $grapher  = Meta::Grapher::Moose->new(
    package  => 'My::Example::Class',
    renderer => $renderer,
)->run;

# this test is to check the methods and attributes are as we would
# expect.

# We're not checking the linking because (a) That's already been tested to
# death in basic.t and (b) The anonymous class names make this very hard to
# write proper tests for

is(
    $renderer->nodes_for_comparison,
    [
        {
            'type'       => 'class',
            'attributes' => [],
            'id'         => 'My::Example::Baseclass',
            'methods'    => ['method_in_baseclass'],
            'label'      => 'My::Example::Baseclass',
        },
        {
            'methods'    => ['method_in_example_class'],
            'label'      => 'My::Example::Class',
            'id'         => 'My::Example::Class',
            'type'       => 'class',
            'attributes' => ['attribute_in_class'],
        },
        {
            'attributes' => bag {
                item 'buffy';
                item 'giles';
                item 'willow';
                item 'xander';
            },
            'type'    => 'role',
            'id'      => 'My::Example::Role::Buffy',
            'methods' => ['slay'],
            'label'   => 'My::Example::Role::Buffy',
        },
        {
            'type'       => 'role',
            'attributes' => bag {
                item 'fred';
                item 'wilma';
            },
            'id'      => 'My::Example::Role::Flintstones',
            'label'   => 'My::Example::Role::Flintstones',
            'methods' => ['have_a_yabba_do_time'],
        },
        {
            'type'       => 'role',
            'id'         => 'My::Example::Role::JackBlack',
            'attributes' => [],
            'label'      => 'My::Example::Role::JackBlack',
            'methods'    => bag {
                item 'get_dragon_scroll';
                item 'play_best_song_in_the_world';
                item 'teach_school_of_rock';
            },
        },
        {
            'methods'    => [],
            'label'      => 'My::Example::Role::PickRandom',
            'type'       => 'prole',
            'attributes' => [],
            'id'         => 'My::Example::Role::PickRandom'
        },
        {
            'methods'    => ['dice_roll'],
            'label'      => 'My::Example::Role::PickRandom',
            'type'       => 'anonrole',
            'id'         => match(qr/__ANON__/),
            'attributes' => [],
        },
        {
            'type'       => 'anonrole',
            'attributes' => [],
            'id'         => match(qr/__ANON__/),
            'label'      => 'My::Example::Role::PickRandom',
            'methods'    => ['coin_flip'],
        },
        {
            'type'       => 'role',
            'attributes' => [],
            'id'         => 'My::Example::Role::RandomValue',
            'methods'    => ['random_value'],
            'label'      => 'My::Example::Role::RandomValue',
        },
        {
            'type'       => 'prole',
            'id'         => 'My::Example::Role::ShedColor',
            'attributes' => [],
            'label'      => 'My::Example::Role::ShedColor',
            'methods'    => [],
        },
        {
            'methods'    => ['paint'],
            'label'      => 'My::Example::Role::ShedColor',
            'type'       => 'anonrole',
            'id'         => match(qr/__ANON__/),
            'attributes' => ['color'],
        },
        {
            'label'      => 'My::Example::Role::StarTrek',
            'methods'    => ['beam_me_up'],
            'type'       => 'role',
            'id'         => 'My::Example::Role::StarTrek',
            'attributes' => bag {
                item 'checkov';
                item 'kirk';
                item 'mccoy';
                item 'scotty';
                item 'spock';
                item 'sulu';
                item 'uhura';
            },
        },
        {
            'label'      => 'My::Example::Role::TVSeries',
            'methods'    => ['get_actor_for_character'],
            'type'       => 'role',
            'attributes' => [
                'actor_factory',
            ],
            'id' => 'My::Example::Role::TVSeries'
        },
        {
            'methods'    => [],
            'label'      => 'My::Example::Role::Tribute',
            'attributes' => [],
            'type'       => 'prole',
            'id'         => 'My::Example::Role::Tribute'
        },
        {
            'id'         => match(qr/__ANON__/),
            'type'       => 'anonrole',
            'attributes' => [],
            'label'      => 'My::Example::Role::Tribute',
            'methods'    => []
        },
        {
            'methods'    => ['method_in_superclass'],
            'label'      => 'My::Example::Superclass',
            'attributes' => ['attribute_in_superclass'],
            'type'       => 'class',
            'id'         => 'My::Example::Superclass',
        }
    ],
    'attribute and method check',
);

done_testing
