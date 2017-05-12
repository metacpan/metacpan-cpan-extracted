package Lingua::Romana::Perligata;

our $VERSION = '0.601';

use Filter::Util::Call;
use IO::Handle;
use Data::Dumper 'Dumper';

my $offset = 0;
my $translate = 0;
my $debug = 0;

sub import {
    filter_add({});
    $offset = (caller)[2]+1;
    $translate = grep /^converte?$/i, @_[1..$#_];
    $debug = grep /^investiga?$/i, @_[1..$#_];
    $lex = grep /^discribe?$/i, @_[1..$#_];
    1;
}

$translator = q{
BEGIN {
    $SIG{__DIE__} = sub { die Lingua::Romana::Perligata::readversum($_[0]) };
    $SIG{__WARN__} = sub { return if $_[0] =~ /(...) interpreted as function/;
                   warn Lingua::Romana::Perligata::readversum($_[0]) };
}
};

sub unimport { filter_del() }

sub filter {
    my($self) = @_ ;

    my $status = 1;
    $status = filter_read(100_000);
    return $status if $status<0;
    s/\A#!.*\n//;
    $tokens = tokenize($_);

    my @commands;
    push @commands, conn_command($tokens,'END') while @$tokens;
    $_ = join ";\n", map { $_->translate } @commands;

    if ($translate) { print and exit }
    elsif ($debug && /\S/) {
        print "=" x 72,
              "\nTranslated to:\n\n$_\n",
              "=" x 72;
    }
    $_ = "$translator\n#line $offset\n;$_";
    return $status;
}

#==========TOKENIZER============

sub adversum { " ad versum " . to_rn($_[0]->{line}) . "\n" }
sub readversum { $_[0] =~ m{(.*)at\s+(\S+)\s+line\s+(\d+)(.*)}s or return $_[0];
         return $1 . " ad $2 versum " . to_rn($3) . $4 }

sub make_range {
    my ($unit, $five, $ten) = @_;
    my ($two, $three) = ($unit x 2, $unit x 3);
    return [ "", $unit, $two, $three, $unit.$five, $five,
         $five.$unit, $five.$two, $five.$three, $unit.$ten ];
}

my @order = (
    make_range(qw{         I         V                  X          }),
    make_range(qw{         X         L                  C          }),
    make_range(qw{         C         D                  M          }),
    make_range(qw{         M         I))              ((I))        }),
    make_range(qw{       ((I))       I)))            (((I)))       }),
    make_range(qw{      (((I)))      I))))          ((((I))))      }),
    make_range(qw{     ((((I))))     I)))))        (((((I)))))     }),
    make_range(qw{    (((((I)))))    I))))))      ((((((I))))))    }),
    make_range(qw{   ((((((I))))))   I)))))))    (((((((I)))))))   }),
    make_range(qw{  (((((((I)))))))  I))))))))  ((((((((I))))))))  }),
);

my %val;
foreach my $power (0..$#order) {
    @val{@{$order[$power]}} = map {$_*10**$power} 0..9;
}

my $roman = '(' . join(")(", map {join("|",map { quotemeta } reverse(@$_))} reverse @order) . '|)';

sub from_rn {
    my $val = shift;
    @numerals = $val =~ /(?:$roman)/ix;
    join("",@numerals) eq $val or return $val;
    my $an = 0;
    $an += $val{$_} foreach @numerals;
    return $an;
}

sub __beautify__ {
    my ($text) = @_;
    $text =~ s/\b(\d+)\b/to_rn($1)/ge;
    return $text;
}

sub to_rn {
    return "nullum" if $_[0] == 0;
    @digits = split '', $_[0];
    return $_[0] if grep {/\D/} @digits;
    my $power = 0;
    my $rn = "";
    $rn = $order[$power++][$_||0] . $rn foreach reverse @digits;
    return $rn;
}

sub getline {
    my ($fh) = @_;
    if (wantarray) {
        my @lines = IO::Handle::getlines($fh);
        s/\b($roman)\b/$1 ? from_rn($1) : $1/ge for @lines;
        return @lines;
    }
    else {
        my $line = IO::Handle::getline($fh);
        $line =~ s/\b($roman)\b/$1 ? from_rn($1) : $1/ge;
        return $line;
    }
}

sub multibless(\%$$)
{
    my ($hash,$blesstype,$lextype) = @_;
    foreach my $key (keys %$hash)
    {
        $hash->{$key}{lex} = $lextype;
        bless $hash->{$key}, $blesstype;
    }
}

sub addres(\%$$)
{
    my ($hash,$blesstype,$lextype) = @_;
    my (%acc, %dat);
    foreach my $key (keys %$hash)
    {
        $acc{$key.'mentum'} = { %{$hash->{$key}} };
        $acc{$key.'menta'}  = { %{$hash->{$key}} };
        $dat{$key.'mento'}  = { %{$hash->{$key}} };
        $dat{$key.'mentis'} = { %{$hash->{$key}} };
    }
    multibless %acc, $blesstype, $lextype.'_ACCUSATIVE';
    multibless %dat, $blesstype, $lextype.'_DATIVE';
    %$hash = ( %$hash, %acc, %dat );
}

sub add_genitives(\%$$$)
{
    my ($hash, $blesstype, $from, $to) = @_;
    foreach my $key (keys %$hash)
    {
        my $genkey = $key;
        $genkey =~ s/$from$/$to/ or next;
        $hash->{$genkey} = bless { %{$hash->{$key}},
                       lex => 'GENITIVE' },
                     $blesstype;
    }
}

my %literals =
(
    'novumversum'   => { perl => '"\n"' },
    'biguttam'  => { perl => '":"' },
    'lacunam'   => { perl => '" "' },
    'stadium'   => { perl => '"\t"' },
    'parprimum' => { perl => '$1' },
    'pardecimum'    => { perl => '$10' },
    'parsecundum'   => { perl => '$2' },
    'partertium'    => { perl => '$3' },
    'parquartum'    => { perl => '$4' },
    'parquintum'    => { perl => '$5' },
    'parsextum' => { perl => '$6' },
    'parseptimum'   => { perl => '$7' },
    'paroctavum'    => { perl => '$8' },
    'parnonum'  => { perl => '$9' },
    'nomen'         => { perl => '$<' },
);

multibless %literals, 'Literal', 'ACCUSATIVE';
add_genitives %literals, 'Literal', 'um' => 'i';


my %numerals =
(
    'nullum'    => { perl => '0' },
    'unum'      => { perl => '1' },
    'unam'      => { perl => '1' },
    'duo'       => { perl => '2' },
    'duas'      => { perl => '2' },
    'tres'      => { perl => '3' },
    'quattuor'  => { perl => '4' },
    'quinque'   => { perl => '5' },
    'sex'       => { perl => '6' },
    'septem'    => { perl => '7' },
    'octo'      => { perl => '8' },
    'novem'     => { perl => '9' },
    'decem'     => { perl => '10' },
);

multibless %numerals, 'Literal', 'NUMERAL';


my %ordinals_a =
(
    'nullimum'  => { perl => '0' },
    'primum'    => { perl => '1' },
    'secundum'  => { perl => '2' },
    'tertium'   => { perl => '3' },
    'quartum'   => { perl => '4' },
    'quintum'   => { perl => '5' },
    'sextum'    => { perl => '6' },
    'septimum'  => { perl => '7' },
    'octavum'   => { perl => '8' },
    'nonum'     => { perl => '9' },
    'decimum'   => { perl => '10' },
);

foreach ( map substr($_,0,-2), keys %ordinals_a ) {
    $ordinals_a{"${_}os"} = $ordinals_a{"${_}um"};  # MASC. PLURALS
    $ordinals_a{"${_}am"} = $ordinals_a{"${_}um"};  # FEMININE
    $ordinals_a{"${_}as"} = $ordinals_a{"${_}um"};  # FEM. PLURALS
}

multibless %ordinals_a, 'Ordinal', 'ORDINAL';
add_genitives %ordinals_a, 'Ordinal', 'um' => 'i';
add_genitives %ordinals_a, 'Ordinal', 'am' => 'ae';
# add_genitives %ordinals_a, 'Ordinal', 'os' => 'orum';

my %ordinals_d =
(
    'nullimo'   => { perl => '0' },
    'primo'     => { perl => '1' },
    'secundo'   => { perl => '2' },
    'tertio'    => { perl => '3' },
    'quarto'    => { perl => '4' },
    'quinto'    => { perl => '5' },
    'sexto'     => { perl => '6' },
    'septimo'   => { perl => '7' },
    'octavo'    => { perl => '8' },
    'nono'      => { perl => '9' },
    'decimo'    => { perl => '10' },
);

multibless %ordinals_d, 'Ordinal', 'ORDINAL_DATIVE';

my %underscores =
(
    'hoc'       => { perl => '$_', lex => 'ACCUSATIVE'},
    'huius'     => { perl => '$_', lex => 'GENITIVE'},
    'huic'      => { perl => '$_', lex => 'DATIVE'},
    'haec'      => { perl => '@_', lex => 'ACCUSATIVE'},
    'horum'     => { perl => '@_', lex => 'GENITIVE'},
    'his'       => { perl => '@_', lex => 'DATIVE'},
    'ianitorem' => { perl => '$/', lex => 'ACCUSATIVE' },
    'ianitoris' => { perl => '$/', lex => 'GENITIVE' },
    'ianitori'  => { perl => '$/', lex => 'DATIVE' },
);

for my $key ( keys %underscores )
{
    bless $underscores{$key}, 'Literal';
}

my %varmods =
(
    'loco'      => bless ({ perl => 'local', lex => 'OWNER_D' },
                  'ScalarMod'),
    'locis'     => bless ({ perl => 'local', lex => 'OWNER_D' },
                  'ArrMod'),
    'meo'       => bless ({ perl => 'my', lex => 'OWNER_D' },
                  'ScalarMod'),
    'meis'      => bless ({ perl => 'my', lex => 'OWNER_D' },
                  'ArrMod'),
    'nostro'    => bless ({ perl => 'our', lex => 'OWNER_D' },
                  'ScalarMod'),
    'nostris'   => bless ({ perl => 'our', lex => 'OWNER_D' },
                  'ArrMod'),
);

my %streams =
(
    'vestibulo' => { perl => '*STDIN' },
    'egresso'   => { perl => 'STDOUT' },
    'oraculo'   => { perl => 'STDERR' },
    'nuntio'    => { perl => '*Lingua::Romana::Perligata::DATA' },
);
multibless %streams, 'Literal', 'DATIVE';

my %matchops =
(
    'compara'   => { perl => 'm' },
    'substitue' => { perl => 's' },
    'converte'  => { perl => 'tr' },
);

multibless %matchops, 'MatchOperator', 'SUBNAME';
addres %matchops, 'MatchOperator', 'SUBNAME';

my %ops =
(
    'adde'      => { perl => '+' },
    'deme'      => { perl => '-' },
    'multiplica'    => { perl => '*' },
    'itera'     => { perl => 'x' },
    'divide'    => { perl => '/' },
    'recide'    => { perl => '%' },
    'eleva'     => { perl => '**' },
    'consocia'  => { perl => '&' },
    'interseca' => { perl => '|' },
    'discerne'  => { perl => '^' },
    'depone'    => { perl => '' , prefix => 1 },
);

$ops{$_}{operator} = 1 foreach keys %ops;
multibless %ops, 'Operator', 'SUBNAME_A';
addres %ops, 'Operator', 'SUBNAME_A';

my %lops =
(
    'da'        => { perl => '=', operator => 1 },
);

multibless %lops, 'Operator', 'SUBNAME_AD';
addres %lops, 'Operator', 'SUBNAME_AD';

my %invarops =
(
    'atque'         => { perl => '&&' },
    'vel'           => { perl => '||' },
    'praestantiam'      => { perl => '<' },
    'non praestantiam'  => { perl => '>=' },
    'praestantias'      => { perl => 'lt' },
    'non praestantias'  => { perl => 'ge' },
    'aequalitam'        => { perl => '==' },
    'non aequalitam'    => { perl => '!=' },
    'aequalitas'        => { perl => 'eq' },
    'non aequalitas'    => { perl => 'ne' },
    'comparitiam'       => { perl => '<=>' },
    'comparitias'       => { perl => 'cmp' },
    'non comparitiam'   => { perl => '!<=>' },
    'non comparitias'   => { perl => '!cmp' },

    'non'           => { perl => '!', prefix => 1 },
    'nega'          => { perl => '-', prefix => 1 },
);

$invarops{$_}{operator} = 1 foreach keys %invarops;
multibless %invarops, 'Operator', 'SUBNAME_A_ACCUSATIVE';

my %connectives =
(
    'que'           => { perl => 'and' },
    've'            => { perl => 'or' },
);

@{$connectives{$_}}{'operator','raw'} = (1,-$_) foreach keys %connectives;
multibless %connectives, 'Operator', 'CONNECTIVE';

my %funcs_td =
(
    'excerpe'   => { perl => 'substr' },    # SPECIAL: SEE BELOW

    'cumula'    => { perl => 'push' },
    'capita'    => { perl => 'unshift' },
    'iunge'     => { perl => 'splice' },
    'digere'    => { perl => 'sort' },
    'retexe'    => { perl => 'reverse' },
    'evolute'   => { perl => 'open' },
    'lege'      => { perl => 'read' },
    'scribe'    => { perl => 'print' },
    'describe'  => { perl => 'printf' },
    'subscribe' => { perl => 'write' },
    'conquire'  => { perl => 'seek' },
    'benedice'  => { perl => 'bless' },
    'liga'      => { perl => 'tie' },
    'modera'    => { perl => 'fcntl' },
    'conflue'   => { perl => 'flock' },
    'impera'    => { perl => 'ioctl' },
    'trunca'    => { perl => 'truncate' },
);

multibless %funcs_td, 'Function', 'SUBNAME_AD';
addres %funcs_td, 'Function', 'SUBNAME_AD';

# "bless" HAS A COMMON LATIN CONTRACTION...

$funcs_td{benedictum} = $funcs_td{benedicementum};
$funcs_td{benedicto} = $funcs_td{benedicemento};

# THE FOLLOWING IS LVALUABLE, SO ARG MUST AGREE IN CASE WITH FUNCTION'S CASE...

for (qw( excerpe )) {
    $funcs_td{"${_}mentum"}{lex} = 'SUBNAME_A_ACCUSATIVE';
}


my %funcs_bd =
(
    'vanne'     => { perl => 'grep' },
    'applica'   => { perl => 'map' },
    'digere'    => { perl => 'sort' },
);

multibless %funcs_bd, 'Function', 'SUBNAME_AB';
addres %funcs_bd, 'Function', 'SUBNAME_AB';

my %funcs_b =
(
        'factorem'  => { perl => 'sub' },
        'factori'   => { perl => 'sub' },
);

multibless %funcs_b, 'Function', 'SUBNAME_B_ACCUSATIVE';
$funcs_b{'factori'}{lex} = 'SUBNAME_B_DATIVE';


my %funcs_t =
(
    'morde'     => { perl => 'chomp' },
    'praecide'  => { perl => 'chop' },
    'stude'     => { perl => 'study' },
    'iani'      => { perl => 'undef' },
    'lusta'     => { perl => 'reset' },
    'decumula'  => { perl => 'pop' },
    'decapita'  => { perl => 'shift' },
    'claude'    => { perl => 'close' },
    'perlege'   => { perl => 'Lingua::Romana::Perligata::getline' },
    'sublege'   => { perl => 'getc' },
    'enunta'    => { perl => 'tell' },
    'dele'      => { perl => 'delete' },
    'quisque'   => { perl => 'each' },
    'adfirma'   => { perl => 'exists' },
    'solvere'   => { perl => 'untie' },
    'preincresce'   => { perl => '++', prefix => 1, operator => 1 },
    'postincresce'  => { perl => '++', prefix => 0, operator => 1 },
    'predecresce'   => { perl => '--', prefix => 1, operator => 1 },
    'postdecresce'  => { perl => '--', prefix => 0, operator => 1 },

    'reperi'    => { perl => 'pos' },   # SPECIAL: SEE BELOW
    'nomina'    => { perl => 'keys' },  # SPECIAL: SEE BELOW
);

multibless %funcs_t, 'Function', 'SUBNAME_D';
addres %funcs_t, 'Function', 'SUBNAME_D';


# THE FOLLOWING ARE LVALUABLE, SO ARG MUST AGREE IN CASE WITH FUNCTION'S CASE...

for (qw( reperi nomina )) {
    $funcs_t{"${_}mentum"}{lex} = 'SUBNAME_A_ACCUSATIVE';
}

my %funcs_d =
(
    'admeta'    => { perl => 'Lingua::Romana::Perligata::__lastelem__' },
    'inque'     => { perl => 'Lingua::Romana::Perligata::__enquote__' },
    'conscribe' => { perl => 'Lingua::Romana::Perligata::__enlist__' },
    'come'      => { perl => 'Lingua::Romana::Perligata::__beautify__' },
    'priva'     => { perl => 'abs' },
    'angula'    => { perl => 'atan2' },
    'oppone'    => { perl => 'sin' },
    'accuba'    => { perl => 'cos' },
    'decolla'   => { perl => 'int' },
    'succide'   => { perl => 'log' },
    'fode'      => { perl => 'sqrt' },
    'conice'    => { perl => 'rand' },
    'prosemina' => { perl => 'srand' },
    'inde'      => { perl => 'chr' },
    'senidemi'  => { perl => 'hex' },
    'octoni'    => { perl => 'oct' },
    'numera'    => { perl => 'ord' },
    'deminue'   => { perl => 'lc' },
    'minue'     => { perl => 'lcfirst' },
    'amplifica' => { perl => 'uc' },
    'amplia'    => { perl => 'ucfirst' },
    'excipe'    => { perl => 'quotemeta' },
    'huma'      => { perl => 'crypt' },
    'meta'      => { perl => 'length' },
    'convasa'   => { perl => 'pack' },
    'deconvasa' => { perl => 'unpack' },
    'scinde'    => { perl => 'split' },
    'scruta'    => { perl => 'index' },
    'coniunge'  => { perl => 'join' },
    'confirma'  => { perl => 'defined' },
    'secerna'   => { perl => 'scalar' },
    'argue'     => { perl => 'values' },
    'extremus'  => { perl => 'eof' },
    'deside'    => { perl => 'wantarray' },
    'aestima'   => { perl => 'eval' },
    'exi'       => { perl => 'exit' },
    'redde'     => { perl => 'return' },
    'mori'      => { perl => 'die' },
    'mone'      => { perl => 'warn' },
    'coaxa'     => { perl => 'Carp::croak' },
    'carpe'     => { perl => 'Carp::carp' },
    'memora'    => { perl => 'caller' },
    'agnosce'   => { perl => 'ref' },
    'exhibere'  => { perl => 'tied' },
    'require'   => { perl => 'require' },
    'demigrare' => { perl => 'chdir' },
    'permitte'  => { perl => 'chmod' },
    'vende'     => { perl => 'chown' },
    'inveni'    => { perl => 'glob' },
    'copula'    => { perl => 'link' },
    'decopula'  => { perl => 'unlink' },
    'aedifica'  => { perl => 'mkdir' },
    'renomina'  => { perl => 'rename' },
    'excide'    => { perl => 'rmdir' },
    'exprime'   => { perl => 'stat' },
    'terre'     => { perl => 'alarm' },
    'mitte'     => { perl => 'dump' },
    'commuta'   => { perl => 'exec' },
    'furca'     => { perl => 'fork' },
    'interfice' => { perl => 'kill' },
    'dormi'     => { perl => 'sleep' },
    'obsecra'   => { perl => 'system' },
    'dissimula' => { perl => 'umask' },
    'manta'     => { perl => 'wait' },

    'inscribe'  => { perl => ':' }, # SPECIAL: SEE BELOW
    'arcesse'   => { perl => '${' },    # SPECIAL: SEE BELOW

    'sere'      => { perl => 'Lingua::Romana::Perligata::__encatenate__' },
);

multibless %funcs_d, 'Function', 'SUBNAME_A';
addres %funcs_d, 'Function', 'SUBNAME_A';

# 'inscribe' IS SPECIAL: ONLY IMPERATIVE

delete @funcs_d{grep /^inscribement/, keys %funcs_d};

# 'arcesse' IS SPECIAL: NO IMPERATIVE AND EXTRA (PSEUDO-)RESULTATIVES

delete $funcs_d{'arcesse'};

# SCALAR AS NON-TERMINAL INDEX

$funcs_d{'arcessementi'} = { %{$funcs_d{'arcessementum'}},
                 lex => 'SUBNAME_A_GENITIVE' };

# ARRAY DEREFERENCE

$funcs_d{'arcessementa'}{perl}  = '@{';
$funcs_d{'arcessementis'}{perl} = '@{';
$funcs_d{'arcessementorum'} = { %{$funcs_d{'arcessementa'}},
                lex => 'SUBNAME_A_GENITIVE' };

$funcs_d{'arcessementus'}   = { %{$funcs_d{'arcessementa'}}, perl => '%{' };
$funcs_d{'arcessementibus'} = { %{$funcs_d{'arcessementis'}}, perl => '%{' };
$funcs_d{'arcessementuum'}  = { %{$funcs_d{'arcessementus'}},
                 lex => 'SUBNAME_A_GENITIVE'};


my %funcs_dl =
(
    'adi'       => { perl => 'goto' },
    'confectus' => { perl => 'continue' },
    'domus'     => { perl => 'package' },
    'ute'       => { perl => 'use' },
);

multibless %funcs_dl, 'Function_Lit', 'SUBNAME_A';
addres %funcs_dl, 'Function_Lit', 'SUBNAME_A';

my %funcs_dlo =
(
    'ultimus'   => { perl => 'last' },
    'posterus'  => { perl => 'next' },
    'reconnatus'    => { perl => 'redo' },
);

multibless %funcs_dlo, 'Function_Lit', 'SUBNAME_OA';
# addres %funcs_dl, 'Function_Lit', 'SUBNAME_OA';

my %misc  =
(
    'fac'       => { lex => 'DO',       perl => 'do' },
    'per'       => { lex => 'FOR',      perl => 'for' },
    'per quisque'   => { lex => 'FOR',      perl => 'foreach' },
    'si'        => { lex => 'CONTROL',      perl => 'if' },
    'nisi'      => { lex => 'CONTROL',      perl => 'unless' },
    'donec'     => { lex => 'CONTROL',      perl => 'until' },
    'dum'       => { lex => 'CONTROL',      perl => 'while' },
    'cum'       => { lex => 'WITH',     perl => '' },
    'intra'     => { lex => 'WITHIN',       perl => '::' },
    'apud'      => { lex => 'ARROW',        perl => '->' },
    'tum'       => { lex => 'COMMA',        perl => ',' },
    'in'        => { lex => 'IN',       perl => '' },
    'sic'       => { lex => 'BEGIN',        perl => '{' },
    'cis'       => { lex => 'END',      perl => '}' },
    'princeps'  => { lex => 'NAME', raw=>'main',perl => 'main' },
    'ad'        => { lex => 'ADDRESS',          perl => '\\' },
);

my %tokens =
(
    %literals, %numerals, %underscores,
    %numerals, %ordinals_a, %ordinals_d,
    %varmods, %matchops, %ops, %lops, %invarops,
    %funcs_td, %funcs_bd, %funcs_b, %funcs_t,
    %funcs_d, %funcs_dl, %funcs_dlo,
    %misc, %streams,
);

# Handle likely captialization variations...
@tokens{map {ucfirst} keys %tokens} = values %tokens;

foreach my $key ( keys %tokens )
{
    $tokens{$key}{raw} = $key
        unless $tokens{$key}{raw};
}

my $distokens = join '|', reverse sort keys %tokens;
my $tokens    = "\\A\\s*($distokens)\\b";
my $tokensque = "\\A\\s*($distokens)que\\b";
my $tokensve  = "\\A\\s*($distokens)ve\\b";

sub token($$$$)
{
    my ($raw, $lex, $perl, $blesstype) = @_;
    return bless { raw => $raw, lex => $lex, perl => $perl }, $blesstype;
}

sub tokdup
{
    my ($archetype) = @_;
    bless { %$archetype }, $archetype->{lex};
}

sub tokenize
{
    my ($text) = @_;
    my @tokens;
    my $bad = "";
    my $lines = $text =~ tr/\n/\n/;

    while (length $text)
    {
        $text =~ s/\A\s+//;
        my $line = $lines - ($text =~ tr/\n/\n/) + $offset;
        if ($text =~ s/\A(adnota.*)//i)
        {
            # ignore comments
        }
        elsif ($text =~ s/\A(nuntius|finis)[ \t]*[.]?[ \t]*\n(.*)//smi)
        {
            # set up DATA stream
            use vars '*DATA';
            local *Lingua::Romana::Perlidata::DATASRC;
            my $pipe = pipe \*Lingua::Romana::Perligata::DATA,
                        \*Lingua::Romana::Perlidata::DATASRC;

            print Lingua::Romana::Perlidata::DATASRC $2;
        }
        elsif ($text =~ s/\Adic(?:emen)?tum(que|ve|)\s+sic\s+\b(.*?)\s+cis\b//si)
        {
            push @tokens, tokdup $connectives{lc $1} if $1;
            push @tokens, token($2,'NAME',"$2",'Name');
        }
        elsif ($text =~ s/\Asic(que|ve|)\s+(.*?)\s+cis\s+dic(?:emen)?tum\b//si)
        {
            push @tokens, tokdup $connectives{lc $1} if $1;
            push @tokens, token($2,'NAME',"$2",'Name');
        }
        elsif ($text =~ s/\A(atque|vel)\b//i)
        {
            push @tokens, tokdup $misc{'tum'};
            push @tokens, tokdup $invarops{lc $1};
        }
        elsif ($text =~ s/\A(($roman)im(?:o|ae)(que|ve|))\b//ix && length $2)
        {
            push @tokens, tokdup $connectives{lc $+} if $+;
            push @tokens, token($1,'ORDINAL_DATIVE',from_rn($2),'ORDINAL_DATIVE');
        }
        elsif ($text =~ s/\A(($roman)im(?:um|os|am|as)(que|ve|))\b//ix && length $2)
        {
            push @tokens, tokdup $connectives{lc $+} if $+;
            push @tokens, token($1,'ORDINAL',from_rn($2),'ORDINAL');
        }
        elsif ($text =~ s/\A(($roman)(que|ve|))\b//ix && length $2)
        {
            push @tokens, tokdup $connectives{lc $+} if $+;
            push @tokens, token($1,'NUMERAL',from_rn($2),'NUMERAL');;
        }
        elsif ($text =~ s/$tokensque//i)
        {
            push @tokens, tokdup $connectives{'que'};
            push @tokens, tokdup $tokens{lc $1};
        }
        elsif ($text =~ s/$tokensve//i)
        {
            push @tokens, tokdup $connectives{'ve'};
            push @tokens, tokdup $tokens{lc $1};
        }
        elsif ($text =~ s/$tokens//i)
        {
            push @tokens, tokdup $tokens{lc $1};
        }
            elsif ($text =~ s/\A(([a-z]+?)(um|)ementum)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $4} if $4;
            my $perl = $3 ? "\$$2->" : $2;
            push @tokens, token($1,'SUBNAME_OA_ACCUSATIVE',$perl,'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+?)(um|)ementa)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $4} if $4;
            my $perl = $3 ? "\$$2->" : $2;
            push @tokens, token($1,'SUBNAME_OA_ACCUSATIVE',$perl,'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+?)(um|)emento)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $4} if $4;
            my $perl = $3 ? "\$$2->" : $2;
            push @tokens, token($1,'SUBNAME_OA_DATIVE',$perl,'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+?)(um|)ementis)(que|ve|)\b//i)
        {
            $bad .= "'-mentis' illicitum: '$1'"
                  . adversum({line=>$line});
            # One day this may be:
            #
            # push @tokens, tokdup $connectives{lc $4} if $4;
            # my $perl = $3 ? "\$$2->" : $2;
            # push @tokens, token($1,'SUBNAME_OA_DATIVE',$perl,'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)orum)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'GENITIVE',"\@$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)uum)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'GENITIVE',"\%$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)um)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'ACCUSATIVE',"\$$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)a)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'ACCUSATIVE',"\@$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)ibus)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'DATIVE',"\%$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)us)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'ACCUSATIVE',"\%$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)o)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'DATIVE',"\$$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)is)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'DATIVE',"\@$2",'Literal');
        }
        elsif ($text =~ s/\A(([a-z]+)tori)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'DATIVE',"\\&$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)i)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'GENITIVE',"\$$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+)ere)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'INFINITIVE',"$2",'Literal');
        }
            elsif ($text =~ s/\A(([a-z]+?)(um|)e)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $4} if $4;
            my $perl = $3 ? "\$$2->" : $2;
            push @tokens, token($1,'SUBNAME',$perl,'Literal');
        }
        elsif ($text =~ s/\A(([a-z]+)torem)(que|ve|)\b//i)
        {
            push @tokens, tokdup $connectives{lc $3} if $3;
            push @tokens, token($1,'ACCUSATIVE',"\\&$2",'Literal');
        }
        elsif ($text =~ s/\A([.])//)
        {
            push @tokens, token($1,'PERIOD',";",'Separator');
        }
        elsif ($text =~ s/\A(\S+)(que|ve|)\b//)
        {
            push @tokens, tokdup $connectives{lc $2} if $2;
            push @tokens, token($1,'NAME',"$1",'Name') if $1;
        }
        else
        {
            $text =~ s/\A(\S+)// or next;
            my $error = $1;
            $bad .= "Aliquod barbarum inveni: '$error'"
                  . adversum({line=>$line});
        }
        $tokens[-1]->{line} = $line if @tokens;
    }
    if (($lex ||$debug) && @tokens) {
        my $format = "%-20s     %-10s     %-20s\n";
        printf $format, qw(Word Role Meaning);
        printf $format, qw(==== ==== =======);
        foreach ( @tokens ) {
            printf $format, @{$_}{qw(raw lex perl)};
        }
        print "\n", "="x72, "\n\n";
        die "\n" if $lex;
    }

    die $bad if $bad;
    return [@tokens];
}

use Carp;

sub conn_command {
    my ($toks, $eatend, $noeatend) = @_;
    my $command = &command;
    while (@$toks && $toks->[0]{lex} eq 'CONNECTIVE') {
        local $Lingua::Romana::Perligata::connective = shift @$toks;
        $connective->{L} = $command;
        $connective->{R} = &command;
        $command = $connective;
    }
    return $command;
}


sub command {
    my ($toks, $eatend, $noeatend) = @_;
    my @Astack = { data => [], complete => 1 };   #SENTINEL ACCUSATIVE FRAME
    my (@Bstack, @Dstack, @Vstack, $Vdone);
    my $Dindir = 0;
    my @lastsubstantive;
    my $empty = 1;

    my $reduce;
    my $Astack_push = sub {
        if ($Astack[-1]{complete}) {
            $reduce->($_[0]) if @Astack > 1;
            push @Astack, { data => [ $_[0] ] };
        }
        else {
            push @{$Astack[-1]{data}}, $_[0];
        }
        $Astack[-1]{complete} = 1;
    };

    $reduce = sub {
        my ($lookahead) = @_;
        if (! @Vstack) {
            if (@Dstack && ($Dstack[-1]{V}{lex}||"") eq 'OWNER_D') {
                $Vdone = pop @Dstack;
                return 1
            }
            return 0;
        }
        return 0 if $Vstack[-1]{lex} =~ /^SUBNAME_?A?D?$/ && $lookahead->{lex} !~ /PERIOD|DO|END|CONNECTIVE/
                 || ref $Vstack[-1] eq "STATEMENT";
        my $verb = $Vstack[-1];
        my ($needA, $needD) = $verb->{lex} =~ /_(O?A?)([BD])?/;
        $needA ||= $verb->{lex} eq 'SUBNAME' ? "OA" : "";
        $needD ||= "";
        return 0 if $needA && $needA ne "OA"  && (@Astack<=1 || !$Astack[-1]{complete})
             || $needD eq 'D' && !@Dstack
             || $needD eq 'B' && !@Bstack;
        my $dat = $needD eq 'D' ? pop(@Dstack)
                : $needD eq 'B' ? pop(@Bstack)
                : undef;
        my $acc = $needA && @Astack>1 ? pop(@Astack)->{data} : undef;
        my $statement = bless { V=>pop(@Vstack), A=>$acc, D=>$dat }, "STATEMENT";
        if ($verb->{lex} =~ /SUBNAME_.*_ACCUSATIVE/
         || $Dindir && $verb->{lex} =~ /SUBNAME_.*_DATIVE|OWNER_D/ )
        {
            if ($verb->{lex} =~ /SUBNAME_.*_DATIVE|OWNER_D/) {
                $statement->{R} = $Dindir;
                $Dindir = 0;
            }
            $Astack_push->($statement);
            push @lastsubstantive, $Astack[-1]{data};
        }
        elsif ($verb->{lex} =~ /SUBNAME_.*_DATIVE|OWNER_D/ ) {
            push @Dstack, $statement;
            push @lastsubstantive, \@Dstack;
        }
        elsif ($verb->{lex} =~ /SUBNAME_.*_GENITIVE/ ) {
            my $lastsubstantive = pop @lastsubstantive;
            die "Genitivum non junctum: '$ord->{raw}'"
                . adversum($verb)
                unless $lastsubstantive;
            $ord = $lastsubstantive[-1][-1];
            die "Index '$ord->{raw}' ordinalis non est"
                . adversum($ord)
                if $ord->{lex} && $ord->{lex} eq 'NUMERAL';
            push @{$ord->{G}}, $statement;
            push @lastsubstantive, $Astack[-1]{data};
        }
        else { $Vdone = $statement }
        if ($debug) {
            print "reduced: ", Data::Dumper->Dump([$statement]);
        }
        return 1;
    };

    my $tok;
    while ( $tok = $toks->[0] ) {
        if ($debug) {
            print "Next: '$toks->[0]{raw}' ($toks->[0]{lex}):\n";
        }
        if ($tok->{lex} =~ /^(NUMERAL|ORDINAL)$/
         || $Dindir && $tok->{lex} eq 'ORDINAL_DATIVE')
            { shift @$toks;
              if ($1 eq 'NUMERAL' && $toks->[0]{lex} eq 'ORDINAL') {
                $tok->{raw} .= " " . $toks->[0]{raw};
                $tok->{perl} /= $toks->[0]{perl};
                shift @$toks;
              }
              if ($tok->{lex} eq 'ORDINAL_DATIVE') {
                  $tok->{R} = $Dindir;
                  $Dindir = 0;
              }
              $Astack_push->($tok);
              $lastownable = $Astack[-1]{data};
              push @lastsubstantive, $lastownable;
            }
        elsif ($tok->{lex} eq 'ORDINAL_DATIVE')
            { shift @$toks;
              $reduce->($tok);
              push @Dstack, $tok;
              $lastownable = \@Dstack;
              push @lastsubstantive, $lastownable;
            }
        elsif ($tok->{lex} eq 'WITH') {
            push @Astack, { data=>[], complete=>0 };
            shift @$toks;
        }
        elsif ($tok->{lex} =~ /^(?:ACCUSATIVE|NAME)$/
            || $Dindir && $tok->{lex} eq 'DATIVE')
            { if ($tok->{lex} eq 'DATIVE') {
                $tok->{R} = $Dindir;
                $Dindir = 0;
              }
              $Astack_push->($tok);
              shift @$toks;
              $lastownable = $Astack[-1]{data};
              push @lastsubstantive, $lastownable;
            }
        elsif ( $tok->{lex} eq 'ARROW' ) {
              my $owner = $toks->[1];
              my $perl = $owner->{perl} =~ /^\W/
                ? $owner->{perl}
                : "$owner->{raw}::";
              $lastownable->[-1]->{perl}
                    =~ s{^}{$perl->};
              splice @$toks, 0, 2;
            }
        elsif ( $tok->{lex} eq 'WITHIN' ) {
              my $owner = $toks->[1];
              $lastownable->[-1]->{raw}
                    =~ s{^(\W*)}{$1$owner->{raw}::};
              $lastownable->[-1]->{perl}
                    =~ s{^(\W*)}{$1$owner->{raw}::};
              splice @$toks, 0, 2;
            }
        elsif ( $tok->{lex} eq 'GENITIVE' ) {
              $reduce->($tok);
              my $gen = shift @$toks;
              die "Genitivum indominum: '$ord->{raw}'"
                . adversum($gen)
                unless @lastsubstantive;
              $ord = $lastsubstantive[-1][-1];
              die "Index '$ord->{raw}' ordinalis non est"
                . adversum($ord)
                if $ord->{lex} && $ord->{lex} eq 'NUMERAL';
              push @{$ord->{G}}, $gen;
              $lastownable = $ord->{G};
            }
        elsif ( $tok->{lex} eq 'INFINITIVE' )
            { $reduce->($tok); $Vdone = subdefn($toks); last }
        elsif ( $tok->{lex} eq 'CONTROL' )
            { $reduce->($tok); $Vdone = control($toks, \@Bstack); last }
        elsif ( $tok->{lex} eq 'FOR' )
            { $reduce->($tok); $Vdone = for_control($toks, \@Bstack); last }
        elsif ( $tok->{lex} eq 'BEGIN' )
            { push @Bstack, block($toks) }
        elsif ( $tok->{lex} eq 'OWNER_D' )
            { $reduce->($tok); push @Vstack, $tok; shift @$toks; }
        elsif ( $tok->{lex} eq 'COMMA' )
            { $reduce->($tok)
                unless $lastownable && @Astack>1 &&
                       $lastownable == $Astack[-1]{data};
              die "'$tok->{raw}' immaturum est " . adversum($tok)
                unless @Astack>1 && $Astack[-1]{complete};
              $Astack[-1]{complete} = 0;
              shift @$toks;
            }
        elsif ( $tok->{lex} eq 'ADDRESS' )
            { $reduce->($tok);
              $Dindir++;
              shift @$toks;
            }
        elsif ( $tok->{lex} eq 'DATIVE' )
            { $reduce->($tok); push @Dstack, $tok; shift @$toks;
              $lastownable = \@Dstack;
              push @lastsubstantive, $lastownable;
            }
        elsif ( $tok->{lex} =~ /^SUBNAME/ )     # WAS: /SUBNAME_
            { if ($Astack[-1]{complete}) {
                $reduce->($tok)
              }
              elsif ($tok->{perl} !~ /^(and|or|[&|]{2})$/) {
                push @Astack, { data=>[] };
              }
              push @Vstack, $tok; shift @$toks;
              $lastownable = \@Vstack;
            }
        # elsif ( $tok->{lex} =~ /^SUBNAME$/ )
            # { if ($Astack[-1]{complete}) {
                # $reduce->($tok)
              # }
              # elsif ($tok->{perl} !~ /^[&|]{2}$/ {
                # push @Astack, { data=>[] };
              # }
              # push @Vstack, $tok; shift @$toks;
              # $lastownable = \@Vstack;
            # }
        elsif ( $tok->{lex} =~ /PERIOD/ )
            { 1 while $reduce->($tok) && !$Vdone;
              $Vdone = pop(@Astack)->{data}
                if $Lingua::Romana::Perligata::connective
                && !($Vdone || @Astack <= 1);
              shift @$toks;
              last
            }
        elsif ( $tok->{lex} =~ /CONNECTIVE/ )
            { 1 while $reduce->($tok) && !$Vdone;
              $Vdone = pop(@Astack)->{data}
                unless $Vdone || @Astack <= 1;
              last }
        elsif ( $eatend && $tok->{lex} =~ /$eatend/ )
            { 1 while $reduce->($tok);
              $Vdone or $Vdone = @Astack > 1
                        ? pop(@Astack)->{data}
                        : pop @Dstack;
              shift @$toks; last }
        elsif ( $noeatend && $tok->{lex} =~ /$noeatend/ )
            { 1 while $reduce->($tok);
              $Vdone or $Vdone = pop(@Astack)->{data}
                      || pop @Dstack;
              last }
        else {
            die "Non intellexi: '$tok->{raw}'" . adversum($tok);
            }
    }
    continue {
        $empty = 0;
        if ($debug) {
            print "After '$tok->{raw}' ($tok->{lex}):\n";
            print Data::Dumper->Dump([\@Vstack, \@Astack, \@Bstack, \@Dstack, \@lastsubstantive, \$lastownable, \$Vdone], [qw{Vstack Astack Bstack Dstack LastS LastO Vdone}]);
        }
    }
    die "Iussum nefastum: '$Vstack[-1]{raw}'" . adversum($Vstack[-1])
      . ( $Vstack[-1]{lex} !~ /(ACCUSATIVE|DATIVE)$/
        ? "(Vellesne '$Vstack[-1]{raw}mentum' unumve ceteri)\n"
        : "" )
        if $Vdone && @Vstack;
    die "Accusativum non junctum: '"
      . join(" tum ", map {$_->{raw}} @{$Astack[-1]{data}})
      . "'"
      . adversum($Astack[-1]{data}[0])
        if @Astack > 1 && !@Vstack;
    die "Dativum non junctum: '$Dstack[-1]{raw}'" . adversum($Dstack[-1])
        if @Dstack && !@Vstack;
    die "Sententia imperfecta prope '$tok->{raw}'" . adversum($tok)
        unless $Vdone || $empty;
    return $empty           ? $tok
           : ref $Vdone eq 'ARRAY'  ? $Vdone->[0]
           :              $Vdone;
}

sub block
{
    my ($toks) = @_;
    my @self;
    my $next = shift @$toks;
    die "Exspectavi 'sic' sed inveni '$next->{raw}'" . adversum($next)
        unless $next->{lex} eq 'BEGIN';
    while ($toks->[0]{lex} ne 'END') {
        my $command = conn_command($_[0],'PERIOD','END');
        push @self, $command if $command;
    }
    $next = shift @$toks;
    die "Exspectavi 'cis' sed inveni '$next->{raw}'" . adversum($next)
        unless $next->{lex} eq 'END';
    return bless \@self, 'BLOCK';
}

sub subdefn
{
    my ($toks) = @_;
    my $self = shift @$toks;
    $self->{B} = block($toks);
    return $self;
}

sub for_control
{
    my ($toks, $Bstack) = @_;
    my $self = shift @$toks;
    my $var;
    $var = $toks->[0]{lex} eq 'ACCUSATIVE'
            ? shift @$toks
         : $toks->[0]{lex} ne 'IN'
            ? die "Exspectavi accusativum post 'per' sed inveni '$toks->[0]{raw}'" . adversum($toks->[0])
         : tokdup $tokens{'huic'};
    my $in = shift @$toks;
    die "'in' pro 'per' afuit" . adversum($in)
        unless $in->{lex} eq 'IN';
    $self->{D} = $var;
    $self->{C} = conn_command($toks,'DO', 'PERIOD');
    unless (($self->{C}{lex}||$self->{C}{V}{lex}) =~ /DATIVE|OWNER_D/) {
        my ($badraw, $bad) = $self->{C}{lex}
            ? ($self->{C}{raw}, $self->{C})
            : ($self->{C}{V}{raw}, $self->{C}{V});
        die "'$badraw' dativus non est in 'per'" . adversum($bad);
    }
    if ($toks->[0]{lex} =~ /PERIOD|CONNECTIVE/) {
        die "Iussa absentia per '$self->{raw}'" . adversum($self)
            unless @$Bstack;
        $self->{B} = pop @$Bstack;
        shift @$toks unless $toks->[0]{lex} eq 'CONNECTIVE';
    }
    else {
        $self->{B} = block($toks);
    }
    return $self;
}

sub control
{
    my ($toks, $Bstack) = @_;
    my $self = shift @$toks;
    $self->{C} = conn_command($toks,'DO');
    if (($self->{perl}||"") eq 'while' &&
        ($self->{C}{V}{perl}||"") eq 'Lingua::Romana::Perligata::getline') {
        $self->{C}{V}{diamond} = 1;
    }
    if (!@$toks || $toks->[0]{lex} =~ /PERIOD|CONNECTIVE/) {
        die "Iussa absentia per '$self->{raw}'" . adversum($self)
            unless @$Bstack;
        $self->{B} = pop @$Bstack;
        shift @$toks unless $toks->[0]{lex} eq 'CONNECTIVE';
    }
    else {
        $self->{B} = block($toks);
    }
    return $self;
}


sub __enlist__ {
    return ($_[0]..$_[1]);
}

sub __enquote__ {
    return join " ", @_;
}

sub __encatenate__ {
    return join "", @_;
}

sub __lastelem__(\@) {
    return $#{$_[0]};
}

my %lb = ( '@'=>'[', '%'=>'{' );
my %rb = ( '@'=>']', '%'=>'}' );

sub STATEMENT::translate {
    my $verb = $_[0]{V}->translate;
    my $prefix = $_[0]{V}{prefix};
    my $hasblock = $verb =~ m{^(grep|map)$};
    my $noparen = $_[0]{V}{lex} eq 'OWNER_D' && $_[0]{V}{raw} =~ /o$/
           || $_[0]{V}{raw} =~ /^(finis|nuntius|factor(em|i))$/
           || $hasblock;
        my $dative = defined $_[0]{D}
            ? $_[0]{D}->translate
            : "";
    my $Dref = $verb =~ /^(bless)$/ && $dative =~ /^[%@]/ ? "\\" : "";
    $dative = $Dref . $dative if $dative;
    my $Dcomma = $dative && defined $_[0]{A} && !$hasblock && $verb !~ /^(print|printf)$/ ? "," : "";
    if ($verb =~ /^(package|use)$/) {
        return "$verb $_[0]{A}[0]{raw} ";
    }
    elsif ($verb eq ':') {  # LABEL
        return " $_[0]{A}[0]{raw}: ";
    }
    elsif ($_[0]{V}{diamond}) {
        $result = "<" . substr($dative,1) . ">";
    }
    elsif ($verb =~ /^[\$%@]\{$/) {
        $result = $verb . $_[0]{A}[0]->translate . '}';
    }
    elsif (! $_[0]{V}{operator}) {
        $result = "$verb "
             . ($noparen ? "" : "(")
             . $dative . $Dcomma
             . " "
             . (defined $_[0]{A} ? join ", ", map({ $_->translate($_[0]{V}) } @{$_[0]{A}}) : "")
             . ($noparen ? "" : ")") ;
    }
    elsif ($prefix && $dative) {
        $result = " $verb $dative ";
    }
    elsif ($prefix) {
        $result = " $verb (" . $_[0]{A}[0]->translate . ")";
    }
    elsif ( $verb eq '=' ) {
        $result = " "
             . $dative
             . " $verb "
             . ( @{$_[0]{A}} > 1
            ? "(" . join(",", map($_->translate, @{$_[0]{A}})) .  ")"
            : $_[0]{A}[0]->translate
               );
    }
    else
    {
        my $Acount = @{$_[0]{A}||[]};
        my $neg = $verb =~ s/^!(<=>|cmp)/$1/ ? "!" : "";
        $result = " $neg("
             . ( $dative          ? $dative
               : $Acount-- ? shift(@{$_[0]{A}})->translate
               :                    "")
             . " $verb "
             . ( $Acount ? $_[0]{A}[0]->translate : "")
             . ")";
    }
    if ($_[0]->{G}) {
        my $perl = pop(@{$_[0]->{G}})->{perl};  # LAST GENITIVE IS THE VARIABLE
        $perl =~ s/^([\%\@])/\$/;
        my $type = $1;
        while (my $next = pop @{$_[0]->{G}}) {
            $perl .= $lb{$type} . $next->translate . $rb{$type};
        }
        $result = $perl . $lb{$type} . $result . $rb{$type};
    }
    return '\\'x($_[0]{R}||0) . $result;
}

sub BLOCK::translate {
    return "{"
         . join(";\n", map {$_->translate} @{$_[0]})
         . "}" ;
}

sub CONNECTIVE::translate {
    return $_[0]{L}->translate . " $_[0]{perl} " . $_[0]{R}->translate;
}

sub Separator::translate {
    return $_[0]{perl};
}

sub SUBNAME::translate {
    return $_[0]{perl};
}

sub SUBNAME_OA::translate {
    return $_[0]{perl};
}

sub SUBNAME_A::translate {
    return $_[0]{perl};
}

sub SUBNAME_D::translate {
    return $_[0]{perl};
}

sub SUBNAME_AD::translate {
    return $_[0]{perl};
}

sub SUBNAME_AB::translate {
    return $_[0]{perl};
}

sub SUBNAME_ACCUSATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_A_ACCUSATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_D_ACCUSATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_AD_ACCUSATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_AB_ACCUSATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_B_ACCUSATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_DATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_A_DATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_D_DATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_AD_DATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_AB_DATIVE::translate {
    return $_[0]{perl};
}

sub SUBNAME_B_DATIVE::translate {
    return $_[0]{perl};
}

sub DATIVE::translate {
    my ($self) = @_;
    my $perl = $self->{perl};
    if ($self->{G}) {
        my $gen = pop(@{$self->{G}})->{perl};   # LAST GENITIVE IS THE VARIABLE
        $gen =~ s/^([\%\@])/\$/;
        my $type = $1;
        while (my $next = pop @{$self->{G}}) {
            $gen .= $lb{$type} . $next->translate . $rb{$type};
        }
        $perl = $gen . $lb{$type} . $perl . $rb{$type};
    }
    return $perl;
}

sub OWNER_D::translate {
    return $_[0]{perl};
}

sub ACCUSATIVE::translate {
    my ($self) = @_;
    my $perl = $self->{perl};
    if ($self->{G}) {
        my $gen = pop(@{$self->{G}})->{perl};   # LAST GENITIVE IS THE VARIABLE
        $gen =~ s/^([\%\@])/\$/;
        my $type = $1;
        while (my $next = pop @{$self->{G}}) {
            $gen .= $lb{$type} . $next->translate . $rb{$type};
        }
        $perl = $gen . $lb{$type} . $perl . $rb{$type};
    }
    return '\\'x($_[0]{R}||0) . $perl;
}

sub CONTROL::translate {
    return $_[0]{perl}
         . " (" . $_[0]{C}->translate . ") "
         . $_[0]{B}->translate
         . "\n";
}

sub FOR::translate {
    return $_[0]{perl}
         . " " . $_[0]{D}->translate
         . " (" . $_[0]{C}->translate . ") "
         . $_[0]{B}->translate
         . "\n";
}

sub NUMERAL::translate {
    my ($self) = @_;
    # if ($self->{G}) {
        # return $self->{G}->index($self->{perl});
    # }
    return $self->{perl};
}

sub ORDINAL::translate {
    my ($self) = @_;
    return $self->{perl} unless $self->{G};
    my $perl = pop(@{$self->{G}})->translate;   # LAST GENITIVE IS THE VARIABLE
    $perl =~ s/^([\%\@])/\$/;
    my $type = $1;
    while (my $next = pop @{$self->{G}}) {
        $perl .= $lb{$type} . $next->translate . $rb{$type};
    }
    return $perl . $lb{$type} . $self->{perl} . $rb{$type};
}

*ORDINAL_DATIVE::translate = *ORDINAL::translate;

sub DISJUNCTION::translate {
    return $_[0]{perl};
}

sub CONJUNCTION::translate {
    return $_[0]{perl};
}

sub Literal::translate {
    my ($self, $context) = @_;
    my $perl;
    if ($context && $context->{raw} =~ /^inque/) {
        $perl = qq{'$_[0]{raw}'}
    }
    elsif ( $self->{lex} eq 'GENITIVE' ) {
        $perl = $self->GENITIVE::translate;
    }
    elsif ( $self->{lex} eq 'SUBNAME_A_GENITIVE' ) {
        $perl = $self->SUBNAME_A_GENITIVE::translate;
    }
    elsif ( $self->{lex} eq 'INFINITIVE' ) {
        $perl = "sub $_[0]{perl}\n" .  $_[0]{B}->translate;
    }
    else {
        $perl = '\\'x($_[0]{R}||0) . $_[0]{perl}
    }
    if ($self->{G}) {
        my $gen = pop(@{$self->{G}})->{perl};   # LAST GENITIVE IS THE VARIABLE
        $gen =~ s/^([\%\@])/\$/;
        my $type = $1;
        while (my $next = pop @{$self->{G}}) {
            $gen .= $lb{$type} . $next->translate . $rb{$type};
        }
        $perl = $gen . $lb{$type} . $perl . $rb{$type};
    }
    return $perl;
}

sub GENITIVE::translate {
    return $_[0]{perl};
};

sub SUBNAME_A_GENITIVE::translate {
    return $_[0]{perl};
};

sub Name::translate {
    return qq{'$_[0]{raw}'}
}

1;

__END__

=head1 NOMEN

Lingua::Romana::Perligata -- Perl in Latin


=head1 EDITIO

This document describes version 0.601 of Lingua::Romana::Perligata
released May  3, 2001.

=head1 SUMMARIUM

    use Lingua::Romana::Perligata;

    adnota Illud Cribrum Eratothenis

    maximum tum val inquementum tum biguttam tum stadium egresso scribe.
    da meo maximo vestibulo perlegementum.

    maximum comementum tum novumversum egresso scribe.
    meis listis conscribementa II tum maximum da.
    dum damentum nexto listis decapitamentum fac
        sic
            lista sic hoc tum nextum recidementum cis vannementa listis da.
            dictum sic deinde cis tum biguttam tum stadium tum cum nextum
            comementum tum novumversum scribe egresso.
        cis


=head1 DESCRIPTIO

The Lingua::Romana::Perligata makes it makes it possible to write Perl
programs in Latin. (If you have to ask "Why?", then the answer probably
won't make any sense to you either.)

The linguistic principles behind Perligata are described in:

    http://www.csse.monash.edu.au/~damian/papers/HTML/Perligata.html

The module is C<use>d at the start of the program, and installs a filter
which allows the rest of the program to be written in (modified) Latin,
as described in the following sections.


=head1 GRAMMATICA PERLIGATA

=head2 Variables

To simplify the mind-numbingly complex rules of declension and
conjugation that govern inflexions in Latin, Perligata treats all
user-defined scalar and array variables as neuter nouns of the second
declension -- singular for scalars, plural for arrays.

Hashes represent something of a difficulty in Perligata, as Latin lacks an
obvious way of distinguishing these "plural" variables from arrays. The
solution that has been adopted is to depart from the second declension
and represent hashes as masculine plural nouns of the fourth declension.

Hence, the type and role of all types variables are specified by their
number and case.

When elements of arrays and hashes are referred to directly in Perl, the
prefix of the container changes from C<@> or C<%> to C<$>. So it should
not be surprising that Perligata also makes use of a different inflexion
to distinguish these cases.

Indexing operations such as C<$array[$elem]> or C<$hash{$key}> might be
translated as "elem of array" or "key of hash". This suggests that when
arrays or hashes are indexed, their names should be rendered in the
genitive (or possessive) case. Multi-level indexing operations
(C<$array[$row][$column]>) mean "column of row of array", and hence the
first indexing variable must also be rendered in the genitive.

Note that the current release of Perligata only supports homogeneous
multi-level indexing. That is: C<$lol[$row][$column]> or
C<$hoh{key}{subkey}{subsubkey}>, but not C<$lohol[$index1]{key}[$index2]>.

The rules for specifying variables may be summarized as follows:

    Perligata    Number, Case, and Declension    Perl         Role
    =========    ============================    ====         ====
    nextum       accusative singular 2nd         $next        scalar rvalue
    nexta        accusative plural 2nd           @next        array rvalue
    nextus       accusative plural 4th           %next        hash rvalue
    nexto        dative singular 2nd             $next        scalar lvalue
    nextis       dative plural 2nd               @next        array lvalue
    nextibus     dative plural 4th               %next        hash lvalue
    nexti        genitive singular 2nd           [$next]...   scalar index
    nextorum     genitive plural 2nd             $next[...]   array element
    nextuum      genitive plural 4th             $next{...}   hash entry


In other words, scalars are always singular nouns, arrays and hashes are
always plural (but of different declensions), and the case of the noun
specifies its syntactic role in a statement : accusative for an rvalue,
dative for an lvalue, genitive when being index. Of course, because the
inflection determines the syntactic role, the various components of a
statement can be given in any order. For example, the Perl statement:

    $last = $next;

could be expressed in Perligata as any of the following (C<da> is the
Perligata assignment operator -- see L<"Built-in functions and operators">):

    lasto da nextum.
    lasto nextum da.
    nextum da lasto.
    nextum lasto da.
    da lasto nextum.
    da nextum lasto.

The special form C<$#array> is rendered via the Perligata verb I<admeta>
("measure out"). See L<"Subroutines, operators, and functions">.

The common punctuation variables C<$_> and C<@_> are special cases.
C<$_> is often the value under implicit consideration (e.g. in pattern
matches, or C<for> loops) and so it is rendered as "this thing": I<hoc>
as an rvalue, I<huic> as an lvalue, I<huius> used as an intermediate index.

Similarly, C<@_> is implicitly the list of things passed into a
subroutine, and so is rendered as "these things": I<haec> as an rvalue,
I<his> as an lvalue, I<horum> when indexed.

Other punctuation variables take the Latin forms of their English.pm
equivalents (see L<"THESAURUS PERLIGATUS">), often with a large measure
of poetic licence. For example, in Perligata, C<$/> is rendered as
I<ianitorem> or "gatekeeper".

The "numeral" variables -- C<$1>, C<$2>, etc. -- are rendered as synthetic
compounds: I<parprimum> ("the equal of the first"),
I<parsecundum> ("the equal of the
second"), etc. When used as interim indices, they take their genitive forms:
I<parprimi>, I<parsecundi>, etc.
Since they cannot be used as an lvalue, they have no dative forms.

=head2 C<my>, C<our>, and C<local>

In Perligata, the C<my> modifier is rendered -- not surprisingly -- by
the first person possessive pronouns: I<meo> (conferring a scalar context)
and I<meis> (for a list context). Note that the modifier is always applied to a
dative (lvalue), and hence is itself declined in that case. Thus:

        meo varo haec da.                # my $var = @_;
        meis varo haec da.               # my ($var) = @_;
        meis varis haec da.              # my @var = @_;

Similarly the C<our> modifier is rendered as I<nostro> or I<nostris>,
depending on the desired context.

The Perl C<local> modifier is I<loco> or I<locis> in Perligata:

        loco varo haec da.               # local $var = @_;
        locis varo haec da.              # local ($var) = @_;
        locis varis haec da.             # local @var = @_;

This is particularly felicitous: not only is I<loco> the Latin term from
which the word "local" derives, it also means "in place of" (as in:
I<in loco parentis>). This meaning is much closer to the
actual behaviour of the C<local> modifier, namely to temporarily install a
new symbol table entry in place of the current one.


=head2 Subroutines, operators, and functions

Functions, operators, and user-defined subroutines are represented as
verbs or, in some situations, verbal nouns. The inflexion of the verb
determines not only its syntactic role, but also its call context.

User-defined subroutines are the simplest group. To avoid ambiguities, they
are all treated as verbs of the third conjugation. For example, here
are the various conjugations for different
usages for a user-defined subroutine C<count()>:

    Perligata       Number, Mood, etc       Perl        Role    Context
    =========       =================       ====        ====    =======
    countere        infinitive              sub count   defn    -
    counte          imperative sing.        count()     call    void
    countementum    acc. sing. resultant    count()     call    scalar
    countementa     acc. plur. resultant    count()     call    list
    countemento     dat. sing. resultant    count()     call    scalar lvalue
    countementis    dat. plur. resultant    count()     call    list lvalue

The use of the infinitive as a subroutine definition is obvious:
I<accipere> would tell Perligata how "to accept"; I<spernere>, how "to
reject". So I<countere> specifies how "to count".

The use of the imperative for void context is also straightforward:
I<accipe> commands Perligata to "accept!", I<sperne> tells it to
"reject!", and I<counte> bids it "count!". In each case, an instruction
is being given (and in a void context too, so no backchat is expected).

Handling scalar and list contexts is a little more challenging. The
corresponding Latin must still have verbal properties, since an action
is being performed upon objects. But it must also have the
characteristics of a noun, since the result of the call will itself be
used as the object (i.e. target or data) of some other verb. Fortunately,
Latin has a rich assortment of verbal nouns -- far more than English --
that could fill this role.

Since it is the result of the subroutine call that is of interest here,
the chosen solution was to use the I<-ementum> suffix, which specifies the
(singular, accusative) outcome of an action. This corresponds to the
result of a subroutine called in a scalar context and used as data. For
a list data context, the plural suffix I<-ementa> is used, and for
targets, the dative forms are used: I<-emento> and I<-ementis>.
Of course, Perl does not (yet) support lvalue subroutines that return a
list/array, so the I<-mentis> suffix currently triggers an error.

Note that these resultative endings are completely consistent with those
for variables.


=head2 Built-in functions and operators

Built-in operators and functions could have followed the same
"dog-latin" pattern as subroutines. For example C<shift> might have
been I<shifte> in a void context, I<shiftementa> when used as data in
an array context, I<shiftemento> when used as a target in a scalar
context, etc.

However, Latin already has a perfectly good verb with the same meaning as
C<shift>: I<decapitare> ("to behead"). Unfortunately, this verb is of the first
conjugation, not the second, and hence has the imperative form I<decapita>,
which makes it look like a Perligata array in a data role.

Orthogonality has never been Perl's highest design criterion, so Perligata
follows suit by eschewing bland consistency in favour of aesthetics. All
Perligata keywords -- including function and operator names -- are therefore
specified as correct Latin verbs, of whatever conjugation is required.
For example:

    Operator/  Literal        In void     When used as      When used as
    function   meaning        context     scalar rvalue     list rvalue
    ========   =======        =======     =============     ============
    +          "add"          adde        addementum        addementa
    =          "give"         da          damentum          damenta
    .          "conjoin"      sere        serementum        serementa
    ..         "enlist"       conscribe   conscribementum   conscribementa

    shift      "behead"       decapita    decapitamentum    decapitamenta

    push       "stack"        cumula      cumulamentum      cumulamenta
    pop        "unstack"      decumula    decumulamentum    decumulamenta

    grep       "winnow"       vanne       vannementum       vannementa
    print      "write"        scribe      scribementum      scribementa
    write      "write below"  subscribe   subscribementum   subscribementa

    die        "die"          mori        morimentum        morimenta


The full list of Perligata keywords is provided in L<THESAURUS PERLIGATUS>.

Note, however, that consistency has not been entirely forsaken. The
back-formations of inflexions for scalar and list context are entirely
regular, and consistent with those for user-defined subroutines (described
above).

A few Perl built-in functions -- C<pos>, C<substr>, C<keys> -- can be
used as lvalues. That is, they can be the target of some other action
(typically of an assignment). In Perligata such cases are written in the
dative singular (since the lvalues are always scalar). Note too that,
because an assignment to an lvalue function modifies its first
argument, that argument must be a target too, and hence must be written
in the dative as well.

Thus:

        nexto stringum reperimentum da.     # $next = pos $string;
        nextum stringo reperimento da.      # pos $string = $next;

        inserto stringum tum unum tum duo excerpementum da.
                                            # $insert = substr($string,1,2);
        insertum stringo unum tum duo excerpemento da.
                                            # substr($string,1,2) = $insert;

        clavis hashus nominamentum da.      # @keys = keys %hash;
        clava hashibus nominamento da.      # keys %hash = @keys;


An interesting special case is the C<$#array> construction, which in
Perligata is rendered via the verb I<admeta>:

    counto da arraya admetamentum.      # $count = $#array;


=head2 Comments

In Perligata, comments are rendered by the verb I<adnota>
("annotate") and extend until the end of the line. For example:

    nexto da prevum.    adnota mensuram antiquam reserva

means:

    $next = $prev;      # remember old amount


=head2 Imposing precedence on argument lists

The order-independence of argument lists and subroutine calls largely
makes up for the lack of bracketing in Perligata. For example, the
Perl statement:

    $res = foo(bar($xray,$yell),$zip);

can be written:

     reso da xrayum tum yellum barmentum tum zipum foomentum.

Note that the lack of argument list brackets in Perligata
means that if it were written:

    reso da foomentum barmentum xrayum tum yellum tum zipum.

it would be equivalent to:

    $res = foo(bar($xray,$yell,$zip));

instead.

Likewise, it is possible to translate:

    $res = foo($xray,bar($yell,$zip));

like so:

    reso da xrayum tum barmentum yellum tum zipum foomentum.

But translating:

    $res = foo($weld,bar($xray,$yell),$zip);

presents a difficulty.

In the first example above
(I<xrayum tum yellum barmentum tum zipum foomentum>), the verb I<barmentum> was
used as a suffix on I<xrayum tum yellum> -- to keep the variable I<zipum> out of
the argument list of the call to C<bar>. In the second example
(I<xrayum tum barmentum yellum tum zipum foomentum>), the verb
I<barmentum> was used as a prefix on I<yellum tum zipum> -- to keep the
variable I<xrayum> out of the argument list.

But in this third example, it's necessary to keep both I<weldum> and I<zipum>
out of C<bar>'s argument list. Unfortunately, I<barmentum> can't be both
a prefix (to isolate I<weldum>) and a suffix (to isolate I<zipum>)
simultaneously.

The solution is to use the preposition I<cum> (meaning "with...") at the start
of C<bar>'s argument list, with I<barmentum> as a suffix at the end of the
list:

        reso da foomentum weldum tum cum xrayum tum yellum barmentum tum zipum.

It is always permissible to specify the start of a nested argument list with
a I<cum>, so long as the governing verb is used as a suffix.


=head2 Blocks and control structures

Natural languages generally use some parenthetical device -- such as
parentheses, commas, or (as here) dashes -- to group and separate
collections of phrases or statements.

Some such mechanism would be an obvious choice for denoting Perligata
code blocks, but there is a more aesthetically pleasing solution.
Perl's block delimiters (C<{>..C<}>) have two particularly desirable
properties: they are individually short, and collectively symmetrical.
It was considered important to retain those characteristics in Perligata.

In Latin, the word I<sic> has a sense that means "as follows".
Happily, its contranym, I<cis>, has the meaning (among others)
"to here". The allure of this kind of wordplay being impossible to
resist, Perligata delimits blocks of statements with these two words. For
example:

        sic                                     # {
            loco ianitori.                      #   local $/;
            dato nuntio perlegementum da.       #   $data = <DATA>;
        cis                                     # }


Control structures in Perligata are rendered as conditional clauses, as they
are in Latin, English, and Perl. And as in those other languages, they
may precede or follow the code blocks they control.

Perligata provides the following control structures:

    Perligata                        Perl
    =========                        ====
    si ... fac                       if ...
    nisi ... fac                     unless ...
    dum ... fac                      while ...
    donec ... fac                    until ...
    per (quisque) ... in ... fac     for(each) ...
    posterus                         next
    ultimus                          last
    reconatus                        redo
    confectus                        continue


The trailing I<fac> is the imperative form of I<facere> ("to do")
and is used as a delimiter on the control statement's condition.
It is required, regardless of whether the control statement precedes or
follows its block.

The choice of I<dum> and I<donec> is completely arbitrary, since Latin
does not distinguish "while" and "until" as abstractions in the way
English does. I<Dum> and I<donec> each mean both "while" and "until",
and Latin relies on context (i.e. semantics) to distinguish them. This
is impractical for Perligata, so it always treats I<dum> as C<while> and
I<donec> as C<until>. This choice was made in order to favour the
shorter term for the more common type of loop.

The choice of I<confectus> for C<continue> seeks to convey the function
of the control structure, not the literal meaning of the English word.
That is, a C<continue> block specifies how to complete (I<conficere>)
an iteration.

Perligata only supports the pure iterative form of C<for(each)>, not the C-like
three-part syntax.

Because:

        foreach $var (@list) {...}

means "for each variable in the list...", the scalar variable must be in
the accusative (as it is governed by the preposition "for"), and the
list must be in the ablative (denoting inclusion). Fortunately, in the
second declension, the inflexion for ablatives is exactly the same as
for datives, giving:

        per quisque varum in listis sic ... cis

This means that no extra inflexions have to be learned just to use the
I<per> loop. Better still, the list (I<listis>) looks like a Perligata
array variable in a target role, which it clearly is, since its contents may
be modified within the loop.

Note that you can also omit the accusative variable completely:

        per quisque in listis sic ... cis

and leave I<hoc> (C<$_>) implied, as in regular Perl.


=head2 Data

The C<__END__> and C<__DATA__> markers in Perligata are I<finis>
("boundary") and I<nuntius> ("information") respectively. Data specified
after either of these markers is available via the input stream
I<nuntio>. For example:

        dum perlege nuntio fac sic              # while (<DATA>) {
                scribe egresso hoc.             #       print $_;
        cis                                     # }
                                                #
        finis                                   # __END__
        post                                    # post
        hoc                                     # hoc
        ergo                                    # ergo
        propter                                 # propter
        hoc                                     # hoc


=head2 Numbers

Numeric literals in Perligata are rendered by Roman numerals -- I<I>,
I<II>, I<III>, I<IV>...I<XV>...I<XLII>, etc, up to
I<(((((((I)))))))((((((((I))))))))((((((I))))))(((((((I)))))))(((((I)))))((((((I))))))((((I))))(((((I)))))(((I)))((((I))))((I))(((I)))M((I))CMXCIX>
(that is: 9,999,999,999)

The digits are:

           Roman            Arabic
           =====            ======
         I                   1
         V                   5
         X                  10
         L                      50
         C                 100
         D                 500
             M                   1,000
             I))                     5,000
           ((I))                    10,000
             I)))                   50,000
          (((I)))              100,000
             I))))             500,000
         ((((I))))           1,000,000
             I)))))          5,000,000
        (((((I)))))         10,000,000
             I))))))       500,000,000
       ((((((I))))))     1,000,000,000
             I)))))))    5,000,000,000
      (((((((I)))))))   10,000,000,000

The value I<((I))> is 10,000 and every additional pair of I<apostrophi>
(rendered as parentheses in ASCII) multiply that value by 10.

Notice that those wacky Romans literally used "half" of each big number
(e.g. I<I))>, I<I)))>, etc.) to represent half of each big numbers
(i.e. 5000, 50000, etc.)

The first 10 numbers may also be referred to by name:
I<unum>/I<unam>, I<duo>/I<duas>, I<tres>, I<quattuor>, I<quinque>,
I<sex>, I<septem>, I<octo>, I<novem>, I<decem>. Zero, for which there is
no Latin numeral, is rendered by I<nullum> ("no-one"). I<Nihil>
("nothing") might have been a closer rendering, but it is indeclinable
and hence indistinguishable in the accusative and genitive.

When a numeric literal is used in an indexing operation, it must be an
ordinal: "zeroth (element)", "first (element)", "second (element)", etc.

The first ten ordinals are named (in the accusative): I<primum>/I<primam>,
I<secundum>/I<secundam>, I<tertium>/I<tertiam>, I<quartum>/I<quartam>,
I<quintum>/I<quintam>, I<sextum>/I<sextam>, I<septimum>/I<septimam>,
I<octavum>/I<octavam>, I<nonum>/I<nonam>, I<decimum>/I<decimam>.
Ordinals greater than ten are represented by their corresponding numeral
with the suffix I<-imum>: I<XVimum> ("15th"), I<XLIIimum> ("42nd"), etc.
By analogy, ordinal zero is rendered by the invented form I<nullimum>.

If the element being indexed is used as an lvalue, then the ordinal must
of course be in the dative instead: I<nullimo>, I<primo>, I<secundo>,
I<tertio>, I<quarto>, I<quinto>, I<sexto>, I<septimo>, I<octavo>,
I<nono>, I<decimo>, I<XIimo>, etc. Note that the feminine dative forms
are I<not> available in Perligata, as they are ambiguous with the feminine
genitive singular forms.

In a multi-level indexing operation, ordinals may need to be specified
in the genitive: I<nulli>/I<nullae>, I<primi>/I<primae>,
I<secundi>/I<secundae>, I<tertii>/I<tertiae>...I<XVimi>/I<XVimae>, etc.

For example:

        $unimatrix[1][3][9][7];

would be:

        septimum noni tertii primi unimatrixorum

which is literally:

        seventh of ninth of third of first of unimatrix

Note that the order of the genitives is significant here, and is the
reverse of that required in Perl.

As mentioned in L<"Variables">, Perligata currently only supports homogeneous
multi-level indexing. If the final genitive indicates
an array (e.g. I<unimatrixorum> in the previous example), then preceding index
is assumed to be an array index. If the final genitive indicates a hash,
every preceding genitive, and the original ordinal are presumed to be
keys.  For example:

        septimum noni tertii primi unimatrixorum   # $unimatrix[1][3][9][7];
        septimum noni tertii primi unimatrixuum    # $unimatrix{1}{3}{9}{7};


Floating point numbers are expressed in Perligata as Latin fractions:

        unum quartum                  # 0.25
        MMMCXLI Mimos                 # 3.141

Note that the numerator is always a cardinal and the denominator a
(singular or plural) ordinal ("one fourth", "3141 1000ths"). The plural
of a Latin accusative ordinal is formed by replacing the I<-um> suffix by
I<-os>.  This nicety can be ignored, as Perligata will accept fractions
in the form I<MMMCXLI Mimum> ("3141 1000th")

Technically, both numerator and denominator should also be in the
feminine gender -- I<una quartam>, I<MMMCXLI Mimas>. This Latin rule is
not enforced in Perligata (to help minimize the number of suffixes that
must be remembered), but Perligata I<does> accept the feminine forms.


Perligata outputs numbers in Arabic, but the verb I<come> ("beautify")
may be used to convert numbers to proper Roman numerals:

        per quisque in I tum C conscribementum sic
                hoc tum duos multiplicamentum comementum egresso scribe.
        cis



=head2 Strings

Classical Latin does not use punctuation to denote direct quotation.
Instead the verb I<inquit> ("said") is used to report a direct
utterance. Hence in Perligata, a literal character string is
constructed, not with quotation marks, but by invoking the verbal noun
I<inquementum> ("the result of saying"), with a data list of literals to be
interpolated. For example:

        print STDOUT 'Enter next word:';

becomes:

        Enter tum next tum word inquementum tum biguttam egresso scribe.

Note that the arguments to I<inquementum> are special, in that they are
treated as literals. Punctuation strings have special names, such as
I<lacunam> ("a hole") for space, I<stadium> ("a stride") for tabspace,
I<novumversum> ("new verse") for newline, or I<biguttam> ("two spots")
for colon.

It is also possible to directly quote a series of characters (as if they
were inside a C<q{...}>. The Perligata equivalent is a I<dictum sic...cis>:

        sic Enter next word : cis dictum egresso scribe.

or:

        dictum sic Enter next word : cis egresso scribe.

C<dictum> is, of course, a contraction of C<dicementum> ("the result of
saying"), and Perligata allows this older form as well.

Perligata does not provide an interpolated quotation mechanism. Instead,
variables must be concatenated into a string. So:

        print STDERR "You entered $word\n";
        $mesg = "You entered $word";

becomes:

        You tum entered inquementum tum wordum tum novumversum oraculo scribe.
        mesgo da You tum entered inquementum tum wordum serementum.


=head2 Regular expressions

B<I<[Perligata's regular expression mechanism is not yet implemented. This section
outlines how it will work in a future release.]>>

In Perligata, patterns will be specified in a constructive syntax (as
opposed to Perl's declarative approach). Literals will regular
strings and other components of a pattern will be adjectives, verbs,
nouns, or a connective:

    Perl        Perligata       Meaning
    ====        =========       =======
    ...+?       multum          "many"
    ...+        plurissimum     "most"
    ...??       potis           "possible"
    ...?        potissimum      "most possible"
    (...)       captivum        "captured"
    (?=...)     excuba          "keep watch"
    [...]       opta            "choose between"
    .           quidlibet       "anything"
    \d          digitum         "a finger"
    \s          lacunam albam   "a white space"
    \w          litteram        "a character"
    |           an              interrogative "or"


The final pattern will be produced using the supine I<desideratum>.
For example:

        pato da desideratum                         # $pat = qr/(?x)
            C tum plurissimum A tum O opta tum T    #          C[AO]+T
            an DOG tum potissimum GY.               #          |DOG(?:GY)?/;

Actual matching against a pattern will be done via the I<compara> ("match")
and I<substitue> ("substitute") verbs:

        si stringum patum comparamentum fac sic   # if ($string =~ /$pat/) {
                scribe egresso par inquementum    #    print "match"
        cis                                       #


        huic substitue patum tum valum            # s/$pat/$val/
                per quisque in listis.            #    foreach @list;


Note that the string being modified by I<substitue> will have to be dative.


=head2 References

To create a reference to a variable, the variable is written in the
ablative (which looks exactly like the dative in Perligata's restricted
Latin syntax) and prefaced with the preposition I<ad> ("to"). To create
a reference to a subroutine, the associated verb is inflected with the
accusative suffix I<-torem> ("one who...") to produce the corresponding
noun-of-agency.

For example:

        val inquemento hashuum ad dato da.       # $hash{'val'} = \$dat;
        arg inquemento hashuum ad argis da.      # $hash{'arg'} = \@arg;
        act inquemento hashuum functorem da.     # $hash{'act'} = \&func;

        ad val inquemento hashuum dato da.       # $dat   = \$hash{'val'};
        ad inquemento arg hashuum argis da.      # @arg   = \$hash{'arg'};
        funcemento da ad inquemento act hashuum. # func() = \$hash{'act'};

A special case of this construction is the anonymous subroutine
constructor I<factorem> ("one who does..."), which is the equivalent of
C<sub {...}> in Perl:

        anonymo da factorem sic haec mori cis.    # $anon = sub { die @_ };

As in Perl, such subroutines may be invoked by concatenating a call
specifier to the name of the variable holding the reference:

        anonymume nos tum morituri inquementum.   # &$anon('Nos morituri');

Note that the variable holding the reference (I<anonymum>) is being used
as data, so it is named in the accusative.

In the few cases where a subroutine reference can be the
target of an action, the dative suffix (I<-tori>) is used instead:

        benedictum functori classum.              # bless \&func, $class;
        benedictum factori sic mori cis classum.  # bless sub{die}, $class;

To dereference other types of references, a resultative of the verb I<arcesse>
("fetch") is used:

        Ref type        Perligata               Perl            Context
        ========        =========               ====            =======
        scalar          arcessementum varum     $$var           rvalue
        scalar          arcessemento varum      $$var           lvalue
        array           arcessementi varum      ...[$$var]      rvalue

        array           arcessementa varum      @$var           rvalue
        array           arcessementis varum     @$var           lvalue
        array           arcessementorum varum   $var->[...]     either

        hash            arcessementus varum     %$var           rvalue
        hash            arcessementibus varum   %$var           lvalue
        array           arcessementuum varum    $var->{...}     either

Note that the first six forms are just the standard resultatives (in
accusative, dative, and genitive) for the regular Perligata verb
I<arcesse>. The last three forms are ungrammatical inflections
(I<-mentum> is 2nd declension, not 4th), but are plausible extensions of the
resultative to denote a hash return value.

Multiple levels of dereferencing are also possible:

        valo da arcessementa arcessementum varum    # $val = @$$var;

as is appropriate indexing (using the genitive forms):

        valo da primum varum arcessementorum        # $val = $var->[1];
        valo da primum varum arcessementuum         # $val = $var->{1};
        valo da primum varum arcessementi arrorum   # $val = $arr[$$var][1];


=head2 Boolean logic

Perl's logical conjunctive and disjunctive operators come in two precedences,
and curiously, so do those of Latin. The higher precedence Perl operators --
C<&&> and C<||> -- are represented in Perligata by the emphatic Latin
conjunctions I<atque> and I<vel> respectively. The lower precedence
operators -- C<and> and C<or> -- are represented by the unemphatic
conjunctive suffixes I<-que> and I<-ve>. Hence:

        reso damentum foundum atque runementum.   # $res = $found && run();
        reso damentum foundum runementumque.      # $res = $found and run();
        reso damentum foundum vel runementum.     # $res = $found || run();
        reso damentum foundum runementumve.       # $res = $found or run();

Note that, as in Latin, the suffix of the unemphatic conjunction is
always appended to the first word after the point at which
the conjunction would appear in English. Thus:

        $result = $val or max($1,$2);

is rendered as:

        resulto damentum valum parprimumve tum parsecundum maxementum.

or:

        resulto damentum valum maxementumve parprimum tum parsecundum.

Proper Latinate comparisons would be odious in Perligata, because they
require their first argument to be expressed in the nominative and would
themselves have to be indicative. This would, of course, improve the
positional independence of the language even further, allowing:

        si valus praecedit datum...              # if $val < $dat...
        si praecedit datum valus...              # if $val < $dat...
        si datum valus praecedit...              # if $val < $dat...

Unfortunately, it also introduces another set of case inflexions and
another verbal suffix. Worse, it would mean that noun suffixes are no
longer unambiguous. In the 2nd declension, the nominative plural ends in
the same I<-i> as the genitive singular, and the nominative singular
ending (I<-us>) is the same as the accusative plural suffix for the
fourth declension. So if nominatives were used, scalars could no longer
always be distinguished from arrays or from hashes, except by context.

To avoid these problems, Perligata represents the equality and simple
inequality operators by three pairs of verbal nouns:

    Perligata       Meaning                     Perl
    =========       =======                     ====
    aequalitam      "equality (of...)"          ==
    aequalitas      "equalities (of...)"        eq
    praestantiam    "precedence (of...)"        <
    praestantias    "precedences (of...)"       lt
    comparitiam     "comparison (of...)"        <=>
    comparitias     "comparisons (of...)"       cmp


Each operator takes two data arguments, which it compares:

        si valum tum datum aequalitam           # si $val == $dat
        si valum tum datum praestantias         # si $val lt $dat
        si aum tum bum comparitiam              # si $a <=> $b

The effects of the other comparison operators -- C<E<gt>>, C<E<lt>=>,
C<!=>, C<ne>, C<ge>, etc. -- are all achieved by appropriate ordering of
the two arguments and combination with the the logical negation operator
I<non>:

        si valum tum datum non aequalitam     # if $val != $dat
        si datum tum valum praestantiam       # if $val > $dat
        si valum non praestantias datum       # if $val ge $dat


=head2 Packages and classes

The Perligata keyword to declare a package is I<domus>, literally
"the house of". In this context, the name of the class follows the keyword
and is treated as a literal; as if it were the data argument of an
I<inquementum>.

To explicitly specify a variable or subroutine as belonging to a
package, the preposition I<intra> ("within") is used. To call a
subroutine as a method of a particular package (or of an object), the
preposition I<apud> ("of the house of") is used. Thus I<intra> is
Perligata's C<::> and I<apud> is it's C<-E<gt>>.

The Perl C<bless> function is I<benedice> in Perligata, but almost invariably
used in the scalar accusative form I<benedicementum>. Perligata also
understands the correct (contracted) Latin form of this verb: I<benedictum>.

Thus:

        domus Specimen.                             # package Specimen;

        newere                                      # sub new
        sic                                         # {
            meis datibus.                           #   my %data;
            counto intra Specimen
                postincresce.                       #   $Specimen::count++;
            datibus primum horum benedictum.        #   bless \%data, $_[0];
        cis                                         # }

        printere                                    # sub print
        sic                                         # {
            modus tum indefinitus inquementum mori. #   die 'method undefined';
        cis                                         # }

        domus princeps.                             # package main;

        meo objecto da                              # my $object =
                newementum apud Specimen.           #       Specimen->new;

        printe apud objectum;                       # $object->print;


=head1 THESAURUS PERLIGATUS

This section lists the complete Perligata vocabulary, except for
Roman numerals (I<I>, I<II>, I<III>, etc.)

In each of the following tables, the three columns are always the same:
"Perl construct", "Perligata equivalent", "Literal meaning of Perligata
equivalent".

Generally, only the accusative form is shown for nouns and adjectives,
and only the imperative for verbs.

=head2 Values and variables

        0            nullum           "no-one"
        1            unum             "one"
        2            duo              "two"
        3            tres             "three"
        4            quattuor         "four"
        5            quinque          "five"
        6            sex              "six"
        7            septem           "seven"
        8            octo             "eight"
        9            novem            "nine"
        10           decem            "ten"
        [0]          nullimum         "zeroth"
        [1]          primum           "first"
        [2]          secundum         "second"
        [3]          tertium          "third"
        [4]          quartum          "fourth"
        [5]          quintum          "fifth"
        [6]          sextum           "sixth"
        [7]          septimum         "seventh"
        [8]          octavum          "eighth"
        [9]          nonum            "ninth"
        [10]         decimum          "tenth"
        $1           parprimum        "equal of the first"
        $2           parsecundum      "equal of the first"
        $3           partertium       "equal of the third"
        $4           parquartum       "equal of the fourth"
        $5           parquintum       "equal of the fifth"
        $6           parsextum        "equal of the sixth"
        $7           parseptimum      "equal of the seventh"
        $8           paroctavum       "equal of the eighth"
        $9           parnonum         "equal of the ninth"
        $10          pardecimum       "equal of the tenth"
        $/           ianitorem        "gatekeeper"
        $#var        admeta varum     "measure out"
        $_           hoc/huic         "this thing"
        @_           his/horum        "these things"
    $<           nomen            "name"
        ":"          biguttam         "two spots"
        " "          lacunam          "a gap"
        "\t"         stadium          "a stride"
        "\n"         novumversum      "new line"
        local        loco             "in place of"
        my           meo              "my"
        our          nostro           "our"
        main         princeps         "principal"


=head2 Quotelike operators

        '...'        inque        "say"
        q//          inque        "say"
        m//          compara      "match"
        s///         substitue    "substitute"
        tr///        converte     "translate"


=head2 Mathematical operators and functions

        +            adde         "add"
        -            deme         "subtract"
        -            nega         "negate"
        *            multiplica   "multiply"
        /            divide       "divide"
        %            recide       "lop off"
        **           eleva        "raise"
        &            consocia     "unite"
        |            interseca    "intersect"
        ^            discerne     "differentiate (between)"
        ++           preincresce  "increase beforehand"
        ++           postincresce "increase afterwards"
        --           predecresce  "decrease beforehand"
        --           postdecresce "decrease afterwards"
        abs          priva        "strip from"
        atan2        angula       "create an angle"
        sin          oppone       "oppose"
        cos          accuba       "lie beside"
        int          decolla      "behead"
        log          succide      "log a tree"
        sqrt         fode         "root into"
        rand         conice       "guess, cast lots"
        srand        prosemina    "to scatter seed"


=head2 Logical and comparison operators

        !            non             "general negation"
        &&           atque           "empathic and"
        ||           vel             "emphatic or"
        and          -que            "and"
        or           -ve             "or"
        <            praestantiam    "precedence of"
        lt           praestantias    "precedences of"
        <=>          comparitiam     "comparison of"
        cmp          comparitias     "comparisons of"
        ==           aequalitam      "equality of"
        eq           aequalitas      "equalities of"


=head2 Strings

        chomp        morde        "bite"
        chop         praecide     "cut short"
        chr          inde         "give a name to"
        hex          senidemi     "sixteen at a time"
        oct          octoni       "eight at a time"
        ord          numera       "number"
        lc           deminue      "diminish"
        lcfirst      minue        "diminish"
        uc           amplifica    "increase"
        ucfirst      amplia       "increase"
        quotemeta    excipe       "make an exception"
        crypt        huma         "inter"
        length       meta         "measure"
        pos          reperi       "locate"
        pack         convasa      "pack baggage"
        unpack       deconvasa    "unpack"
        split        scinde       "split"
        study        stude        "study"
        index        scruta       "search"
        join         coniunge     "join"
        substr       excerpe      "extract"


=head2 Scalars, arrays, and hashes

        defined      confirma     "verify"
        undef        iani         "empty, make void"
        scalar       secerna      "to distinguish, isolate"
        reset        lusta        "cleanse"
        pop          decumula     "unstack"
        push         cumula       "stack"
        shift        decapita     "behead"
        unshift      capita       "crown"
        splice       iunge        "splice"
        grep         vanne        "winnow"
        map          applica      "apply to"
        sort         digere       "sort"
        reverse      retexe       "reverse"
        delete       dele         "delete"
        each         quisque      "each"
        exists       adfirma      "confirm"
        keys         nomina       "name"
        values       argue        "to disclose the contents"


=head2 I/O

        open         evolute      "open a book"
        close        claude       "close a book"
        eof          extremus     "end of"
        read         lege         "read"
        getc         sublege      "pick up something"
        readline     perlege      "read through"
        print        scribe       "write"
        printf       describe     "describe"
        sprintf      rescribe     "rewrite"
        write        subscribe    "write under"
        pipe         inriga       "irrigate"
        tell         enunta       "tell"
        seek         conquire     "to seek out"
        STDIN        vestibulo    "an entrance"
        STDOUT       egresso      "an exit"
        STDERR       oraculo      "a place where doom is pronounced"
        DATA         nuntio       "information"


=head2 Control structures

        {...}        sic...cis                "as follows...to here"
        do           fac                      "do"
        sub {...}    factorem sic...cis       "one who does ...
        eval         aestima                  "evaluate"
        exit         exi                      "exit"
        for          per...in...fac           "for...in...do"
        foreach      per quisque...in...fac   "for each...in...do"
        goto         adi                      "go to"
        <label>:     inscribe <label>         "make a mark"
        return       redde                    "return"
        if           si...fac                 "if"
        unless       nisi...fac               "if not"
        until        donec...fac              "until"
        while        dum...fac                "while"
        wantarray    deside                   "want"
        last         ultimus                  "final"
        next         posterus                 "following"
        redo         reconatus                "trying again"
        continue     confectus                "complete"
        die          mori                     "die"
        warn         mone                     "warn"
        croak        coaxa                    "croak (like a frog)"
        carp         carpe                    "carp at"
        __DATA__     nuntius                  "information"
        __END__      finis                    "a boundary"


=head2 Packages, classes, and modules

        ->           apud         "of the house of"
        ::           intra        "within"
        bless        benedice     "bless"
        caller       memora       "recount a history"
        package      domus        "house of "
        ref          agnosce      "identify"
        tie          liga         "tie"
        tied         exhibe       "display something"
        untie        solve        "to untie"
        require      require      "require"
        use          ute          "use"


=head2 System and filesystem interaction

        chdir        demigrare    "migrate"
        chmod        permitte     "permit"
        chown        vende        "sell"
        fcntl        modera       "control"
        flock        confluee     "flock together"
        glob         inveni       "search"
        ioctl        impera       "command"
        link         copula       "link"
        unlink       decopula     "unlink"
        mkdir        aedifica     "build"
        rename       renomina     "rename"
        rmdir        excide       "raze"
        stat         exprime      "describe"
        truncate     trunca       "shorten"
        alarm        terre        "frighten"
        dump         mitte        "drop"
        exec         commuta      "transform"
        fork         furca        "fork"
        kill         interfice    "kill"
        sleep        dormi        "sleep"
        system       obsecra      "entreat a higher power"
        umask        dissimula    "mask"
        wait         manta        "wait for"


=head2 Miscellaneous

        ,            tum          "and then"
        .            sere         "conjoin"
        ..           conscribe    "enlist"
        \            ad           "towards"
        =            da           "give"
        #...         adnota       "annotate"
        (...         cum          "with"
        to_roman     come         "beautify"



=head1 DIIUDICATORES

The Lingua::Romana::Perligata module may issue the following diagnostic
messages:

=over 4

=item Aliquod barbarum inveni: '%s'

Some foreign (non-Perligata) symbol was encountered. Commonly this is a
semi-colon where a period should have been used, but any other
non-alphanumeric will trigger the same error.


=item '-mentis' illicitum: '%s'

Perl does not (yet) support lvalue subroutines that return arrays.
Hence Perligata does not allow the I<-mentis> suffix to be used
on user-defined verbs.


=item Index '%s' ordinalis non est

An index or key was specified as a numeral (e.g. I<unum>),
rather than an ordinal (e.g. I<primum>).


=item '%s' immaturum est

The symbol indicated (typically I<tum>) appeared too early in the
command (e.g. before any accusative).


=item Iussum nefastum: '%s'

The indicated imperative verb was encountered where a resultative
was expected (e.g. the imperative was incorrectly used as an argument to
another subroutine or a conjunction).


=item Accusativum non junctum: '%s'

The indicated accusative noun or clause appears in a command, but does
not belong to any verb in the command.


=item Dativum non junctum: '%s'

The indicated dative noun or clause appears in a command, but does not
belong to any verb in the command.


=item Genitivum non junctum: '%s'

The indicated genitive noun or clause appears in a command, but does not
belong to any verb in the command.


=item Sententia imperfecta prope '%s'

The command or clause is missing an imperative verb.


=item Exspectavi 'sic' sed inveni '%s'

The beginning of a code block was expected at the point where
the indicated word was found.


=item Exspectavi 'cis' sed inveni '%s'

The end of a code block was expected at the point where
the indicated word was found.


=item Exspectavi accusativum post 'per' sed inveni '%s'

The I<per> control structure takes an accusative noun after it.
The indicated symbol was found instead.


=item 'in' pro 'per' afuit

The I<in> in a I<per> statement was missing.


=item '%s' dativus non est in 'per'

After the I<in> of a I<per> statement a dative noun or clause is
required. It was not found.


=item Iussa absentia per '%s'

The block of the indicated control statement was missing.


=item Non intellexi: '%s'

A general error message indicating the symbol was not understood in
the context it appeared.

=back

In addition to these diagnostics, additional debugging support is provided
in the form of three arguments that may be passed to the call to
C<S<use Lingua::Romana::Perligata>>.

The first of these -- C<'converte'> ("translate") -- causes the module
to translate the Perligata code into Perl and write it to STDOUT instead
of executing it. This is useful when your Perligata compiles and runs,
but does not execute as you expected.

The second argument that may be passed when loading the module is
C<'discribe'> ("classify"), which causes the module to print a lexical
analysis of the original Latin program. This is very handy for
identifying incorrect inflections, etc.

The final argument -- C<'investiga'>, ("trace") -- provides a
blow-by-blow trace of the translation process, tracking eack of the
internal stacks (the verb stack, the accusative stack, the dative stack,
the block stack), and showing where each reduction is performed. This
wealth of information tends to be useful only to those familiar with the
internals of the module.


=head1 GRATIAE

Special thanks to Marc Moskowitz, John Crossley, Tom Christiansen, and
Bennett Todd, for their invaluable feedback and suggestions. And my
enduring gratitude to David Secomb and Deane Blackman for their
heroic patience in helping me struggle with the perplexities of the
I<lingua Romana>.


=head1 SCRIPTOR

Damian Conway (damian@conway.org)


=head1 CIMICES

There are undoubtedly some very serious bugs lurking somewhere in code this
funky :-) Bug reports and other feedback are most welcome.

Corrections to my very poor Latin are doubly welcome.


=head1 IUS TRANSCRIBENDI

Copyright (c) 2000-2016, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
