use Test::Simple 'no_plan';
use strict;
use lib './lib';
use File::PathInfo::Ext;
use Carp;
use Cwd;
use Smart::Comments '###';
my $abs = Cwd::cwd().'/t/tmp/file.txt';

mkdir './t/tmp';
open(FI,'>',$abs) or die($!);
print FI 'this is content';
close FI or die($!);
mkdir './t/tmp/dir';






my $f = File::PathInfo::Ext->new($abs);
ok $f, "instanced $abs";


ok( $f->can('errstr'), 'can errstr') or die;

my $val;
$val = $f->abs_path;
ok( $val, 'absapath' )or die;


$val = $f->errstr;
### $val

$f->errstr('this is');
$val = $f->errstr;
### $val


$val = $f->errstr('this is a val for errstr');
ok( $val, 'errstr returns');
### $val
$val or confess();
#
ok_part();

$val = $f->_resolve_arg_to('file.ha') or die($f->errstr);

ok($val,"resolved to '$val'");
ok($val eq Cwd::cwd().'/t/tmp/file.ha');





ok_part();

ok $val = $f->_resolve_arg_to(Cwd::cwd().'/t/tmp/dir/') or die($f->errstr);
### $val

ok $val eq Cwd::cwd().'/t/tmp/dir/file.txt';





ok_part('others');

for my $arg( qw(./file.txt ./ . ./../file.txt ./../bogus/thing ./t/tmp/bogusdir/) ){
   my $err;
   my $result = $f->_resolve_arg_to($arg)
      or $err = $f->errstr;
   
   printf STDERR " arg '$arg' = [%s]\n err? $err\n\n", ( $result || 'NO RESULT');

}
   


exit;







sub ok_part { print STDERR "\n\n--------------@_\n----\n\n"; 1 }



