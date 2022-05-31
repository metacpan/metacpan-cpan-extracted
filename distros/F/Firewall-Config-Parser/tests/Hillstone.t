#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use Mojo::Util qw(dumper);
my $name = File::Basename::basename($0);
use 5.018;
use utf8;
use Firewall::Config::Content::Static;
use Firewall::Config::Element::Service::Hillstone;
my $usage = "$name type file\ntype: 1 => 'Netscreen', 2 => 'Srx', 3 => 'Asa',4=>Fortinet\n";

my %types = (
  1 => 'Netscreen',
  2 => 'Srx',
  3 => 'Asa',
  4 => 'Fortinet'
);
my $fwId = 7;

my ($file) = @ARGV;
if ( scalar @ARGV < 1 ) {
  print("ERROR: 缺少输入参数\n");
  print $usage;
  exit;
}

my $conf;
my $fwType = "Hillstone";
open( my $FH, "< $file" ) or die $!;
$conf = Firewall::Config::Content::Static->new(
  config => [<$FH>],
  fwId   => $fwId,
  fwName => 'test',
  fwType => $fwType
);
close $FH;

=pod
my $predefinedService = {
'HTTP' => Firewall::Config::Element::Service::Hillstone->new( srvName => 'http', protocol => 'tcp', srcPort => '0-65535', dstPort => '80'),
'HTTPS' => Firewall::Config::Element::Service::Hillstone->new( srvName => 'https', protocol => 'tcp', srcPort => '0-65535', dstPort => '443'),
'Any'  => Firewall::Config::Element::Service::Hillstone->new( srvName => 'Any', protocol => '0', srcPort => '0-65535', dstPort => '0-65535'),
'PING' => Firewall::Config::Element::Service::Hillstone->new( srvName => 'PING', protocol => 'icmp', srcPort => '0-65535', dstPort => '0-65535'),
};
=cut

use Firewall::DBI::Pg;
my $dbi = Firewall::DBI::Pg->new(
  host     => 'dbhost',
  port     => 5432,
  dbname   => 'firewall',
  user     => 'postgres',
  password => 'postgres'
);
my $predefinedService;
use Firewall::Config::Dao::PredefinedService::Hillstone;
$predefinedService = Firewall::Config::Dao::PredefinedService::Hillstone->new( dbi => $dbi );
$predefinedService = $predefinedService->load(23);

my $parser;
eval(
  "use Firewall::Config::Parser::$fwType; \$parser = Firewall::Config::Parser::$fwType->new(config => \$conf, preDefinedService => \$predefinedService);"
);
die $@ if $@;

$parser->parse();
say dumper $parser->{elements};

=pod
use Storable;

#my $serializedParser = Storable::freeze($parser);
#$dbi->execute("update test123 set serialized_parser = :serializedParser where fw_id = 1",
#           {serializedParser => $serializedParser});
                   # bind_type => [serializedParser => DBI::SQL_BLOB]); #注意这里 bind_type 是绑在变量名 serializedParser 上，而非字段名 serialized_parser 上


Storable::store ($parser,'404Forti');
#open my $f_h,'>404ser';
#print $f_h $serParser;
=cut
