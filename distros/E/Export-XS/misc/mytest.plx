#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch', 't';
use Benchmark qw/timethis timethese/;
use Export::XS { abc => 1};
use Time::HiRes;

say "START";

my $cnt = shift @ARGV;
my @list = (map {"MY_CONSTANT_$_"} 1..$cnt);
my $str = join(", ", map { "'$_' => 1"} @list);

{
    package MyPack1;
    use parent 'Export::XS';
    
    my $sub = eval "sub { Export::XS->import({$str}) }";
    
    my $now = Time::HiRes::time;
    $sub->();
    my $delta = Time::HiRes::time - $now;
    my $speed = int($cnt/$delta);
    my $ms = sprintf("%.2f", $delta*1000);
    say "CREATE HREF $speed/s, took $ms ms";
}

{
    package MyPack2;
    use parent 'Export::XS';
    
    my $sub = eval "sub { Export::XS->import($str) }";
    
    my $now = Time::HiRes::time;
    $sub->();
    my $delta = Time::HiRes::time - $now;
    my $speed = int($cnt/$delta);
    my $ms = sprintf("%.2f", $delta*1000);
    say "CREATE LIST $speed/s, took $ms ms";
}

{
    package Consumer;
    my $now = Time::HiRes::time;
    MyPack2->import;
    my $delta = Time::HiRes::time - $now;
    my $speed = int($cnt/$delta);
    my $ms = sprintf("%.2f", $delta*1000);
    say "IMPORT $speed/s, took $ms ms";
}


say scalar @{Export::XS::constants_list('MyPack1')};
say scalar @{Export::XS::constants_list('MyPack2')};

1;
