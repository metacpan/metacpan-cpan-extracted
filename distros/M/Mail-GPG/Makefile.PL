# $Id: Makefile.PL,v 1.4 2009-05-30 13:57:34 joern Exp $

use strict;

use File::Find;
use ExtUtils::MakeMaker;

$| = 1;

#-- Check for patched MIME-tools
eval {
    print "* Checking for patched MIME-tools package... ";
    require MIME::Parser;
    my $parser = MIME::Parser->new;
    $parser->decode_bodies(0);
    print "Ok\n";
};

if ( $@ ) {
    print "Not Ok!\n";
    print "  Please read the README file and apply the required\n";
    print "  MIME-tools patch before installing Mail::GPG.\n";
    print "  You can use Mail::GPG without this patch, but\n";
    print "  Mail::GPG then can't verify all MIME signed messages.\n";
}

#-- check for gpg program
eval {
    print "* Checking for gpg program... ";
    my $out = qx[gpg --version 2>&1 && echo GPGOK];
    die unless $out =~ /GPGOK/;
    print "Ok\n";
};

if ( $@ ) {
    print "Not Ok!\n";
    print "  Please read the README file and first install the\n";
    print "  gpg program in your PATH, or extend your PATH that\n";
    print "  the gpg program can be found. This is needed for\n";
    print "  the regression tests only.\n";
}

WriteMakefile(
    'NAME'              => 'Mail::GPG',
    'VERSION_FROM'      => 'lib/Mail/GPG.pm',
    'PREREQ_PM'         => {
        'Event'             => 0,
        'List::MoreUtils'   => 0,
        'MIME::Entity'      => 5.419,
        'MIME::Parser'      => 5.419,
        'Mail::Address'     => 0,
        'MIME::QuotedPrint' => 2.20,
        'GnuPG::Interface'  => 0,
        'Encode'            => 2.12,
    },
    'EXE_FILES'         => [ 'bin/mgpg-test' ],
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX   => "gz",
        PREOP    => q[./genreadme],
        POSTOP   => q[mkdir -p dist; mv Mail*tar.gz dist/],
    },
);
