use strict;
use Test::More tests => (12 + (12 * 4));

my $truth;

my @check_support = (
    "ISO 843", "Common DEU", "ISO 9", "Greeklish", "DIN 31634", "Common RON",
    "Common CES", "DIN 1460 BUL", "Streamlined System BUL", "Common SLV",
    "Common SLK", "Common POL"
);


BEGIN
{
    # 1
    use_ok("Lingua::Translit::Tables");

    # 2
    use_ok("Lingua::Translit::Tables", qw/translit_supported/);

    # 3
    use_ok("Lingua::Translit::Tables", qw/translit_reverse_supported/);

    # 4
    use_ok("Lingua::Translit::Tables", qw/translit_list_supported/);

    # 5
    use_ok("Lingua::Translit::Tables", qw/:checks/);

    # 6
    use_ok("Lingua::Translit::Tables", qw/:list/);

    # 7
    use_ok("Lingua::Translit::Tables", qw/:all/);
}

# 8
can_ok("Lingua::Translit::Tables", qw/translit_supported/);

# 9
can_ok("Lingua::Translit::Tables", qw/translit_reverse_supported/);

# 10
can_ok("Lingua::Translit::Tables", qw/translit_list_supported/);


use Lingua::Translit::Tables qw/:checks/;

$truth = translit_supported("nonexistent");

# 11
is($truth, 0, "support for nonexistent table");


$truth = translit_supported("");

# 12
is($truth, 0, "support for empty table");


foreach my $name (@check_support)
{
    my $id = Lingua::Translit::Tables::_get_table_id($name);

    $truth = translit_supported($name);

    is($truth, 1, "support for existing table $id - by name");

    $truth = translit_supported(uc($name));

    is($truth, 1, "support for existing table $id - by uc(name)");

    $truth = translit_supported(lc($name));

    is($truth, 1, "support for existing table $id - by lc(name)");

    $truth = translit_supported($id);

    is($truth, 1, "support for existing table $id - by id");
}
