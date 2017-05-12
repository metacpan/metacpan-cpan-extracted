#!/usr/bin/env perl

use v5.14.0;

use lib $ENV{HOME}.'/gcis/gcis-pl-client/lib';
use Gcis::Client;

my $gc = Gcis::Client->new()->connect(url => 'http://localhost:3000');

$gc->post(
  q[/image/prov/b229781f-3215-4a0c-945f-fd838c9fabea] => {
    delete => {
      'parent_uri' => '/dataset/ncep-ncar',
      'parent_rel' => 'prov:wasDerivedFrom'
    }
  }
) or say $gc->error;

say $gc->tx->res->to_string;

