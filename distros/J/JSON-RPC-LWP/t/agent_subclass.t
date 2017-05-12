use warnings;
use strict;

use Test::More;

use JSON::RPC::LWP;
my $package = 'JSON::RPC::LWP';
my $dist    = 'JSON-RPC-LWP';
my $version = $JSON::RPC::LWP::VERSION;
my $default = "JSON-RPC-LWP/$version";

use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin,'lib');

use Util;

sub init_agent{
  my($package) = @_;
  no strict 'refs';

  my $version = ${$package.'::VERSION'};
  return "$package/$version" if defined $version;
  return $package;
}


### Create sub-classes ###

my $parent_package = $package;

my $test_with_version_package = 'MY::Test::WithVersion';
{
  package MY::Test::WithVersion;
  our @ISA = $parent_package;
  our $VERSION = '0.001';
}

my $test_without_version_package = 'MY::Test::NoVersion';
{
  package MY::Test::NoVersion;
  our @ISA = $parent_package;
}


### Test values ###

my @test_with_version;
{
  my $package = $test_with_version_package;

  my $init_agent = init_agent($package);

  @test_with_version = (
    [ undef, $init_agent ],
    [ 'testing' ],
    [ '' ],
    [ ' ', " $init_agent" ],
    [ 'testing ', "testing $init_agent" ],
    [ $init_agent ],
    [ $package ],
    [ $parent_package ],
    [ $dist ],
  );
}

my @test_without_version;
{
  my $package = $test_without_version_package;

  my $init_agent = init_agent($package);

  @test_without_version = (
    [ undef, $init_agent ],
    [ 'testing' ],
    [ '' ],
    [ ' ', " $init_agent" ],
    [ 'testing ', "testing $init_agent" ],
    [ $init_agent ],
    [ $package ],
    [ $parent_package ],
    [ $dist ],
  );
}


### Count tests ###

{
  my $init_count = test_on_initialize_count + test_after_initialize_count;
  my $tests_with_version    = 4 +  @test_with_version    * $init_count;
  my $tests_without_version = 4 + @test_without_version * $init_count;

  plan tests => $tests_with_version + $tests_without_version;
}


### Start testing ###

{
  note 'sub classing JSON::RPC::LWP with $VERSION';

  my $package = $test_with_version_package;
  my $init_agent = init_agent($package);
  my @test = @test_with_version;

  my $test = new_ok $package;
  isa_ok $test, $parent_package;
  is
    $test->_agent,
    $init_agent,
    'the ->_agent attribute is initialized with the new classname';
  is
    $test->agent,
    $init_agent,
    'the ->agent attribute is initialized with the new classname';

  for my $test (@test){
    my($init,$full) = @$test;

    test_on_initialize(    $package, $init_agent, $init, $full );
    test_after_initialize( $package, $init_agent, $init, $full );
  }
}

{
  note 'sub classing JSON::RPC::LWP without $VERSION';

  my $package = $test_without_version_package;
  my $init_agent = init_agent($package);
  my @test = @test_without_version;

  my $test = new_ok $package;
  isa_ok $test, $parent_package;
  is
    $test->_agent,
    $init_agent,
    'the ->_agent attribute is initialized with the new classname';
  is
    $test->agent,
    $init_agent,
    'the ->agent attribute is initialized with the new classname';

  for my $test (@test){
    my($init,$full) = @$test;

    test_on_initialize(    $package, $init_agent, $init, $full );
    test_after_initialize( $package, $init_agent, $init, $full );
  }
}
