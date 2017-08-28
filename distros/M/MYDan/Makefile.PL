use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

our %PREREQ_PM =
(
    DBI => 1.625,#box
    JSON => 2.90,
    Expect => 1.21,#box
    threads => 1.80,#box
    DateTime => 1.03,
    'YAML::XS' => 0.65,#box
    'DBD::SQLite' => 1.37,#box
    'Getopt::Long' => 2.38,#box
    'Thread::Queue' => 2.12,#box
    'IO::Socket::Multicast' => 1.12,

    'Term::ANSIColor' => 3.00,#box

    'Time::TAI64' => 0,
    'AnyEvent' => 0,#box
    'Crypt::PK::RSA' => 0,
    'Term::Completion' => 0,#box
    'Mail::Sendmail' => 0,
    'Data::UUID' => 0,
    'Time::HiRes' => 0,#box
    'Compress::Zlib' => 0,#box
    'Crypt::PK::RSA' => 0,#box
    'LWP::UserAgent' => 0,#box
    'IO::Stty' => 0,#box
    'Term::ReadKey' => 0,
    'IO::Poll' => 0,
    'AnyEvent::Handle' => 0,
    'AnyEvent::Socket' => 0,
    'AnyEvent::Impl::Perl' => 0,
    'IO::Pty' => 1.12,
    'Term::Size' => 0,
    'File::Temp' => 0,
);

our $PKG_NAME = 'mydan';
our $PKG_FILE = "lib/MYDan.pm";

WriteMakefile
(
    AUTHOR        => 'Lijinfeng <lijinfeng2011@gmail.com>',
    NAME          => $PKG_NAME,
    VERSION_FROM  => $PKG_FILE,
    ABSTRACT_FROM => $PKG_FILE,
    PREREQ_PM     => \%PREREQ_PM, 
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => [ "$PKG_NAME-*", "dan.i", "box.i", qw( *.in *.ex ) ] },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( LICENSE => 'perl' ) : () ),
);




