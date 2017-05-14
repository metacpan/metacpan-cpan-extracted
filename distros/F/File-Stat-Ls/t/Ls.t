# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use File::Stat::Ls qw(:all);
my $class = 'File::Stat::Ls';
my $obj = $class->new;

isa_ok($obj, $class);

my @md = @File::Stat::Ls::EXPORT_OK;
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}

# my $fn = '/opt/orasw/dba/cgi/listdir.bat';
# my $f2 = '/opt/orasw/dba/cgi';
# my $f3 = '/opt/orasw/dba/cgi/wordstat.pl'; 
# my $txt = `ls -l $fn`;
# print "$fn\n";
# print "$txt";
# print $obj->ls_stat($fn); 
# # print `ls -l $f2`;
# print $obj->ls_stat($f2); 
# print `ls -l $f3`;
# print $obj->ls_stat($f3); 

# my @a = `ls $f2`;
# foreach my $f (@a) {
#     next if ! $f || $f =~ /^\s*$/;
#     chomp $f;
#     # print "$f2/$f\n";
#     print $obj->ls_stat("$f2/$f");
# }

exit;

1;

