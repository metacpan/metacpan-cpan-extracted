#!/usr/bin/perl 

use strict;
use Getopt::Long;

use IMDB::Local;

my $opt_help;
my $opt_imdbDir;
my $opt_import;
my $opt_quiet=0;
my $opt_force=0;
my @opt_download;
my $opt_optimize=0;

GetOptions('help'             => \$opt_help,
	   'imdbdir=s'        => \$opt_imdbDir,
	   'import=s'         => \$opt_import,
	   'optimize'         => \$opt_optimize,
	   'quiet'            => \$opt_quiet,
	   'force'            => \$opt_force,
	   'download:s'       => \@opt_download
    ) or usage(0);

if ( $opt_help ) {
    die "no usage implemented";
}

if ( ! defined($opt_imdbDir) ) {
    die "imdbdir flag is required";
}

# lets put list files below the imdbDir
my $listsDir="$opt_imdbDir/lists";

if ( @opt_download ) {
    use IMDB::Local::Download;
    
    if ( ! -d $listsDir ) {
	mkdir($listsDir, 0777) or die "cannot mkdir $listsDir: $!";
    }
    
    my $n=new IMDB::Local::Download('listsDir' => $listsDir,
				    'verbose' => !$opt_quiet);
    
    if ( $opt_download[0] eq 'all' ) {
	# no args give, get everything
	$n->download($opt_force);
    }
    else {
	for my $type (@opt_download) {
	    if ( !grep(/^$type$/i, $n->listFiles) ) {
		warn("invalid list file '$type', must be one of ".join(',', $n->listFiles));
	    }
	    else {
		$n->downloadListFile($type, $opt_force);
	    }
	}
    }
}

if ( defined($opt_import) ) {
    my $n=new IMDB::Local('listsDir' =>  $listsDir,
			  'imdbDir'  =>  $opt_imdbDir,
			  'verbose'  => !$opt_quiet,
			  'showProgressBar' => !$opt_quiet);
    
    if ( $opt_import eq 'all' ) {
	for my $type ( $n->listTypes() ) {
	    my $ret=$n->importList($type);
	    if ( $ret == 0 ) {
		if ( $n->{errorCountInLog} == 0 ) {
		    #$n->status("list import $type succeeded with no errors") if ( ! $opt_quiet );
		}
		else {
		    $n->status("list import $type succeeded with $n->{errorCountInLog} errors in $n->{imdbDir}/stage-$type.log");
		}
	    }
	    elsif ( $n->{errorCountInLog} == 0 ) {
		#$n->status("list import $type failed (with no logged errors)");
	    }
	    else {
		$n->status("list import $type failed with $n->{errorCountInLog} errors in $n->{imdbDir}/stage-$type.log");
	    }
        }

	# trigger optimize process
	$opt_optimize=1;
    }
    else {
	my $type=$opt_import;

	my $ret=$n->importList($type);
	if ( $ret == 0 ) {
	    if ( $n->{errorCountInLog} == 0 ) {
		$n->status("list import $type succeeded with no errors") if ( ! $opt_quiet );
	    }
	    else {
		$n->status("list import $type succeeded with $n->{errorCountInLog} errors in $n->{imdbDir}/stage-$type.log");
	    }
	}
	elsif ( $n->{errorCountInLog} == 0 ) {
	    $n->status("list import $type failed (with no logged errors)");
	}
	else {
	    $n->status("list import $type failed with $n->{errorCountInLog} errors in $n->{imdbDir}/stage-$type.log");
	}
    }
}

if ( $opt_optimize ) {
    my $n=new IMDB::Local('listsDir' =>  $listsDir,
			  'imdbDir'  =>  $opt_imdbDir,
			  'verbose'  => !$opt_quiet,
			  'showProgressBar' => !$opt_quiet);

    $n->status("optimizing IMDB::Local database - $n->{imdbDir}...");
    $n->status("Note: Optimizing will take several minutes, please be patient");
    $n->optimize();
}

exit(0);
