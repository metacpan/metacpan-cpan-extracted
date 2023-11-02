#!/usr/bin/perl
# t/takeput-3.t
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

use_ok 'File::Takeput' , separator => 'x'; # 1

my $fn = $tdir.'/takeput-3.txt';

unlink $fn;

my $val;
ok (File::Takeput::set(error => sub {$val = $@; undef;})); # 2
ok (not take($fn)); # 3
ok ($val =~ m/ does not exist\.$/); # 4

ok (File::Takeput::reset()); # 5
ok ( grab($fn , error => sub {return 734256;}) == 734256 ); # 6

my $a;
ok ( $a = append($fn , error => sub {return 'kolme';}) ); # 7
ok ( $a ne 'kolme' ); # 8
ok ( $a->('yksi','kaksi') eq 'kolme' ); # 9

__END__
