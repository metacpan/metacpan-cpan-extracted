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

              , [k3 => json_type => 'T1']
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
      my $typeSpec = MOP4Import::Base::CLI_JSON->cli_json_type_of(t1::T1);

      my $json = $cjson->encode($rec, $typeSpec);

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

#
# Only one hash type can be specified in anyof at /usr/lib64/perl5/vendor_perl/Cpanel/JSON/XS/Type.pm line 293.
#
# {
#   {
#     package
#       t2;
#     use MOP4Import::Types +{}
#       , Item => [[fields => qw/foo bar baz/]]
#       , Tree => [[fields =>
#                   , [items => json_type => [hashof => [anyof => qw(Tree Item)]]]
#                 ]]
#       ;
#   }
# }

{
  {
    package
      t4;
    use MOP4Import::Types +{}
      , User => [[fields =>
                  , [id => json_type => 'int']
                  , [name => json_type => 'string']
                ]]
      ;
    use MOP4Import::Types +{basepkg => 'MOP4Import::Base::JSON'}
      , Message => [[fields =>
                     , [sender => json_type => User]
                     , [recipient => json_type => [arrayof => 'User']]
                   ]]
      ;
  }

  {
    my t4::User $from = +{}; $from->{id} = 1; $from->{name} = "Smith";
    my t4::User $alice = +{}; $alice->{id} = 2; $alice->{name} = "Alice";
    my t4::User $bob   = +{}; $bob->{id} = 3; $bob->{name} = "Bob";

    my $expected = q!{"recipient":[{"id":2,"name":"Alice"},{"id":3,"name":"Bob"}],"sender":{"id":1,"name":"Smith"}}!;

    {
      my t4::Message $msg = +{};
      $msg->{sender} = $from;
      $msg->{recipient} = [$alice, $bob];

      my $typeSpec = MOP4Import::Base::CLI_JSON->cli_json_type_of(t4::Message);
      my $json = $cjson->encode($msg, $typeSpec);

      is($json, $expected, "Nested hash - raw HASH $expected");
    }

    {
      my t4::Message $msg = t4::Message->new;
      $msg->{sender} = $from;
      $msg->{recipient} = [$alice, $bob];

      my $json = $msg->cli_encode_json($msg);

      is($json, $expected, "Nested hash - blessed Object: $expected");
    }


  }
}

done_testing;
