#!/usr/bin/perl
# $File: //member/autrijus/Finance-Bank-Fubon-TW/Makefile.PL $ $Author: autrijus $
# $Revision: #2 $ $Change: 5938 $ $DateTime: 2003/05/17 22:34:34 $

use ExtUtils::MakeMaker;

my $have_io_socket_ssl = eval { require IO::Socket::SSL; 1 };

WriteMakefile(
    AUTHOR		=> 'Autrijus Tang (autrijus@autrijus.org)',
    ABSTRACT		=> 'Check Fubon bank accounts from Perl',
    NAME		=> 'Finance::Bank::Fubon::TW',
    VERSION_FROM	=> 'lib/Finance/Bank/Fubon/TW.pm',
    DISTNAME		=> 'Finance-Bank-Fubon-TW',
    PREREQ_PM		=> {
	'WWW::Mechanize'	=> '0.39',
      $have_io_socket_ssl ? () : (
	'Crypt::SSLeay'		=> 0,
      ),
    },

    dist		=> {
        COMPRESS	=> 'gzip -9',
        SUFFIX		=> '.gz',
    },
);

