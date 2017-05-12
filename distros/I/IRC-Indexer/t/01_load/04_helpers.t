use Test::More tests => 23;
use strict; use warnings;
use File::Spec;

BEGIN {
  use_ok( 'IRC::Indexer::Logger') ;
  use_ok( 'IRC::Indexer::Conf') ;
}

## IRC::Indexer::Logger

my $logobj = new_ok( 'IRC::Indexer::Logger' => [ LogFile => 
  File::Spec->devnull 
]);
isa_ok( $logobj->logger, 'Log::Handler' );
$logobj = undef;

$logobj = new_ok( 'IRC::Indexer::Logger' => [ DevNull => 1 ] );
my $logger = $logobj->logger;
ok( $logger->add(screen => { log_to => "STDOUT", maxlevel => "debug" }),
  "Add logger to STDOUT"
);

my $stdout;
{
  local *STDOUT;
  open STDOUT, '>', \$stdout
    or die $!;
  $logger->warn("Warning");
  $logger->info("Information");
  $logger->debug("Debug");
  close STDOUT or die $!;
}
ok( $stdout, "Got log on STDOUT" );

my @lines = split /\n/, $stdout;
is(scalar @lines, 3, "Got warn, info, debug" );

## IRC::Indexer::Conf

new_ok( 'IRC::Indexer::Conf' );

my $mycf = <<CONF;
---
Scalar: "String"
Array:
  - one
  - two
Hash:
  Key: value

CONF

my $fh;
ok( open($fh, '<', \$mycf), 'Scalar FH open' );
my $cf;
ok( $cf = IRC::Indexer::Conf->parse_conf($fh), 'parse_conf()' );
close $fh;
is_deeply( $cf,
  {
    Scalar => "String",
    Array  => [ "one", "two" ],
    Hash   => { Key => "value" },
  },
  'parse_conf() compare'
);
$fh = undef;
$cf = undef;

my($htcf, $speccf);
ok( $htcf = IRC::Indexer::Conf->get_example_cf('httpd'),
  "Get example HTTPD conf" 
);
ok( $speccf = IRC::Indexer::Conf->get_example_cf('spec'),
  "Get example specfile"
);

ok( open($fh, '<', \$htcf), 'HTTPD conf open' );
ok( $cf = IRC::Indexer::Conf->parse_conf($fh), 'HTTPD parse_conf()' );
close $fh;
ok( defined $cf->{NetworkDir}, "HTTPD conf has NetworkDir" );
$fh = undef;
$cf = undef;

ok( open($fh, '<', \$speccf), 'Server spec open' );
ok( $cf = IRC::Indexer::Conf->parse_conf($fh), 'Specfile parse_conf()' );
close $fh;
ok( defined $cf->{Network}, 'Server spec has Network' );

$fh = undef;
$cf = undef;
ok( open($fh, '>', \$cf), 'Output FH open' );
ok( IRC::Indexer::Conf->write_example_cf('httpd', $fh), 
  'write_example_cf() to scalar FH'
);
like( $cf, qr/^---/, 'write_example_cf() looks like YAML' );
