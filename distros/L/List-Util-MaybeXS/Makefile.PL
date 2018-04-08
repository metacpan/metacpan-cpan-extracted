use strict;
use warnings;
use 5.006;
use lib 'inc';
use ExtUtils::HasCompiler qw(can_compile_loadable_object);

my %META = (
  name => 'List-Util-MaybeXS',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    build => { requires => {
    } },
    test => {
      requires => {
        'Test::More' => 0,
      },
    },
    runtime => {
      requires => {
      },
      suggests => {
        'List::Util' => '1.50',
      },
    },
    develop   => {
      requires => {
        'List::Util' => '1.50',
        'Test::Pod::Coverage' => '1.04',
        'Test::Pod' => '1.14',
        'Test::More' => '0.88',
      },
    },
  },
  resources => {
    repository => {
      url => 'https://github.com/haarg/List-Util-MaybeXS.git',
      web => 'https://github.com/haarg/List-Util-MaybeXS',
      type => 'git',
    },
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-MaybeXS',
      mailto => 'bug-List-Util-MaybeXS@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
);

my $want_lu = $META{prereqs}{runtime}{suggests}{'List::Util'};
my %MM_ARGS = (
  PREREQ_PM => {
    (
      (
        eval { require List::Util; List::Util->VERSION($want_lu) }
        or (
          !parse_args()->{PUREPERL_ONLY}
          and can_compile_loadable_object(quiet => 1)
        )
      ) ? ('List::Util' => $want_lu) : ()
    ),
  },
);

sub parse_args {
  require ExtUtils::MakeMaker;
  require Text::ParseWords;
  # copied from EUMM
  ExtUtils::MakeMaker::parse_args(
    my $tmp = {},
    Text::ParseWords::shellwords($ENV{PERL_MM_OPT} || ''),
    @ARGV,
  );
  return $tmp->{ARGS} || {};
}

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  my $r = $MM_ARGS{$key} = {
    %{$META{prereqs}{$_}{requires} || {}},
    %{delete $MM_ARGS{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} = {%{$MM_ARGS{BUILD_REQUIRES}}, %{delete $MM_ARGS{TEST_REQUIRES}}}
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} = {%{$MM_ARGS{PREREQ_PM}}, %{delete $MM_ARGS{BUILD_REQUIRES}}}
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
## END BOILERPLATE ###########################################################
