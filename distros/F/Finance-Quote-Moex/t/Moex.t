# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-Quote-Moex.t'
 
#########################
 
#use encoding 'utf8';
use Test::More;
 
if(not $ENV{ONLINE_TEST}) {
        plan skip_all => 'Set $ENV{ONLINE_TEST} to run this test';
}
 
plan tests => 15;
 
use_ok('Finance::Quote');
use_ok('Finance::Quote::Moex');



my $quoter = Finance::Quote->new("Moex");
 
ok(defined $quoter, "created");

# OFZ test 

my $ticker_ofz="SU26205RMFS3"; # ОФЗ 26218

my %info = $quoter->fetch("moex_bond_ofz_nkd", $ticker_ofz);
ok(%info, "fetched");
ok($info{$ticker_ofz, "name"}, $ticker_ofz);

my %info = $quoter->fetch("moex_bond_ofz", $ticker_ofz);
ok(%info, "fetched");
ok($info{$ticker_ofz, "name"}, $ticker_ofz);

# bond test

my $ticker_ofz="RU000A0JU2L7"; # ФСК ЕЭС-27-об

my %info = $quoter->fetch("moex_bond_nkd", $ticker_ofz);
ok(%info, "fetched");
ok($info{$ticker_ofz, "name"}, $ticker_ofz);

my %info = $quoter->fetch("moex_bond", $ticker_ofz);
ok(%info, "fetched");
ok($info{$ticker_ofz, "name"}, $ticker_ofz);

# stock test
my $ticker="GAZP"; # Газпром

my %info = $quoter->fetch("moex_stock", $ticker);
ok(%info, "fetched");
ok($info{$ticker, "name"}, $ticker);

my %info = $quoter->fetch("micex", $ticker);
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
