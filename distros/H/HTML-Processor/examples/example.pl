#!/usr/bin/perl

use strict;
use CGI;
use HTML::Processor;

my $tpl = new HTML::Processor;
my $cgi = new CGI;

my $sortby 	= $cgi->param('sort');


my %countries = (
    'South Africa' => {
            id          => 1,
            population  => '41.465',
            currency    => 'Rand',
            capital     => 'Pretoria',
            area        => '1,123,226',
            languages   => [qw(Afrikaans English Zulu Sotho Xhosa Ndebele Pedi Swazi Tsonga Tswana Venda)]
            },
    'United Kingdom' => {
            id          => 2,
            population  => '58.586',
            currency    => 'Pound',
            capital     => 'London',
            area        => '244,110',
            languages   => [qw(English Welsh Scots-Gaelic)]
            },
    'USA' => {
            id          => 3,
            population  => '263.057',
            currency    => 'Dollar',
            capital     => 'Washington DC',
            area        => '9,529,063',
            languages   => [qw(English Spanish)]
            },
    'Italy' => {
            id          => 3,
            population  => '57.386',
            currency    => 'Lire',
            capital     => 'Rome',
            area        => '301,277',
            languages   => [qw(Italian Sardinian)]
            },
    'Australia' => {
            id          => 4,
            population  => '18.025',
            currency    => 'Australian dollar',
            capital     => 'Canberra',
            area        => '7,682,300',
            languages   => [qw(English Aboriginal)]
            },            
);


my $ctr = $tpl->new_loop("countries");
foreach my $country( keys %countries){
	$ctr->array("name",         $country);
    $ctr->array("id",           $countries{$country}{id});
    $ctr->array("population",   $countries{$country}{population});
    $ctr->array("currency",     $countries{$country}{currency});
    $ctr->array("capital",      $countries{$country}{capital});
    $ctr->array("area",         $countries{$country}{area});
    
	my $lang = $tpl->new_loop("languages", $countries{$country}{id});
    foreach (@{ $countries{$country}{languages} } ){
        $lang->array("name", $_);
    }
}

$tpl->variable("hour", (localtime)[2]);
$tpl->variable("time", scalar localtime);


$tpl->variable("this", "then");
$tpl->option("inner", 0);
$tpl->option("outer", 1);

$tpl->sort($sortby);

print $cgi->header;
print $tpl->process("templates/countries.html");
