use 5.006;
use strict;
use ExtUtils::MakeMaker;

if ($ENV{AUTOMATED_TESTING}) {
  # This module is basically unused, abandoned, and done.  There is no need to
  # bother with test reports. -- rjbs, 2009-07-09
  # Real failures from real users are welcome.
  exit 0;
}

WriteMakefile(
    NAME              => 'Email::Store',
    VERSION_FROM      => 'lib/Email/Store.pm',
    (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
    PREREQ_PM         => {
        'Class::DBI' => '3.0.3',
        'Class::DBI::DATA::Schema' => 0,
        'DBD::SQLite' => 0,
        'Email::Address'   => 1.80,
        'Email::Date'      => 1.10, # return undef on nothing found
        'Email::MessageID' => 0,
        'Email::MIME' => 1.8,
        'Email::Simple' => 1.92,
        'File::Slurp' => 0,
        'Mail::ListDetector' => 0.31,
        'MIME::Parser' => 0,
        'Module::Pluggable' => 2.6,
        'Module::Pluggable::Ordered' => 1.0,
        'SQL::Translator' => 0,
        'Time::Piece' => 0,
    },
);
