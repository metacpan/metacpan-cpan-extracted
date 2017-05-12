use Data::Dumper;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Getopt-ApacheCommonsCLI.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 64;
BEGIN { use_ok( 'Getopt::ApacheCommonsCLI', qw(GetOptionsApacheCommonsCLI OPT_PREC_UNIQUE OPT_PREC_LEFT_TO_RIGHT OPT_PREC_RIGHT_TO_LEFT), ) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

   my $DEBUG = 1;

# These are somewhat scattered tests based on Cassandra nodetool behavior, rather than module-specific coverage, though
# there is still benefit from doing a bunch of tests.

# use Cassandra nodetool options for a real-world example to parse

   my @spec = ("include-all-sstables|a",
               "column-family|cf:s",
               "compact|c",
               "in-dc|dc:s",
               "host|h:s",
               "hosts|in-host:s",
               "ignore|i",
               "local|in-local",
               "no-snapshot|ns",
               "parallel|par",
               "partitioner-range|pr",
               "port|p:i",
               "resolve-ip|r",
               "skip-corrupted|s",
               "tag|t:s",
               "tokens|T",
               "username|u:s",
               "password|pw:s",
               "start-token|st:s",
               "end-token|et:s",
   );

   my %ambiguous = ( cf  => "column-family",
                     dc  => "in-dc",
                     et  => "end-token",
                     par => "parallel",
                     pr  => "partitioner-range",
                     pw  => "password",
                     st  => "start-token",
   );

sub do_err {
   my ($option, $value) = @_;
   
   if (not defined $value or $value eq '') {
      print "Missing argument for option:$option\n";
   }
   else {
      print "Incorrect value, precedence or duplicate option for option:$option:$value\n";
   }
   
   return 0;
}

   my %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 0, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-h 10.0.0.2 -T -t 1001 -u john -pw 123456 -- cmd1 cmd2";
   my %opts; # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'host'} eq '10.0.0.2', 'host');
ok($opts{'tokens'} eq '1', 'tokens');
ok($opts{'tag'} eq '1001', 'tag');
ok($opts{'username'} eq 'john', 'username');
ok($opts{'password'} eq '123456', 'password');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 0, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-h 10.0.0.2 -T -t 1001 -u john -pw 123456 -- cmd1 cmd2";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'__argv__'} eq '-- cmd1 cmd2', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 0, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "--h 10.0.0.2 --T --t 1001 --u john --pw 123456 cmd1 cmd2";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'host'} eq '10.0.0.2', 'host');
ok($opts{'tokens'} eq '1', 'tokens');
ok($opts{'tag'} eq '1001', 'tag');
ok($opts{'username'} eq 'john', 'username');
ok($opts{'password'} eq '123456', 'password');
ok($opts{'__argv__'} eq 'cmd1 cmd2', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 0, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-host 10.0.0.2 -tokens -tag 1001 -username john -password 123456 cmd1 cmd2";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'host'} eq '10.0.0.2', 'host');
ok($opts{'tokens'} eq '1', 'tokens');
ok($opts{'tag'} eq '1001', 'tag');
ok($opts{'username'} eq 'john', 'username');
ok($opts{'password'} eq '123456', 'password');
ok($opts{'__argv__'} eq 'cmd1 cmd2', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 0, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "--host 10.0.0.2 --tokens --tag 1001 --username john --password 123456 cmd1 cmd2";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'host'} eq '10.0.0.2', 'host');
ok($opts{'tokens'} eq '1', 'tokens');
ok($opts{'tag'} eq '1001', 'tag');
ok($opts{'username'} eq 'john', 'username');
ok($opts{'password'} eq '123456', 'password');
ok($opts{'__argv__'} eq 'cmd1 cmd2', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 0, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-aT cmd1 cmd2";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'include-all-sstables'} eq '', 'include-all-sstables');

ok($opts{'tokens'} eq '', 'tokens');
ok($opts{'__argv__'} eq '-aT cmd1 cmd2', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-aT cmd1 cmd2";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'include-all-sstables'} eq '1', 'include-all-sstables');
ok($opts{'tokens'} eq '1', 'tokens');
ok($opts{'__argv__'} eq 'cmd1 cmd2', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-pw 123456 cmd1 cmd2";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'password'} eq '123456', 'password');
ok($opts{'port'} ne '0', 'port');
ok($opts{'__argv__'} eq 'cmd1 cmd2', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-aT -pw 123456";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'include-all-sstables'} eq '1', 'include-all-sstables');
ok($opts{'tokens'} eq '1', 'tokens');
ok($opts{'password'} eq '123456', 'password');
ok($opts{'port'} ne '0', 'port');
ok($opts{'__argv__'} eq '', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-pw 123456 --password 456";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 0, 'result');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 1, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-pw 123456 -Dabc=x.y.z  -DX=1234";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'password'} eq '123456', 'password');
ok($opts{'abc'} eq 'x.y.z', '-D1');
ok($opts{'X'} eq '1234', '-D2');
ok($opts{'__argv__'} eq '', 'args');

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 1, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-- -pw 123456 -Dabc=x.y.z  -DX=1234";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'password'} ne '123456', 'password');
ok($opts{'abc'} ne 'x.y.z', '-D1');
ok($opts{'X'} ne '1234', '-D2');
ok($opts{'__argv__'} eq '-- -pw 123456 -Dabc=x.y.z -DX=1234', 'args');
print Dumper(\%opts);

   %options = ( DEBUG => $DEBUG, JAVA_DOPTS => 0, OPT_PRECEDENCE => OPT_PREC_UNIQUE, BUNDLING => 1, AMBIGUITIES => \%ambiguous, );
   (@ARGV)=split / +/, "-pw 123456 -Dabc=x.y.z  -DX=1234";
   %opts=(); # output hash
   my $result = GetOptionsApacheCommonsCLI(\@spec, \%opts, \%options, \&do_err);

ok($result == 1, 'result');
ok($opts{'password'} eq '123456', 'password');
ok($opts{'abc'} ne 'x.y.z', '-D1');
ok($opts{'X'} ne '1234', '-D2');
ok($opts{'__argv__'} eq '-Dabc=x.y.z -DX=1234', 'args');

# end
