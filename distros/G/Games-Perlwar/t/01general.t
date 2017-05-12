use strict;
use warnings;
use Test::More tests => 26;

use Games::Perlwar;

ok(1); # So we can load Perlwar. Yay!

my $pw = new Games::Perlwar( 't' );
$pw->load;

ok(1);  # game loaded

my( $result, $error, @Array );

use Games::Perlwar::Cell;
my $cell = Games::Perlwar::Cell->new;

$cell->set_code( '"hello world!"' );

is $cell->run->return_value => "hello world!", 'cell execution';

$cell->set_code( 'die' );
ok $cell->run->crashed => 'agent doing a hara-kiri';

ok $cell->set_code( '6/0' )->run->crashed => "agent's code segfault'ing";

ok $cell->set_code( 'system "ls"' )->run->crashed 
    => "agent trying to be naughty";

ok $cell->set_code( '1 while 1' )->run->crashed 
    => 'agent running forever';

is $cell->set_code( '$_' )->run->return_value => '$_',
    'access to $_';

# access to @_
$pw->array->cell(5)->set_code('scalar @_');
$pw->array->cell(6)->set_code('$_[-1]');
is $pw->run_cell(5)->return_value => 97, 'Array size';
is $pw->run_cell(6)->return_value => 'scalar @_', 'access other cells';

# access to @_
$pw->array->clear;
$pw->array->cell(0)->set_code('join ":",@_');
$pw->array->cell($_)->set_code($_) for 1..20;

is $pw->run_cell( 0 )->return_value => 'join ":",@_:1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::', 'access to @_';

$pw->array->cell(0)->set_code('join ":",@o');
$pw->array->cell(0)->set_owner('neo');
is $pw->run_cell( 0 )->return_value => 'neo::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::', 'access to @o';


is $cell->set_code( '@x = map undef, 0..5; join ":",@x' )
        ->run
        ->return_value => ':::::', 'code with undef values';

# variables accessibles from a cell
# $S, $I, $i
$pw->array->cell(9)->set_code('"$S:$I:$i"');
is $pw->run_cell(9)->return_value => '67:95:13', '$S, $I, $i';

# And now, operations

$pw->array->clear;

# nuke function
$pw->array->cell(10)->set({ owner => 'neo', code => '"!13"' });
$pw->array->cell(11)->set({ owner => 'smith', 
                            code => '$_[-1] =~ s/!/#/g;"~-1"' });
$pw->array->cell(23)->set({ owner => 'smith', code => '1' });
$pw->array->cell(24)->set({ owner => 'smith', code => 'join ":", @_' });
$pw->array->cell(25)->set({ owner => 'neo', code => '"^-1"'  });

$pw->runSlot( $_ ) for 10..25;
my $array = $pw->array;

ok $array->cell(23)->is_empty, "nuke function (!)";

is $array->cell(10)->get_owner => 'neo', "alter function (~)";
is $array->cell(10)->get_code => '"#13"', "alter function (~)";
is $array->cell( 24 )->get_owner => 'neo', 'p0wning function (^)';

# 0wning
$array->cell(0)->set( { owner => 'luigi', code => "':2'" } );
$array->cell(1)->set( { owner => 'mario', code => "'^1'" } );
$pw->runSlot($_) for 0..1;
is $array->cell(0)->get_owner => 'luigi', "parents shouldn't be 0wned";
is $array->cell($_)->get_owner => 'mario', "0wning" for 1..2;

# self-modification
$cell->set_code( '$_="tadam"' );
is $cell->run->eval( '$_' ) => 'tadam', "self-modification";

# ownership
$pw->array->clear;
$array->cell(0)->set( { owner => 'neo', code => '$o="morpheus"' } );
$array->cell(1)->set( { owner => 'smith', code => '$o[1]="neo"' } );
$array->cell(2)->set( { owner => 'smith', code => '1' } );
$array->cell(3)->set( { owner => 'neo', code => '$O' } );

$pw->runSlot(0);
is $array->cell(0)->get_facade => 'morpheus', 
    'agent can change its own facade';
$pw->runSlot(1);
is $array->cell(2)->get_facade => 'smith', 
    'but not the facade of another agent';

$pw->runSlot(3);
is $array->cell(3)->run->return_value => 'neo', 'agent can access $O';

$pw->array->clear;
$array->cell(0)->set( { owner => 'neo', code => '$x="pass it on"' } );
$array->cell(1)->set( { owner => 'neo', code => '$_=$x' } );
$pw->runSlot($_) for 0..1;

is $array->cell(1)->get_code => '',
    "agents can't pass information back and forth";

