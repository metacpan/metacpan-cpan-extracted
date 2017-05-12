use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %WriteMakefileArgs = (
  NAME => 'JSON::MaybeXS',
  VERSION_FROM => 'lib/JSON/MaybeXS.pm',

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 1,
    resources => {
      # GitHub mirrors from Shadowcat. We list it so we can get pull requests.
      # The canonical repo is:
      # r/o: git://git.shadowcat.co.uk/p5sagit/JSON-MaybeXS.git
      # r/w: p5sagit@git.shadowcat.co.uk:JSON-MaybeXS.git
      # web: http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/JSON-MaybeXS.git
      repository => {
        url => 'https://github.com/p5sagit/JSON-MaybeXS.git',
        web => 'https://github.com/p5sagit/JSON-MaybeXS',
        type => 'git',
      },
      bugtracker => {
        mailto => 'bug-JSON-MaybeXS@rt.cpan.org',
        web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=JSON-MaybeXS',
      },
    },
    x_contributors => [ # manually added, from git shortlog -e -s -n
      'Clinton Gormley <develop@traveljury.com>',
      'Graham Knop <haarg@haarg.org>',
      'John SJ Anderson <genehack@genehack.org>',
      'Karen Etheridge <ether@cpan.org>',
      'Kieren Diment <diment@gmail.com>',
      'Matt S Trout <mst@shadowcat.co.uk>',
    ],
    keywords => [ qw(json serializer serialiser data) ],
  },

  META_ADD => {
    'meta-spec' => { version => 2 },
    prereqs => {
      configure => {
        requires => {
          'ExtUtils::MakeMaker' => '0',
          'ExtUtils::CBuilder' => '0.27',
          'File::Spec' => '0',
          'File::Temp' => '0',
        },
      },
      runtime => {
        requires => {
          'Scalar::Util' => '0',
          'Carp' => '0',
          'JSON::PP' => '2.27300',
          # we may also add a runtime prereq for Cpanel::JSON::XS, on the
          # installer's machine
          perl => '5.006',
        },
        recommends => { 'Cpanel::JSON::XS' => '2.3310' },
      },
      test => {
        requires => {
          'Test::More' => '0.88',
        },
      },
    },
  },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
           or exists $WriteMakefileArgs{$key};
  my $r = $WriteMakefileArgs{$key} = {
    %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
    %{delete $WriteMakefileArgs{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

my $args = parse_args();

if (not $args->{PUREPERL_ONLY}) {
    # we require Cpanel::JSON::XS, except if JSON::XS is already installed.
    # (we also always recommend Cpanel::JSON::XS, just to make sure.)
    $WriteMakefileArgs{PREREQ_PM}{'Cpanel::JSON::XS'} = '2.3310'
        if eval { require Cpanel::JSON::XS; 1 }
            or (not eval { require JSON::XS; 1; } and can_xs());

    # JSON::XS 3 changed its boolean handling - update it
    # if JSON::XS is installed and < 3.0
    $WriteMakefileArgs{PREREQ_PM}{'JSON::XS'} = '3.00'
        if eval { require JSON::XS; 1 } and not eval { JSON::XS->VERSION('3.0'); 1 };
}

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

die 'attention developer: you need to do a sane meta merge here!'
  if keys %{$WriteMakefileArgs{BUILD_REQUIRES}};

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
  if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
  if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
  if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);


sub parse_args {
  # copied from EUMM
  require ExtUtils::MakeMaker;
  require Text::ParseWords;
  ExtUtils::MakeMaker::parse_args(
    my $tmp = {},
    Text::ParseWords::shellwords($ENV{PERL_MM_OPT} || ''),
    @ARGV,
  );
  return $tmp->{ARGS} || {};
}

# can we locate a (the) C compiler
sub can_cc {
  my @chunks = split(/ /, $Config::Config{cc}) or return;

  # $Config{cc} may contain args; try to find out the program part
  while (@chunks) {
    return can_run("@chunks") || (pop(@chunks), next);
  }

  return;
}

# check if we can run some command
sub can_run {
  my ($cmd) = @_;

  return $cmd if -x $cmd;
  if (my $found_cmd = MM->maybe_command($cmd)) {
    return $found_cmd;
  }

  require File::Spec;
  for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    next if $dir eq '';
    my $abs = File::Spec->catfile($dir, $cmd);
    return $abs if (-x $abs or $abs = MM->maybe_command($abs));
  }

  return;
}

# Can our C compiler environment build XS files
sub can_xs {
  # Do we have the configure_requires checker?
  local $@;
  eval "require ExtUtils::CBuilder; ExtUtils::CBuilder->VERSION(0.27)";
  if ( $@ ) {
    # They don't obey configure_requires, so it is
    # someone old and delicate. Try to avoid hurting
    # them by falling back to an older simpler test.
    return can_cc();
  }

  # Do we have a working C compiler
  my $builder = ExtUtils::CBuilder->new(
    quiet => 1,
  );
  unless ( $builder->have_compiler ) {
    # No working C compiler
    return 0;
  }

  # Write a C file representative of what XS becomes
  require File::Temp;
  my ( $FH, $tmpfile ) = File::Temp::tempfile(
    "compilexs-XXXXX",
    SUFFIX => '.c',
  );
  binmode $FH;
  print $FH <<'END_C';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main(int argc, char **argv) {
    return 0;
}

int boot_sanexs() {
    return 1;
}

END_C
  close $FH;

  # Can the C compiler access the same headers XS does
  my @libs   = ();
  my $object = undef;
  eval {
    local $^W = 0;
    $object = $builder->compile(
      source => $tmpfile,
    );
    @libs = $builder->link(
      objects     => $object,
      module_name => 'sanexs',
    );
  };
  my $result = $@ ? 0 : 1;

  # Clean up all the build files
  foreach ( $tmpfile, $object, @libs ) {
    next unless defined $_;
    1 while unlink;
  }

  return $result;
}
