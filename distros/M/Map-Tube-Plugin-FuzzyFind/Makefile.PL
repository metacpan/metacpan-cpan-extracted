#!/usr/bin/perl
use strict;
use ExtUtils::MakeMaker 6.64;

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
	PL_FILES		   => { },
	MIN_PERL_VERSION   => 5.012,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 6.64, },
    TEST_REQUIRES      => {
                            'Test::More'        => 0.82,
							'Map::Tube'         => 3.77,
                          },
    PREREQ_PM          => {
							'Map::Tube'         => 3.77,
                            'Moo::Role'         => 0,
                            'Moo'               => 0,
                            'namespace::clean'  => 0,
                            'Try::Tiny'         => 0,
                          },
	( MM->can('signature_target') ? ( SIGN => 1 ) : ( ) ),
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
																		'Text::Soundex'                  => 3,
																		'Text::Phonetic::Phonix'         => 0,
																		'Text::Phonetic::Phonem'         => 0,
																		'Text::Phonetic::DaitchMokotoff' => 0,
																		'Text::Phonetic::Koeln'          => 0,
																		'Text::Metaphone'                => 20081017,
																		'Text::DoubleMetaphone'          => 0,
																		'Text::Levenshtein::XS'          => 0.503,
																		'Text::Levenshtein::Damerau::XS' => 3.2,
																		'Text::JaroWinkler'              => 0,
																		'String::Trigram'                => 0.12,
																		'Text::Unidecode'                => 0,  # not needed by ourselves but by Text::Soundex, which does not declare this fact
                                                                      },
                                                        },
                                           },
                            resources   => {
											 bugtracker => { mailto => 'bug-' . $mod_distname . '@rt.cpan.org', },
                                           },
                          },
);
