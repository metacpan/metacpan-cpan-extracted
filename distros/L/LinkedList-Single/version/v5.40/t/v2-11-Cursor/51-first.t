########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Testy;
use v5.40;
use FindBin::libs;

use Test::More;
use LinkedList::Single::TestUtil;

use Sub::Name       qw( subname );

########################################################################
# tests
########################################################################

my $method  = $test->method;
my @data    = ( 0 .. 9 );

my $prep
= sub( $list_c )
{
    my $list    = $list_c->new;
    $list->unshift( $_ ) for @data;

    $list->cursor
};

my $filter
= subname first_lt_5
=> sub
{
    my $val = shift;

    $val < 5
};

my $pass1
= sub( $curs )
{
    $curs->$method( $filter )->node
};

my $pass2
= sub
{
    [
        [
            [
                [
                    [
                        []
                      , 0
                    ]
                  , 1
                ]
              , 2
            ]
          , 3
        ]
      , 4
    ]
};

$test->generic_cursor( $prep, $pass1, $pass2 );
done_testing
__END__
