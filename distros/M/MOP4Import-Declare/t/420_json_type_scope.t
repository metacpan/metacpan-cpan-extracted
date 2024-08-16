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

#========================================

use MOP4Import::Base::JSON;

{
  use MOP4Import::Types
    T1 => [[fields =>
            , [k1 => json_type => 'string']
            , [k2 => json_type => 'int']
          ]]
    ;

  BEGIN {
    # Force typename confliction (This can't happen normally, I guess)
    $MOP4Import::Util::JSON_TYPE::JSON_TYPES{'T1'}
      = $MOP4Import::Util::JSON_TYPE::JSON_TYPES{'main::T1'};
  }

  {
    package inner1;
    use MOP4Import::Types
      T1 => [[fields =>
              [k3 => json_type => 'bool']
            ]],
      X1 => [[fields =>
              , [kx => json_type => 'T1']
            ]]
      ;
  }

  {
    my $typeSpec = MOP4Import::Base::JSON->cli_json_type_of(inner1::X1);

    is_deeply($typeSpec, {kx => {k3 => Cpanel::JSON::XS::Type::JSON_TYPE_BOOL}})
  }

}

#========================================
done_testing;
