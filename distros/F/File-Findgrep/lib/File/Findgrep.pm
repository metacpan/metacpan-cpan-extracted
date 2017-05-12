
package File::Findgrep;
require 5.005;  # we want qr's !
$VERSION = '0.02';
use strict;

# POD AT THE END!

sub Locale::Maketext::DEBUG () {0}
 # set to 1 or higher to see trace messages.

sub DEBUG () {0}

use File::Findgrep::I18N;
use vars qw($LH $orig_rs $binary_re);

$LH = File::Findgrep::I18N->get_handle()
 || die "Can't get a language handle!";

#------------------------------------------------------------------------
$orig_rs = $/;

$binary_re = # file suffixes to ignore:
             qr<\.(?:
              gif|png|jpg|jpeg|bmp|wav|snd|ra|ram|au|exe|com|img
              |pdf|ps|jar|mcp|ico|cur
              |mid|sit|mp3|hqx|uu|uue|swf|tgz|tar\.gz|zip|z|gz
             )(?:~.*)?$>xis;

sub findgrep {
  @_ = @ARGV unless @_;
  _usage($LH->maketext("What options?")) unless @_;
  
  my($_R, $_m, $_M) = (0,1,10_000_000);  # defaults
  # Lame switch processing...
  while(@_ and $_[0] =~ m/^-/s) {
    if($_[0] eq '-R')                   { $_R =  1 }
    elsif($_[0] =~ m/^-m=?(\d+)/s)      { $_m = $1 * 1           }
    elsif($_[0] =~ m/^-m=?(\d+)[Kk]$/s) { $_m = $1 * 1024        }
    elsif($_[0] =~ m/^-m=?(\d+)M$/s)    { $_m = $1 * (1024 ** 2) }
    elsif($_[0] =~ m/^-m=?(\d+)G$/s)    { $_m = $1 * (1024 ** 3) }
    elsif($_[0] =~ m/^-M=?(\d+)/s)      { $_M = $1 * 1           }
    elsif($_[0] =~ m/^-M=?(\d+)[Kk]$/s) { $_M = $1 * 1024        }
    elsif($_[0] =~ m/^-M=?(\d+)M$/s)    { $_M = $1 * (1024 ** 2) }
    elsif($_[0] =~ m/^-M=?(\d+)G$/s)    { $_M = $1 * (1024 ** 3) }
    # two bonus switches:
    elsif($_[0] eq '--') { shift @_; last; }
    elsif($_[0] eq '-h') { _usage() }
    else { _usage($LH->maketext("Unknown switch \"[_1]\"\n", $_[0])) }
    shift @_;
  }
  
  die $LH->maketext(
    "Minimum ([_1]) is larger than maximum ([_2])!\n",
    $_m, $_M
   ) if $_m > $_M   # sanity
  ;
  
  _usage($LH->maketext("Not enough arguments for findgrep!")) unless @_;
  my($line_pattern, $file_pattern);

  eval { $line_pattern = qr/$_[0]/i };
  $@ and die $LH->maketext("Invalid line-regexp: [_1] -- [_2]",
    $_[0], $@
  );
  shift @_;
  
  if(@_) {
    $file_pattern = $_[0];
    if($file_pattern =~ m/^[*?]/s) {
      # forgive things that look like wildcards instead of REs, I guess
      $file_pattern = '^' . $file_pattern . '$';
      $file_pattern =~ s/\*/.*/gs;
      $file_pattern =~ s/\?/./gs;
    }

    eval { $file_pattern = qr/$file_pattern/i };
    $@ and die $LH->maketext("Invalid file-regexp: [_1] -- [_2]",
      $_[0], $@
    );
    shift @_;
  } else {
    $file_pattern = qr/^[^.~][^~]+$/s;
      # we can ignore the possibilty of a zero-length filename, I think.
  }
  
  my @dirs = @_;
  @dirs = ('.') unless @dirs;
  my($lines_matched, $files_matched, $directory_count) = (0,0,0);
  
  my $recursor;
  $recursor = sub {
    my $dir = $_[0];
    $dir .= '/' unless $dir =~ m<[\\/]$>s;
    my @files;
    unless(opendir(INDIR, $dir)) {
      warn $LH->maketext("Can't open directory [_1]: [_2]\n", $dir, $!);
      closedir(INDIR);
      return;
    }

    @files = sort readdir(INDIR);
    DEBUG and print "Items in $dir: <@files>\n";
    ++$directory_count;
    closedir(INDIR);
    print STDERR $LH->maketext("# Searching in directory [_1]\n", $dir);

    my $basename;
   File:
    foreach my $f (@files) {
      next File if $f eq '.' or $f eq '..'; # skip scary things
      $basename = $f;
      $f = "$dir$f";       # fully qualify it
      DEBUG > 2 and print "Considering $f\n";
      if(-l $f) {
        # skip symlinks
        DEBUG and print "$f is a symlink.  Skipping.\n";
      } elsif(-d _ and $_R) {
        DEBUG and print "$f is a dir.  Recursing.\n";
        $recursor->($f); # recurse into the subdir
      } elsif(
         -f _ and 
         -s _ >= $_m    and   -s _ <= $_M
      ) {
        DEBUG and print "Considering file $f...\n";
        if($basename =~ $binary_re) {
          DEBUG and print "The filename $basename is excluded by binary_re.\n";
          next File;
        } elsif($basename =~ $file_pattern ) {
          DEBUG > 1 and print "The filename $basename matches $file_pattern\n";
        } else {
          DEBUG > 1 and print
           "The filename $basename doesn't match $file_pattern!  Skipping\n";
          next File;
        }
        unless(open(IN, "<$f")) {
          close(IN);
          warn $LH->maketext( "Can't open file [_1]: [_2]\n", $f, $! );
          next File;
        }
        my $chunk = '';
        binmode(IN);
        read(IN, $chunk, 1024);

        if($chunk =~ m/[\x00-\x08\x0b\x0e-\x1F]/s) {
          # any control codes but tab (09), lf(0a), ff (0c), and cr (0d)
          print STDERR "# ", $LH->maketext(
            "[_1] looks like a binary file.  Skipping.\n", $f
          );
          close(IN);
          next;
        } elsif($chunk =~ m<(\cm\cj|\cm|\cj)>s) {
          $/ = $1;
        } else {
          $/ = $orig_rs;
        }
        
        seek(IN,0,0); # rewind
        my $count_this_file;
        while(<IN>) {
          next unless $_ =~ $line_pattern;
          chomp;
          print "$f\:$.\:$_\n";
          ++$lines_matched;
          $count_this_file = 1;
        }
        close(IN);
        ++$files_matched if $count_this_file;
        
      } # end of if-it's-a-file
    } # end of File loop
    return;
  }; #end of closure
  

  # Prep for the recursion:
  local $/ = $/; # since the file loop alters $/
  local($_);     # since the file loop alters $_
  ++$|;
  { my $oldfh = select(STDERR); ++$|; select($oldfh); }
  DEBUG and print "Dirs: <@dirs>\n";

  # Actually recurse now:
  foreach my $dir (@dirs) { $recursor->($dir) }
  undef $recursor; # break self-reference
  
  print $LH->maketext(
    "Found [quant,_1,line] in [quant,_2,file], in [quant,_3,directory,directories] scanned.\n",
    $lines_matched, $files_matched, $directory_count
  )
}

#---------------------------------------------------------------------------

sub _usage {
  die join("\n", @_, $LH->maketext('_USAGE_MESSAGE'));
}

#------------------------------------------------------------------------
findgrep(@ARGV) unless caller; # if executed instead of used, go run!
1;

__END__

Example batch file using this module:

@echo off
rem  set LANG=fr
rem    or, with Win32::Locale installed, just set your locale
rem    in the "Regional Settings" control panel.
perl -MFile::Findgrep -e File::Findgrep::findgrep(@ARGV) -- %1 %2 %3 %4 %5 %6 %7 %8 %9

=head1 NAME

File::Findgrep -- example Locale::Maketext-using application

=head1 SYNOPSIS

  # Nih.

=head1 DESCRIPTION

This module provides a trivial reimplementation of Unix find and grep.
It is most useful as an example of a small application that
uses L<Locale::Maketext|Locale::Maketext>.  Read the source of these
files:

File/Findgrep.pm

File/Findgrep/I18N.pm

File/Findgrep/I18N/en.pm

File/Findgrep/I18N/en-us.pm

File/Findgrep/I18N/fr.pm

File/Findgrep/I18N/i-default.pm

Remember that perldoc -l I<modulename> will tell the path to where
this module in installed -- if you install it at all.

=head1 COPYRIGHT AND DISCLAIMER

Copyright (c) 2001 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut

# YOW!

