use strict;
use warnings FATAL => 'all';
use 5.006;

my %META = (
  name => 'Devel-Confess',
  license => 'perl_5',
  dynamic_config => 0,
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    build => { requires => {
    } },
    test => { requires => {
      'File::Temp'  => 0,
      'Test::More'  => 0,
      'Safe'        => 0,
      'Cwd'         => 0,
      'File::Spec'  => 0,
      'IPC::Open3'  => 0,
    } },
    runtime => { requires => {
      'perl' => '5.006',
      'Carp' => 0,
      'Scalar::Util' => 0,
    } },
    develop => { requires => {
      'Exception::Class'  => 0,
      'Ouch'              => 0,
      'Class::Throwable'  => 0,
      'Exception::Base'   => 0,
    } },
  },
  resources => {
    repository => {
      url => 'git://github.com/haarg/Devel-Confess',
      web => 'https://github.com/haarg/Devel-Confess',
      type => 'git',
    },
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Confess',
      mailto => 'bug-Devel-Confess@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
);

my %MM_ARGS = ();

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
