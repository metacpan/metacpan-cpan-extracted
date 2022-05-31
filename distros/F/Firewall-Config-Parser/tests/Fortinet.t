#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use Mojo::Util qw(dumper);
my $name = File::Basename::basename($0);
use 5.018;

use Firewall::Config::Content::Static;
use Firewall::Config::Element::Service::Fortinet;
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
my $fwType = "Fortinet";
open( my $FH, "< $file" ) or die $!;
$conf = Firewall::Config::Content::Static->new(
  config => [<$FH>],
  fwId   => $fwId,
  fwName => 'test',
  fwType => $fwType
);
close $FH;

#my $predefinedService = {
#'http' => Firewall::Config::Element::Service::Fortinet->new( fwId =>22222, srvName => 'http', protocol => 'tcp', srcPort => '0-65535', dstPort => '80'),
#};
use Firewall::DBI::Pg;
my $dbi = Firewall::DBI::Pg->new(
  host     => 'dbhost',
  port     => 5432,
  dbname   => 'firewall',
  user     => 'postgres',
  password => 'postgres'
);
my $predefinedService;
use Firewall::Config::Dao::PredefinedService::Fortinet;
$predefinedService = Firewall::Config::Dao::PredefinedService::Fortinet->new( dbi => $dbi );
$predefinedService = $predefinedService->load(404);

my $parser;
eval(
  "use Firewall::Config::Parser::$fwType; \$parser = Firewall::Config::Parser::$fwType->new(config => \$conf, preDefinedService => \$predefinedService);"
);
die $@ if $@;
$parser->{vdom} = 'root';

$parser->parse();
say dumper $parser->elements->{service};

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
