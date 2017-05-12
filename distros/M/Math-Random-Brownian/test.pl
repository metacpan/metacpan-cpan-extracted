#!/usr/bin/perl
use ExtUtils::testlib;
use Devel::Peek;
use Math::Random::Brownian;

printf "Creating Test.out\n";

open(OUT,">Test.out");
my $noise = Math::Random::Brownian->new();
my @ans = $noise->Hosking(LENGTH=>32, HURST => 0.5, VARIANCE => 1.0, NOISE => 'Gaussian');

foreach(@ans)
{
 printf OUT "$_\n";
}

printf OUT "\n\n";

@ans = $noise->Circulant(LENGTH=>32, HURST => 0.5, VARIANCE => 1.0, NOISE => 'Gaussian');

foreach(@ans)
{
 printf OUT "$_\n";
}

printf OUT "\n\n";

@ans = $noise->ApprCirc(LENGTH=>32, HURST => 0.5, VARIANCE => 1.0, NOISE => 'Gaussian');

foreach(@ans)
{
 printf OUT "$_\n";
}

printf OUT "\n\n";

@ans = $noise->Paxson(LENGTH=>32, HURST => 0.5, VARIANCE => 1.0, NOISE => 'Gaussian');

foreach(@ans)
{
 printf OUT "$_\n";
}

