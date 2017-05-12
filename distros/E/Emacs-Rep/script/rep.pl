#!/usr/bin/perl
# rep.pl                   doom@kzsu.stanford.edu
#                          13 May 2010

=head1 NAME

rep.pl - perform a series of find and replaces

=head1 SYNOPSIS

 rep.pl --backup <backup_file> --substitutions <filename> --target <file_to_act_on>

 rep.pl -b <backup_file> -f <file_to_act_on> 's/foo/bar/'

=head2 USAGE

  rep.pl -[options] [arguments]

  Options:

     -s                substitutions list file
     --substitutions   same
     -f                target file name to be modified
     --target          same
     -B                backup file name
     --backup          same

     --trial           report change metadata without modifying target file

     -d                debug messages on
     --debug           same
     -h                help (show usage)
     -v                show version
     --version         show version

     -T                make no changes to the input file, but report
     --trailrun        metadata for changes that would've been made.


=head1 DESCRIPTION

B<rep.pl> is a script which does finds and replaces on a file,
and records the beginning and end points of the modified
strings.

It is intended to act as an intermediary between Emacs::Rep
and the emacs lisp code which drives the "rep" process.

Emacs can then use the recorded locations to highlight the
changed regions, and it can use information about what was
replaced to perform undo operations.

The elisp code must choose a unique backup file name. This makes
it possible to do reverts of an entire run of substitutions.

The script returns a data dump of the history of the changes to
the text.  This is in the form of an array of hashes, serialized
using JSON.

The array is in the order in which the individual changes took
place.  Each row has fields:

  pass   the number of the "pass" through the file
         (one pass per substitution command)
  beg    begin point of changed string
  end    end point of changed string
  delta  the change in string length
  orig   the original string that was replaced
  rep    the replacement string that was substituted
  pre    up to ten characters found before the replacement
  post   up to ten characters found after the replacement

Note: in "beg" and "end" characters are counted from the
beginning of the text, starting with 1.

=cut

use warnings;
use strict;
$|=1;
use Carp;
use Data::Dumper;

use File::Path     qw( mkpath );
use File::Basename qw( fileparse basename dirname );
use File::Copy     qw( copy move );
use Fatal          qw( open close mkpath copy move );
use Cwd            qw( cwd abs_path );
use Env            qw( HOME );
use Getopt::Long   qw( :config no_ignore_case bundling );
use FindBin qw( $Bin );
use Emacs::Rep     qw( :all );
use JSON; # encode_json

our $VERSION = 1.00;
my  $prog    = basename($0);

my $DEBUG   = 0;                 # TODO set default to 0 when in production
my ( $locs_temp_file, $reps_file, $backup_file, $target_file, $trialrun_flag,
     $elisp_version );
GetOptions ("d|debug"           => \$DEBUG,
            "v|version"         => sub{ say_version(); },
            "h|?|help"          => sub{ say_usage();   },
            "s|substitutions=s" => \$reps_file,
            "b|backup=s"        => \$backup_file,
            "f|target=s"        => \$target_file,
            "T|trialrun"        => \$trialrun_flag,
            "V|check_versions=s" =>\$elisp_version,
           ) or say_usage();

if( $elisp_version ) {
  my $pl_version = $VERSION;
  my $report =
    check_versions( $elisp_version, $pl_version );
  if( $report =~ m{ \A Warning: \s+ }xms ) {
    print $report, "\n";
    exit;
  } else {
    exit 1;
  }
}


# get a series of finds and replaces
#   either from the substitutions file,
#   or from command-line (a series of strings from @ARGV),

my $reps_text;
if( $reps_file ) {
  undef $/;
  open my $fh, '<', $reps_file or croak "$!";
  $reps_text = <$fh>;
} else {
  $reps_text = join( "\n", @ARGV );
}

# process the find_and_reps into an array of find and replace
# pairs (modifiers get moved inside the find.)
my $find_replaces_aref;
eval {
  $find_replaces_aref =
    parse_perl_substitutions( \$reps_text );
};
if ($@) {
  carp "Problem parsing perl substitutions: $@";
  exit;
}

unless (-e $target_file) {
  croak "file not found: $target_file";
}
my $backup_file_dir = dirname( $backup_file );
unless (-d $backup_file_dir) {
  croak "directory does not exist: $backup_file_dir";
}

if ( $trialrun_flag ) {
  # During a trial run, we work on the copy of the input file,
  # and never modify the original
  copy( $target_file, $backup_file ) or
    croak "can't copy $target_file to $backup_file: $!";
} else {
  rename( $target_file, $backup_file ) or
    croak "can't move $target_file to $backup_file: $!";
}

my $text;
{ undef $/;
  open my $fin, '<', $backup_file or croak "$!";
  $text = <$fin>;
  close( $fin );
}

# Apply the finds and replaces to text, recording the
# change meta-data
my $change_metadata_aref;
eval {
  $change_metadata_aref =
    do_finds_and_reps( \$text, $find_replaces_aref );
};
if ($@) {
  carp "Problem applying finds and replaces: $@";
  rename( $backup_file, $target_file ); # rollback!
} else {
  if ( not( $trialrun_flag ) ) { # then don't modify input file
    open my $fout, '>', $target_file or croak "$!";
    print {$fout} $text;
    close( $fout );
  }
 # serialize the data to pass to emacs
 my $chg_md_json = encode_json( $change_metadata_aref );
 print $chg_md_json;
}

### end main, into the subs

sub say_usage {
  my $usage=<<"USEME";
   $prog <-options> <arguments>

  Options:

     -s                substitutions list file
     --substitutions   same
     -f                target file name to be modified
     --target          same
     -b                backup file name
     --backup          same

     -d                debug messages on
     --debug           same
     -h                help (show usage)
     -v                show version
     --version         show version

Typical use:

  perl rep.pl -b "/tmp/edit_this.txt.bak" -f "edit_this.txt" 's/foo/bar/'

  perl rep.pl --backup <backup_file> --substitutions <filename> --target <file_to_act_on>

USEME
  print "$usage\n";
  exit;
}

sub say_version {
  print "Running $prog version: $VERSION\n";
  exit 1;
}



__END__

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Joseph Brenner

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 TODO

o  Simplify the UI for command-line use:

   o If there's no -f or --target, could guess that the first
     item is the file, and the remaining arguments are
     substitution commands.

   o In the absence of -b of --backup, should have a default
     scheme.

   o Could it be that "rep.pl" is too short?  Possible name collison,
     and this isn't really for command-line use in any case.

=cut
