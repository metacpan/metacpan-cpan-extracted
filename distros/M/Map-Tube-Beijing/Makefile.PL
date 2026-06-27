use strict;
use ExtUtils::MakeMaker 6.64;
use File::ShareDir::Install;

my $mod_name     =  'Map::Tube::Beijing';
my $mod_file     =  'lib/' . $mod_name . '.pm';
$mod_file        =~ s|::|/|g;
my $mod_distname =  $mod_name;
$mod_distname    =~ s|::|-|g;
my $mod_version  = MM->parse_version($mod_file);

install_share dist => 'share';

WriteMakefile(
  NAME               => $mod_name,
  AUTHOR             => q{Gisbert W. Selke <gws@cpan.org>},
  VERSION_FROM       => $mod_file,
  ABSTRACT_FROM      => $mod_file,
  LICENSE            => 'artistic_2',
  PL_FILES           => { },
  MIN_PERL_VERSION   => 5.014,
  CONFIGURE_REQUIRES => {
                          'ExtUtils::MakeMaker'     => 6.64,
                          'File::ShareDir::Install' => 0,
                        },
  TEST_REQUIRES      => { 'Test::More' => 0.82, },
  PREREQ_PM          => {
                          'Moo'              => 0,
                          'namespace::clean' => 0,
                          'File::Share'      => 0,
                          'Map::Tube'        => v5.0.1,
                        },
  dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean              => { FILES    => $mod_distname . '-*', },
  META_MERGE         => {
                          'meta-spec'    => { version => 2 },
                          dynamic_config => 0,
                          prereqs        => {
                                              test => {
                                                        recommends => {
                                                                        'Test::CheckManifest'    => 0.9,
                                                                        'Test::CPAN::Changes'    => 0,
                                                                        'Test::CPAN::Meta::JSON' => 0,
                                                                        'Test::CPAN::Meta'       => 0,
                                                                        'Test::Kwalitee'         => 0,
                                                                        'Test::Map::Tube'        => 0,
                                                                        'Test::Pod'              => 1.22,
                                                                        'Test::Pod::Coverage'    => 1.0,
                                                                        'Test::Version'          => 0,
                                                                        'XML::Twig'              => 0,
                                                                        'Graph'                  => 0,
                                                                      },
                                                      },
                                            },
                          provides       => {
                                              $mod_name => {
                                                             file    => $mod_file,
                                                             version => $mod_version,
                                                           },
                                            },
                          resources      => {
                                              repository => {
                                                              type => 'git',
                                                              url  => 'https://github.com/gwselke/' . $mod_distname . '.git',
                                                              web  => 'https://github.com/gwselke/' . $mod_distname,
                                                            },
                                              bugtracker => {
                                                               web => 'https://github.com/gwselke/' . $mod_distname . '/issues'
                                                             },
                                            },
                        },
);

package MY;
use File::ShareDir::Install;

sub postamble {
  my $self = shift;
  my @ret  = File::ShareDir::Install::postamble($self);
  push @ret, <<"MAKEFILE";
sigstore-sign:
\t\@echo "Signing distribution with Sigstore..."
\tcosign sign-blob \$(DISTVNAME).tar.gz --bundle \$(DISTVNAME).tar.gz.sigstore.json
MAKEFILE
  return join( "\n", @ret );
}
