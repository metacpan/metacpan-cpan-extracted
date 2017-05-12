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
{
my $warning;
local $SIG{__WARN__} = sub {$warning = "@_"};
my $in = \"monkey";
is (create_json_strict ($in), undef, "undef value on scalar reference");
like ($warning, qr/Input's type cannot be serialized to JSON/i, "warning on scalar reference");
is (create_json ($in), '"monkey"', "dereference on scalar reference");
$warning = undef;
my $number = 22;
my $innumber = \$number;
is (create_json_strict ($innumber), undef, "undef on scalar reference");
like ($warning, qr/Input's type cannot be serialized to JSON/i, "warning on scalar reference");
is (create_json ($innumber), '22', "dereference on scalar reference");
}
done_testing ();
