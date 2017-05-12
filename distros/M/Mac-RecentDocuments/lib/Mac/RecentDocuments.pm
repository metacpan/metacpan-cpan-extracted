
require 5;
package Mac::RecentDocuments;
use strict;   # Time-stamp: "2004-12-29 18:58:03 AST"
use vars qw($RD $SF $OK $AM @ISA @EXPORT %EXPORT_TAGS $VERSION);
$VERSION = '1.02';

require Exporter;
@ISA = ('Exporter');
@EXPORT = ('recent_document', 'recent_documents');
%EXPORT_TAGS = (
 'all' => \@EXPORT,
 'none' => [],
);

=head1 NAME

Mac::RecentDocuments -- add items to the MacOS Recent Documents menu

=head1 SYNOPSIS

  use Mac::RecentDocuments qw(:ARGV);
   # Adds all files in @ARGV to Recent Documents folder,
   #  and imports recent_documents and recent_document
  
  foreach my $in (@ARGV) {
    open(IN, "<$in") or die "Can't read-open $in: $!";
    my $out = $in . '2';
    die "But $out already exists!" if -e $out;
    open(OUT, ">$out") or die "Can't write-open $out: $!";
    
    ...do whatever to $out...
    
    recent_documents($out); # add to Recent Documents folder
  }

=head1 DESCRIPTION

This module provides a function that adds specified files to the
MacOS Apple Menu "Recent Documents" folder.  You can use this module
under non-MacOS environments, and it will compile, but it will do
nothing.

=head1 FUNCTIONS

=over

=item recent_documents( ...files... )

This adds the given items to the Recent Documents folder, for each item
that is a pathspec to an existing file. Relative (C<":bar.txt">) as
well as absolute filespecs (C<"Lame Drive:stuff:bar.txt">) should work
equally well.

The number of aliases that this creates in the Recent Documents folder
is returned.

Under non-MacOS environments, this function does nothing at all, and
always returns 0.

=item recent_document( file )

This is just an alias to C<recent_documents>

=item Mac::RecentDocuments::OK()

This function returns true iff you are running under MacOS, and if, at
compile-time, Mac::RecentDocuments was able to find your Recent
Documents folder, and verified that it was a writeable directory.
In all other cases, this returns false.

=back

=head1 IMPORTING, AND :ARGV

If you say

  use Mac::RecentDocuments;

then this will by default import the functions C<recent_documents>
and C<recent_document>.

This is equivalent to:

  use Mac::RecentDocuments qw(:all);

If you want to use the module but import no functions, you can say:

  use Mac::RecentDocuments ();

or

  use Mac::RecentDocuments qw(:none);

This module also defines a use-option C<":ARGV"> that causes
Mac::RecentDocuments to also call C<recent_documents(@ARGV)>, at compile
time.  This should be rather useful with MacPerl droplets.

That is, this:

  use Mac::RecentDocuments qw(:ARGV);

is basically equivalent to:

  BEGIN {
    use Mac::RecentDocuments;
    Mac::RecentDocuments(@ARGV);
  }

(The only difference is that if several instances of
C<use Mac::RecentDocuments qw(:ARGV)> are seen in a given session,
C<Mac::RecentDocuments(@ARGV)> is called only the first time.)

When "qw(:ARGV)" is the whole option list, it is interpreted as
equivalent to "qw(:ARGV :all)".  If you want the C<:ARGV> option
without importing anything, explicitly specify the C<":none">
option:

  use Mac::RecentDocuments qw(:ARGV :none);

=head1 CAVEATS

The module is called Mac::RecentDocuments (no underscore), but
the function is called C<recent_documents> (with underscore).

The module is called Mac::RecentDocuments, not Mac::RecentFiles.

=head1 THANKS

Thanks to Chris Nandor for the C<kRecentDocumentsFolderType> tips.

=head1 COPYRIGHT

Copyright (c) 2000 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut

#--------------------------------------------------------------------------

$OK = 0;

sub OK () {$OK}

sub recent_document { goto &recent_documents } # alias

#--------------------------------------------------------------------------
my $already_argved = 0;
sub import {
  if(@_ > 1) {
    my $argvy;
    for(my $i = 1; $i < @_;) {
      if($_[$i] eq ':ARGV') {
        $argvy = 1;
        splice(@_,$i,1); # remove the ':ARGV'
      } else {
        ++$i;
      }
    }
    if($OK and $argvy and not $already_argved) {
      recent_documents(@ARGV);
      $already_argved = 1;
    }
    if(@_ == 1) { # did we just empty the list?
      push @_, @EXPORT;
    }
  }
  goto &Exporter::import;
}

#--------------------------------------------------------------------------
if(!$MacPerl::Version) {
  $OK = 0;
  eval 'sub recent_documents { 0 }';
  die $@, ' in ', __PACKAGE__ if $@; # should never fail!
} else {
  eval <<'EOMAC'; # cook up the MacPerl-specific code:

    # Init code :
    unless(defined $RD) {
      require Mac::Files;
      $RD = Mac::Files::FindFolder(
        Mac::Files::kOnSystemDisk(),
        'rdoc' # kRecentDocumentsFolderType
      );  # will work on only recent MacOS versions

      unless(defined $RD) {
        $AM = Mac::Files::FindFolder(
          Mac::Files::kOnSystemDisk(),
          Mac::Files::kAppleMenuFolderType()
        ); # should work anywhere
        if($AM and -e $AM) {
          $RD = $AM . ':Recent Documents';
        } else {
          #print "No AM: $AM?\n";
        }
      }

      unless(defined $RD) {
        $SF = Mac::Files::FindFolder(
          Mac::Files::kOnSystemDisk(),
          Mac::Files::kSystemFolderType()
        ); # should REALLY work anywhere
        if($SF and -e $SF) {
          $RD = $SF . ':Apple Menu Items:Recent Documents';
        } else {
          #print "No SF: $SF?\n";
        }
      }

      unless(defined $RD and -e $RD and -d _ and -w _) {
        #print "No RD ($RD)?\n";
        $RD = undef;
        $OK = 0;  # ahwell, give up
      } else {
        $OK = 1;
      }
    }

    sub recent_documents  {
      return 0 unless @_ and $OK;
      my $successes = 0;
      my $new;
      foreach my $item (@_) {
        next unless defined $item
         and $item =~ m/([^:]+)$/;
        $new = $RD . ':' . $1;
        
        next unless -e $item and -f _; # let only existing files thru
        #print "Trying $item -> $new\n";
        unlink($new); # which does nothing if there is none there
          # That presumably was a mere alias, tho.
          # Anyone putting real items in their RD folder gets what
          #  they deserve.
        if(symlink($item, $new)) {
          #print "OK\n";
          ++$successes;
        } else {
          #print "<$!>\n";
        }
      }
      return $successes;
    }
EOMAC
  ;
  die $@, ' in ', __PACKAGE__ if $@; # shouldn't fail!
}

#--------------------------------------------------------------------------
1;
