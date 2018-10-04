#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 79;

ok require Datify, 'Required Datify';

no warnings 'qw';
my $datify = join(' ', qw(
    -infinite        => "'-inf'",
    array_ref        => '[$_]',
    assign           => '$var = $value;',
    beautify         => undef,
    body             => '...',
    code             => 'sub {$_}',
    dereference      => '$referent->$place',
    encode           =>   {0 => '\\\\0',  7 => '\\\\a',  9 => '\\\\t',
                          10 => '\\\\n', 12 => '\\\\f', 13 => '\\\\r',
                          27 => '\\\\e',
                          byte => '\\\\x%02x', wide => '\\\\x{%04x}'},
    false            => "''",
    format           => "format UNKNOWN =\\n.\\n",
    hash_ref         => '{$_}',
    infinite         => "'inf'",
    io               => '*UNKNOWN{IO}',
    keyfilter        => undef,
    keyfilterdefault => 1,
    keysort          => sub {...},
    keywords         => ['undef'],
    list             => '($_)',
    list_sep         => ', ',
    longstr          => 1_000,
    lvalue           => 'substr($lvalue, 0)',
    name             => '$self',
    nested           => '$referent$place',
    nonnumber        => "'nan'",
    null             => 'undef',
    num_sep          => '_',
    object           => 'bless($data, $class_str)',
    overloads        => ['""', '0+'],
    pair             => '$key => $value',
    q1               => 'q',
    q2               => 'qq',
    q3               => 'qr',
    qpairs           => ['()', '<>', '[]', '{}'],
    qquotes          => ['!', '#', '%', '&', '*', '+', ',', '-', '.', '/',
                         ':', ';', '=', '?', '^', '|', '~', '$', '@', '`'],
    quote            => undef,
    quote1           => "'",
    quote2           => '"',
    quote3           => '/',
    reference        => '\\\\$_',
    sigils           => '$@',
    true             => 1,
    vformat          => 'v%vd'
));

format EMPTY_FORMAT =
.

my @specials = (
    undef             => undef()          => 'undef',
    '\\8_675_309'     => \867_5309        => 'number ref',
    "\\'scalar'"      => \'scalar'        => 'string ref',

    "['array', 1]"    => [ array => 1 ]   => 'array ref',
    'sub {...}'       => sub {}           => 'code ref',
    '*::STDOUT'       => *STDOUT          => 'glob',
    '{hash => 1}'     => { hash  => 1 }   => 'hash ref',
    "\\substr('', 0)" => \substr('', 0)   => 'lvalue ref',
    'qr/(?^:\s*)/'    => qr/\s*/          => 'regexp',
    '\\v99.98.97'     => \v99.98.97       => 'vstring ref',

    q!bless(*STDOUT{IO}, 'IO::File')! => *STDOUT{IO}   => 'IO',
    "bless({$datify}, 'Datify')"      => Datify->new() => 'object',

    "format UNKNOWN =\n.\n" => *EMPTY_FORMAT{FORMAT} => 'format ref',
);
foreach my $stingified (qw( [] {} 'string' 123 456.78 )) {
    my $thing = eval $stingified;
    my $ref   = ref($thing);
    my $repr  = $stingified;
    if ( !$ref ) {
        $thing = \do { 1; $thing };
        $repr = '\\' . $repr;
    }
    push @specials,
        qq!bless($repr, 'Test::${ref}::Object')!,
        bless( $thing, "Test::${ref}::Object" ),
        "a $ref object",
        ;
}

for ( my $i = 0; $i < @specials - 1; $i += 3 ) {
    my ( $string, $special, $desc ) = @specials[ $i, $i + 1, $i + 2 ];
    my $str;

    $str = Datify->scalarify($special);
    is $str, $string, "$desc scalarified";

    $str = Datify->scalarify(\$special);
    is $str, "\\$string", "$desc ref scalarified";

    $str = Datify->varify( '$var' => $special );
    is $str, "\$var = $string;", "$desc varified";

    $str = Datify->varify( var => \$special );
    is $str, "\$var = \\$string;", "$desc ref varified";
}

my $str;
my $circular; $circular = \$circular;

$str = Datify->scalarify($circular);
is $str, '\\$self', "Circular scalarified";

$str = Datify->varify( var => $circular );
is $str, '$var = \\$var;', "Circular varified";

$str = Datify->scalarify(\$circular);
is $str, '\\$self', "Circular ref scalarified";

$str = Datify->varify( var => \$circular );
is $str, '$var = \\$var;', "Circular ref varified";

$str = Datify->scalarify(\\$circular);
is $str, '\\\\$self', "Circular double ref scalarified";

$str = Datify->varify( var => \\$circular );
is $str, '$var = \\\\$var;', "Circular double ref varified";

undef $circular;

