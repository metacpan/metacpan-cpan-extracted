#!/usr/bin/perl -w

use Gfsm;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename);
use IO::File;

use strict;

##======================================================================
## Defaults

our $prog    = basename($0);
our $VERSION = 0.01;
our ($help,$version);

our $labfile=undef;
our $fsmfile='-';
our $outfile='-';

our $max_len=10;

##======================================================================
## Command-Line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'version|V' => \$version,
	   ##
	   ##-- Extraction
	   'labels|l=s'            => \$labfile,
	   'max-length|maxlen|L=i' => \$max_len,
	   'output|o|F=s'          => \$outfile,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

if ($version) {
  print STDERR
    ("${prog} v$VERSION by Bryan Jurish <moocow\@bbaw.de>\n",
    );
  exit(0);
}

##======================================================================
## Main: fsm file
$fsmfile = @ARGV ? shift(@ARGV) : '-';

if (!defined($labfile) && $fsmfile ne '-') {
  $labfile = $fsmfile;
  $labfile =~ s/\.[^\.]*$//;
  $labfile .= '.lab';
}
pod2usage({-msg=>"Labels file must be specified when FSM is given on STDIN!", -exitval=>1, -verbose=>0})
  if (!defined($labfile));

##-- Main: load alphabet
our $abet = Gfsm::Alphabet->new();
die("$prog: could not load labels from '$labfile': $!")
  if (!$abet->load($labfile));
our $sym2id = $abet->asHash;
our $id2sym = $abet->asArray;

##-- Main: load FSM
our $fsm = Gfsm::Automaton->new();
die("$prog: could not load FST from '$fsmfile': $!") if (!$fsm->load($fsmfile));

##-- Main: output file
open(OUT,">$outfile") or die("$prog: open failed for output file '$outfile': $!");

##-- Main: report
print STDERR
  (
   "$prog: FSM           = $fsmfile (", $fsm->n_states, " state(s), ", $fsm->n_arcs, " arcs)\n",
   "$prog: Alphabet      = $labfile (", $abet->size, " labels)\n",
   "$prog: Output        = $outfile\n",
   "$prog: Max Length    = $max_len\n",
  );

##======================================================================
## Main: Generate

our %paths   = qw(); ## pack('LS*', $qid, @labels) => undef
our @configs = qw(); ## pack('LS*', $qid, @labels)
our %checked = qw(); ## pack('LS*', $qid, @labels) => $bool

push(@configs, pack('L',$fsm->root));
our $ai = Gfsm::ArcIter->new(); 
our ($cfg, $qid,@labs,$lo,$cfg2);
while (defined($cfg=pop(@configs))) {
  ($qid,@labs) = unpack('LS*', $cfg);

  ##-- check for final state
  $paths{$cfg}=undef if ($fsm->is_final($qid));

  ##-- check for more strings
  for ($ai->open($fsm,$qid); $ai->ok; $ai->next) {
    $lo = $ai->lower;
    if ($lo==$Gfsm::epsilon || @labs<$max_len) {
      $cfg2 = pack('LS*', $ai->target,@labs,($lo==$Gfsm::epsilon ? qw() : $lo));
      next if (exists($checked{$cfg2}));
      $checked{$cfg2}=undef;
      push(@configs,$cfg2);
    }
  }
}

##-- output
foreach $cfg (sort { length($a) <=> length($b) || $a cmp $b } keys(%paths)) {
  ($qid,@labs) = unpack('LS*',$cfg);
  print OUT
    (join('',
	  map {
	    (defined($_)
	     ? (length($_)<=1
		? $_
		: "[$_]")
	     : "X")
	  } @$id2sym[@labs]),
     "\n");
}

__END__

##======================================================================
## Pods
=pod

=head1 NAME

gfsm-enumerate.perl - enumerate strings in an FSA

=head1 SYNOPSIS

 gfsm-enumerate.perl [OPTIONS] GFSMFILE

 General Options:
  -help
  -version

 Lookup Options:
  -maxlen  LENGTH     # maximum length of strings to generate
  -labels  LABFILE    # default=`basename FSTFILE`.lab
  -output  OUTFILE    # default=STDOUT

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

