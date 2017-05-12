use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Email::Store',
    VERSION_FROM      => 'lib/Email/Store.pm',
    PREREQ_PM         => {
        Class::DBI => 0.9,
        Class::DBI::DATA::Schema => 0,
        DBD::SQLite => 0,
        Email::Address => 1.80,
        Email::MessageID => 0,
        Email::MIME => 1.8,
        Email::Simple => 1.92,
        File::Slurp => 0,
        Mail::ListDetector => 0.31,
        MIME::Parser => 0,
        Module::Pluggable => 2.6,
        Module::Pluggable::Ordered => 1.0,
        SQL::Translator => 0,
        Time::Piece => 0,
    },
);
