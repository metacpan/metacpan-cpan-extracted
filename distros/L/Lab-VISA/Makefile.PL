#!/usr/bin/perl
use warnings;
use strict;
use ExtUtils::MakeMaker;

my %visa_options = ();

if ($^O =~ /MSWin32/) {
    # The location of 'visa32.lib' differs for 32- and 64-bit Windows.
    my $lib64 = "C:\\Program Files (x86)\\IVI Foundation\\VISA\\WinNT\\lib\\msc\\visa32.lib";
    my $inc64 = "C:\\Program Files (x86)\\IVI Foundation\\VISA\\WinNT\\include";
    my $lib32 = "C:\\Program Files\\IVI Foundation\\VISA\\WinNT\\lib\\msc\\visa32.lib";
    my $inc32 = "C:\\Program Files\\IVI Foundation\\VISA\\WinNT\\Include";
    my $lib;
    my $inc;
    if (-e $lib32) {
	$lib = $lib32;
	$inc = $inc32;
    }
    elsif (-e $lib64) {
	$lib = $lib64;
	$inc = $inc64;
    }
    
    if ($lib) {
	$visa_options{LIBS} = "\"-l${lib}\"";
	$visa_options{INC} = "\"-I${inc}\"";
    }
}
else {
    # Linux
    $visa_options{LIBS} = '-lvisa';
    $visa_options{INC} = '-I/usr/local/include';
}


WriteMakefile(
    %visa_options,
    'NAME'              => 'Lab::VISA',
    'VERSION_FROM'      => 'VISA.pm',
    'OBJECT'            => q/$(O_FILES)/,
    'PREREQ_PM'         => {
        'DynaLoader'    => 0,     # first released with perl 5
        'Exporter'      => 0,     # first released with perl 5
    },
    'META_MERGE'        => {
        resources => {
            homepage    =>      'https://github.com/lab-measurement/Lab-VISA',
            bugtracker  =>      'https://github.com/lab-measurement/Lab-VISA/issues',
            MailingList =>      'lab-measurement-users@mailman.uni-regensburg.de',
            repository  =>      'https://github.com/lab-measurement/Lab-VISA.git',
        },
    },
    'ABSTRACT_FROM'     => 'VISA.pod',
    'AUTHOR'            => ['Daniel Schroeer <schroeer@cpan.org>', 'Andreas K. Huettel <mail@akhuettel.de>'],

);
