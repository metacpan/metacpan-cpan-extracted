use strict;
use warnings FATAL => 'all';

my %META = (
  name => 'Import-Into',
  license => 'perl_5',
  dynamic_config => 0,
  resources => {
    # r/w: p5sagit@git.shadowcat.co.uk:Import-Into.git
    repository => {
      url => 'git://git.shadowcat.co.uk/p5sagit/Import-Into.git',
      web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=p5sagit/Import-Into.git',
      type => 'git',
    },
    bugtracker => {
        mailto => 'bug-Import-Into@rt.cpan.org',
        web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Import-Into',
    },
  },
  prereqs => {
    configure => {
      requires => {
        'ExtUtils::MakeMaker' => 0,
      },
    },
    runtime => {
      requires => {
        'strict' => '0',
        'warnings' => '0',
        'Module::Runtime' => '0',
        'perl' => '5.006',
      },
    },
    test => {
      requires => {
        'Exporter' => '0',
        'base' => '0',
        'Test::More' => '0',
      },
    },
  },
);

my %MM_ARGS = (
);

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

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
