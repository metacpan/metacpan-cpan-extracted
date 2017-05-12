
use strict;
use warnings;

use Test::More;
use Test::File::ShareDir::Dist { 'Gentoo-Util-VirtualDepend' => 'share/' };
use Gentoo::Util::VirtualDepend;

# ABSTRACT: Test basic behaviour

my $v = Gentoo::Util::VirtualDepend->new( min_perl => '5.18.0', max_perl => '5.20.2' );

sub resolve_module {
  my ( $module, $version ) = @_;
  if ( $v->has_module_override($module) ) {
    return $v->get_module_override($module);
  }
  if ( $v->module_is_perl( $module, $version ) ) {
    return 'perl';
  }
  return 'CPAN';
}

# Hoisted from Dzil 5.034
my $data = {
  'configure' => {
    'requires' => {
      'ExtUtils::MakeMaker'     => '0',
      'File::ShareDir::Install' => '0.06'
    }
  },
  'develop' => {
    'requires' => {
      'Test::Pod' => '1.41'
    }
  },
  'runtime' => {
    'recommends' => {
      'Archive::Tar::Wrapper' => '0.15',
      'Term::ReadLine::Gnu'   => '0'
    },
    'requires' => {
      'App::Cmd::Command::version'                 => '0',
      'App::Cmd::Setup'                            => '0.309',
      'App::Cmd::Tester'                           => '0.306',
      'App::Cmd::Tester::CaptureExternal'          => '0',
      'Archive::Tar'                               => '0',
      'CPAN::Meta::Converter'                      => '2.101550',
      'CPAN::Meta::Merge'                          => '0',
      'CPAN::Meta::Prereqs'                        => '2.120630',
      'CPAN::Meta::Requirements'                   => '2.121',
      'CPAN::Meta::Validator'                      => '2.101550',
      'CPAN::Uploader'                             => '0.103004',
      'Carp'                                       => '0',
      'Class::Load'                                => '0.17',
      'Config::INI::Reader'                        => '0',
      'Config::MVP::Assembler'                     => '0',
      'Config::MVP::Assembler::WithBundles'        => '2.200010',
      'Config::MVP::Reader'                        => '2.101540',
      'Config::MVP::Reader::Findable::ByExtension' => '0',
      'Config::MVP::Reader::Finder'                => '0',
      'Config::MVP::Reader::INI'                   => '2',
      'Config::MVP::Section'                       => '2.200009',
      'Data::Dumper'                               => '0',
      'Data::Section'                              => '0.200002',
      'DateTime'                                   => '0.44',
      'Digest::MD5'                                => '0',
      'Encode'                                     => '0',
      'ExtUtils::Manifest'                         => '1.66',
      'File::Copy::Recursive'                      => '0',
      'File::Find::Rule'                           => '0',
      'File::HomeDir'                              => '0',
      'File::Path'                                 => '0',
      'File::ShareDir'                             => '0',
      'File::ShareDir::Install'                    => '0.03',
      'File::Spec'                                 => '0',
      'File::Temp'                                 => '0',
      'File::pushd'                                => '0',
      'JSON::MaybeXS'                              => '0',
      'List::MoreUtils'                            => '0',
      'List::Util'                                 => '1.33',
      'Log::Dispatchouli'                          => '1.102220',
      'Mixin::Linewise::Readers'                   => '0.100',
      'Module::CoreList'                           => '0',
      'Moose'                                      => '0.92',
      'Moose::Role'                                => '0',
      'Moose::Util::TypeConstraints'               => '0',
      'MooseX::LazyRequire'                        => '0',
      'MooseX::Role::Parameterized'                => '0',
      'MooseX::SetOnce'                            => '0',
      'MooseX::Types'                              => '0',
      'MooseX::Types::Moose'                       => '0',
      'MooseX::Types::Path::Class'                 => '0',
      'MooseX::Types::Perl'                        => '0',
      'PPI::Document'                              => '0',
      'Params::Util'                               => '0',
      'Path::Class'                                => '0.22',
      'Path::Tiny'                                 => '0.052',
      'Perl::PrereqScanner'                        => '1.016',
      'Perl::Version'                              => '0',
      'Pod::Eventual'                              => '0.091480',
      'Scalar::Util'                               => '0',
      'Software::License'                          => '0.101370',
      'Software::LicenseUtils'                     => '0',
      'Storable'                                   => '0',
      'String::Formatter'                          => '0.100680',
      'String::RewritePrefix'                      => '0.005',
      'Sub::Exporter'                              => '0',
      'Sub::Exporter::ForMethods'                  => '0',
      'Sub::Exporter::Util'                        => '0',
      'Term::Encoding'                             => '0',
      'Term::ReadKey'                              => '0',
      'Term::ReadLine'                             => '0',
      'Term::UI'                                   => '0',
      'Test::Deep'                                 => '0',
      'Text::Glob'                                 => '0.08',
      'Text::Template'                             => '0',
      'Try::Tiny'                                  => '0',
      'YAML::Tiny'                                 => '0',
      'autodie'                                    => '0',
      'namespace::autoclean'                       => '0',
      'parent'                                     => '0',
      'strict'                                     => '0',
      'version'                                    => '0',
      'warnings'                                   => '0'
    },
    'suggests' => {
      'PPI::XS' => '0'
    }
  },
  'test' => {
    'recommends' => {
      'CPAN::Meta' => '2.120900'
    },
    'requires' => {
      'CPAN::Meta::Check'        => '0.007',
      'CPAN::Meta::Requirements' => '2.121',
      'ExtUtils::MakeMaker'      => '0',
      'ExtUtils::Manifest'       => '1.66',
      'File::Spec'               => '0',
      'Software::License::None'  => '0',
      'Test::FailWarnings'       => '0',
      'Test::Fatal'              => '0',
      'Test::File::ShareDir'     => '0',
      'Test::More'               => '0.96',
      'lib'                      => '0',
      'utf8'                     => '0'
    }
  }
};

my @tc;

for my $phase ( sort keys %{$data} ) {
  my $phased = $data->{$phase};
  for my $rel ( sort keys %{$phased} ) {
    my $reld = $phased->{$rel};
    for my $module ( sort keys %{$reld} ) {
      my $module_version = $reld->{$module};
      push @tc, [ $module, $module_version, $phase . '_' . $rel ];
    }
  }
}

my %maps;
for my $case ( sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] || $a->[2] cmp $b->[2] } @tc ) {
  my $resolution = resolve_module( $case->[0], $case->[1] );
  $maps{$resolution} ||= [];
  push @{ $maps{$resolution} }, join q[, ], @{$case};
}
note explain \%maps;

cmp_ok( scalar @{ $maps{perl} }, '==', 4,  "Exactly 4 things mapped to perl" );
cmp_ok( scalar @{ $maps{CPAN} }, '==', 69, "Exactly 69 things mapped to some kind of CPAN distribution" );
delete $maps{perl};
delete $maps{CPAN};
cmp_ok( scalar keys %maps, '==', 20, "Exactly 20 overrides invoked" );

done_testing;

