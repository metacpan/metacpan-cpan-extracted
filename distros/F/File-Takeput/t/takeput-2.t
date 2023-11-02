#!/usr/bin/perl
# t/takeput-2.t
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

my ($dir,$tdir);
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $tdir = dirname(abs_path($0));
    $dir = $tdir =~ s/[^\/]+$/lib/r;
    };

use File::Copy;
use lib $dir;

use_ok 'File::Takeput' , qw(ftake put grab); # 1

my $fn = $tdir.'/takeput-2.txt';
my $fn_1 = $tdir.'/takeput-2-1.csv';

unlink $fn_1;
copy $fn , $fn_1;

sub changecurr($r,$w,$x) {
    $w->( map {s/((\d*\.)?\d+)/$x*$1/ger} $r->() );
    };

my $r;
ok ($r = ftake($fn_1 , patience => 5)); # 2
my $w;
ok ($w = put($fn_1)); # 3
my $rate = 0.1;
changecurr($r,$w,$rate);

my $content = 'nuggets   2.55
fritter   2.2
pizza     3.3
sodavand  2
total:   10.05
';

ok ($content eq join '' , grab($fn_1)); # 4

__END__
