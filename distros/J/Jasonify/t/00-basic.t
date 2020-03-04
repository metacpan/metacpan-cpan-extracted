#! /usr/bin/env perl

# Proper testing requires a . at the end of the error message
use Carp 1.25;

use Test2::V0;
plan 116;

ok require Jasonify, 'Can require Jasonify';
#ok( Jasonify->VERSION, 'Jasonify version ' . Jasonify->VERSION );

can_ok(
    'Jasonify',
    qw(
        booleanify pairify undefify
        encode
        get set
        new
    )
);


# Ensure things are set correctly.
is( Jasonify->undefify, 'null', 'undefify is "null"' );

is( Jasonify->booleanify(  undef ), 'null',  'booleanify( undef) is "null"' );
is( Jasonify->booleanify( \undef ), 'null',  'booleanify(\undef) is "null"' );
is( Jasonify->booleanify(  '' ),    'false', 'booleanify( "") is "false"' );
is( Jasonify->booleanify( \'' ),    'false', 'booleanify(\"") is "false"' );
is( Jasonify->booleanify(  0 ),     'false', 'booleanify( 0) is "false"' );
is( Jasonify->booleanify( \0 ),     'false', 'booleanify(\0) is "false"' );
is( Jasonify->booleanify(  1 ),     'true',  'booleanify( 1) is "true"' );
is( Jasonify->booleanify( \1 ),     'true',  'booleanify(\1) is "true"' );


is(
    Jasonify->pairify( key => 'value' ),
    '"key" : "value"',
    'pairify(key => value) is "key" : "value"'
);

# Verify undef/null
my $null = undef;
is( Jasonify->encode($null), 'null', 'undef encodes correctly' );


# Verify booleans
my $false = Jasonify::Boolean::false();
my $true  = Jasonify::Boolean::true();

is(  $false, $Jasonify::Boolean::false, ' false is false' );
is(  $true,  $Jasonify::Boolean::true,  ' true  is true'  );
is( !$false, $Jasonify::Boolean::true,  '!false is true'  );
is( !$true,  $Jasonify::Boolean::false, '!true  is false' );

is( "$false", 'false', 'stringified false eq "false"' );
is( "$true",  'true',  'stringified true  eq "true"'  );

cmp_ok( $false, '==', $false, 'false == false' );
cmp_ok( $true,  '==', $true,  'true  == true'  );
cmp_ok( $false, '!=', $true,  'false != true'  );
cmp_ok( $true,  '!=', $false, 'true  != false' );

cmp_ok( $false, 'eq', $false, 'false eq false' );
cmp_ok( $true,  'eq', $true,  'true  eq true'  );
cmp_ok( $false, 'ne', $true,  'false ne true'  );
cmp_ok( $true,  'ne', $false, 'true  ne false' );

cmp_ok( $false, '==',  '', 'false == ""' );
cmp_ok( $true,  '!=',  '', 'true  != ""' );
cmp_ok( $false, '==',   0, 'false == 0'  );
cmp_ok( $true,  '!=',   0, 'true  != 0'  );

cmp_ok( $false, '!=',   1, 'false != 1'  );
cmp_ok( $true,  '==',   1, 'true  == 1'  );
cmp_ok( $false, '!=',  11, 'false != 11' );
cmp_ok( $true,  '==',  11, 'true  == 11' );

cmp_ok( $false, '==', \'', 'false == \""' );
cmp_ok( $true,  '!=', \'', 'true  != \""' );
cmp_ok( $false, '==',  \0, 'false == \0'  );
cmp_ok( $true,  '!=',  \0, 'true  != \0'  );

cmp_ok( $false, '!=',  \1, 'false != \1'  );
cmp_ok( $true,  '==',  \1, 'true  == \1'  );
cmp_ok( $false, '!=', \11, 'false != \11' );
cmp_ok( $true,  '==', \11, 'true  == \11' );

cmp_ok( $false, 'eq',  '', 'false eq ""' );
cmp_ok( $true,  'ne',  '', 'true  ne ""' );
cmp_ok( $false, 'eq',   0, 'false eq 0'  );
cmp_ok( $true,  'ne',   0, 'true  ne 0'  );

cmp_ok( $false, 'ne',   1, 'false ne 1'  );
cmp_ok( $true,  'eq',   1, 'true  eq 1'  );
cmp_ok( $false, 'ne',  11, 'false ne 11' );
cmp_ok( $true,  'eq',  11, 'true  eq 11' );

cmp_ok( $false, 'eq', \'', 'false eq \""' );
cmp_ok( $true,  'ne', \'', 'true  ne \""' );
cmp_ok( $false, 'eq',  \0, 'false eq \0'  );
cmp_ok( $true,  'ne',  \0, 'true  ne \0'  );

cmp_ok( $false, 'ne',  \1, 'false ne \1'  );
cmp_ok( $true,  'eq',  \1, 'true  eq \1'  );
cmp_ok( $false, 'ne', \11, 'false ne \11' );
cmp_ok( $true,  'eq', \11, 'true  eq \11' );

cmp_ok( $false, 'eq', undef, 'false eq undef' );
cmp_ok( $true,  'ne', undef, 'true  ne undef' );
cmp_ok( $false, '==', undef, 'false == undef' );
cmp_ok( $true,  '!=', undef, 'true  != undef' );

is( Jasonify->encode($false), 'false', 'false encodes correctly' );
is( Jasonify->encode($true),  'true',  'true  encodes correctly' );

is( Jasonify->encode(\''), 'false', '\"" encodes correctly' );
is( Jasonify->encode(\0),  'false', '\0  encodes correctly' );
is( Jasonify->encode(\1),  'true',  '\1  encodes correctly' );
is( Jasonify->encode(\11), 'true',  '\11 encodes correctly' );


# Verify numbers
my $int  = 9_876_543_210;
my $num  = 1_234_567_890.12_345_678_9;
my $numf = Jasonify::Number->formatted( '%.6f', $num );
my $inf  = 9**9**9;
my $nan  = $inf / $inf;

my $numstr  = "$num";
my $numfstr = "1234567890.123457";

is( Jasonify->encode($int),     '9876543210', ' int  encodes correctly' );
is( Jasonify->encode($num),          $numstr, ' num  encodes correctly' );
is( Jasonify->encode( -$inf ), '"-Infinity"', '-inf  encodes correctly' );
is( Jasonify->encode($inf),     '"Infinity"', ' inf  encodes correctly' );
is( Jasonify->encode($nan),     '"NaN"',      ' nan  encodes correctly' );

is( Jasonify->encode($numf), $numfstr, 'formatted number encodes correctly' );


# Scalars
is( Jasonify->encode( undef ), 'null', 'scalar undef' );
is( Jasonify->encode( '' ),    '""',   'scalar ""' );
is( Jasonify->encode( 0 ),     '0',    'scalar 0' );
is( Jasonify->encode( 1 ),     '1',    'scalar 1' );


# Scalar references
is( Jasonify->encode( \undef ), 'null',  'scalar reference \undef' );
is( Jasonify->encode( \'' ),    'false', 'scalar reference \""' );
is( Jasonify->encode( \0 ),     'false', 'scalar reference \0' );
is( Jasonify->encode( \1 ),     'true',  'scalar reference \1' );


# Verify arrays
is( Jasonify->encode( [] ),          '[]',       'array encodes correctly' );
is( Jasonify->encode( [qw( A 1 )] ), '["A", 1]', 'array encodes correctly' );

my @array = ();
my @value = ();

push @array, [ undef, $false, $true, '', 0, 1 ];
push @value, '[null, false, true, "", 0, 1]';
is( Jasonify->encode($array[-1]), $value[-1], 'array of scalars' );

push @array, [ \undef, \$false, \$true, \'', \0, \1 ];
push @value, '[null, false, true, false, false, true]';
is( Jasonify->encode($array[-1]), $value[-1], 'array of scalar references' );

push @array, [ $int, $num, $numf, $inf, $nan ];
push @value,
    qq![9876543210, $numstr, $numfstr, "Infinity", "NaN"]!;
is( Jasonify->encode($array[-1]), $value[-1],
    'array of numbers encodes correctly' );

push @array, [ \$int, \$num, \$inf, \$nan ];
push @value, '[true, true, true, true]';
is( Jasonify->encode( $array[-1] ), $value[-1],
    'array of number references encodes correctly' );

my $value = join( ', ', @value );
is( Jasonify->encode( \@array ), "[$value]",
    'array of arrays encodes correctly' );

is( Jasonify->encode( [ (@array) x 2 ] ), "[$value, $value]",
    'doubled array of arrays encodes correctly' );

is( Jasonify->encode( [ @array, \@array ] ), "[$value, [$value]]",
    'doubled array of arrays encodes correctly' );

push @array, \@array;
is(
    dies { Jasonify->encode( \@array ) },
    sprintf(
        "Recursive structures not allowed at [%d] at %s line %d.\n",
        $#array,
        __FILE__,
        __LINE__ - 5
    ),
    'nested array of arrays dies correctly'
);


# Verify hashes
is( Jasonify->encode( {} ),         '{}',        'hash  encodes correctly' );
is( Jasonify->encode( { A => 1 } ), '{"A" : 1}', 'hash  encodes correctly' );

my %hash = ();
my %value = ();

$hash{first}  = { map { $_ => $_ } $false, $true, '', 0, 1 };
$value{first} = '{"0" : 0, "1" : 1, "" : "", "false" : false, "true" : true}';
is( Jasonify->encode( $hash{first} ), $value{first}, 'hash of scalars' );

$hash{second} = { map { $_ => $_ } $int, $num, $numf };
$value{second} = join( '',
    map { sprintf( '"%s" : %s, ', $_, $hash{second}{$_} ) }
        sort { $a <=> $b }
            keys %{ $hash{second} }
);
$hash{second}{$inf} = $inf;
$hash{second}{$nan} = $nan;
$value{second}
    = '{'
    . $value{second}
    . '"Infinity" : "Infinity", '
    . '"NaN" : "NaN"'
    . '}';
is( Jasonify->encode( $hash{second} ), $value{second},
    'hash of numbers encodes correctly' );

$hash{third} = { map { $_ => \$_ } $int, $num, $inf, $nan };
$value{third}
    = '{'
    . qq!"$numstr" : true, !
    . '"9876543210" : true, '
    . '"Infinity" : true, '
    . '"NaN" : true'
    . '}';
is( Jasonify->encode( $hash{third} ), $value{third},
    'hash of number references encodes correctly' );

$hash{fourth} = {%hash};
$value{fourth} = '{'
    . join( ', ',
        map { sprintf( '"%s" : %s', $_, $value{$_} ) }
            qw( first second third ) )
    . '}';
is( Jasonify->encode( $hash{fourth} ), $value{fourth},
    'hash of hashes encodes correctly' );

$hash{fifth} = \%hash;
is(
    dies { Jasonify->encode( \%hash ) },
    sprintf(
        qq!Recursive structures not allowed at {"%s"} at %s line %d.\n!,
        "fifth",
        __FILE__,
        __LINE__ - 5
    ),
    'nested hash of hashes dies correctly'
);

# Unusual things
is( Jasonify->encode(  substr( 'abcdef', 0, 3 ) ), '"abc"',  'lvalue' );
is( Jasonify->encode(  qr/abc/ ),              '"(?^:abc)"', 'regexp' );
is( Jasonify->encode(  v97.98.99 ),  '"\u0061\u0062\u0063"', 'vstring "abc"' );
is( Jasonify->encode(  v48 ),                    '"\u0030"', 'vstring "0"' );
is( Jasonify->encode(  sub {'abc'} ),                'null', 'code' );
is( Jasonify->encode(  *STDIO{IO} ),                 'null', 'io' );


# Unusual thing references
is( Jasonify->encode( \substr( 'abcdef', 0, 3 ) ), 'true', 'lvalue ref' );
is( Jasonify->encode( \qr/abc/ ),    '"(?^:abc)"', 'regexp ref' );
is( Jasonify->encode( \v97.98.99 ),        'true', 'vstring ref "abc"' );
is( Jasonify->encode( \v48 ),             'false', 'vstring ref "0"' );
is( Jasonify->encode( \sub {'abc'} ),      'null', 'code ref' );
is( Jasonify->encode( \*STDIO{IO} ),       'null', 'io ref' );


# The Jasonify object
my $jasonify = do {
    no warnings 'qw';
    join(' ', qw(
        {"-infinite"   : "-Infinity",
         "_cache_hit"  : 1,
         "array_ref"   : "[$_]",
         "beautify"    : null,
         "code"        : "null",
         "dereference" : "$referent$place",
         "encode2" :
              {"0" : "\\\\u0000",
               "1" : "\\\\u0001",
               "2" : "\\\\u0002",
               "3" : "\\\\u0003",
               "4" : "\\\\u0004",
               "5" : "\\\\u0005",
               "6" : "\\\\u0006",
               "7" : "\\\\u0007",
               "8" : "\\\\b",
               "9" : "\\\\t",
              "10" : "\\\\n",
              "11" : "\\\\u000b",
              "12" : "\\\\u000c",
              "13" : "\\\\r",
              "14" : "\\\\u000e",
              "15" : "\\\\u000f",
              "16" : "\\\\u0010",
              "17" : "\\\\u0011",
              "18" : "\\\\u0012",
              "19" : "\\\\u0013",
              "20" : "\\\\u0014",
              "21" : "\\\\u0015",
              "22" : "\\\\u0016",
              "23" : "\\\\u0017",
              "24" : "\\\\u0018",
              "25" : "\\\\u0019",
              "26" : "\\\\u001a",
              "27" : "\\\\u001b",
              "28" : "\\\\u001c",
              "29" : "\\\\u001d",
              "30" : "\\\\u001e",
              "31" : "\\\\u001f",
              "34" : "\\\\\\"",
              "92" : "\\\\\\\\",
             "127" : "\\\\u007f",
             "128" : "\\\\u0080",
             "129" : "\\\\u0081",
             "130" : "\\\\u0082",
             "131" : "\\\\u0083",
             "132" : "\\\\u0084",
             "133" : "\\\\u0085",
             "134" : "\\\\u0086",
             "135" : "\\\\u0087",
             "136" : "\\\\u0088",
             "137" : "\\\\u0089",
             "138" : "\\\\u008a",
             "139" : "\\\\u008b",
             "140" : "\\\\u008c",
             "141" : "\\\\u008d",
             "142" : "\\\\u008e",
             "143" : "\\\\u008f",
             "144" : "\\\\u0090",
             "145" : "\\\\u0091",
             "146" : "\\\\u0092",
             "147" : "\\\\u0093",
             "148" : "\\\\u0094",
             "149" : "\\\\u0095",
             "150" : "\\\\u0096",
             "151" : "\\\\u0097",
             "152" : "\\\\u0098",
             "153" : "\\\\u0099",
             "154" : "\\\\u009a",
             "155" : "\\\\u009b",
             "156" : "\\\\u009c",
             "157" : "\\\\u009d",
             "158" : "\\\\u009e",
             "159" : "\\\\u009f",
            "8232" : "\\\\u2028",
            "8233" : "\\\\u2029",
            "byte" : "\\\\u00%02x",
            "utf"  : 16,
            "wide" : "\\\\u%04x"},
         "false"            : "false",
         "format"           : "null",
         "hash_ref"         : "{$_}",
         "infinite"         : "Infinity",
         "io"               : "null",
         "json_method"      : "TO_JSON",
         "keyfilter"        : null,
         "keyfilterdefault" : 1,
         "keymap"           : null,
         "keysort"          : null,
         "list_sep"         : ", ",
         "longstr"          : -1,
         "lvalue"           : "$lvalue",
         "nonnumber"        : "NaN",
         "null"             : "null",
         "object"           : "$data",
         "overloads"        : ["\"\"", "0+"],
         "pair"             : "$key : $value",
         "quote"            : "\"",
         "quote2"           : "\"",
         "reference"        : "$_",
         "tag"              : null,
         "tag_method"       : "FREEZE",
         "true"             : "true",
         "vformat"          : "\"\\\\u%0*v4x\"",
         "vsep"             : "\\\\u"}
    ))
};
my $jason;
isa_ok( $jason = Jasonify->new(), 'Jasonify' );
is( Jasonify->encode($jason), '{}',
    'simple Jasonify object encodes correctly' );
isa_ok( $jason = Jasonify->new( Jasonify->get ), 'Jasonify' );
is( Jasonify->encode($jason), $jasonify,
    'compelete Jasonify object encodes correctly' );

### End of File ###
