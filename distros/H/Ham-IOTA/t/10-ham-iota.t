# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-04-28 23:35:11 +0100 (Sun, 28 Apr 2013) $
# Id:            $Id: 10-ham-iota.t 160 2013-04-28 22:35:11Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/iotamarathon/trunk/t/10-ham-iota.t $
#
use strict;
use warnings;
use Test::More tests => 2;

our $PKG = 'Ham::IOTA';
use_ok($PKG);

{
  my $iota   = $PKG->new;
  my $parsed = $iota->parse('t/data/iota-fulllist-short.xml');

  is_deeply($parsed, [
		      {
		       'grpref'    => 'AF-001',
		       'grpname'   => 'Agalega Islands',
		       'dxcc_name' => 'AGALEGA & ST BRANDON',
		       'dxcc_id'   => '4',
		       'islands'   => [{'name' => 'Agalega Islands', 'id' => '00012428'},
				       {'name' => 'North',           'id' => '00000493'},
				       {'name' => 'South',           'id' => '00000492'},],
		      },
		      {
		       'grpref'    => 'AF-002',
		       'grpname'   => 'Amsterdam & St Paul Islands',
		       'dxcc_name' => 'AMSTERDAM & ST PAUL',
		       'dxcc_id'   => '10',
		       'islands'   => [{'name' => 'Amsterdam',   'id' => '00000491'},
				       {'name' => 'Deux Freres', 'id' => '00000490'},
				       {'name' => 'Milieu',      'id' => '00000489'},
				       {'name' => 'Nord',        'id' => '00000488'},
				       {'name' => 'Ouest',       'id' => '00000487'},
				       {'name' => 'Phoques',     'id' => '00000486'},
				       {'name' => 'Quille',      'id' => '00000485'},
				       {'name' => 'St Paul',     'id' => '00000484'},],
		      },
		      {
		       'grpref'    => 'AF-003',
		       'grpname'   => 'Ascension Island',
		       'dxcc_name' => 'ASCENSION ISLAND',
		       'dxcc_id'   => '205',
		       'islands'   => [{'name' => 'Ascension',      'id' => '00000483'},
				       {'name' => 'Boatswain-bird', 'id' => '00000482'},],
		      }
		     ], 'deep parsed data');
}
