#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
no warnings 'once';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Test::RequiresInternet;
use Test::More;
use Test::Differences;
use Encode qw{encode};
use Mail::BIMI::Prelude;
use Mail::BIMI::App;
use App::Cmd::Tester;
use File::Slurp qw{ read_file write_file };
use Net::DNS::Resolver::Mock;

unless ($ENV{AUTHOR_TESTS}) {
  plan(skip_all => 'CMD Output tests skipped');
}

my $write_data = $ENV{MAIL_BIMI_TEST_WRITE_DATA} // 0; # Set to 1 to write new test data, then check it and commit

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
$Mail::BIMI::TestSuite::Resolver = $resolver;

#subtest 'Bare' => sub {
#
#  subtest 'Bare' => sub{
#    my $file = 'app-bare';
#    my $result = test_app(Mail::BIMI::App->new => [ qw{ } ]);
#    do_tests($result,$file);
#  };
#
#  subtest 'Help' => sub{
#    my $file = 'app-bare-help';
#    my $result = test_app(Mail::BIMI::App->new => [ qw{ --help } ]);
#    do_tests($result,$file);
#  };
#
#};

subtest 'checkdomain' => sub {

  subtest 'Help' => sub{
    my $file = 'app-checkdomain-help';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkdomain --help } ]);
    do_tests($result,$file);
  };

  subtest 'No Domain' => sub{
    my $file = 'app-checkdomain-nodomain';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkdomain } ]);
    do_tests($result,$file);
  };

  subtest 'Has Domain' => sub{
    my $file = 'app-checkdomain-fastmaildmarc';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkdomain fastmaildmarc.com } ]);
    do_tests($result,$file);
  };

  subtest 'Multi Domain' => sub{
    my $file = 'app-checkdomain-multi';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkdomain fastmaildmarc.com fastmail.com } ]);
    do_tests($result,$file);
  };

  subtest 'SVG Profile (Tiny 1.2)' => sub{
    my $file = 'app-checkdomain-profile-tiny';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkdomain', '--profile', 'Tiny-1.2', 'fastmaildmarc.com' ]);
    do_tests($result,$file);
  };

  subtest 'SVG Profile (BIMI 1.2)' => sub{
    my $file = 'app-checkdomain-profile-bimi';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkdomain', '--profile', 'SVG_1.2_BIMI', 'fastmaildmarc.com' ]);
    do_tests($result,$file);
  };

  subtest 'SVG Profile (Bad Profile)' => sub{
    my $file = 'app-checkdomain-profile-bad';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkdomain', '--profile', 'Bogus-1.2', 'fastmaildmarc.com' ]);
    do_tests($result,$file);
  };

};

subtest 'checkrecord' => sub {

  subtest 'Help' => sub{
    my $file = 'app-checkrecord-help';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkrecord --help } ]);
    do_tests($result,$file);
  };

  subtest 'No Record' => sub{
    my $file = 'app-checkrecord-norecord';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checkrecord } ]);
    do_tests($result,$file);
  };

  subtest 'Has (Bogus) Record' => sub{
    my $file = 'app-checkrecord-bogus';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkrecord', 'v=bimi1;l=http://bogus' ]);
    do_tests($result,$file);
  };

  subtest 'Multiple Records' => sub{
    my $file = 'app-checkrecords-multi';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkrecord', 'v=bimi1;l=http://bogus', 'v=bimi1;l=http://bogus2' ]);
    do_tests($result,$file);
  };

  subtest 'SVG Profile (Tiny 1.2)' => sub{
    my $file = 'app-checkrecord-profile-tiny';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkrecord', '--profile', 'Tiny-1.2', 'v=bimi1;l=' ]);
    do_tests($result,$file);
  };

  subtest 'SVG Profile (BIMI 1.2)' => sub{
    my $file = 'app-checkrecord-profile-bimi';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkrecord', '--profile', 'SVG_1.2_BIMI', 'v=bimi1;l=' ]);
    do_tests($result,$file);
  };

  subtest 'SVG Profile (Bad Profile)' => sub{
    my $file = 'app-checkrecord-profile-bad';
    my $result = test_app(Mail::BIMI::App->new => [ 'checkrecord', '--profile', 'Bogus-1.2', 'v=bimi1;l=' ]);
    do_tests($result,$file);
  };

};

subtest 'checksvg' => sub {

  subtest 'Help' => sub{
    my $file = 'app-checksvg-help';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checksvg --help } ]);
    do_tests($result,$file);
  };

  subtest 'No SVG' => sub{
    my $file = 'app-checksvg-nosvg';
    my $result = test_app(Mail::BIMI::App->new => [ qw{ checksvg } ]);
    do_tests($result,$file);
  };

  subtest 'Test SVG (URI)' => sub{
    local $ENV{MAIL_BIMI_SVG_FROM_FILE} = 't/data/FM-good.svg'; # Fake getting SVG from internet
    my $file = 'app-checksvg-uri';
    my $result = test_app(Mail::BIMI::App->new => [ 'checksvg', 'https://fastmaildmarc.com/FM_BIMI.svg' ]);
    do_tests($result,$file);
  };

  subtest 'Test SVG (File)' => sub{
    my $file = 'app-checksvg-file';
    my $result = test_app(Mail::BIMI::App->new => [ 'checksvg', '--fromfile', 't/data/FM-good.svg' ]);
    do_tests($result,$file);
  };

  subtest 'Test SVG (File Tiny 1.2)' => sub{
    my $file = 'app-checksvg-file-tiny';
    my $result = test_app(Mail::BIMI::App->new => [ 'checksvg', '--profile', 'Tiny-1.2', '--fromfile', 't/data/FM-good.svg' ]);
    do_tests($result,$file);
  };

  subtest 'Test SVG (File Bad Profile)' => sub{
    my $file = 'app-checksvg-file-badprofile';
    my $result = test_app(Mail::BIMI::App->new => [ 'checksvg', '--profile', 'Bogus-1.2', '--fromfile', 't/data/FM-good.svg' ]);
    do_tests($result,$file);
  };

  subtest 'Multiple URIs' => sub{
    my $file = 'app-checksvg-file-multi';
    my $result = test_app(Mail::BIMI::App->new => [ 'checksvg', 'uri-one', 'uri-two' ]);
    do_tests($result,$file);
  };

};

# TODO when we have test data checkvmc

sub do_tests{
  my ($result,$file) = @_;
  my $error = encode('UTF-8',$result->error//'');
  my $stderr = encode('UTF-8',$result->stderr//'');
  my $stdout = encode('UTF-8',$result->stdout//'');
  if ( $write_data ) {
    write_file('t/data/'.$file.'.error',{binmode=>':utf8:'},$result->error);
    write_file('t/data/'.$file.'.stderr',{binmode=>':utf8:'},$result->stderr);
    write_file('t/data/'.$file.'.stdout',{binmode=>':utf8:'},$result->stdout);
  }
  my $expected_error=scalar read_file('t/data/'.$file.'.error');
  my $expected_stderr=scalar read_file('t/data/'.$file.'.stderr');
  my $expected_stdout=scalar read_file('t/data/'.$file.'.stdout');
  eq_or_diff($error, $expected_error, 'No Exceptions as expected');
  eq_or_diff($stderr, $expected_stderr, 'STDERR as expected');
  eq_or_diff($stdout, $expected_stdout,'STDOUT as expected');
};

done_testing;

