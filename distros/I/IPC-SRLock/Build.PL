use strict;
use warnings;

use Module::Build 0.4202;

my $perl_ver = 5.010001;
my $name     = 'IPC-SRLock'; $name =~ s{ - }{::}gmx;
my $prereqs  = {
  'build_requires' => {
    'Module::Build' => '0.4202',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4202',
    'version' => '0.88'
  },
  'recommends' => {
    'Cache::Memcached' => '1.30'
  },
  'requires' => {
    'Class::Null' => '2.110730',
    'Date::Format' => '2.24',
    'Exporter::Tiny' => '0.042',
    'File::DataClass' => 'v0.66.0',
    'IPC::ShareLite' => '0.17',
    'Moo' => '2.000001',
    'Time::Elapsed' => '0.31',
    'Try::Tiny' => '0.22',
    'Type::Tiny' => '1.000005',
    'namespace::autoclean' => '0.26',
    'perl' => '5.010001'
  },
  'test_requires' => {
    'File::DataClass' => 'v0.66.0',
    'File::Spec' => '0',
    'Module::Build' => '0.4202',
    'Module::Metadata' => '0',
    'Sys::Hostname' => '0',
    'Test::Requires' => '0.06',
    'version' => '0.88'
  },
};
my $testing  = sub { $ENV{AUTOMATED_TESTING}
                  || $ENV{PERL_CPAN_REPORTER_CONFIG}
                  || $ENV{PERL5_CPANPLUS_IS_VERSION} };
my $whimper  = sub { print {*STDOUT} $_[ 0 ]."\n"; exit 0 };
my $stop     = sub {
   $testing->() or $whimper->( $_[ 0 ] );
   $prereqs->{build_requires} = { %{ $prereqs->{configure_requires} } };
   $prereqs->{test_requires } = { %{ $prereqs->{configure_requires} } };
   $prereqs->{test_requires }->{ 'Test::Requires' } = 0.06;
   delete $prereqs->{requires};
};
my $osname   = lc $^O; ($osname eq 'mswin32' or $osname eq 'cygwin')
   and delete $prereqs->{requires}->{ 'IPC::ShareLite' };

# Not interested in reports below min perl ver
$] < $perl_ver and $stop->( "Minimum required Perl version is ${perl_ver}" );

Module::Build->subclass( code => do { local $/; <DATA> } )->new(
   'module_name' => $name,
   'notes'       => { min_perl_version => $perl_ver, testing => $testing->() },
   %{ $prereqs },

)->create_build_script;

exit 0;

__DATA__

sub _added_to_INC { # CVE-2016-1238
  my $self = shift; my %seen;

  for ($self->_default_INC) { $seen{ $_ }++ }

  return grep { not $seen{ $_ }++ } $self->base_dir, @INC;
}
