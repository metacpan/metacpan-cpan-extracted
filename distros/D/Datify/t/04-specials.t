#! /usr/bin/env perl

use Test::More tests => 59;

ok require Datify, 'Required Datify';

no warnings 'qw';
my $datify = join(' ', qw(
    array_ref   => '[$_]',
    assign      => '$var = $value;',
    beautify    => undef,
    body        => '...',
    code        => 'sub {$_}',
    dereference => '$referent->$place',
    encode      =>   {0 => '\\\\0',  7 => '\\\\a',  9 => '\\\\t',
                     10 => '\\\\n', 12 => '\\\\f', 13 => '\\\\r',
                     27 => '\\\\e',
                    255 => '\\\\x%02x', 65535 => '\\\\x{%04x}'},
    false       => "''",
    format      => "format UNKNOWN =\\n.\\n",
    hash_ref    => '{$_}',
    io          => '*UNKNOWN{IO}',
    keysort     => sub {...},
    keywords    => ['undef'],
    list        => '($_)',
    list_sep    => ', ',
    longstr     => 1_000,
    lvalue      => 'substr($lvalue, 0)',
    name        => '$self',
    nested      => '$referent$place',
    null        => 'undef',
    num_sep     => '_',
    object      => 'bless($data, $class_str)',
    overloads   => ['""', '0+'],
    pair        => '$key => $value',
    q1          => 'q',
    q2          => 'qq',
    q3          => 'qr',
    qpairs      => ['()', '<>', '[]', '{}'],
    qquotes     => ['!', '#', '%', '&', '*', '+', ',', '-', '.', '/',
                    ':', ';', '=', '?', '^', '|', '~', '$', '@', '`'],
    quote       => undef,
    quote1      => "'",
    quote2      => '"',
    quote3      => '/',
    reference   => '\\\\$_',
    sigils      => '$@',
    true        => 1,
    vformat     => 'v%vd'
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

