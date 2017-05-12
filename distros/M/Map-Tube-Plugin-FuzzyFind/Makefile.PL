#!/usr/bin/perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $mod_name     =  'Map::Tube::Plugin::FuzzyFind';
my $mod_file     =  'lib/' . $mod_name . '.pm';
$mod_file        =~ s|::|/|g;
my $mod_distname =  $mod_name;
$mod_distname    =~ s|::|-|g;
my $mod_version  = MM->parse_version($mod_file);

WriteMakefile(
    NAME               => $mod_name,
    AUTHOR             => q{Gisbert W. Selke <gws@cpan.org>},
    VERSION_FROM       => $mod_file,
    ABSTRACT_FROM      => $mod_file,
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 6.64, },
    TEST_REQUIRES      => {
                            'Test::More'        => 0.82,
                            'Map::Tube::London' => 0.71,
                            'Map::Tube'         => 2.92,
                          },
    PREREQ_PM          => {
                            'Map::Tube'         => 2.85,
                            'Moo::Role'         => 0,
                            'Moo'               => 0,
                            'namespace::clean'  => 0,
                            'Try::Tiny'         => 0,
                          },
    dist               => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean              => { FILES    => $mod_distname . '-*', },
    META_MERGE         => {
                            'meta-spec' => { version => 2 },
                            dynamic_config => 0,
                            provides    => {
                                             $mod_name => {
                                                            file    => $mod_file,
                                                            version => $mod_version,
                                                          },
                                           },
                            prereqs     => {
                                             runtime => {
                                                          suggests => {
                                                                        'Text::Soundex'     => 3,
                                                                        'Text::Unidecode'   => 0,
                                                                        'Text::Metaphone'   => 20081017,
                                                                        'Text::Levenshtein' => 0.12,
                                                                        'String::Trigram'   => 0.12,
                                                                      },
                                                        },
                                           },
                            resources   => {
                #                             repository => {
                #                                             url  => 'https://...',
                #                                             web  => 'https://...',
                #                                             type => 'git',
                #                                           },
                                             bugtracker => {
                                                             mailto => 'bug-' . $mod_distname . '@rt.cpan.org',
                                                             web    => 'https://rt.cpan.org/Dist/Display.html?Name=' . $mod_distname,
                                                           },
                                           },
                          },
);
