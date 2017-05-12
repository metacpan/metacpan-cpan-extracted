package File::Irenamer;
##############################################################################
#  $Id: Irenamer.pm,v 1.3 2004/11/07 13:59:23 bheckel Exp bheckel $
#
#  $Log: Irenamer.pm,v $
#  Revision 1.3  2004/11/07 13:59:23  bheckel
#  Adjust docs
#
#  Revision 1.2  2004/11/07 02:30:36  bheckel
#  Cleaned up release for initial upload to CPAN
#
#  Revision 1.1  2004/11/07 02:29:39  bheckel
#  Initial revision
#
##############################################################################
use 5.008002;
use strict;
use warnings;
use Getopt::Std;
use File::Find;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
  InteractiveRename
);
our $VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/o);
our %opts;

getopts('drv', \%opts);


# Main
sub InteractiveRename {
  my (@options) = @_;

  $opts{d} = 1 if grep { /debug/ } @options;
  $opts{r} = 1 if grep { /recurse/ } @options;
  $opts{v} = 1 if grep { /verbose/ } @options;

  if ( $ARGV[0] ) {
    # Remove user's trailing slash if necessary.
    $ARGV[0] =~ s#/$##;
  } else {
    # Default to current working dir.
    $ARGV[0] = '.';
  }

  print "DEBUG \$ARGV[0] is $ARGV[0]\n" if $opts{d};

  RenameFiles(ParseChanges(EditFilesInEditor(ReadFiles($ARGV[0]))));

  exit 0;
}


my @FILES;
sub Wanted {
  -f $_ and push @FILES, $File::Find::name;
}


sub ReadFiles {
  my $dir = shift;

  @FILES = ();

  die "ERROR: no input directory in ReadFiles().  Exiting.\n" if ! $dir;

  if ( $opts{r} ) {
    find \&Wanted, $dir;
  } else {
    opendir DH, "$dir" or die "Error: $0: $!";
    @FILES = grep { !/^..?$/ && !-d } map "$dir/$_", readdir DH;
    close DH;
  }

  return @FILES;
}


sub EditFilesInEditor {
  my @orignames = @_;

  my $rand = int(rand(42)) + time + $$;
  my $tmpfile = "$ENV{TMP}/renamer-pl.$rand.tmp";
  open TMPF, ">$tmpfile" || die "Can't create $tmpfile in $ENV{TMP}: $!\n";

  print TMPF <<"EOT";
#
# Changes to these filenames will be made after exiting this
# tempfile.  Delete all lines to cancel.
#
EOT

  for ( @orignames ) {
    print TMPF "$_\n";
  }
  
  close TMPF;

  system "$ENV{EDITOR} $tmpfile";

  # We make changes to $tmpfile within our favorite editor...Vim, right? ;-)

  open TMPF, "<$tmpfile" || die "Can't open $tmpfile : $!\n";
  my @newnames = <TMPF>;
  @newnames = grep { !/^#/ } @newnames;

  if ( $opts{d} ) {
    close TMPF;
    print "DEBUG: $tmpfile\n";
  } else {
    # TODO only if user does not cancel
    close TMPF && unlink $tmpfile;
  }

  return \@orignames, \@newnames;
}


# Parse saved editor diffs into a hash.
sub ParseChanges {
  my $origarrref = shift;
  my $newarrref = shift;

  if ( scalar @$origarrref != scalar @$newarrref ) {
    die "ERROR: Problem with parsing filename change file.\nDifferent " .
        "number of files in old vs. new.  Exiting.\n";
  }

  my %same = map { $_, 1 } @$origarrref;

  my %torename;
  my $i = 0;
  foreach my $f ( @$newarrref ) {
    chomp $f;  # take away newlines used previously for easier editing
    if ( ! $same{$f} ) {   
      $torename{@$origarrref[$i]} = @$newarrref[$i];
    }
    $i++;
  }

  return \%torename;
}


sub RenameFiles {
  my $hr = shift;

  if ( ! keys %$hr ) {
    die "No changes requested.  Exiting.\n" if $opts{v};
  } else {
    print "We are about to rename:\n" if $opts{v};
  }

  foreach ( sort keys %$hr ) {
    print "  FROM:\t$_\n    TO:\t$$hr{$_}\n\n" if $opts{v};
  }

  if ( $opts{v} ) {
    print "Proceed? [yes/no] ";
    if ( <STDIN> !~ /yes/i ) {
      die "cancelled\n";
    }
  }

  # It's possible to try to rename a file into a subdir that doesn't exist,
  # etc.  Can't stop all stupidity but can at least whine about it.
  my $rc = 1;
  foreach ( sort keys %$hr ) {
    $rc = rename $_, $$hr{$_};
    print "Potential error during rename of $_\n" if $rc ne 1;
  }

  if ( $opts{v} ) {
    print "Directory contents after committed changes:\n";
    map { print "  $_\n" } ReadFiles($ARGV[0]);
  }

  return 0;
}


1;


__END__


=head1 NAME

File::Irenamer - Perform interactive filename changes from within 
                 an editor


=head1 SYNOPSIS

  use Irenamer;

  InteractiveRename();
  InteractiveRename(verbose);
  InteractiveRename(recurse);
  InteractiveRename(debug);
  InteractiveRename(recurse,verbose,debug);


  Recognizes up to three optional switches:
    -d debug mode
    -r recurse mode
    -v verbose mode


  E.g. 

    $ perl -MFile::Irenamer -e 'InteractiveRename()' 
    $ perl -MFile::Irenamer -e 'InteractiveRename(verbose)' /tmp/mydir


    or via a separate script:

    $ cat mytest.pl
    #!/usr/bin/perl

    use strict;
    use warnings;
    use File::Irenamer;

    InteractiveRename();


    $ mytest.pl -dv ~/mydir


=head1 DESCRIPTION

Interactive file renamer module allows filename changes from within
your favorite editor.  

It is most useful when complicated or one-time repetitive changes to a
directory or directory tree must be made but programmatic solutions are
probably not worth the time to implement.  Defaults to 'do not recurse'.

It exports a single function called InteractiveRename()

It assumes a Unix-like environment that exports $EDITOR.
If you're on Win32, Cygwin works well.  Otherwise you can try to set 
$ENV{EDITOR} in the code that calls InteractiveRename().

Verbose mode is highly recommended, at least initially, since there is no
prompting nor undo available.


=head1 EXPORT

None by default.


=head1 TODO

Code is blissfully unaware of filesystem permissions.

Tempfile creation is not craker-proofed.


=head1 SEE ALSO

Perl's rename function

www.vim.org


=head1 AUTHOR

Robert S. Heckel Jr., E<lt>bheckel@gmail.com<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Robert S. Heckel Jr.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

I've used this code reliably for quite a while but, as you'd expect, I 
cannot take responsibility for any damage to your files (or your foot 
should you choose to shoot it) so obviously use it at your own risk.


=cut
