# This Makefile.PL for IO-Socket-CLI was generated by
# Dist::Zilla::Plugin::MakeMaker::Awesome 0.27.
# Don't edit it but the dist.ini and plugins used to construct it.

use strict;
use warnings;

use 5.006;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "CLI for IO::Socket::INET6 and IO::Socket::SSL",
  "AUTHOR" => "Ashley Willis <ashley+perl\@gitable.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "IO-Socket-CLI",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "IO::Socket::CLI",
  "PREREQ_PM" => {
    "Carp" => 0,
    "IO::Socket::INET6" => 0,
    "IO::Socket::SSL" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "0.041",
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Carp" => 0,
  "IO::Socket::INET6" => 0,
  "IO::Socket::SSL" => 0,
  "Test::More" => 0,
  "strict" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

# modified from code in Crypt-SSLeay-0.58
my ($host, $port);
sub write_test_config {
    open OUT, '> test.config' or die "Cannot write test config: $!";
    if (is_live_test_wanted()) {
        print OUT "network_tests 1\n";
        print OUT "host $host\n";
        print OUT "port $port\n";
    } else {
        print OUT "network_tests 0\n";
    }
    close OUT or die "Cannot write test.config: $!";
    return;
}

# modified from code in Crypt-SSLeay-0.58
sub is_live_test_wanted {
    print <<"INFO";
The test suite can attempt to connect to an IMAP server on
port 143 to ensure that the code is working properly. If you
don't have an IMAP server on port 143, these tests will fail
(through no fault of the code).
INFO
    my $wanted = prompt "Do you want to run the live tests (y/N)?", 'N';
    ($wanted) = $wanted =~ /\Ay(?:es)?/i;
    if ($wanted) {
        $host = prompt "Enter host for tests (blank for 127.0.0.1)", '127.0.0.1';
        $port = prompt "Enter port for tests (blank for 143)", 143;
    }
    return $wanted;
}

write_test_config();
