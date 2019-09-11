#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use Test::More;

{
  if (do {eval {require Cpanel::JSON::XS}; $@}) {
    plan skip_all => "Cpanel::JSON::XS is missing: $@";
  }
  if (do {eval {require Cpanel::JSON::XS::Type}; $@}) {
    plan skip_all => "Cpanel::JSON::XS::Type is missing: $@";
  }
}

my $cjson = Cpanel::JSON::XS->new->canonical->allow_nonref;
if (my $sub = $cjson->can('require_types')) {
  $sub->($cjson);
}

{
  {
    package
      t1;
    use MOP4Import::Types
      T1 => [[fields =>
              , [k1 => json_type => 'string']
              , [k2 => json_type => 'int']

              , [k3 => json_type => 't1::T1']
              # Todo: Allow writing this as 'T1'
            ]]
      ;
  }

  {
    my t1::T1 $rec = +{};
    $rec->{k1} = 'string';
    $rec->{k2} = '10';
    $rec->{k3} = do {
      my t1::T1 $lv1 = +{};
      $lv1->{k1} = 'level1';
      $lv1->{k2} = '20';
      $lv1->{k3} = do {
        my t1::T1 $lv2 = +{};
        $lv2->{k1} = 'level2';
        $lv2->{k2} = 30;
        $lv2;
      };
      $lv1;
    };

    my $expect = '{"k1":"string","k2":10,"k3":'
      .'{"k1":"level1","k2":20,"k3":{"k1":"level2","k2":30}}}';

    {
      my $json = $cjson->encode(
        $rec,
        MOP4Import::Base::CLI_JSON->cli_json_type_of(t1::T1),
      );

      is($json, $expect, "Nested hash: $expect");
    }

    {
      {
        package
          ob1;
        use MOP4Import::Base::CLI_JSON -as_base;
      }

      my $obj1 = ob1->new;

      my $json = $obj1->cli_encode_json($rec, t1::T1);

      is($json, $expect, "Nested hash with cli_encode_json: $expect");
    }
  }
}


done_testing;
