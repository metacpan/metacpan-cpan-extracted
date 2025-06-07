#!/usr/bin/perl

# Can be invoked as:
#   ./bench.PL          # generates FU/Benchmarks.pod, running new benchmarks as necessary
#   ./bench.PL id x y   # invalidate cache for the (regex-)matching benchmark IDs, x and y and re-run them
#
# This script obviously has more dependencies than the FU distribution itself.
# It's supposed to be used by maintainers, not users.


# MakeMaker automatically runs this script as a default built step, but that's not very useful.
BEGIN { exit if @ARGV && @ARGV[0] eq 'bench'; }

use v5.36;
use builtin 'true', 'false';
use Benchmark ':hireswallclock', 'timethis';

my %modules = map +($_, eval "require $_; \$${_}::VERSION"), qw/
    FU
    Cpanel::JSON::XS
    JSON::PP
    JSON::SIMD
    JSON::Tiny
    JSON::XS
    TUWF::XML
    HTML::Tiny
    XML::Writer
    DBD::Pg
    Pg::PQ
/;
use FU::Pg;

my %data; # "id x y" => { id x y rate exists }
my %oldmodules;
{ if (open my $F, '<', 'FU/Benchmarks.pod') {
    my $indata;
    while (<$F>) {
        chomp;
        $oldmodules{$1} = $2 if /^=item L<([a-zA-Z0-9:]+)> ([0-9.]+)/;
        $indata = 1 if /^# Cached data used by bench\.PL/;
        next if !$indata || !$_ || /^#/;
        my %d;
        @d{qw/id x y rate/} = split /\t/;
        $data{"$d{id} $d{x} $d{y}"} = \%d;
    }
} }

if (@ARGV) {
    my $idre = qr/$ARGV[0]/i;
    my $xre = $ARGV[1] ? qr/$ARGV[1]/i : qr/.*/;
    my $yre = $ARGV[2] ? qr/$ARGV[2]/i : qr/.*/;
    delete $_->{rate} for grep $_->{id} =~ /$idre/ && $_->{x} =~ /$xre/ && $_->{y} =~ /$yre/, values %data;
}


my @bench; # [ id, text, [ x_1, .. ], [ [ y_1, mod_1, sub_1, .. ], .. ] ]
sub def($id, $text, $xs, @ys) {
    for my ($ya) (@ys) {
        my($y, $m, @sub) = @$ya;
        $m ||= $y;
        for my($i, $x) (builtin::indexed @$xs) {
            next if !$sub[$i];
            my $d = "$id $x $y";
            $data{$d} ||= { id => $id, x => $x, y => $y };
            $d = $data{$d};
            $d->{exists} = 1;
            delete $d->{rate} if !$oldmodules{$m} || $modules{$m} ne $oldmodules{$m};
            if (!exists $d->{rate}) {
                my $o = timethis -5, $sub[$i], 0, 'none';
                $d->{rate} = sprintf '%.0f', $o->iters/$o->real;
                printf "%-20s%-12s%-20s%10d/s\n", $id, $x, $y, $d->{rate};
            }
        }
    }
    push @bench, [ $id, $text, $xs, \@ys ];
}




use FU::Util 'json_format', 'json_parse';

sub defjson($name, $canon, $text, $val) {
    # Use similar options for fair comparisons.
    my $cp = Cpanel::JSON::XS->new->allow_nonref->unblessed_bool->convert_blessed;
    my $pp = JSON::PP->new->allow_nonref->core_bools->convert_blessed;
    my $xs = JSON::XS->new->allow_nonref->boolean_values([false,true])->convert_blessed;
    my $si = JSON::SIMD->new->allow_nonref->core_bools->convert_blessed;
    my $c_cp = Cpanel::JSON::XS->new->allow_nonref->unblessed_bool->convert_blessed->canonical;
    my $c_pp = JSON::PP->new->allow_nonref->core_bools->convert_blessed->canonical;
    my $c_xs = JSON::XS->new->allow_nonref->boolean_values([false,true])->convert_blessed->canonical;
    my $c_si = JSON::SIMD->new->allow_nonref->core_bools->convert_blessed->canonical;
    my $enc = json_format $val;
    def "json/$name", $text, [ 'Encode', $canon ? 'Canonical' : (), 'Decode' ],
        [ 'JSON::PP',         undef, sub { $pp->encode($val) }, $canon ? sub { $c_pp->encode($val) } : (), sub { $pp->decode($enc) } ],
        [ 'JSON::Tiny',       undef, sub { JSON::Tiny::to_json($val) }, $canon ? undef : (), sub { JSON::Tiny::from_json($enc) } ],
        [ 'Cpanel::JSON::XS', undef, sub { $cp->encode($val) }, $canon ? sub { $c_cp->encode($val) } : (), sub { $cp->decode($enc) } ],
        [ 'JSON::SIMD',       undef, sub { $si->encode($val) }, $canon ? sub { $c_si->encode($val) } : (), sub { $si->decode($enc) } ],
        [ 'JSON::XS',         undef, sub { $xs->encode($val) }, $canon ? sub { $c_xs->encode($val) } : (), sub { $xs->decode($enc) } ],
        [ 'FU::Util',         'FU',  sub { json_format $val  }, $canon ? sub { json_format $val, canonical => 1 } : (), sub { json_parse $enc } ];
}

# From JSON::XS POD.
defjson api => 1, 'API object from L<JSON::XS> documentation.',
    [ map +{method => 'handleMessage', params => ['user1','we were just talking'], 'id' => undef, 'array' => [1,11,234,-5,1e5,1e7,1,0]}, 1..10 ];

defjson objs => 1, 'Object (small)', [ map +{ map +("string$_", 1), 'a'..'f' }, 0..100 ];
defjson objl => 1, 'Object (large)', { map +("string$_-something", 1), 'aa'..'zz' };
defjson obju => 1, 'Object (large, mixed unicode)', { map +("str\x{1234}g$_-some\x{85232}hing", 1), 'aa'..'zz' };

defjson ints => 0, 'Small integers', [ -5000..5000 ];
defjson intl => 0, 'Large integers', [ map { my $n=$_; map +($n+1<<$_), 10..60 } 1..10 ];
defjson strs => 0, 'ASCII strings', [ map +('hello, world', 'one more string', 'another string'), 1..100 ];
defjson stru => 0, 'Unicode strings', do { use utf8;
    [ map +('グリザイアの果実 -LE FRUIT DE LA GRISAIA-', '💩', 'Я люблю нічого не робити'), 1..50 ];
};
defjson stres => 0, 'String escaping (few)', [ map 'This string needs to "be escaped" a little bit', 1..100 ];
defjson strel => 0, 'String escaping (many)', [ map "This \" \\ needs \n\x41\x42\x43\x44 more", 1..100 ];




package BENCH::TUWFXML {
    use TUWF::XML ':html5_', 'xml_string';
    sub f($id) {
        li_ class => $id % 2 ? 'one' : undef, '+', $id % 5 > 2 ? 'two' : undef, sub {
            small_ '--'x($id % 50).' ' if $id % 3;
            a_ href => "/$id",
                class => $id % 7 > 2 ? 'another-class' : undef,
                '+' => $id % 9 < 7 ? 'and-another-one' :  undef,
                style => "width: ${id}px",
                $id;
        };
    }
    sub t { xml_string sub { div_ sub { f $_ for (1..100) } } }
}

package BENCH::XMLWriter {
    my $wr;
    sub f($id) {
        $wr->startTag(li => class => join(' ', $id % 2 ? 'one' : (), $id % 5 > 2 ? 'two' : ()));
        $wr->dataElement(small => '--'x($id % 50).' ') if $id % 3;
        $wr->dataElement(a => $id, href => "/$id", class => join(' ',
                $id % 7 > 2 ? 'another-class' : (),
                $id % 9 < 7 ? 'and-another-one' :  ()
            ), style => "width: ${id}px");
        $wr->endTag();
    }
    sub t {
        $wr = XML::Writer->new(OUTPUT => \my $str, UNSAFE => 1);
        $wr->startTag('div');
        f $_ for (1..100);
        $wr->endTag();
    }
}

package BENCH::HTMLTiny {
    my $h;
    sub f($id) {
        $h->li({ class => join(' ', $id % 2 ? 'one' : (), '+', $id % 5 > 2 ? 'two' : ()) }, [
            $id % 3 ? $h->small('--'x($id % 50).' ') : '',
            $h->a({
                href => "/$id",
                class => join (' ',
                    $id % 7 > 2 ? 'another-class' : (),
                    $id % 9 < 7 ? 'and-another-one' :  (),
                ),
                style => "width: ${id}px"
            }, $id),
        ]);
    }
    sub t {
        $h = HTML::Tiny->new;
        $h->div(map f($_), 1..100);
    }
}

package BENCH::FUXMLWriter {
    use FU::XMLWriter ':html5_', 'fragment';
    sub f($id) {
        li_ class => $id % 2 ? 'one' : undef, '+', $id % 5 > 2 ? 'two' : undef, sub {
            small_ '--'x($id % 50).' ' if $id % 3;
            a_ href => "/$id",
                class => $id % 7 > 2 ? 'another-class' : undef,
                '+' => $id % 9 < 7 ? 'and-another-one' :  undef,
                style => "width: ${id}px",
                $id;
        };
    }
    sub t { fragment { div_ sub { f $_ for (1..100) } } }
}

def 'xml/a', 'HTML fragment', [ 'Rate' ],
    [ 'TUWF::XML',     undef, \&BENCH::TUWFXML::t ],
    [ 'XML::Writer',   undef, \&BENCH::XMLWriter::t ],
    [ 'HTML::Tiny',    undef, \&BENCH::HTMLTiny::t ],
    [ 'FU::XMLWriter', 'FU',  \&BENCH::FUXMLWriter::t ];




{
    die "FU_TEST_DB not set.\n" if !$ENV{FU_TEST_DB};
    my $pq = Pg::PQ::Conn->new($ENV{FU_TEST_DB});
    my $fu = FU::Pg->connect($ENV{FU_TEST_DB});
    # XXX: Doesn't support all connection params this way
    my $dbi = DBI->connect("dbi:Pg:dbname=".$pq->db, $pq->user, $pq->pass, {RaiseError => 1, PrintError => 0});

    my $small = 'SELECT x, x+1, x+2, x+3, x+4, x+5, x+6, x+7, x+8, x+9 FROM generate_series(-10000::smallint, 9999, 10) x(x)';
    my $big = 'SELECT x<<5, x<<10, x<<15, x<<20, x<<25, x<<30, x<<35, x<<40, x<<45, x<<50 FROM generate_series(1::bigint, 20000, 1) x(x)';

    my sub dbi { my $sum = 0; my $st = $dbi->prepare_cached($_[0]); for my $row ($dbi->selectall_arrayref($st)->@*) { $sum ^= $_ for @$row; } }
    my sub pq  { my $sum = 0; $pq->prepare('' => $_[0]); for my $row ($pq->execQueryPrepared('')->rows) { $sum ^= $_ for @$row; } }
    my sub fub { my $sum = 0; for my $row ($fu->q($_[0])->alla->@*) { $sum ^= $_ for @$row; } }
    my sub fut { my $sum = 0; for my $row ($fu->q($_[0])->text->alla->@*) { $sum ^= $_ for @$row; } }

    def 'pg/ints', 'Fetch and bitwise-or 20k integers', [ 'Smallint', 'Bigint' ],
        [ 'DBD::Pg', undef, sub { dbi($small) }, sub { dbi($big) } ],
        [ 'Pg::PQ', undef, sub { pq($small) }, sub { pq($big) } ],
        [ 'FU::Pg (bin)', 'FU', sub { fub($small) }, sub { fub($big) } ],
        [ 'FU::Pg (text)', 'FU', sub { fut($small) }, sub { fut($big) } ];
}





delete @data{ grep !$data{$_}{exists}, keys %data };

sub fmtbench($id, $text, $xs, $ys) {
    my $r = "$text\n\n";
    if (@$xs > 1) {
        $r .= sprintf '%18s', '';
        $r .= sprintf '%12s', $_ for @$xs;
        $r .= "\n";
    }
    for my ($n, $yr) (builtin::indexed @$ys) {
        my $x = $xs->[$n];
        my ($y, $m, @ys) = @$yr;
        $m ||= $y;
        $r .= sprintf '%18s', $y;
        for my $i (0..$#$xs) {
            my $d = $data{"$id $xs->[$i] $y"};
            $r .= $d ? sprintf '%10d/s', $d->{rate} : sprintf '%12s', '-';
        }
        $r .= "\n";
    }
    "$r\n"
}

{
    open my $F, '>FU/Benchmarks.pod' or die $!;
    select $F;
    while (<DATA>) {
        s/^%/=/;
        s#^:modules#join '', map sprintf("=item L<%s> %s\n\n", $_, $modules{$_}), sort keys %modules#e;
        s#^:benches (.+)#join '', map fmtbench(@$_), grep $_->[0] =~ /$1/, @bench#e;
        print;
    }
    for (sort keys %data) {
        my $b = $data{$_};
        print join("\t", @{$b}{qw/ id x y rate /})."\n";
    }
}

# s/^=/%/  to prevent tools from interpreting the below as POD
__DATA__
%head1 NAME

FU::Benchmarks - A bunch of automated benchmark results.

%head1 DESCRIPTION

This file is automatically generated from 'bench.PL' in the L<FU> distribution.
These benchmarks compare performance of some FU functionality against similar
modules found on CPAN.

B<DISCLAIMER#1:> Obtaining accurate measurements is notoriously hard. Take the
numbers below with a few buckets of salt, any difference below 10% is most
likely noise.

B<DISCLAIMER#2:> Goodhart's law: "When a measure becomes a target, it ceases to
be a good measure". I've used these benchmarks to find and optimize hotspots in
FU, which in turn means these numbers may look better than they are in
real-world use.

B<DISCLAIMER#3:> Many of these benchmarks exists solely to test edge case
performance, these numbers are not representative for real-world use.

%head1 MODULE VERSIONS

The following module versions were used:

%over

:modules

%back

%head1 BENCHMARKS

%head2 JSON Parsing & Formatting

These benchmarks run on large-ish arrays with repeated values. JSON encoding is
sufficiently fast that Perl function calling overhead tends to dominate for
smaller inputs, but I don't find that overhead very interesting.

Also worth noting that L<JSON::SIMD> formatting code is forked from
L<JSON::XS>, the SIMD parts are only used for parsing.

:benches ^json

%head2 XML Writing

L<FU::XMLWriter> is the only XS-based XML DSL that I'm aware of, so all direct
competition is inherently slower by virtue of being pure perl. I'm sure some
templating modules will perform better, though.

:benches ^xml

%head2 PostgreSQL client

Fetching query results is highly unlikely to be a bottleneck in your code, this
benchmark is mainly here to verify that L<FU::Pg> is not introducing a
bottleneck where there shouldn't be one.

:benches ^pg

%cut

# Cached data used by bench.PL. Same as the formatted tables above but easier to parse.
