#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

die "No support for OS" if $^O !~ m/Win/;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Mail::Outlook',
    VERSION_FROM        => 'lib/Mail/Outlook.pm',
    ABSTRACT_FROM       => 'lib/Mail/Outlook.pm',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'File::Basename'    => '0',
	'Win32::OLE'        => '0',
	'Win32::OLE::Const' => '0',
	'Alien::Microsoft::Outlook' => '0',

        # build/test prereqs
        'Cwd'               => '0',
        'IO::File'          => '0',
        'Test::More'        => '0.70',
        'Test::Output'      => '0',
        'Test::Pod'         => '1.26',
        'Test::Pod::Coverage' => '1.08',
        'Test::CPAN::Meta' => '0',
        'Test::CPAN::Meta::JSON' => '0',
        'Test::MockObject' => '0',

    }
);


print <<HERE;

  Please note that Microsoft Outlook is required by this distribution.


  PLEASE NOTE:
  1) You will see several Win32::OLE errors during testing. This is expected
     as we should try and test failure as well as success :)
  2) 1 message is sent during testing. If Outlook requests your acceptance,
     you may decline, as the testing will acknowledge this.
  3) Part of the testing uses your Inbox to validate whether the distribution
     can read mail. If you are uncomfortable with this, please decline any
     Outlook security pop up and those tests will be skipped.

HERE
