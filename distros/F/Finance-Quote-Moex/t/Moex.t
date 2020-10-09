# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-Quote-Moex.t'
 
#########################
 
#use encoding 'utf8';
use Test::More;
 
if(not $ENV{ONLINE_TEST}) {
        plan skip_all => 'Set $ENV{ONLINE_TEST} to run this test';
}
 
plan tests => 9;
 
use_ok('Finance::Quote');
use_ok('Finance::Quote::Moex');


my $quoter = Finance::Quote->new("Moex");
 
ok(defined $quoter, "created");

# bond tplus test 

my $ticker_ofz="SU26205RMFS3"; # ОФЗ 26218

my %info = $quoter->fetch("moex_bond_tplus", $ticker_ofz);
ok(%info, "fetched");
ok($info{$ticker_ofz, "name"}, $ticker_ofz);

my %info = $quoter->fetch("moex_bond_tplus_nkd", $ticker_ofz);
ok(%info, "fetched");
ok($info{$ticker_ofz, "name"}, $ticker_ofz);

# stock test
my $ticker="GAZP"; # Газпром

my %info = $quoter->fetch("moex_stock", $ticker);
ok(%info, "fetched");
ok($info{$ticker, "name"}, $ticker);


##!/usr/bin/perl -w

# use Finance::Quote;
# 
# my $module = "Moex";
# 
# my $method = "moex_bond_ofz_nkd";
# 
# 
# my $quoter = Finance::Quote->new($module);
# 
# 
# my $ticker="SU26205RMFS3"; # ОФЗ 26218
# 
# 
# my %info = $quoter->fetch($method, $ticker); 
# print "$ticker: \n";
# print "   date: $info{$ticker,'date'}\n";
# print "   price: $info{$ticker,'price'}\n";
# print "   currency: $info{$ticker,'currency'} \n";
# print "   isodate: $info{$ticker,'isodate'} \n";
