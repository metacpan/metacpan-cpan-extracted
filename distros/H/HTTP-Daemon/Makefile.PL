#!perl -w

require 5.008001;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'HTTP::Daemon',
    VERSION_FROM => 'lib/HTTP/Daemon.pm',
    ABSTRACT_FROM => 'lib/HTTP/Daemon.pm',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.008001,
    PREREQ_PM => {
	'Sys::Hostname' => 0,
	'IO::Socket' => 0,
	'HTTP::Request' => 6,
	'HTTP::Response' => 6,
	'HTTP::Status' => 6,
	'HTTP::Date' => 6,
	'LWP::MediaTypes' => 6,
    },
    META_MERGE => {
	resources => {
            repository => 'http://github.com/gisle/http-daemon',
	    MailingList => 'mailto:libwww@perl.org',
        }
    },
);


BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f ".gitignore";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
