package File::chdir::WalkDir;
{
  $File::chdir::WalkDir::VERSION = '0.040';
}

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT = ( qw/walkdir/ );

use File::Spec::Functions 'no_upwards';
use File::chdir;

sub walkdir {
  my $opts = ( ref $_[-1] eq 'HASH' ) ? pop : {};

  my ($dir, $code_ref, @excluded_patterns) = @_;
  #old api support
  if (ref $opts->{'exclude'} eq 'Regexp') {
    push @excluded_patterns, $opts->{'exclude'};
  }
  push @{ $opts->{'exclude'} }, @excluded_patterns if @excluded_patterns;

  local $CWD = $dir;
  opendir( my $dh, $CWD);
  #print "In: $CWD\n";

  #holder for files/dirs that will be acted on after full dir is read,
  #use if worried about confusing readdir, say by renaming files
  my @deferred;

  FILE: while ( my $entry = readdir $dh ) {
    
    # next if the $entry refers to a '.' or '..' like construct
    next unless no_upwards( $entry );
    
    my $include = $opts->{'include'} || [];
    if (@$include) {
      my $allow = 0;

      foreach my $pattern (@$include) {
        if ($entry =~ $pattern) {
          $allow = 1;
          last;
        }
      }

      next unless $allow; 
    }

    foreach my $pattern (@{ $opts->{'exclude'} || [] }) {
      next FILE if ($entry =~ $pattern);
    }  

    if (-d $entry) {
      next if (-l $entry); # skip linked directories
      walkdir($entry, $code_ref, $opts);

      #all directory actions are deferred
      push @deferred, $entry if $opts->{'act_on_directories'};
    } else {
      if ($opts->{'defer'}) {
        push @deferred, $entry;
      } else {
        $code_ref->($entry, $CWD);
      }
    }

  }

  #process files/dirs that were deferred
  foreach my $entry (@deferred) {
    $code_ref->($entry, $CWD);
  }

}

1;

__END__
__POD__

=head1 NAME

File::chdir::WalkDir

=head1 SYNOPSIS

 use File::chdir::WalkDir

 my $do_something = sub {
   my ($filename, $directory) = @_;

   ...
 }

 walkdir( $dir, $do_something, qr/^\./ );
 # executes $do_something->($filename, $directory) [$directory is the folder
 # containing $filename] for all files within the directory and all 
 # subdirectories. In this case excluding all files and folders that 
 # are named with a leading `.'.

=head1 DESCRIPTION

This module is a wrapper around David Golden's excellent module L<File::chdir> for walking directories and all subdirectories and executing code on all files which meet certain criteria.

=head1 FUNCTION

=head2 walkdir( $dir, $code_ref [, @exclusion_patterns, $opts_hashref ]);

C<walkdir> takes a base directory (either absolute or relative to the current working directory) and a code reference to be executed for each (qualifing) file. This code reference will by called with the arguments (i.e. C<@_>) containing the filename and the full folder that contains it. Through the magic of C<File::chdir>, the working directory when the code is executed will also be the folder containing the file.

Optionally exclusion patterns may by passed which will exclude BOTH files AND directories (and hence all subfiles/subdirectories) which match any of the patterns.  This use is discouraged in favor of the C<exclude> option below.

An optional hash reference, passed as the last option to C<walkdir> will process key-value pairs as follows:

=over

=item *

C<include> - an array reference of inclusion patterns (i.e. C<qr//>). 

If this option is not empty, files/folders will be skipped unless they meet one of these patterns. The are checked in order and short-circuit when a match is found. This check is executed before exclusion patterns are checked.

=item *

C<exclude> - an array reference of exclusion patterns (i.e. C<qr//>). 

If specified, files/folders which match any of these patterns will be immediately skipped. They are checked in order and short-circuit when a match is found. This check is executed after inclusion patterns are checked. This is a coarse exclusion. Fine detail may be used in excluding files by returning early from the code reference.

=item *

C<defer> - when set to a true value, tells C<walkdir> to process the files after listing the directory, recursing into the subdirectories, and excluding via the C<exclude> patterns. This is less efficient, however may be necessary if the actions taken might confuse C<readdir>. For example if changing the name of the file. This is only a per-directory defer however, moving files between directory might still be suspect.

=item *

C<act_on_directories> - when set to a true value, tells C<walkdir> to include the directory names as files to be acted on (subject to the normal exclusion mechanisms). For protection from infinite loops, directory actions are always deferred.

=back

Note: C<walkdir> will act on symlinked files but not on symlinked folders to prevent unwanted actions outside the folder and to prevent infinite loops. To exclude symlinked files too add a line like C<return if (-l $filename);> near the top of the code to be executed; this is an example of the fine exclusion mentioned above.

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/File-chdir-WalkDir>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

