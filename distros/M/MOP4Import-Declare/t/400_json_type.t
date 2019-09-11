#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use Test::More;

{
  {
    package
      t1;
    use MOP4Import::Base::CLI_JSON -as_base;
    {
      package t1::Object;
      use MOP4Import::Base::Configure -as_base;
      sub TO_JSON {+{%{shift()}}}
    }
    use MOP4Import::Types +{basepkg => 't1::Object'}
      , T1 => [[fields =>
                , [e1 => json_type => 'int']
                , [e2 => json_type => 'int']
                , [e3 => json_type => 'string']
              ]]
      ;
  }
  my $enc = t1->new;
  my $test = sub {
    my ($data, $expect, $theme) = @_;
    is($enc->cli_encode_json($data), $expect, "$theme: $expect");
  };
  {
    $test->(t1::T1->new(e1 => 10, e2 => "10", e3 => 10.25)
            , '{"e1":10,"e2":10,"e3":"10.25"}', 'has TO_JSON');
  }
}

{
  {
    package
      t2;
    use MOP4Import::Base::CLI_JSON -as_base;
    use MOP4Import::Types
      T2 => [[fields =>
              , [e1 => json_type => 'int']
              , [e2 => json_type => 'int']
              , [e3 => json_type => 'string']
            ]]
      ;
  }

  {
    use JSON::MaybeXS;
    my t2::T2 $t2 = +{};
    @{$t2}{qw(e1 e2 e3)} = (10, "10", 10.25);
    my $expect = '{"e1":10,"e2":10,"e3":"10.25"}';
    my $json = JSON()->new->canonical->allow_nonref # ->require_types
      ->encode($t2, MOP4Import::Util::JSON_TYPE->lookup_json_type(t2::T2));
    is($json, $expect, "raw HASH: $expect");
  }

  {
    my $enc = t2->new;

    my t2::T2 $t2 = fields::new(t2::T2);
    @{$t2}{qw(e1 e2 e3)} = (10, "10", 10.25);
    my $expect = '{"e1":10,"e2":10,"e3":"10.25"}';
    is($enc->cli_encode_json(+{%$t2}, t2::T2)
       , $expect, "plain fields::new: $expect");
  }
}

{
  {
    package
      t3;
    use MOP4Import::Base::CLI_JSON -as_base;
    use MOP4Import::Types +{basepkg => 't2::T2'}
      , T3 => [[fields =>
              , [e4 => json_type => 'int']
            ]]
      ;
  }

  {
    use JSON::MaybeXS;
    my t3::T3 $t3 = +{};
    @{$t3}{qw(e1 e2 e3 e4)} = (10, "10", 10.25, "12");
    my $expect = '{"e1":10,"e2":10,"e3":"10.25","e4":12}';
    my $json = JSON()->new->canonical->allow_nonref # ->require_types
      ->encode($t3, MOP4Import::Util::JSON_TYPE->lookup_json_type(t3::T3));
    is($json, $expect, "raw HASH: $expect");
  }

  {
    my $enc = t3->new;

    my t3::T3 $t3 = fields::new(t3::T3);
    @{$t3}{qw(e1 e2 e3 e4)} = (10, "10", 10.25, "13");
    my $expect = '{"e1":10,"e2":10,"e3":"10.25","e4":13}';
    is($enc->cli_encode_json(+{%$t3}, t3::T3)
       , $expect, "plain fields::new: $expect");
  }
}

done_testing;

