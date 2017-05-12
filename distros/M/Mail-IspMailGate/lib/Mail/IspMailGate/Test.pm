# -*- perl -*-
#
# Base class for running tests.
#


require 5.004;
use strict;

require Mail::IspMailGate;
require Mail::IspMailGate::Config;
require Mail::IspMailGate::Parser;
require Exporter;


package Mail::IspMailGate::Test;

use vars qw($VERSION @ISA @EXPORT $numTests $outputDir $outputToCore $parser
	    $mailOutput);
$VERSION = '0.10';
@ISA = qw(Exporter);
@EXPORT = qw(MiInit MiTest MiParser MiParse MiMail MiMailParse MiSearch);
$numTests = 0;

my $outputDir;
my $outputToCore;
my $parser;
my $mailOutput;

sub MiInit (@) {
    my %opts = @_;
    $outputDir = $opts{'output_dir'} || 'output';
    if (!-d $outputDir) {
	mkdir $outputDir, 0755;
    }
    if (!defined($outputToCore = $opts{'output_to_core'})) {
	$outputToCore = 0;
    }
    \%opts;
}

sub MiTest ($;$$@) {
    my $result = shift;
    my $smsg = shift;
    if (defined(my $msg = shift)) { printf($msg, @_) }
    ++$numTests;
    if (!defined($smsg)) { $smsg = '' } else { $smsg = " $smsg" }
    if (!$result) { print "not " }
    print "ok $numTests$smsg\n";
    $result;
}

sub MiParser(@) {
    MiInit(@_);
    $parser = Mail::IspMailGate::Parser->new
	('output_dir' => $outputDir,
	 'output_to_core' => $outputToCore);
    MiTest($parser, undef, "Creating the Parser\n");
}

sub MiParse ($$$;$$) {
    my $parser = shift;  my $filter = shift; my $inputEntity = shift;
    if (defined(my $inputFile = shift)) {
	$inputFile = "$outputDir/$inputFile";
	my $fh = Symbol::gensym();
	if (!open($fh, ">$inputFile")  ||
	    !(print $fh $inputEntity->as_string())  ||
	    !close($fh)) {
	    die "Cannot create input file $inputFile: $!";
	}
    }
    my $outputEntity = $inputEntity->dup();
    my $result = $filter->doFilter({'entity' => $outputEntity,
				    'parser' => $parser});
    if (defined(my $outputFile = shift)) {
	$outputFile = "$outputDir/$outputFile";
	my $fh = Symbol::gensym();
	if (!open($fh, ">$outputFile")  ||
	    !(print $fh $outputEntity->as_string())  ||
	    !close($fh)) {
	    die "Cannot create input file $outputFile: $!";
	}
    }
    ($result, $outputEntity);
}


sub MiMail ($@) {
    my $name = shift;
    my $opts = MiInit(@_);
    my $cfg = $Mail::IspMailGate::Config::config;
    my $tmpdir = $opts->{'tmp_dir'}  ||  'output/tmp';
    if ($tmpdir) {
	$cfg->{'tmp_dir'} = $tmpdir;
	if (!-d $tmpdir) {
	    require File::Path;
	    File::Path::mkpath($tmpdir, 0, 0755)
	}
    }
    if ($opts->{'recipients'}) {
	$cfg->{'recipients'} = [@{$opts->{'recipients'}}];
    }

    require Sys::Syslog;
    Sys::Syslog::openlog($name, 'pid,cons', 'daemon');
    if (defined(&Sys::Syslog::setlogsock)  &&
	defined(&Sys::Syslog::_PATH_LOG)) {
        Sys::Syslog::setlogsock('unix');
    }

    $parser = Mail::IspMailGate->new({'debug' => 1,
				      'tmpDir' => $tmpdir,
				      'noMails' => \$mailOutput});
    MiTest($parser, undef, "Creating the parser\n");
}


sub MiMailParse ($$$$$$;$) {
    my($parser, $filter, $input, $sender, $recipients, $inputFile,
       $outputFile) = @_;

    $inputFile = "$outputDir/$inputFile";
    my $fh = Symbol::gensym();
    if (!open($fh, ">$inputFile")  ||
	!(print $fh $input)  ||  !close($fh)) {
	die "Error while creating input file $inputFile: $!";
    }
    if (!open($fh, "<$inputFile")) {
	die "Error while opening input file $inputFile: $!";
    }
    $mailOutput = '';
    $parser->Main($fh, $sender, $recipients);
    if (defined($outputFile)) {
	$outputFile = "$outputDir/$outputFile";
	if (!open($fh, ">$outputFile")  ||
	    !(print $fh $mailOutput)  ||  !close($fh)) {
	    die "Error while creating output file $outputFile: $!";
	}
    }
    $mailOutput;
}


sub MiSearch ($) {
    my $prog = shift;
    my $pathsep = ($^O =~ /win32/i) ? ';' : ':';
    foreach my $dir (split(/$pathsep/, $ENV{'PATH'})) {
	if (-x "$dir/$prog") { return "$dir/$prog" }
    }
    undef;
}


1;
