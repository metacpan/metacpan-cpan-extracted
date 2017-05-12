#!/usr/bin/perl

use strict;
use lib './lib';
use Test::More tests => 19;

use FindBin;
use lib $FindBin::RealBin;
use testload;

my $file  = "$Dat_Dir/basic.html";
my $file2 = "$Dat_Dir/basic2.html";

use HTML::TableExtract;

# Check header row retention cases

my($label, $te, @rows, $table);

$label = 'header row (basic, default)';
$te = HTML::TableExtract->new();
ok($te->parse_file($file), "$label (parse)");
$table = $te->first_table_found;
@rows = $table->rows;
cmp_ok(@rows, '==', scalar @{$table->{grid}}, "$label (row count)");

$label = 'header row (basic, no keep)';
$te = HTML::TableExtract->new( keep_headers => 0 );
ok($te->parse_file($file), "$label (parse)");
$table = $te->first_table_found;
@rows = $table->rows;
cmp_ok(@rows, '==', scalar @{$table->{grid}}, "$label (row count)");

$label = 'header row (basic, keep)';
$te = HTML::TableExtract->new( keep_headers => 1 );
ok($te->parse_file($file), "$label (parse)");
$table = $te->first_table_found;
@rows = $table->rows;
cmp_ok(@rows, '==', scalar @{$table->{grid}}, "$label (row count)");

my(@hrow, $hindex);
my @headers = qw(Eight Six Four Two Zero);
my @hlabels = map("Header $_", @headers);

$label = 'header row (header, default)';
$te = HTML::TableExtract->new( headers => [@headers] );
ok($te->parse_file($file), "$label (parse)");
$table = $te->first_table_found;
@rows = $table->rows;
cmp_ok(@rows, '==', scalar @{$table->{grid}} - 1, "$label (row count)");
$hindex = $table->hrow_index;
@hrow = $table->hrow;
cmp_ok(join(' ', @hrow), 'eq', join(' ', @hlabels), "$label (hrow)");


$label = 'header row (header, nokeep)';
$te = HTML::TableExtract->new( headers => [@headers],
                               keep_headers => 0,
                             );
ok($te->parse_file($file), "$label (parse)");
$table = $te->first_table_found;
@rows = $table->rows;
cmp_ok(@rows, '==', scalar @{$table->{grid}} - 1, "$label (row count)");
$hindex = $table->hrow_index;
@hrow = $table->hrow;
cmp_ok(join(' ', @hrow), 'eq', join(' ', @hlabels), "$label (hrow)");

$label = 'header row (header, keep)';
$te = HTML::TableExtract->new( headers => [@headers],
                               keep_headers => 1,
                             );
ok($te->parse_file($file), "$label (parse)");
$table = $te->first_table_found;
@rows = $table->rows;
cmp_ok(@rows, '==', scalar @{$table->{grid}}, "$label (row count)");
$hindex = $table->hrow_index;
@hrow = $table->hrow;
cmp_ok(join(' ', @hrow), 'eq', join(' ', @hlabels), "$label (hrow)");

###

# Traditionally we clip extraneous rows above our header rows.

$label = 'pre-header row clip (header, nokeep)';
$te = HTML::TableExtract->new( headers => [@headers],
                               keep_headers => 0,
                             );
ok($te->parse_file($file2), "$label (parse)");
$table = $te->first_table_found;
my $ghi = get_grid_header_index($table->{grid});
@rows = $table->rows;
cmp_ok(@rows, '==', scalar @{$table->{grid}} - $ghi - 1, "$label (row count)");

$label = 'pre-header row clip (header, keep)';
$te = HTML::TableExtract->new( headers => [@headers],
                               keep_headers => 1,
                             );
ok($te->parse_file($file2), "$label (parse)");
$table = $te->first_table_found;
$ghi = get_grid_header_index($table->{grid});
@rows = $table->rows;
cmp_ok(@rows, '==', scalar @{$table->{grid}} - $ghi, "$label (row count)");

sub get_grid_header_index {
  my $grid = shift;
  my $ghi = 0;
  foreach (0 .. $#{$table->{grid}}) {
    my $item = $table->{grid}[$_][0];
    $item = $$item if ref $item;
    next if $item =~ /not\s+header/i;
    $ghi = $_;
    last;
  }
  $ghi;
}
