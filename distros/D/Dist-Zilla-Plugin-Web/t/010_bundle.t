use strict;
use warnings;
use Test::More 0.88;

use Path::Class;
use Dist::Zilla::Tester;

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/Bundle' },
    );

    $tzil->build;
    
    `java -version`;
    my $has_java    = "$?" eq "0";
    
    my $build_dir = dir($tzil->tempdir, 'build');
    
    ok(-e $build_dir->file(qw(even-plus-odd.js)), 'Bundle created #1');
    ok(-e $build_dir->file(qw(even-plus-odd.min.js)), 'Bundle created #2') if $has_java;
    ok(-e $build_dir->file(qw(bundles part21.js)), 'Bundle created #3');
    
    my $even_plus_odd_content       = $build_dir->file(qw(even-plus-odd.js))->slurp . '';
    my $even_plus_odd_min_content   = $build_dir->file(qw(even-plus-odd.min.js))->slurp . '' if $has_java;
    my $part21_content              = $build_dir->file(qw(bundles part21.js))->slurp . '';

    my $s   = qr/(?:\s|;)+/;

    ok($even_plus_odd_content =~ /2;$s+4;$s+1;$s+3;/s, '`EvenPlusOdd` bundle is correct');
    ok($even_plus_odd_min_content =~ /2;4;1;3;/s, '`EvenPlusOddMin` bundle is correct') if $has_java;
    ok($part21_content =~ /npm1;$s+part23;$s+yo!;$s+npm2;$s+part22;$s+part21;$s+npm4/s, '`Part21` bundle is correct');
}

done_testing;
