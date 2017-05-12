use Test;
BEGIN { plan tests => 3 }
package TestPkg;
use Exporter::Dispatch;
Test::ok(1);

sub sub_a { Test::ok(1) }
package main;
my $table = create_dptable TestPkg;
ok(1);

$table->{sub_a}->("Hello!");
