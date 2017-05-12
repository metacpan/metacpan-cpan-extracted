#-------------------------------------------------------
#
#   $Id: Utils.pm,v 1.1 2005/09/18 19:11:02 erwan Exp $
#
#   Util - a few usefull functions for testing Log::Localized
#
#   20050912 erwan Created 
#

package Utils; 

use strict;
use warnings;
use Carp qw/confess/;
use File::Spec;

#-------------------------------------------------------
#
#   default settings from Log::Localized
#

my $SEARCH_PATHS     = [".","~","/"];
my $FILE_RULES       = 'verbosity.conf';
my $GLOBAL_VERBOSITY = 'LOG_LOCALIZED_VERBOSITY';

#-------------------------------------------------------
#
#   backup_log_settings - backup all settings influencing Log::Localized
#                         (ie create neutral environment)
#

my $GLOBAL_SWITCH_VALUE;
my $GLOBAL_VERBOSITY_VALUE;
my $CONFIG_FILES = {
    # original path => new path
};

sub backup_log_settings {
    if (defined $ENV{$GLOBAL_VERBOSITY}) {
	$GLOBAL_VERBOSITY_VALUE = $ENV{$GLOBAL_VERBOSITY};
	delete $ENV{$GLOBAL_VERBOSITY};
    }

    foreach my $path (@{$SEARCH_PATHS}) {
	my $file = File::Spec->catfile($path,$FILE_RULES);
	if (-f $file) {
	    my $newfile = "$file.tmp.backup";
	    $CONFIG_FILES->{$file} = $newfile;
	    rename($file,$newfile) or confess "ERROR: failed to backup [$file]: $!\n";
	}
    }
}

#-------------------------------------------------------
#
#   restore_log_settings - restore all settings influencing Log::Localized
#                          (ie restore initial environment)
#

sub restore_log_settings {
    if (defined $GLOBAL_VERBOSITY_VALUE) {
	$ENV{$GLOBAL_VERBOSITY} = $GLOBAL_VERBOSITY_VALUE;
	$GLOBAL_VERBOSITY_VALUE = undef;
    }

    foreach my $file (keys %{$CONFIG_FILES}) {
	my $newfile = $CONFIG_FILES->{$file};
	rename($newfile,$file) or confess "ERROR: failed to restore [$file]: $!\n";
    }
    $CONFIG_FILES = {};
}

#-------------------------------------------------------
#
#   set_global_verbosity - 
#

sub set_global_verbosity {
    $ENV{$GLOBAL_VERBOSITY} = shift;
}

#-------------------------------------------------------
#
#   mark_log_called - remember if self has been executed
#   check_log_called - check if mark_log_called has been executed
#

my $marker = 0;

sub mark_log_called {
    $marker = 1;
    return "called mark_log_called";
}

sub check_log_called {
    my $m = $marker;
    $marker = 0;
    return $m;
}

#-------------------------------------------------------
#
#   write_config - save a configuration file for use by 
#

sub write_config {
    my $conf = shift;
    #print "# dumping temporary test configuration into [$FILE_RULES]\n";
    open(OUT,"> ".$FILE_RULES) or die "ERROR: failed to open [$FILE_RULES] for writting:$!\n";
    print OUT $conf;
    close(OUT) or die "ERROR: failed to close [$FILE_RULES]:$!\n";
}

sub remove_config {
    unlink $FILE_RULES;
}

1;
