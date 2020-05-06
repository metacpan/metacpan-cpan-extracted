use strict;
use warnings FATAL => 'all';
use 5.006;
use lib 'inc';
use ExtUtils::HasCompiler qw(can_compile_loadable_object);
use ExtUtils::MakeMaker;

my %META = (
  name => 'JSON-MaybeXS',
  license => 'perl_5',
  dynamic_config => 1,
  prereqs => {
    configure => {
      requires => {
        'ExtUtils::MakeMaker' => '0',
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
    license => [ 'http://dev.perl.org/licenses/' ],
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
  no_index => {
    directory => [ 't', 'xt' ]
  },
);

my %MM_ARGS = ();

## DYNAMIC PREREQS ###########################################################

if (! parse_args()->{PUREPERL_ONLY} && can_compile_loadable_object(quiet => 1)) {
  $MM_ARGS{PREREQ_PM}{'Cpanel::JSON::XS'} = '2.3310';
}

use Text::ParseWords;

sub parse_args {
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
$MM_ARGS{PL_FILES} ||= {};
$MM_ARGS{NORECURS} = 1
  if not exists $MM_ARGS{NORECURS};

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
