#!/usr/bin/env perl

# run with $ GLOG="yourglogserver" perl scripts/log.pl
use strict;
use warnings;
use Curses::UI;

use Data::Dumper;
use JSON::Tiny qw(encode_json);
use Data::Faker;

use Log::Log4perl;



use Log::Log4perl::DataDumper;
use Log::Log4perl::Appender::ScreenColoredLevels;
use Log::Log4perl::Appender::Graylog;

use Log::Log4perl::Layout::PatternLayout;
use Log::Log4perl::Layout::SimpleLayout;
use Log::Log4perl::Layout::NoopLayout;
my $config = <<"END";
log4perl.logger = DEBUG, SERVER, Screen
log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.color.DEBUG=bold blue
log4perl.appender.Screen.stderr = 1
log4perl.appender.Screen.stdout = 0
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = [%d] [%-5p] [%c %X{IP}] %m%n
log4perl.appender.Screen.utf8 = 1
log4perl.appender.SERVER          = Log::Log4perl::Appender::Graylog
log4perl.appender.SERVER.layout = NoopLayout
log4perl.appender.SERVER.PeerAddr = $ENV{'GLOG'}
log4perl.appender.SERVER.PeerPort = 12201
log4perl.appender.SERVER.Gzip    = 1
log4perl.appender.SERVER.Chunked = wan
END

Log::Log4perl->reset();
Log::Log4perl->init_once(\$config);

my $log = Log::Log4perl->get_logger("meh");
Log::Log4perl::DataDumper::override( $log, 0);
my $faker = Data::Faker->new();
use List::Util 'shuffle';
my @methods = $faker->methods;
while(1)
{

    
    my %data;
    
    @methods = shuffle  @methods;


      for (@methods)
      {
       $data{$_} = $faker->$_();
       }
      
    my $l = {};
    $l->{'json'}  = encode_json(\%data);
    $l->{'dumper'} = Dumper(%data);
    $l->{raw} = \%data;
    $log->debug($l);
    sleep(2);
    $log->info($faker->name);
    sleep(2);
}

