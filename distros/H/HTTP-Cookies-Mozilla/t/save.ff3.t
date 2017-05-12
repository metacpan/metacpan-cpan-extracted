use Test::More tests => 8;
use Text::Diff;

use HTTP::Cookies::Mozilla;

use lib 't';
use TestSqliteCmd;

my $dist_file = 't/cookies.sqlite';
my $save_file = 't/cookies2.sqlite';
my $txt_file1 = 't/cookies2.former';
my $txt_file2 = 't/cookies2.later';
END { -e $_ && unlink $_ for $save_file, $txt_file1, $txt_file2 }

SKIP: {
   eval {
      require DBI;
      require DBD::SQLite;
   } or skip('DBI/DBD::SQLite not installed', 4);
   check("DBI/DBD::SQLite");
} ## end SKIP:

SKIP: {    # FF3, using sqlite executable
   my ($prg, $error) = TestSqliteCmd::which_sqlite();
   skip($error, 4) unless $prg;

   $HTTP::Cookies::Mozilla::SQLITE = $prg;
   {       # force complaining from DBI
      no warnings;
      *DBI::connect = sub { die 'oops!' };
   }

   check("external program $prg");
} ## end SKIP:

sub check {
   my ($condition) = @_;

   my %Domains = qw( .ebay.com 2 .usatoday.com 3 );

   my $jar = HTTP::Cookies::Mozilla->new(File => $dist_file);
   isa_ok($jar, 'HTTP::Cookies::Mozilla');

   my $result = $jar->save($save_file);
   ok(-s $save_file, "something was saved, actually ($condition)");

   $jar->save($txt_file1);

   my $jar2 = HTTP::Cookies::Mozilla->new(File => $save_file);
   isa_ok($jar2, 'HTTP::Cookies::Mozilla');

   $jar2->save($txt_file2);

   my $diff = Text::Diff::diff($txt_file1, $txt_file2);
   my $same = not $diff;
   ok($same, "Saved file is same as original ($condition)");
   print STDERR $diff;

   # clean up for next call to check, if any
   -e $_ && unlink $_ for $save_file, $txt_file1, $txt_file2;

   return;
}
