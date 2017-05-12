# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-02-18 22:58:09 +0000 (Mon, 18 Feb 2013) $
# Id:            $Id: 10-ham-dxcc.t 66 2013-02-18 22:58:09Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/iotamarathon/trunk/t/10-ham-dxcc.t $
#
use strict;
use warnings;
use Test::More tests => 2;

our $PKG = 'Ham::DXCC';
use_ok($PKG);

{
  my $dxcc     = $PKG->new;
  my $parsed   = $dxcc->parse('t/data/dxcc-cty-short.xml');
  my $expected = {
                  'exceptions' => [
                                   {
                                    'cqz' => '5',
                                    'adif' => '1',
                                    'lat' => '45.00',
                                    'entity' => 'CANADA',
                                    'record' => '1051',
                                    'cont' => 'NA',
                                    'long' => '-80.00',
                                    'call' => '3C3EUP',
                                    'ituz' => '9'
                                   },
                                   {
                                    'cqz' => '5',
                                    'adif' => '1',
                                    'lat' => '45.00',
                                    'end' => '2007-05-20T23:59:59+00:00',
                                    'entity' => 'CANADA',
                                    'record' => '12762',
                                    'cont' => 'NA',
                                    'long' => '-80.00',
                                    'call' => '4Y1CAO',
                                    'ituz' => '9',
                                    'start' => '2007-05-17T00:00:00+00:00'
                                   }
                                  ],
                  'invalid_operations' => [
                                           {
                                            'record' => '12167',
                                            'call' => 'P7CZE'
                                           },
                                           {
                                            'record' => '9908',
                                            'call' => 'AM2AAC',
                                            'end' => '2010-05-15T23:59:59+00:00',
                                            'start' => '2010-05-08T00:00:00+00:00'
                                           }
                                          ],
                  'prefixes' => [
                                 {
                                  'cqz' => '26',
                                  'adif' => '247',
                                  'lat' => '8.80',
                                  'entity' => 'SPRATLY IS.',
                                  'record' => '3',
                                  'cont' => 'AS',
                                  'long' => '111.90',
                                  'call' => '1S',
                                  'ituz' => '50'
                                 },
                                 {
                                  'cqz' => '26',
                                  'adif' => '247',
                                  'lat' => '8.80',
                                  'entity' => 'SPRATLY IS.',
                                  'record' => '4',
                                  'cont' => 'AS',
                                  'long' => '111.90',
                                  'call' => '9M0',
                                  'ituz' => '50'
                                 }
                                ],
                  'zone_exceptions' => [
                                        {
                                         'record' => '61',
                                         'call'   => 'KD6WW/VY0',
                                         'end'    => '2006-07-18T00:00:00+00:00',
                                         'start'  => '2005-09-01T00:00:00+00:00',
                                         'zone'   => 1,
                                        },
                                        {
                                         'record' => '236',
                                         'call'   => 'VG1JA',
                                         'start'  => '1991-02-01T00:00:00+00:00',
                                         'zone'   => 1,
                                        }
                                       ]
                 };
  is_deeply($parsed, $expected, q[parsed DXCC/cty.xml]);
}
