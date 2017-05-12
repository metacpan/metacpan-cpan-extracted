package Emacs::Run::Testorama;
#                                doom@kzsu.stanford.edu
#                                24 Mar 2008


=head1 NAME

Emacs::Run::Testorama - routines for just for writing tests of Emacs::Run

=head1 SYNOPSIS

   use Emacs::Run::Testorama ':all';

   my $mock_home = "$Bin/dat/home/mockingbird";
   my $code_lib = "$USR/lib";
   my $code_lib_alt = "$USR/lib-alt";
   my $dot_emacs_tpl = "$SRC_LOC/templates/.emacs-template";

   create_dot_emacs_in_mock_home( $mock_home, $code_lib, $code_lib_alt, $dot_emacs_tpl );

=head1 DESCRIPTION

Emacs::Run::Testorama is a small collection of utility routines
to be used in testing the Emacs::Run package.  It is not expected
that there will be any reason to install this for use on the
system at large.

=head2 EXPORT

None by default.  The follow are available on request (all
can be requested at once using the ':all" tag).

=over

=cut

use 5.8.0;
use strict;
use warnings;
my $DEBUG = 0;
use Carp;
use Data::Dumper;
use File::Path     qw( mkpath );
require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [
  # TODO Add names of items to export here.
  qw(
      create_dot_emacs_in_mock_home
      clean_whitespace
      create_dot
      echo_home
      slurp_files
      get_short_label_from_name
    ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(  );
our $VERSION = '0.01';

=item clean_whitespace

# trims leading and trailing whitespace on multi-line text.
# eliminates blank lines.
# this is used to make it eaisier to compare generated and expected elisp

=cut

sub clean_whitespace {
  my $text = shift;
  my $output;
  my @lines = split /\n/, $text;
  foreach my $line (@lines) {
    $line =~ s{^\s+}{}xms;
    $line =~ s{\s+$}{}xms;
    next if ($line =~ m{^ \s* $}xms);
    $output .= "$line\n";
  }
  return $output;
}

=item create_dot_emacs_in_mock_home

# create a .emacs for $mock_home

Args:

  first:    (path) a mock home location for a non-existant user
  second:   (path) a dummy location of elisp libraries
  third:    (path) another dummy location of elisp libraries
  fourth:   (file) the dot emacs "template" used to create a .emacs
                 for the dummy user

Note: this resorts to a number of cheesy expedients that would
not be recommended in production use: The .emacs files are
generated using a home grown template "language" where the second
and third arguments of this routine are subsituted for the
strings 'XXX' and 'YYY'.  For our current purposes, we expect
that these are elisp library locations, but nothing enforces this.

=cut

sub create_dot_emacs_in_mock_home {
  my $mock_home     = shift;
  my $code_lib      = shift;
  my $code_lib_alt  = shift;
  my $dot_emacs_tpl = shift;

  if ($DEBUG) {
    print STDERR "mock_home: $mock_home\n";
    print STDERR "code_lib: $code_lib\n";
    print STDERR "code_lib_alt: $code_lib_alt\n";
    print STDERR "dot_emacs_tpl: $dot_emacs_tpl\n";
  }

  # make sure $mock_home exists
  mkpath( $mock_home ) unless -d $mock_home;

  # read in template used to create a mock .emacs
  open my $fh_in, "<", $dot_emacs_tpl
    or die "Could not open $dot_emacs_tpl for read:$!";

  my $slurpie;
  {
    undef $/;
    $slurpie =<$fh_in>;
  }

  # munge template placeholders XXX and YYY with mock library locations.
  $slurpie =~ s{XXX}{$code_lib}xmsg;
  $slurpie =~ s{YYY}{$code_lib_alt}xmsg;

  # output the mock .emacs file in the mock home directory
  my $dot_emacs = "$mock_home/.emacs";
  open my $fh_out, ">", $dot_emacs
    or die "Could not open $dot_emacs for read:$!";

  print {$fh_out} $slurpie;
  close($fh_out);

  return $dot_emacs;
}

=item echo_home

Prints the current home location to STDERR (for debugging purposes).

=cut


sub echo_home {
  print STDERR "HOME is now: $ENV{HOME}\n";
}


=item slurp_files

Given two files (with full paths, most likely) open them, slurp in
their contents, and return a list of both of them.

This is a utility to make it slightly easier to compare the effects
of a file munging operation to an archived copy of the expected
results.

Example usage:

  my ($result, $expected) = slurp_files($result_file, $expected_file);

  eq_or_diff( $result, $expected,
              "$test_name: checking effects of upcase-region on $result_file");

  # Note: presumes Test::Differences is in use.

=cut


sub slurp_files {
  my $result_file   = shift;
  my $expected_file = shift;

  # open each file, slurp in.
  local $/; # mister slurpie
  open my $fh, "<", $result_file or die "Could not open $result_file for read:$!";
  my $result = <$fh>;
  close( $fh );

  open $fh, "<", $expected_file or die "Could not open $expected_file for read:$!";
  my $expected = <$fh>;
  close( $fh );

  return ($result, $expected);
}

=item get_short_label_from_name

If a given name is long (i.e. has many hyphens),
will create a short version of it (arbitrarily
taking the fourth element).

=cut

sub  get_short_label_from_name {
  my $varname = shift;
  my @frags = split /-/, $varname;
  my $varlabel;
  if (scalar @frags > 3) {
    $varlabel = $frags[3];
  } else {
    $varlabel = $varname;
  }
  return $varlabel;
}



1;

=back

=head1 SEE ALSO

L<Emacs::Run>

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
