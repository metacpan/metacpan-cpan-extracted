package Geo::Postcodes::Update;

#################################################################################
#                                                                               #
#           This file is written by Arne Sommer - perl@bbop.org                 #
#                                                                               #
#################################################################################

use strict;
use warnings;

use LWP::Simple (); 

our $VERSION = '0.311';

#################################################################################

sub update
{
  my $module_name   = shift;
  my $file_name     = shift;
  my $full_url      = shift; # Can be 'undef'
  my $procedure     = shift;
  my $update        = shift; # Do not update the module, but show the resulting perl code.

  $module_name = "$module_name.pm" unless $module_name =~ /\.pm$/;
 
  unless (-e $module_name)
  {
    if (-e "lib/Geo/Postcodes/")
    {
      chdir("lib/Geo/Postcodes/");
    }
    elsif (-e "../lib/Geo/Postcodes/")
    {
      chdir("../lib/Geo/Postcodes/");
    }
  }

  die("Unable to find '$module_name'") unless -e $module_name;

  my $in = "../../../misc/$file_name";

  my $downloaded = 0;

  unless (-e $in)
  {
    print "The file 'misc/$file_name' does not exist.\n";
    $downloaded = _download_it($full_url, $in) if $full_url;
  }

  die "Unable to open the file 'misc/$file_name'.\n - Unable to update the module.\n" unless -e $in;

  unless (_update_module($module_name, $in, $procedure, $update))
  {
    unless ($downloaded)
    {
      $downloaded = _download_it($full_url, $in) if $full_url;

      _update_module($module_name, $in, $procedure, $update) if $downloaded;
    }
  }
}

################################################################################

sub _download_it
{
  my $full_url = shift;
  my $in       = shift;

  if (_ask("Do you want to download '$full_url'"))
  {
    if (-e $in)
    {
      rename($in, $in . "." . time());
    }

    if (LWP::Simple::getstore($full_url, $in))
    {
      print "Downloaded file '$full_url'.\n";
      return 1;

      print "Unable to download file '$full_url'.\n";
      return 0;
    }
  }
}

################################################################################

sub _update_module
{
  my $module_name = shift;
  my $in          = shift;
  my $procedure   = shift;
  my $update      = shift;

  my $file = $in =~ /(misc.*)/; # Get rid of the leading "../../.." to avoid confusion.

  unless ($update) # No update of the module.
  {
    print "Verbose mode; no file update.\n";
    print "----------------------------------------------------\n";
    print "## misc/update begin\n";
    print "## This data structure was auto generated on " . localtime() . ". Do NOT edit it!\n\n";

    open(IN, $in) or die "Unable to open the file $file.\n";
    my @new = &$procedure(<IN>);
    print @new;
    close IN;
    print "----------------------------------------------------\n";
    print "(Verbose mode, no file update!)\n";
    print "Run the program with the '-update' argument to update the module.\n";
    return 1;
  }

  open(OLD, $module_name) or die "Unable to open the file $module_name.\n";
  open(NEW,    ">$module_name.new") or die "Unable to open the file '$module_name.new'.\n";

  ## Copy the old file - part 1

  my $part = 1; # 1 (first) 2 (skip) 3 (last)
  my @part1;
  my @part2;    # For comparison.
  my @part3;

  foreach (<OLD>)
  {
    if (m{^\#\# misc/update begin})
    {
      $part = 2; # This part we skip.
    }
    elsif (m{^\#\# misc/update end})
    {
      $part = 3; push(@part3, $_);
    }
    elsif ($part == 1) { push(@part1, $_); }
    elsif ($part == 2) { push(@part2, $_); }
    elsif ($part == 3) { push(@part3, $_); }
  }

  close OLD;
  print NEW @part1;

  ## Update the postal info - part 2

  print NEW "## misc/update begin\n";
  print NEW "## This data structure was auto generated on " . localtime() . ". Do NOT edit it!\n\n";

  open(IN, $in) or die "Unable to open the file $file.\n";

  my @new = &$procedure(<IN>);

  print NEW @new;
  close IN;

  ## Copy the old file - part 3

  print NEW @part3;
  close NEW;

  ## Check for equality ###

  my $old_line; my $new_line;

  my $difference = 0;

  shift @part2; shift @part2; # Get rid of some initial lines.

FRCH:
  foreach $new_line (@new)
  {
    $old_line = shift(@part2) || "";
    if ($old_line ne $new_line)
    {
      $difference++;
      last FRCH;
    }
  }

  if ($difference)
  {
    my $source = "$module_name." . time;
    rename($module_name, $source) or die "Unable to rename file $module_name.\n";
    rename("$module_name.new", $module_name);
    print "The postcodes are updated in the module.\n";
    print " - The old file is available as '$source'\n";
    return 1;
  }
  else
  {
    $in =~ m{.*/(.*)}; # Drop all the leading line nose; e.g. 'tilbud5' instead of 
                       #  '../../../misc/tilbud5'.

    print "The postcodes in the module are the same as in the file '$1'.\n";
    print " - The module did not need an update.\n";
    unlink "$module_name.new";
    return 0;
  }
}

################################################################################

sub _ask
{
  my $question = shift;
  print "$question (y/n): ";
  my $answer = <STDIN>;
  return $answer =~ /y/i; # Accept Y as well.
}

################################################################################

__END__

=head1 NAME

Geo::Postcodes::Update - Helper module for keeping the postcodes up to date

=head1 SYNOPSIS

 #! /usr/bin/perl -w
 use strict;
 use Geo::Postcodes::Update;

 my $class     = 'NO';
 my $file      = 'tilbud5';
 my $url       = 'http://epab.posten.no/Norsk/Nedlasting/_Files/tilbud5';
 my $procedure = \&parse_no;
 my $update    = @ARGV && $ARGV[0] eq "-update";

 Geo::Postcodes::Update::update($class, $file, $url, $procedure, $update);

 sub parse_no
 {
   my @in = @_;
   my @out;
   ...
   return @out;
 }

This is how the norwegian postcodes are treated, without showing the inner workings of
I<parse_no> which receives the lines from the file I<tilbud5> and returns suitable perl
code for inclusion in the module. (The program is included as I<misc/update_no> in the norwegian module.)

Run the program from the root (or the I<./misc>) directory of the distribution.

=head1 PROCEDURES

This module has only one external procedure.

=head2 update

Call this procedure with the following four parameters:

=over

=item Class Name

The name of the class in upper case letters, e.g. 'DK', 'NO' or 'U2'.
This is a two-letter country code, as defined in I<ISO 3166-1>,
except for our utopian 'U2' (as used in the tutorial;
I<perldoc Geo::Postcodes::Tutorial> or I<man Geo::Postcodes::Tutorial>).

=item File Name

The file where the postcodes are taken from. It is located in the
I<./misc> directory of the distribution, together with the I<update_xx> program.

=item URL

An optional URL, where the program can download the postcode file if allowed
to do so by the user. Use I<undef> if no URL is available.

=item Procedure

A pointer to a procedure that parses the postcode data. It will receive the lines
from the postcode file as input, and must return a list of perl code lines with
a suitable data structure, ready for writing to the country module file.

=item Update Flag

Set this to true to get the procedure to actually offer to update the module. It will
display the perl code on-screen otherwise. This is usefull for debugging purposes when
making the parsing procedure.

=back

=head1 WALK-THROUGH

The I<update_*> programs will do the following, when executed:

=over

=item 1

(URL Specified:) The program offers to fetch the postcode file, if it cannot
locate the postcode file (in the I<./misc> directory). The user can decline the
offer.

=item 2

The program terminates if it cannot locate the postcode file (in the I<./misc>
directory).

=item 3

If the 'update' flag is B<not> set, the program outputs the data structure (as lines
of perl code on-screen) and terminates.

=item 4

The program compares the data structure in the module with the one taken from
the postcode file. The module is updated if the data structures differ, and the
program will terminate.

=item 5

The program terminates if it has fetched the postcode file already (in point 1).

=item 6

As point 1.

=item 7

As point 2.

=item 8

As point 4.

=back

=head1 REQUIREMENTS

This module requires the CPAN-module I<libwww-perl> to work. It is used for semiautomatic
downloading of the postcode file.

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2006 by Arne Sommer - perl@bbop.org

This library is free software; you can redistribute them and/or modify
it under the same terms as Perl itself.

=cut
