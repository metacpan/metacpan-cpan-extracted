use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Create qw/create_json create_json_strict/;

# Test against hash reference.

package Maka::Maka;
sub new {return bless {mog => 'cat'};}
1;
package main;
my $mm = Maka::Maka->new ();
my $outmm = create_json ($mm);
is ($outmm, '{"mog":"cat"}',
    "Perl object containing hash reference");
{
    my $warning;
    local $SIG{__WARN__} = sub {$warning = "@_"};
    is (create_json_strict ($mm), undef, "get undefined value with strict routine");
    like ($warning, qr/Object cannot be serialized to JSON/, "get correct warning");
    like ($warning, qr/Maka::Maka/, "get object name in warning");
}

# Test against scalar reference.

package Baka::Baka;
sub new {my $cat = "neko";return bless \$cat;}
1;

package main;

my $bb = Baka::Baka->new ();
my $outbb = create_json ($bb);
is ($outbb, '"neko"',
    "Perl object containing scalar reference");

# Test against scalar reference containing Unicode string.

package Ba::Bi::Bu::Be::Bo;

sub new
{
    my $lion = 'ライオン';
    return bless \$lion;
}

1;

package main;

my $babibubebo = Ba::Bi::Bu::Be::Bo->new ();
my $zz = {"babibubebo" => $babibubebo};
my $outzz = create_json ($zz);
is ($outzz, '{"babibubebo":"ライオン"}',
    "Perl object containing scalar reference to Unicode");

done_testing ();
