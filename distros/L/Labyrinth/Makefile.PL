#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth',
    VERSION_FROM        => 'lib/Labyrinth.pm',
    ABSTRACT	        => 'Labyrinth Website Management Framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Archive::Extract'                          => 0,
        'CGI'                                       => 0,
        'CGI::Cookie'                               => 0,
        'Config::IniFiles'                          => 0,
        'Data::Dumper'                              => 0,
        'Data::FormValidator'                       => 0,
        'Data::FormValidator::Constraints::Upload'  => 0,
        'Data::FormValidator::Constraints::Words'   => 0,
        'Data::FormValidator::Filters::Demoroniser' => 0,
        'Data::Phrasebook'                          => 0,
        'Data::Phrasebook::Loader::Ini'             => 0,
        'DateTime'                                  => 0,
        'DBD::mysql'                                => 0,
        'DBI'                                       => 0,
        'Digest::MD5'                               => 0,
        'Encode::ZapCP1252'                         => 0,
        'Exporter'                                  => 0,
        'File::Basename'                            => 0,
        'File::Copy'                                => 0,
        'File::Path'                                => 2.08,
        'File::Slurp'                               => 0,
        'File::Spec::Functions'                     => 0,
        'File::Temp'                                => 0.2304,
        'HTML::Entities'                            => 0,
        'HTML::TagCloud'                            => 0.34,
        'Image::Size'                               => 0,
        'IO::File'                                  => 0,
        'JSON::XS'                                  => 0,
        'Log::LogLite'                              => 0,
        'MIME::Lite'                                => 0,
        'MIME::Lite::TT::HTML'                      => 0,
        'MIME::Types'                               => 0,
        'Module::Pluggable'                         => 0,
        'Regexp::Assemble'                          => 0,
        'Regexp::Common'                            => 0,
        'Session::Token'                            => 0,
        'Template'                                  => 0,
        'Text::Wrap'                                => 0,
        'Time::Local'                               => 0,
        'URI::Escape'                               => 0,
        'WWW::Mechanize'                            => 0,
        'XML::Atom'                                 => 0,
        'XML::Atom::Feed'                           => 0,
        'XML::Atom::Entry'                          => 0,
        'XML::RSS'                                  => 0,

        # build/test prereqs
        'Test::More'                                => '0.70',
    }
);
