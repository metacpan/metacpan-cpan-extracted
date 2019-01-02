use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %META_MERGE = 
(
    'meta-spec' => { version => 2 },
    dynamic_config => 0,
    no_index => {
        directory => [ 'xt' ],
    },
    resources => {
        "bugtracker" => +{
           "web" => "https://github.com/mydan/mayi/issues"
        },
        "homepage" => "https://github.com/mydan/mayi",
        repository => {
            type => 'git',
            url  => 'https://github.com/mydan/mayi.git',
            web  => 'https://github.com/mydan/mayi',
        },
    }
);

our %PREREQ_PM =
(
    DBI => 1.625,
    JSON => 2.90,
    Expect => 1.21,
    threads => 1.80,
    DateTime => 1.03,
    'YAML::XS' => 0.65,
    'DBD::SQLite' => 1.37,
    'Getopt::Long' => 2.38,
    'Thread::Queue' => 2.12,
    'IO::Socket::Multicast' => 1.12,

    'Term::ANSIColor' => 3.00,

    'Time::TAI64' => 0,
    'AnyEvent' => 0,
    'Crypt::PK::RSA' => 0,
    'Term::Completion' => 0,
    'Data::UUID' => 0,
    'Time::HiRes' => 0,
    'Compress::Zlib' => 0,
    'Crypt::PK::RSA' => 0,
    'LWP::UserAgent' => 0,
    'IO::Stty' => 0,
    'Term::ReadKey' => 0,
    'IO::Poll' => 0,
    'AnyEvent::HTTP' => 0,
    'AnyEvent::Handle' => 0,
    'AnyEvent::Socket' => 0,
    'AnyEvent::Impl::Perl' => 0,
    'IO::Pty' => 1.12,
    'Term::Size' => 0,
    'File::Temp' => 0,
    'Authen::OATH' => 0,
    'Convert::Base32' => 0,
    'Net::IP::Match::Regexp' => 0,
    'Data::Validate::IP' => 0,
    'LWP::Protocol::https' => 0,
    'List::MoreUtils' => 0,
    'Module::Runtime' => 0,
    'URI::Escape' => 0,
    'Filesys::Df' => 0,
);

our $PKG_NAME = 'MYDan';
our $PKG_FILE = "lib/MYDan.pm";

WriteMakefile
(
    AUTHOR        => 'Li Jinfeng <lijinfeng2011@gmail.com>',
    NAME          => $PKG_NAME,
    VERSION_FROM  => $PKG_FILE,
    ABSTRACT_FROM => $PKG_FILE,
    PREREQ_PM     => \%PREREQ_PM, 
    META_MERGE    => \%META_MERGE,
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => [ "$PKG_NAME-*", qw( dan.i box.i bin.i def.i *.in *.ex ) ] },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( LICENSE => 'perl' ) : () ),
);

