use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME                => 'Interchange6::Schema',
    AUTHOR              => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM        => 'lib/Interchange6/Schema.pm',
    ABSTRACT_FROM       => 'lib/Interchange6/Schema.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.47
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES           => ['bin/interchange6-create-schema-png',
                            'bin/interchange6-create-database'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'DBIx::Class'         => 0,
    },
    PREREQ_PM => do {
        eval { require DBIx::Class::Optional::Dependencies };
        my $dbic_deps =
          $@
          ? { 'SQL::Translator' => 0 }
          : DBIx::Class::Optional::Dependencies->req_list_for('deploy');

        my $ret = +{
            'Class::Method::Modifiers'             => 0,
            'Data::UUID'                           => 0,
            'DBIx::Class'                          => 0,
            'DBIx::Class::Candy'                   => 0.002104,
            'DBIx::Class::PassphraseColumn'        => '0.02',
            'DBIx::Class::Helpers'                 => 2.024001,
            'DBIx::Class::InflateColumn::DateTime' => 0,
            'DBIx::Class::InflateColumn::DateTime::Duration' => 0,
            'DBIx::Class::Schema::Config'          => 0.001011,
            'DBIx::Class::TimeStamp'               => 0,
            'DBIx::Class::Tree'                    => 0,
            'Digest::MD5'                          => 0,
            'Encode'                               => 0,
            'Session::Token'                       => 1.008,
            'Sub::Quote'                           => 1.004006,
            # for populating country/state records
            'Locale::SubCountry'    => 1.64,
            'namespace::clean'      => 0,
            'DateTime'              => 0,
            'Test::Roo'             => 1.003,
            'Time::Duration::Parse' => 0,
            'Try::Tiny'             => 0,
            %$dbic_deps,
        };
    },
    BUILD_REQUIRES => {
                       'Data::Dumper::Concise' => 0,
                       'File::Temp' => 0,
                       'Test::MockTime' => 0,
                       'Test::More' => 0,
                       'Test::Most' => 0.33,
                       'Test::Warnings' => 0,
                       'DBD::SQLite' => 1.38_01,
                       'YAML' => 0, # https://github.com/symkat/DBIx-Class-Schema-Config/pull/10
                      },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Interchange6-Schema-*' },
    META_MERGE        => {
        resources => {
            repository  => 'https://github.com/interchange/interchange6-schema.git',
            bugtracker => 'https://github.com/interchange/interchange6-schema/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
