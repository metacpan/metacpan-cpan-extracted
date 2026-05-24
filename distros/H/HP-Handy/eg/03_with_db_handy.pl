######################################################################
#
# 03_with_db_handy.pl - HP::Handy + DB::Handy CRUD report example
#
# Run: perl eg/03_with_db_handy.pl
#
# Demonstrates:
#   render_string, DB::Handy connect/do/prepare/execute/fetchrow_hashref,
#   HP::Handy for loop/filter/if over DB query results,
#   CREATE TABLE, INSERT, SELECT, UPDATE, DELETE via DB::Handy
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec;

use lib 'lib';
use HP::Handy;
use DB::Handy;

######################################################################
# Setup: create a temporary database directory
######################################################################
my $dbdir = File::Spec->catfile(File::Spec->tmpdir(), "hp_db_demo_$$");
mkdir($dbdir, 0700) or die "Cannot mkdir $dbdir: $!";

END {
    # Cleanup on exit
    if (defined $dbdir && -d $dbdir) {
        opendir(DBDIR, $dbdir) or last;
        my @f = grep { $_ ne '.' && $_ ne '..' } readdir(DBDIR);
        closedir(DBDIR);
        for my $f (@f) {
            my $fp = File::Spec->catfile($dbdir, $f);
            if (-d $fp) {
                opendir(SUB, $fp) or next;
                my @sf = grep { $_ ne '.' && $_ ne '..' } readdir(SUB);
                closedir(SUB);
                unlink File::Spec->catfile($fp, $_) for @sf;
                rmdir $fp;
            }
            else {
                unlink $fp;
            }
        }
        rmdir $dbdir;
    }
}

######################################################################
# Connect and create schema
######################################################################
my $db  = DB::Handy->new(data_dir => $dbdir);
my $dbh = $db->connect("dbi:Handy:dbname=demo", '', '');

$dbh->do(<<'SQL');
CREATE TABLE products (
    id       INTEGER,
    name     VARCHAR(40),
    category VARCHAR(20),
    price    NUMERIC(8,2),
    stock    INTEGER
)
SQL

######################################################################
# INSERT sample data
######################################################################
my $ins = $dbh->prepare(
    "INSERT INTO products (id, name, category, price, stock) VALUES (?,?,?,?,?)"
);
my @seed = (
    [ 1, 'Perl Cookbook',      'Book',  3500, 12 ],
    [ 2, 'Learning Perl',      'Book',  2800, 25 ],
    [ 3, 'USB Hub 4-port',     'Gadget', 980,  8 ],
    [ 4, 'Mechanical Keyboard','Gadget',8900,  3 ],
    [ 5, 'Wireless Mouse',     'Gadget',2400, 15 ],
    [ 6, 'Programming Perl',   'Book',  4200,  6 ],
    [ 7, 'HDMI Cable 2m',      'Gadget', 650, 30 ],
);
for my $row (@seed) {
    $ins->execute(@$row);
}
$ins->finish;

######################################################################
# UPDATE: price increase 10% for Gadgets
######################################################################
$dbh->do("UPDATE products SET price = price * 1.10 WHERE category = 'Gadget'");

######################################################################
# DELETE: remove out-of-stock items (stock < 5)
######################################################################
$dbh->do("DELETE FROM products WHERE stock < 5");

######################################################################
# SELECT all remaining products
######################################################################
my $sth = $dbh->prepare("SELECT * FROM products ORDER BY category, price");
$sth->execute();
my @products;
while (my $row = $sth->fetchrow_hashref()) {
    push @products, {
        id       => $row->{id},
        name     => $row->{name},
        category => $row->{category},
        price    => sprintf("%.0f", $row->{price}),
        stock    => $row->{stock},
    };
}
$sth->finish;

######################################################################
# Aggregate: total and category summary
######################################################################
my %cat_total;
my $grand_total = 0;
for my $p (@products) {
    $cat_total{ $p->{category} } += $p->{price} * $p->{stock};
    $grand_total                  += $p->{price} * $p->{stock};
}
my @summary;
for my $cat (sort keys %cat_total) {
    push @summary, { category => $cat, total => $cat_total{$cat} };
}

$dbh->disconnect;

######################################################################
# Render with HP::Handy
######################################################################
my $tmpl = HP::Handy->new(auto_escape => 0);

$tmpl->add_filter('yen', sub {
    my $n = defined $_[0] ? int($_[0]) : 0;
    $n =~ s/(\d)(?=(\d{3})+$)/$1,/g;
    return "\xc2\xa5" . $n;   # UTF-8 yen sign
});

######################################################################
# Report 1: product list
######################################################################
my $list_src = <<'TMPL';
========================================
  Product List  (after UPDATE + DELETE)
========================================
{% for p in products %}
{{ "%2d" | format(loop.index) }}. [{{ p.category }}] {{ p.name }}
    Price: {{ p.price | yen }}  Stock: {{ p.stock }}
    {% if p.stock <= 5 %} *** Low Stock ***{% endif %}
{% endfor %}
Total products: {{ products | count }}
TMPL

print $tmpl->render_string($list_src, { products => \@products });

######################################################################
# Report 2: category summary
######################################################################
my $summary_src = <<'TMPL';

========================================
  Category Summary
========================================
{% for row in summary %}
  {{ row.category }}: {{ row.total | yen }}
{% endfor %}
  ----------------------------------------
  Grand Total: {{ grand_total | yen }}
TMPL

print $tmpl->render_string($summary_src, {
    summary     => \@summary,
    grand_total => $grand_total,
});

######################################################################
# Report 3: last_insert_id demo
######################################################################
my $dbh2 = $db->connect("dbi:Handy:dbname=demo", '', '');
$dbh2->do("INSERT INTO products (id,name,category,price,stock) VALUES (8,'New Item','Book',1500,10)");
my $last_id = $dbh2->last_insert_id('', '', 'products', 'id');
$dbh2->disconnect;

print $tmpl->render_string(
    "\nlast_insert_id after new INSERT: {{ lid }}\n",
    { lid => $last_id }
);
