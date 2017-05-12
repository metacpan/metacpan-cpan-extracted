use strict;
use warnings;

use lib '.';

use Test::More;

BEGIN {
    use_ok('HTML::TableContent');
}

my $tc = HTML::TableContent->new();

$tc->add_caption_selectors([qw/h3/]);

$tc->parse_file('t/html/horizontal/facebook.html');

is($tc->table_count, 13, "correct table count");

is($tc->get_first_table->caption->text, 'Fields', "expected caption text: Fields");

is($tc->get_table(1)->caption->text, 'Edges', "exptect caption text: Edges");

is($tc->get_table(2)->caption->text, 'Validation Rules', "expected caption text: Validation Rules");

is($tc->get_table(3)->caption->text, 'Validation Rules', "expected caption text: Validation Rules");

is($tc->get_table(4)->caption->text, 'Parameters', "expected caption text: Parameters");

ok(my $table = $tc->get_first_table, "okay get first table");

is($table->row_count, 55, "expected row count: 55");

ok(my $row = $table->get_row(0), "okay get first row");

is($row->cell_count, 2, "expected cell count");

ok($row->clear_last_cell, "drop one cell");

is($row->cell_count, 1, "correct cell count");

ok( $table->clear_first_row, "drop the first row" );

is($table->row_count, 54, "rowcount one less than before: 54");

ok($row = $table->get_last_row, "get the next row" );

is($row->cell_count, 2, "corrent cell count 2"); 

ok($row->clear_first_cell, "okay clear first cell");

is($row->cell_count, 1, "correct cell count 1");

ok($table->clear_last_row, "drop the last row from the table");

is($table->row_count, 53, "row count one less than before: 53");

ok($row = $table->get_row(5));

is($row->cell_count, 2, "expected cell count: 2");

ok($row->clear_cell(1), "clear cell by index");

is($row->cell_count, 1, "expected cell count: 1");

ok($table->clear_row(5));

is($table->row_count, 52, "okay table row count one less than before");

is($table->header_count, 2, "header count: 2");

ok($table->clear_last_header, "clear last header");

is($table->header_count, 1, "header count: 1");

ok($table->clear_first_header, "clear first header");

is($table->header_count, 0, "header count: 0");

ok($tc->clear_first_table, "okay drop first table");

is($tc->table_count, 12, "one less table: 16");

ok($tc->clear_last_table, "drop last table");

is($tc->table_count, 11, "one less table: 15");

ok($tc->clear_table(5), "drop table by index 5");

is($tc->table_count, 10, "one less table: 14");

ok($table = $tc->get_first_table);

is($table->header_count, 2, "okay header count: 1");

is($table->row_count, 54, "okay row count");

is($table->get_first_row->cell_count, 2, "okay row cell count ~ 2");

ok($table->clear_column('Description'));

is($table->header_count, 1, "okay header count: 1");

is($table->get_first_row->cell_count, 1, "okay row cell count - 1");

ok( $tc->clear_table(0) );

is( $tc->table_count, 9, "one less table: 13");

ok($table = $tc->get_first_table);

is($table->header_count, 2, "okay header count: 1");

is($table->row_count, 8, "okay row count");

is($table->get_first_row->cell_count, 2, "okay first row cell count: 2");

is($table->get_last_row->cell_count, 2, "okay last row cell count: 2");

ok($table->clear_column('Description'), "clear column Description");

is($table->header_count, 1, "okay header count: 1");

is($table->get_first_row->cell_count, 1, "okay row cell count");

is($table->get_last_row->cell_count, 1, "okay row cell count: 1");

$tc = HTML::TableContent->new();

$tc->add_caption_selectors([qw/h3 h2/]);

$tc->parse_file('t/html/horizontal/facebook2.html');

is($tc->table_count, 2);

$table = $tc->get_first_table;

is($table->caption->text, 'Fields', "expected caption: Fields");

is($table->row_count, 9, "row count: 7");

is($table->header_count, 3, "header count: 3");

my $aoa = [
    [ 'Name', 'Description', 'Type' ],
    [ 'id', 'ID of this particular achievement.', 'string' ],
    [ 'from', 'The user who achieved this.', 'User' ],
    [ 'publish_time', 'Time at which this was achieved.', 'datetime' ],
    [ 'application', 'The app in which the user achieved this.', 'App' ],
    [ 'data', 'Information about the achievement type this instance is connected with.', 'object' ],
    [ 'achievement', 'The achievement type that the user achieved.', 'AchievementType' ],
    [ 'importance', 'A weighting given to each achievement type by the app.', 'int' ],
    [ 'type', 'Always game.achievement .', 'string' ],
    [ 'no_feed_story', 'Indicates whether gaining the achievement published a feed story for the user.', 'boolean' ]
]; 

is_deeply($table->aoa, $aoa, "aoa");

my $aoh = [
    {
        'Type' => 'string',
        'Description' => 'ID of this particular achievement.',
        'Name' => 'id'
    },
    {
        'Description' => 'The user who achieved this.',
        'Name' => 'from',
        'Type' => 'User'
    },
    {
        'Description' => 'Time at which this was achieved.',
        'Name' => 'publish_time',
        'Type' => 'datetime'
    },
    {
        'Description' => 'The app in which the user achieved this.',
        'Name' => 'application',
        'Type' => 'App'
    },
    {
        'Type' => 'object',
        'Description' => 'Information about the achievement type this instance is connected with.',
        'Name' => 'data'
    },
    {
        'Type' => 'AchievementType',
        'Name' => 'achievement',
        'Description' => 'The achievement type that the user achieved.'
    },
    {
        'Type' => 'int',
        'Name' => 'importance',
        'Description' => 'A weighting given to each achievement type by the app.'
    },
    {
        'Name' => 'type',
        'Description' => 'Always game.achievement .',
        'Type' => 'string'
    },
    {
        'Description' => 'Indicates whether gaining the achievement published a feed story for the user.',
        'Name' => 'no_feed_story',
        'Type' => 'boolean'
    }
];

is_deeply($table->aoh, $aoh, "aoh");

my $first_row = $table->get_first_row;

my $array = [ 'id', 'ID of this particular achievement.', 'string' ],

my @array = $first_row->array;
is_deeply(\@array, $array, "array");

my $hash = {
    'Type' => 'string',
    'Description' => 'ID of this particular achievement.',
    'Name' => 'id'
};

is_deeply($first_row->hash, $hash, "hash");

$table = $tc->get_table(1);

is($table->caption->text, 'Edges', "expected caption: Edges");

is($table->row_count, 2, "row count: 2");

is($table->header_count, 2, "header count: 2");

$aoa = [
    [ 'Name', 'Description' ],
    [ '/comments', 'Comments on the achievement story.'],
    [ '/likes', 'Likes on the achievement story.' ]
];

is_deeply($table->aoa, $aoa, "aoa");

$aoh = [
    {
        'Name' => '/comments',
        'Description' => 'Comments on the achievement story.'
    },
    {
        'Description' => 'Likes on the achievement story.',
        'Name' => '/likes'
    }
];

is_deeply($table->aoh, $aoh, "aoh");

$first_row = $table->get_first_row;

$array = [ '/comments', 'Comments on the achievement story.' ];

@array = $first_row->array;
is_deeply(\@array, $array, "array");

$hash = {
        'Name' => '/comments',
        'Description' => 'Comments on the achievement story.'
};

is_deeply($first_row->hash, $hash, "hash");

$tc = HTML::TableContent->new();

$tc->add_caption_selectors([qw/fields edges/]);

$tc->parse_file('t/html/horizontal/facebook2.html');

is($tc->table_count, 2);

$table = $tc->get_first_table;

is($table->caption->text, 'Fields', "expected caption: Fields");

is($table->row_count, 9, "row count: 7");

is($table->header_count, 3, "header count: 3");

$aoa = [
    [ 'Name', 'Description', 'Type' ],
    [ 'id', 'ID of this particular achievement.', 'string' ],
    [ 'from', 'The user who achieved this.', 'User' ],
    [ 'publish_time', 'Time at which this was achieved.', 'datetime' ],
    [ 'application', 'The app in which the user achieved this.', 'App' ],
    [ 'data', 'Information about the achievement type this instance is connected with.', 'object' ],
    [ 'achievement', 'The achievement type that the user achieved.', 'AchievementType' ],
    [ 'importance', 'A weighting given to each achievement type by the app.', 'int' ],
    [ 'type', 'Always game.achievement .', 'string' ],
    [ 'no_feed_story', 'Indicates whether gaining the achievement published a feed story for the user.', 'boolean' ]
]; 

is_deeply($table->aoa, $aoa, "aoa");

$aoh = [
    {
        'Type' => 'string',
        'Description' => 'ID of this particular achievement.',
        'Name' => 'id'
    },
    {
        'Description' => 'The user who achieved this.',
        'Name' => 'from',
        'Type' => 'User'
    },
    {
        'Description' => 'Time at which this was achieved.',
        'Name' => 'publish_time',
        'Type' => 'datetime'
    },
    {
        'Description' => 'The app in which the user achieved this.',
        'Name' => 'application',
        'Type' => 'App'
    },
    {
        'Type' => 'object',
        'Description' => 'Information about the achievement type this instance is connected with.',
        'Name' => 'data'
    },
    {
        'Type' => 'AchievementType',
        'Name' => 'achievement',
        'Description' => 'The achievement type that the user achieved.'
    },
    {
        'Type' => 'int',
        'Name' => 'importance',
        'Description' => 'A weighting given to each achievement type by the app.'
    },
    {
        'Name' => 'type',
        'Description' => 'Always game.achievement .',
        'Type' => 'string'
    },
    {
        'Description' => 'Indicates whether gaining the achievement published a feed story for the user.',
        'Name' => 'no_feed_story',
        'Type' => 'boolean'
    }
];

is_deeply($table->aoh, $aoh, "aoh");

$first_row = $table->get_first_row;

$array = [ 'id', 'ID of this particular achievement.', 'string' ],

@array = $first_row->array;
is_deeply(\@array, $array, "array");

$hash = {
    'Type' => 'string',
    'Description' => 'ID of this particular achievement.',
    'Name' => 'id'
};

$table = $tc->get_table(1);

is($table->caption->text, 'Edges', "expected caption: Edges");

is($table->row_count, 2, "row count: 2");

is($table->header_count, 2, "header count: 2");

$aoa = [
    [ 'Name', 'Description' ],
    [ '/comments', 'Comments on the achievement story.'],
    [ '/likes', 'Likes on the achievement story.' ]
];

is_deeply($table->aoa, $aoa, "aoa");

$aoh = [
    {
        'Name' => '/comments',
        'Description' => 'Comments on the achievement story.'
    },
    {
        'Description' => 'Likes on the achievement story.',
        'Name' => '/likes'
    }
];

is_deeply($table->aoh, $aoh, "aoh");

$first_row = $table->get_first_row;

$array = [ '/comments', 'Comments on the achievement story.' ];

@array = $first_row->array;
is_deeply(\@array, $array, "array");

$hash = {
        'Name' => '/comments',
        'Description' => 'Comments on the achievement story.'
};

is_deeply($first_row->hash, $hash, "hash");

done_testing();

1;
