#!perl
use strict ;

use Data::Dumper ;

use Test::More tests => 23;

## Check module loads ok
BEGIN { use_ok('Linux::DVB::DVBT') };

##### Linux::DVB::DVBT::Config - internal functions

## Find channel
my $pr1_href = 
        { 
          'audio' => "407",
          'audio_details' => "eng:407 und:408",
          'ca' => "0",
          'name' => "BBC ONE",
          'net' => "BBC",
          'pnr' => "19456",
          'running' => "4",
          'teletext' => "0",
          'tsid' => "16384",
          'type' => "1",
          'video' => "203",
        } ;
my $pr2_href = 
        { 
          'audio' => "409",
          'audio_details' => "eng:409",
          'ca' => "0",
          'name' => "BBC TWO",
          'net' => "BBC",
          'pnr' => "19457",
          'running' => "4",
          'teletext' => "0",
          'tsid' => "16384",
          'type' => "1",
          'video' => "204",
        } ;
my $pr5r_href = 
        { 
          'audio' => "4507",
          'audio_details' => "eng:407 und:408",
          'ca' => "0",
          'name' => "Fiver",
          'net' => "Five",
          'pnr' => "1234",
          'running' => "4",
          'teletext' => "0",
          'tsid' => "5678",
          'type' => "1",
          'video' => "203",
        } ;
my $pr5_href = 
        { 
          'audio' => "4508",
          'audio_details' => "eng:407 und:408",
          'ca' => "0",
          'name' => "Five",
          'net' => "Five",
          'pnr' => "1235",
          'running' => "4",
          'teletext' => "0",
          'tsid' => "6789",
          'type' => "1",
          'video' => "203",
        } ;

my $tsid1_href =
        { 
          'bandwidth' => "8",
          'code_rate_high' => "23",
          'code_rate_low' => "12",
          'frequency' => "713833330",
          'guard_interval' => "32",
          'hierarchy' => "0",
          'modulation' => "64",
          'net' => "Oxford/Bexley",
          'transmission' => "2",
          'tsid' => "16384",
        } ;
my $tsid5r_href =
        { 
          'bandwidth' => "8",
          'code_rate_high' => "23",
          'code_rate_low' => "34",
          'frequency' => "513833330",
          'guard_interval' => "32",
          'hierarchy' => "0",
          'modulation' => "64",
          'net' => "Oxford/Bexley1",
          'transmission' => "1",
          'tsid' => "5678",
        } ;
my $tsid5_href =
        { 
          'bandwidth' => "8",
          'code_rate_high' => "23",
          'code_rate_low' => "34",
          'frequency' => "513833330",
          'guard_interval' => "32",
          'hierarchy' => "0",
          'modulation' => "64",
          'net' => "Oxford/Bexley1",
          'transmission' => "1",
          'tsid' => "6789",
        } ;

my %tuning = (
    'pr' => 
    { 
        'BBC ONE' => $pr1_href,
        'BBC TWO' => $pr2_href,
        'Fiver' => $pr5r_href,
        'Five' => $pr5_href,
    },
    
    'ts' =>
    {
      "16384" => $tsid1_href,
      "5678" => $tsid5r_href,
      "6789" => $tsid5_href,
    }
) ;

my ($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('bbc1', \%tuning) ;
is_deeply($frontend_params_href, $tsid1_href) ;
is_deeply($demux_params_href, $pr1_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('B B C oNe', \%tuning) ;
is_deeply($frontend_params_href, $tsid1_href) ;
is_deeply($demux_params_href, $pr1_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('bbc two', \%tuning) ;
is_deeply($frontend_params_href, $tsid1_href) ;
is_deeply($demux_params_href, $pr2_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('bbc 2', \%tuning) ;
is_deeply($frontend_params_href, $tsid1_href) ;
is_deeply($demux_params_href, $pr2_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('bbc2', \%tuning) ;
is_deeply($frontend_params_href, $tsid1_href) ;
is_deeply($demux_params_href, $pr2_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('BBC2', \%tuning) ;
is_deeply($frontend_params_href, $tsid1_href) ;
is_deeply($demux_params_href, $pr2_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('fiver', \%tuning) ;
is_deeply($frontend_params_href, $tsid5r_href) ;
is_deeply($demux_params_href, $pr5r_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('five r', \%tuning) ;
is_deeply($frontend_params_href, $tsid5r_href) ;
is_deeply($demux_params_href, $pr5r_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('FiV     eR', \%tuning) ;
is_deeply($frontend_params_href, $tsid5r_href) ;
is_deeply($demux_params_href, $pr5r_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('5', \%tuning) ;
is_deeply($frontend_params_href, $tsid5_href) ;
is_deeply($demux_params_href, $pr5_href) ;

##
($frontend_params_href, $demux_params_href) = Linux::DVB::DVBT::Config::find_channel('Five', \%tuning) ;
is_deeply($frontend_params_href, $tsid5_href) ;
is_deeply($demux_params_href, $pr5_href) ;

##




