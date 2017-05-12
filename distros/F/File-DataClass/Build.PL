use strict;
use warnings;

use Module::Build 0.4004;

my $perl_ver = 5.010001;
my $name     = 'File-DataClass'; $name =~ s{ - }{::}gmx;
my $prereqs  = {
  'build_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'requires' => {
    'Cache::FastMmap' => '1.40',
    'Class::Null' => '2.110730',
    'File::Path' => '2.09',
    'File::ReadBackwards' => '1.05',
    'Hash::Merge' => '0.200',
    'JSON::MaybeXS' => '1.003',
    'Module::Pluggable' => '5.1',
    'Module::Runtime' => '0.014',
    'Moo' => '2.000001',
    'Sub::Install' => '0.928',
    'Subclass::Of' => '0.003',
    'Try::Tiny' => '0.22',
    'Type::Tiny' => '1.000002',
    'Unexpected' => 'v0.39.0',
    'boolean' => '0.45',
    'namespace::autoclean' => '0.26',
    'namespace::clean' => '0.25',
    'perl' => '5.010001'
  },
  'test_requires' => {
    'Capture::Tiny' => '0.30',
    'File::Spec' => '0',
    'File::pushd' => '1.00',
    'Module::Build' => '0.4004',
    'Module::Metadata' => '0',
    'Path::Tiny' => '0.013',
    'Sys::Hostname' => '0',
    'Test::Deep' => '0.117',
    'Test::Requires' => '0.06',
    'Text::Diff' => '1.37',
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
