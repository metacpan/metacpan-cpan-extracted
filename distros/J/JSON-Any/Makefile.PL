# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.030.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "(DEPRECATED) Wrapper Class for the various JSON classes",
  "AUTHOR" => "Chris Thompson <cthom\@cpan.org>, Chris Prather <chris\@prather.org>, Robin Berjon <robin\@berjon.com>, Marc Mims <marc\@questright.com>, Tomas Doran <bobtfish\@bobtfish.net>",
  "CONFIGURE_REQUIRES" => {
    "CPAN::Meta::Requirements" => "2.120620",
    "ExtUtils::MakeMaker" => 0,
    "Module::Metadata" => 0
  },
  "DISTNAME" => "JSON-Any",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "JSON::Any",
  "PREREQ_PM" => {
    "Carp" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Data::Dumper" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Storable" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.88",
    "Test::Needs" => 0,
    "Test::Warnings" => "0.009",
    "Test::Without::Module" => 0,
    "open" => 0,
    "utf8" => 0
  },
  "VERSION" => "1.40",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Storable" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "0.88",
  "Test::Needs" => 0,
  "Test::Warnings" => "0.009",
  "Test::Without::Module" => 0,
  "constant" => 0,
  "open" => 0,
  "strict" => 0,
  "utf8" => 0,
  "warnings" => 0
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.040
sub has_json () {
    our @order = qw(CPANEL XS PP JSON DWIW);
    foreach my $testmod (@order) {
        $testmod = "JSON::$testmod" unless $testmod eq "JSON";
        $testmod = "Cpanel::JSON::XS" if $testmod eq "JSON::CPANEL";
        return 1 if has_module($testmod);
    }
    return 0;
}
if (has_json) {
    # we have some kind of supported JSON module, we're good
}
else {
    # we need to have a version of JSON, go with JSON::PP as a sane default
    requires('JSON::PP')
}


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.040
sub _add_prereq {
  my ($mm_key, $module, $version_or_range) = @_;
  $version_or_range ||= 0;
  warn "$module already exists in $mm_key (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $WriteMakefileArgs{$mm_key}{$module}
      and $WriteMakefileArgs{$mm_key}{$module} ne '0'
      and $WriteMakefileArgs{$mm_key}{$module} ne $version_or_range;
  warn "$module already exists in FallbackPrereqs (at version $FallbackPrereqs{$module}) -- need to do a sane metamerge!"
    if exists $FallbackPrereqs{$module} and $FallbackPrereqs{$module} ne '0'
        and $FallbackPrereqs{$module} ne $version_or_range;
  $WriteMakefileArgs{$mm_key}{$module} = $FallbackPrereqs{$module} = $version_or_range;
  return;
}

sub has_module {
  my ($module, $version_or_range) = @_;
  require Module::Metadata;
  my $mmd = Module::Metadata->new_from_module($module);
  return undef if not $mmd;
  return $mmd->version($module) if not defined $version_or_range;

  require CPAN::Meta::Requirements;
  my $req = CPAN::Meta::Requirements->new;
  $req->add_string_requirement($module => $version_or_range);
  return 1 if $req->accepts_module($module => $mmd->version($module));
  return 0;
}

sub requires { goto &runtime_requires }

sub runtime_requires {
  my ($module, $version_or_range) = @_;
  _add_prereq(PREREQ_PM => $module, $version_or_range);
}
