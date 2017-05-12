#!/usr/bin/perl -w

=head1

Contributed by Erwin Harte.

This is a script used to create a fresh set of database files from
spam/nonspam mail folders.

It uses a $HOME/.bayesian configuration file that can look like this:

--8<---
[paths]
home = mail/Bayesian
dir  = mail
dir  = mail/.archive

[spam]
folder = SPAM-bayesian
folder = SPAM-assassin

[nonspam]
folder = billing
folder = bugtraq
folder = family
folder = friends
folder = other
--8<---

Home and dir parameters are taken from $HOME if not starting with '/'.

Home is where the database files will be stored.  My setup is that I
store them in ~/mail/Bayesian.xxx.yyy and symlink to that, the script
updates that symlink and leaves the old files behind for someone or
something else to clean up.

The folders are searched in each 'dir' that you provide.

=cut

BEGIN {
    push @INC, $ENV{'HOME'} . '/lib';
}

use strict;
use Config::IniFiles;
use Mail::SpamTest::Bayesian;

my $bayesian_dir    = undef;
my @search_dirs     = ();
my @spam_folders    = ();
my @nonspam_folders = ();

sub read_config()
{
    my $config = new Config::IniFiles(-file   => "$ENV{HOME}/.bayesian",
				      -nocase => 1);

    $bayesian_dir = $config->val('paths', 'home');

    $bayesian_dir =~ s/\/$//;
    if ($bayesian_dir !~ /^\//) {
	$bayesian_dir = "$ENV{HOME}/$bayesian_dir";
    }
    
    @search_dirs = ();
    foreach ($config->val('paths', 'dir')) {
	s/\/$//;
	if (!/^\//) {
	    $_ = "$ENV{HOME}/$_";
	}
	push(@search_dirs, $_);
    }

    @spam_folders    = $config->val('spam',    'folder');
    @nonspam_folders = $config->val('nonspam', 'folder');
}

sub main()
{
    my $scratch_dir;
    my $db;

    read_config;

    $scratch_dir = $bayesian_dir . '.' . time() . '.' . $$;
    mkdir $scratch_dir, 0755 ||
	die "Could not create $scratch_dir: $!\n";

    $db = Mail::SpamTest::Bayesian->new(dir => $scratch_dir);

    print STDERR localtime().": Initializing Database.\n";
    $db->init_db;

    foreach my $dir (@search_dirs) {
	foreach my $folder (@spam_folders) {
	    if (-f "$dir/$folder") {
		local *FILE;

		open(FILE, "$dir/$folder") ||
		    die "Could not open $dir/$folder: $!\n";
		print STDERR localtime().": Processing $dir/$folder...\n";
		$db->merge_stream_spam(\*FILE);
		close(FILE);
	    }
	}
	foreach my $folder (@nonspam_folders) {
	    if (-f "$dir/$folder") {
		local *FILE;

		open(FILE, "$dir/$folder") ||
		    die "Could not open $dir/$folder: $!\n";
		print STDERR localtime().": Processing $dir/$folder...\n";
		$db->merge_stream_nonspam(\*FILE);
		close(FILE);
	    }
	}
    }
    print STDERR localtime().": Redirecting symlink.\n";
    unlink $bayesian_dir ||
	die "Could not remove existing symlink: $!\n";
    symlink $scratch_dir, $bayesian_dir ||
	die "Could not symlink to scratch directory: $!\n";
    print STDERR localtime().": Done.\n";
}

main;
