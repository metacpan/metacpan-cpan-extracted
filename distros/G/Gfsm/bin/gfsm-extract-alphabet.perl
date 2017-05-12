#!/usr/bin/perl -w

use Gfsm;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename);

##======================================================================
## Defaults

our $prog    = basename($0);
our $VERSION = 0.01;

our ($help,$version);

##-- Extraction
our $xlo = undef;
our $xhi = undef;
our $labfile = undef;
our $outfile = '-';

##======================================================================
## Command-Line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'version|V' => \$version,

	   ##-- Extraction
	   'labels|l|i=s' => \$labfile,
	   'lower|lo!'    => sub { $xlo=$_[1]; $xhi=!$_[1] if (!defined($xhi)); },
	   'upper|up|hi!' => sub { $xhi=$_[1]; $xlo=!$_[1] if (!defined($xlo)); },
	   'both|b!'      => sub { $xlo=$xhi=$_[1]; },
	   'output|o=s'   => \$outfile,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

if ($version) {
  print STDERR
    ("${prog} v$VERSION by Bryan Jurish <moocow\@bbaw.de>\n",
    );
  exit(0);
}



##======================================================================
## Main

##-- sanity check
if (!$xlo && !$xhi) { $xlo=$xhi=1; }

##-- load labels
our ($abet_in);
if (defined($labfile)) {
  $abet_in = Gfsm::Alphabet->new();
  $abet_in->load($labfile)
    or die("$prog: load failed for input labels file '$labfile': $!");
}

our %fsmlabs = qw();
push(@ARGV,'-') if (!@ARGV);

our $fsm = Gfsm::Automaton->new();
our $ai  = Gfsm::ArcIter->new();

foreach $file (@ARGV) {
  print STDERR "$prog: processing FSM file '$file'... ";
  $fsm->load($file)
    or die("$prog: load failed for gfsm file '$file': $!");

  foreach $state (0..($fsm->n_states-1)) {
    for ($ai->open($fsm,$state); $ai->ok; $ai->next()) {
      @fsmlabs{$ai->lower} = undef if ($xlo);
      @fsmlabs{$ai->upper} = undef if ($xhi);
    }
    $ai->close;
  }
  print STDERR "done.\n";
}

##======================================================================
## Output
our $abet_out = Gfsm::Alphabet->new();
if (defined($abet_in) && $abet_in->size) {
  my $id2lab_in = $abet_in->asArray;
  $abet_out->insert($id2lab_in->[$_], $_) foreach (keys(%fsmlabs));
} else {
  $abet_out->insert($_,$_) foreach (keys(%fsmlabs));
}
$abet_out->save($outfile);


__END__

##======================================================================
## Pods
=pod

=pod

=head1 NAME

gfsm-extract-alphabet.perl - extract alphabet from a Gfsm::Automaton

=head1 SYNOPSIS

 gfsm-extract-alphabet.perl [OPTIONS] GFSMFILE(s)

 General Options:
  -help
  -version

 Extraction Options:
  -lower , -nolower # do/don't extract only upper labels (default=do)
  -upper , -noupper # do/don't extract only lower labels (default=do)
  -both  , -noboth  # do/don't extract lower & upper labels
  -labels LABFILE
  -output OUTFILE

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

Not yet written.

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@ling.uni-potsdam.deE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Bryan Jurish

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
Gfsm(3perl)

=cut

