BEGIN {

    $INT1 = '123456';
    $INT2 = '1e8';
    $INT3 = '10E+10';
    $INT4 = '0';
    $INT5 = '-987654';

    $NUM1 = '3';
    $NUM2 = '0.1';
    $NUM3 = '.1';
    $NUM4 = '1.456e156';
    $NUM5 = '+1E-01';
    $NUM6 = '999.9e-1';
    $NUM7 = '0.00';
    $NUM8 = '-0.1';
    $NUM9 = '-1E-6';

    $STR1 = 'asdf';
    $STR2 = '"Test me!"';

    $IN1  = $0;
    $IN2  = '.';

    $OUT1 = $0;
    $OUT2 = '.';

    @ARGV = (
        '-integer'     , $INT1, $INT2, $INT3, $INT4, $INT5,
        '-int'         , $INT1, $INT2, $INT3, $INT4, $INT5,
        '-i'           , $INT1, $INT2, $INT3, $INT4, $INT5,
        '-pos_integer' , $INT1, $INT2, $INT3,
        '-pos_int'     , $INT1, $INT2, $INT3,
        '-pos_i'       , $INT1, $INT2, $INT3,
        '-zero_integer', $INT1, $INT2, $INT3, $INT4,
        '-zero_int'    , $INT1, $INT2, $INT3, $INT4,
        '-zero_i'      , $INT1, $INT2, $INT3, $INT4,
        '-number'      , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7, $NUM8, $NUM9,
        '-num'         , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7, $NUM8, $NUM9,
        '-n'           , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7, $NUM8, $NUM9,
        '-zero_number' , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7,
        '-zero_num'    , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7,
        '-zero_n'      , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7,
        '-pos_number'  , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6,
        '-pos_num'     , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6,
        '-pos_n'       , $NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6,
        '-string'      , $STR1, $STR2,
        '-str'         , $STR1, $STR2,
        '-s'           , $STR1, $STR2,
        '-readable'    , $IN1 , $IN2 ,
        '-input'       , $IN1 , $IN2 ,
        '-in'          , $IN1 , $IN2 ,
        '-writable'    , $OUT1, $OUT2,
        '-writeable'   , $OUT1, $OUT2,
        '-output'      , $OUT1, $OUT2,
        '-out'         , $OUT1, $OUT2,
    );

    chmod 0644, $0;
}


use Getopt::Euclid;
use Test::More 'no_plan';

sub got_args {
    my ($arr1, $arr2) = @_;
    for my $i (0 .. $#$arr1) {
      is $arr1->[$i], $arr2->[$i];
    }
}

is ref $ARGV{'-integer'}, 'ARRAY' => 'Testing integers';
got_args $ARGV{'-integer'}, [$INT1, $INT2, $INT3, $INT4, $INT5];
got_args $ARGV{'-int'    }, [$INT1, $INT2, $INT3, $INT4, $INT5];
got_args $ARGV{'-i'      }, [$INT1, $INT2, $INT3, $INT4, $INT5];

got_args $ARGV{'-zero_integer'}, [$INT1, $INT2, $INT3, $INT4];
got_args $ARGV{'-zero_int'    }, [$INT1, $INT2, $INT3, $INT4];
got_args $ARGV{'-zero_i'      }, [$INT1, $INT2, $INT3, $INT4];

got_args $ARGV{'-pos_integer'}, [$INT1, $INT2, $INT3];
got_args $ARGV{'-pos_int'    }, [$INT1, $INT2, $INT3];
got_args $ARGV{'-pos_i'      }, [$INT1, $INT2, $INT3];

is ref $ARGV{'-number'}, 'ARRAY' => 'Testing numbers';
got_args $ARGV{'-number'}, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7, $NUM8, $NUM9];
got_args $ARGV{'-num'   }, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7, $NUM8, $NUM9];
got_args $ARGV{'-n'     }, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7, $NUM8, $NUM9];

got_args $ARGV{'-zero_number'}, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7];
got_args $ARGV{'-zero_num'   }, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7];
got_args $ARGV{'-zero_n'     }, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6, $NUM7];

got_args $ARGV{'-pos_number'}, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6];
got_args $ARGV{'-pos_num'   }, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6];
got_args $ARGV{'-pos_n'     }, [$NUM1, $NUM2, $NUM3, $NUM4, $NUM5, $NUM6];

is ref $ARGV{'-string'}, 'ARRAY' => 'Testing strings';
got_args $ARGV{'-string'}, [$STR1, $STR2];
got_args $ARGV{'-str'   }, [$STR1, $STR2];
got_args $ARGV{'-s'     }, [$STR1, $STR2];

is ref $ARGV{'-readable'}, 'ARRAY' => 'Testing input/output files';
got_args $ARGV{'-readable'},  [$IN1 , $IN2 ];
got_args $ARGV{'-input'},     [$IN1 , $IN2 ];
got_args $ARGV{'-in'},        [$IN1 , $IN2 ];
got_args $ARGV{'-writable'},  [$OUT1, $OUT2];
got_args $ARGV{'-writeable'}, [$OUT1, $OUT2];
got_args $ARGV{'-output'},    [$OUT1, $OUT2];
got_args $ARGV{'-out'},       [$OUT1, $OUT2];

# type 'regex' tested in file ./t/types_regex.t
# comparison to $variables are tested in file ./t/types_vars.t

__END__

=head1 NAME

orchestrate - Convert a file to Melkor's .orc format

=head1 VERSION

This documentation refers to orchestrate version 1.9.4

=head1 REQUIRED ARGUMENTS

=over

=item  -integer <integer>...

=for Euclid:
    integer.type: integer

=item  -int <int>...

=for Euclid:
    int.type: int

=item  -i <i>...

=for Euclid:
    i.type: i

=item  -zero_integer <zero_integer>...

=for Euclid:
    zero_integer.type: 0+integer

=item  -zero_int <zero_int>...

=for Euclid:
    zero_int.type: 0+int

=item  -zero_i <zero_i>...

=for Euclid:
    zero_i.type: 0+i

=item  -pos_integer <pos_integer>...

=for Euclid:
    pos_integer.type: +integer

=item  -pos_int <pos_int>...

=for Euclid:
    pos_int.type: +int

=item  -pos_i <pos_i>...

=for Euclid:
    pos_i.type: +i

=item  -number <number>...

=for Euclid:
    number.type: number

=item  -num <num>...

=for Euclid:
    num.type: num

=item  -n <n>...

=for Euclid:
    n.type: n

=item  -pos_number <pos_number>...

=for Euclid:
    pos_number.type: +number

=item  -pos_num <pos_num>...

=for Euclid:
    pos_num.type: +num

=item  -pos_n <pos_n>...

=for Euclid:
    pos_n.type: +n

=item  -zero_number <zero_number>...

=for Euclid:
    zero_number.type: 0+number

=item  -zero_num <zero_num>...

=for Euclid:
    zero_num.type: 0+num

=item  -zero_n <zero_n>...

=for Euclid:
    zero_n.type: 0+n

=item  -string <string>...

=for Euclid:
    string.type: string

=item  -str <str>...

=for Euclid:
    str.type: str

=item  -s <s>...

=for Euclid:
    s.type: s

=item  -readable <readable>...

=for Euclid:
    readable.type: readable

=item  -input <input>...

=for Euclid:
    input.type: input

=item  -in <in>...

=for Euclid:
    in.type: in

=item  -writable <writable>...

=for Euclid:
    writable.type: writable

=item  -writeable <writeable>...

=for Euclid:
    writeable.type: writeable

=item  -output <output>...

=for Euclid:
    output.type: output

=item  -out <out>...

=for Euclid:
    out.type: out

=back
