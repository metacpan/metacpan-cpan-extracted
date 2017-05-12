# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-12-26 22:25:17 +0000 (Thu, 26 Dec 2013) $
# Id:            $Id: 10-ham-adif.t 344 2013-12-26 22:25:17Z rmp $
# $HeadURL: svn+ssh://psyphi.net/repository/svn/iotamarathon/trunk/t/10-ham-adif.t $
#
use strict;
use warnings;
use Test::More tests => 7;

our $PKG = 'Ham::ADIF';
use_ok($PKG);

{
  my $adif    = Ham::ADIF->new;
  my $records = $adif->parse_file(q[t/data/example.adx], q[t/data/adx302.xsd]);
  is_deeply($records, [
                       {
                        shoesize       => '11',
                        time_on        => '1523',
                        qso_date       => '19900620',
                        epc            => '',
                        mode           => 'RTTY',
                        band           => '20M',
                        freq           => '',
                        sweatersize    => 'M',
                        call           => 'VK9NS',
                        iota           => '',
                        iota_island_id => '',
                        dxcc           => '',
                       },
                       {
                        shoesize       => '',
                        time_on        => '0111',
                        qso_date       => '20101022',
                        epc            => '32123',
                        mode           => 'PSK63',
                        band           => '40M',
                        freq           => '',
                        sweatersize    => '',
                        call           => 'ON4UN',
                        iota           => '',
                        iota_island_id => '',
                        dxcc           => '',
                       }
                      ], 'ADIF parsing: standard + user-defined fields processed');
}

{
  my $adif    = Ham::ADIF->new;
  my $records = $adif->parse_file(q[t/data/example2.adi]);
  is_deeply($records, [
                       {
                        'cqz' => '20',
                        'swl' => 'N',
                        'qso_date' => '20120101',
                        'dxcc' => '45',
                        'mode' => 'RTTY',
                        'band' => '12m',
                        'rst_sent' => '59',
                        'force_init' => 'N',
                        'operator' => 'F4BKV',
                        'iota' => 'EU-001',
                        'qsl_sent' => 'N',
                        'call' => 'SV5BYR/5',
                        'ms_shower' => 'N',
                        'time_on' => '1407',
                        'own_gridsq' => 'IN95PT',
                        'qsl_rcvd' => 'N',
                        'name' => 'MIKE',
                        'freq' => '24.926',
                        'rnd_meteors' => 'N',
                        'cont' => 'EU',
                        'rst_rcvd' => '59',
                        'ituz' => '28'
                       },
                       {
                        'cqz' => '14',
                        'swl' => 'N',
                        'qso_date' => '20130510',
                        'dxcc' => '279',
                        'mode' => 'SSB',
                        'band' => '20m',
                        'rst_sent' => '59',
                        'force_init' => 'N',
                        'operator' => 'F4BKV',
                        'iota' => 'EU-008',
                        'qsl_sent' => 'N',
                        'call' => 'GS3PYE/P',
                        'ms_shower' => 'N',
                        'time_on' => '1955',
                        'qsl_rcvd' => 'N',
                        'freq' => '14.256',
                        'rnd_meteors' => 'N',
                        'cont' => 'EU',
                        'rst_rcvd' => '59',
                        'ituz' => '27'
                       }
                      ], 'ADI parsing: real example file from F4BKV');
}

{
  my $adif    = Ham::ADIF->new;
  my $records = $adif->parse_file(q[t/data/VE3LYC-iota-marathon.adi]);
  is_deeply($records->[0], {
                            'time_off' => '003200',
                            'cont' => 'NA',
                            'app_logger32_qso_number' => '1',
                            'time_on' => '003200',
                            'call' => 'K6VVA/7',
                            'mode' => 'CW',
                            'band' => '20M',
                            'dxcc' => '291',
                            'iota' => 'NA-065',
                            'rst_rcvd' => '599',
                            'freq' => '14.000000',
                            'pfx' => 'K7',
                            'cqz' => '4',
                            'rst_sent' => '599',
                            'ituz' => '7',
                            'qso_date' => '20120101',
                           }, 'VE3LYC ClubLog QSO_DATE:8:D data type');
}

{
  my $adif    = Ham::ADIF->new;
  my $records = $adif->parse_file(q[t/data/JA1NLX-iota-marathon.adi]);
  is_deeply($records->[0], {
                            distance => '8810.08',
                            band => '20M',
                            call => 'K6VVA/7',
                            cont => 'NA',
                            cqz => '3',
                            dxcc => '291',
                            freq => '14.040000',
                            iota => 'NA-065',
                            ituz => '6',
                            mode => 'CW',
                            operator => 'JA1NLX',
                            pfx => 'K7',
                            qsl_sent => 'Y',
                            qslmsg => 'GL in 2012',
                            qslsdate => '20120104',
                            qso_date => '20120101',
                            time_on => '011911',
                            rst_rcvd => '599',
                            rst_sent => '599',
                            k_index => '3',
                            time_off => '011911',
                            tx_pwr => '100w',
                            sfi => '141',
                            a_index => '10',
                            lotw_qsl_sent => 'Y',
                            app_logger32_qso_number => '30030',
                           }, 'JA1NLX log without header - first record');
  is((scalar @{$records}), 4, 'JA1NLX log without header - number of records');
}


{
  my $adif    = Ham::ADIF->new;
  my $records = $adif->parse_file(q[t/data/SV8IIR.adi]);
  is_deeply($records->[0], {
                            adif_ver         => '1.00',
                            station_callsign => 'SV8IIR',
                            call             => 'VK8NSB',
                            qso_date         => '20120101',
                            time_on          => '091324',
                            time_off         => '091827',
                            freq             => '28.12000',
                            mode             => 'PSK31',
                            submode          => 'BPSK',
                            rst_rcvd         => '599',
                            rst_sent         => '599',
                            name             => 'STUART',
                            qth              => ' Australia',
                            cnty             => ' Australia',
                            iota             => 'OC-001',
                            qsl_sent         => 'N',
                            qsl_rcvd         => 'N',
                           });
}
