#######################################################################
# housekeeping
########################################################################
package LinkedList::Single::TestUtil    v2.0.0;
use v5.40;

use Test::More;
use Test::Deep;

use Benchmark       qw( timethis                );
use Devel::Size     qw( size                    );
use File::Basename  qw( dirname basename        );
use List::Util      qw( first                   );
use Sub::Name       qw( subname                 );
use Symbol          qw( qualify qualify_to_ref  );

########################################################################
# package variables
########################################################################

my $madness = 'LinkedList::Single';

my $dir0    = dirname  $0;
my $base0   = basename $0 => qw( .pm .t );

my ( $vers, $class, $method ) 
= do
{
    my ( $n, $m )
    = map
    {
        m{ (\w+) $}x
    }
    (
        $dir0
      , $base0
    );

    my ( $vers ) = ( basename $dir0 ) =~ m{^ (v[12]) }x;

    (
        $vers
      , qualify( $n => $madness )
      , $m
    )
};

########################################################################
# generic test handlers
########################################################################

sub export
{
    my $caller  = shift || caller;

    do { qualify_to_ref test => $caller }->$* = \( __PACKAGE__ );
}

sub import
{
    # discard extraneous class.
    shift;      

    my $caller  = caller;

    # i.e., $test->foobar will access the contents of 
    # this module.

    export $caller;

    use_ok $madness => $vers
    or die "'$madness' is useless\n";

    # not all tests imply a method.

    if( $class->VERSION )
    {
        can_ok $class, $method
        or BAIL_OUT "Your $class lacks any '$method'";
    }
    else
    {
        # we aren't using the filesystem to derive the 
        # class and method.
    }
}

my $list_c  = qualify List      => $madness;
my $curs_c  = qualify Cursor    => $madness;
my $frag_c  = qualify Fragment  => $madness;
my $nmgr_r  = qualify NodeMgr   => $madness;

sub list_class      { $list_c };
sub cursor_class    { $curs_c };
sub fragment_class  { $frag_c };
sub nodemgr_role    { $nmgr_r };

sub madness :lvalue { $madness  }
sub class   :lvalue { $class    }
sub method  :lvalue { $method   }

sub gen_expect
{
    my ( undef, $count ) = @_;

    my $n = $count // 3 + int rand 5;

    map 
    {
        int rand 10 
    }
    ( 1 .. $n )
}

sub show_size
{
    my ( undef, $obj ) = @_;

    diag 'Struct size: ' . size $obj;
    diag 'Node   size: ' . size $obj->node;
}

sub dump
{
    require Data::Dumper;

    local $Data::Dumper::Indent     = 2;
    local $Data::Dumper::Pad        = '| ';
    local $Data::Dumper::Useqq      = 1;
    local $Data::Dumper::Terse      = 1;
    local $Data::Dumper::Quotekeys  = '';
    local $Data::Dumper::Maxdepth   = 16;
    local $Data::Dumper::Maxrecurse = 1024;
    local $Data::Dumper::Sortkeys   = 1;
    local $Data::Dumper::Sparseseen = 1;

    shift;

    say Data::Dumper::Dumper( @_ );
}

# breakpoints in generic tests are intentional, left here
# to simplify testing the underlying methods.

sub generic_list
{
    $DB::single = 1;

    try
    {
        my ( undef, $pass1, $pass2 ) = @_;

        my $list    = $madness->new;
        ok ! $list, 'Empty list is false';

        my $found   = [ $list->$pass1 ];
        ok $list  ,  'Populated list is true';

        my $expect  = [ $list->$pass2 ];

        cmp_deeply $found, $expect, 'Found expected'
        or diag
            "Expect:\n" , explain( $expect )
          , "Found:\n"  , explain( $found  )
        ;

        pass "$class -> $method";
    }
    catch( $err )
    {
        fail $err;
    }
}

sub generic_cursor
{
    $DB::single = 1;

    try
    {
        my ( undef, $prep, $pass1, $pass2 ) = @_;

        my $curs    = $list_c->$prep;

        my $found   = [ $curs->$pass1 ];
        my $expect  = [ $curs->$pass2 ];

        cmp_deeply $found, $expect, 'found : expected'
        or diag
            "Expect:\n" , explain( $expect )
          , "Found:\n"  , explain( $found  )
        ;

        pass "$class -> $method";
    }
    catch( $err )
    {
        fail "$class -> $method: $err";
    }
}

sub generic_fragment
{
    $DB::single = 1;

    try
    {
        my ( undef, $prep, $pass1, $pass2 ) = @_;

        my ( $frag )    = $list_c->$prep;

        my $found   = [ $frag->$pass1 ];
        my $expect  = [ $frag->$pass2 ];

        cmp_deeply $found, $expect, 'found : expected'
        or diag
            "Expect:\n" , explain( $expect )
          , "Found:\n"  , explain( $found  )
        ;

        pass "$class -> $method";
    }
    catch( $err )
    {
        fail "$class -> $method: $err";
    }
}

sub generic_benchmark
{
    $DB::single = 1;

    my ( undef, $prep, $base, $bench, $post )    = @_;

    SKIP:
    {
        my ( $env ) = $dir0 =~ m{ \d+ \W (\w+) $}x; 
        my $name    = "$env $base0";

        $ENV{ $env }
        or skip "$name, '$env' not set", 1;

        try
        {
            diag do
            {
                my $buffer      = "\n";
                local *STDOUT;
                open *STDOUT, '>', \$buffer;

                my $count   = $prep->();

                if( $base )
                {
                    say "\nBaseline timing:";
                    timethis 1, $base;
                }

                say "\nExecute: $name x $count";
                timethis $count, $bench;

                $post->()
                if $post;

                $buffer
            };

            pass $name;
        }
        catch( $err )
        {
            fail "$name: $err";
        }
    }

    done_testing
}

# keep require happy
1
__END__
