use strict;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

my $mod_name     =  'Map::Tube::KoelnBonn';
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
	MIN_PERL_VERSION   => 5.10.0,
    CONFIGURE_REQUIRES => {
                            'ExtUtils::MakeMaker'     => 6.64,
                            'File::ShareDir::Install' => 0,
                          },
    TEST_REQUIRES      => {
                            'Test::More'  => 0.82,
                            'XML::Simple' => 0,
                          },
    PREREQ_PM          => {
                            'Moo'              => 0,
                            'namespace::clean' => 0,
                            'File::Share'      => 0,
							'Map::Tube'        => 3.77,
                          },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean              => { FILES => 'Map-Tube-KoelnBonn-*', },
    META_MERGE         => {
                            'meta-spec' => { version => 2 },
                            dynamic_config => 0,
                            provides    => {
                                             $mod_name => {
                                                            file    => $mod_file,
                                                            version => $mod_version,
                                                          },
                                           },
                            resources   => {
                #                            repository => {
                #                                            url  => 'https://...',
                #                                            web  => 'https://...',
                #                                            type => 'git',
                #                                          },
                                             bugtracker => {
                                                             mailto => 'bug-' . $mod_distname . '@rt.cpan.org',
               #                                              web    => 'https://...',
                                                           },
                                           },
                          },
);

package MY;
use File::ShareDir::Install 'postamble';
