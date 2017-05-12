use Test::More tests => 15;

use HTTP::Cookies::Mozilla;
use Data::Dumper;

use lib 't';
use TestSqliteCmd;

my %Domains = qw( .ebay.com 2 .usatoday.com 3 );

check('t/cookies.txt', 'plain text');

SKIP: {    # FF3, using DBI
   eval {
      require DBI;
      require DBD::SQLite;
   } or skip('DBI/DBD::SQLite not installed', 5);
   check('t/cookies.sqlite', 'DBI/DBD::SQLite');
} ## end SKIP:

SKIP: {    # FF3, using sqlite executable
   my ($prg, $error) = TestSqliteCmd::which_sqlite();
   skip($error, 5) unless $prg;

   $HTTP::Cookies::Mozilla::SQLITE = $prg;
   {       # force complaining from DBI
      no warnings;
      *DBI::connect = sub { die 'oops!' };
   }

   check('t/cookies.sqlite', "external program $prg");
} ## end SKIP:

sub check {
   my ($file, $condition) = @_;

   my $jar = HTTP::Cookies::Mozilla->new(File => $file);
   isa_ok($jar, 'HTTP::Cookies::Mozilla');

   my $hash = $jar->{COOKIES};

   my $domain_count = keys %$hash;
   is($domain_count, 2, "Count of cookies ($condition)");

   foreach my $domain (keys %Domains) {
      my $domain_hash = $hash->{$domain}{'/'};
      my $count       = keys %$domain_hash;
      is($count, $Domains{$domain}, "$domain has $count cookies ($condition)");
   }

   is($hash->{'.ebay.com'}{'/'}{'lucky9'}[1],
      '88341', "Cookie has right value ($condition)");
} ## end sub check
