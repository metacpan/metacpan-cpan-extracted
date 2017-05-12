use strict;
use warnings;

use Test::More tests => 26;
use Test::Exception;
use Test::Warn;

use Language::l33t;

sub l33t_run {
    my $l33t = Language::l33t->new( source => shift );
    $l33t->run;
    return $l33t;
}

sub l33t_run_memory_is(@) {
    my( $code, $result, $comment ) = @_;

    my $l33t = l33t_run($code);

    is_deeply [ $l33t->memory ], $result, $comment;
}

my $l33t = Language::l33t->new( source => '7 75 55' );
is_deeply [ $l33t->memory ], [ 7, 12, 10, 0 ], 'memory()';

is $l33t->mem_ptr => 3, 'mem_ptr';

$l33t->run(1);
is_deeply [ $l33t->memory ], [ 7, 12, 10, 13 ], 'INC';

$l33t->run;
is_deeply [ $l33t->memory ], [ 7, 12, 10, 13 ], 'END';

$l33t = l33t_run( '8 75 55' );
is_deeply [ $l33t->memory ], [ 8, 12, 10, 243 ], 'DEC';

throws_ok {
    $l33t = l33t_run( '3 5o5' );
} qr/dud3, wh3r3's my EIF?/, 'IF without EIF';

warning_like {
    $l33t = l33t_run( '777 55' );
} qr/j00 4r3 teh 5ux0r/, 'error if opCode > 10';

warning_like {
    $l33t = l33t_run( '6 5 9 55 999999999999991 0 0 1 999999998 999999998' );
} qr/h0s7 5uXz0r5! c4N'7 c0Nn3<7 101010101 l4m3R !!!/, 'error if connect to invalid socket';


throws_ok {
$l33t = Language::l33t->new( 
    memory_max_size => 10,  
    source => join ' ', 1..10
);
} qr/F00l! teh c0d3 1s b1g3R th4n teh m3m0ry!!1!/, 'exceeding memory max size';

{
    my $output;
    open my $fh_output, '>', \$output;
    my $l33t = Language::l33t->new( 
        stdout => $fh_output,
        source => join ' ', 7, ( '9'x( 256/9 ) ), 7, 7, 1, '5o5',
    );

    $l33t->run;

    my $expected = ( 9*int( 256/9 ) + 9 ) % 256;
    is ord($output) => $expected, 'default byte size';

    $output = undef;
    open $fh_output, '>', \$output;
    $l33t = Language::l33t->new( 
        stdout => $fh_output,
        byte_size => 11,
        source => '7 9 7 1 1 5o5',
    );

    $l33t->run;

    is ord( $output ), 1, 'byte size';
}

l33t_run_memory_is '7 75 55'
    => [ 7, 12, 10, 13 ], 'INC';

l33t_run_memory_is '8 75 55'
    => [ 8, 12, 10, 243 ], 'DEC';

throws_ok {
    Language::l33t->new->run;
} qr/^L0L!!1!1!! n0 l33t pr0gr4m l04d3d, sUxX0r!/,
        'run()ning with no source';

{
    # test the error message if the program is bigger than 
    # the memory size
    my $l33t = Language::l33t->new( memory_max_size => 10 );

    for ( 1..9 ) {
        $l33t->source( join ' ', 1..$_ );  
        ok "program within the memory size ($_)";
    }

    throws_ok {
        $l33t->source( join ' ', 1..10 );
    } qr/F00l! teh c0d3 1s b1g3R th4n teh m3m0ry!!1!\n/, 
        'program outside the memory size';
}

{
    # test if the byte size is respected, by default

    my $output;
    open my $fh_output, '>', \$output;
    my $l33t = Language::l33t->new( stdout => $fh_output );
    $l33t->source( '7 '.( '9'x( 256/9 ) ).' 7 7 1 5o5' );
    $l33t->run;
    my $expected = ( 9*int( 256/9 ) + 9 ) % 256;
    is ord($output) => $expected, 'default byte size';
}

{
    # test if the byte size is respected, if different than default

    my $output = q{};
    open my $fh_output, '>', \$output;
    $l33t = Language::l33t->new( stdout => $fh_output,
                            byte_size => 11 );

    $l33t->source( '7 9 7 1 1 5o5' );
    $l33t->run;

    is ord( $output ), 1, 'byte size';
}
