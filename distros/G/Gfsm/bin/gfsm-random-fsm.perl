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

##-- options: I/O
our $outfile = '-';
our $zlevel  = -1;

##-- options: topology
our $acceptor = 0;
our $epsilon  = 1;

our $n_states = 1;
our $n_arcs   = 1;
our $n_labels = 2;
our $n_finals = 1;
our $w_min = 0;
our $w_max = 0;

our $seed = undef;

##======================================================================
## Command-Line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'version|V' => \$version,

	   ##-- Topology
	   'seed|srand|r=i'  => \$seed,
	   'acceptor|fsa|A!' => \$acceptor,
	   'transducer|fst|T!' => sub { $acceptor=!$_[1]; },
	   'epsilon|eps|e!' => \$epsilon,
	   'n-states|states|q=i' => \$n_states,
	   'n-arcs|arcs|a=i' => \$n_arcs,
	   'n-finals|finals|f=i' => \$n_finals,
	   'n-labels|labels|l=i' => \$n_labels,
	   'min-weight|wmin|w=f' => \$w_min,
	   'max-weight|wmax|W=f' => \$w_max,

	   ##-- I/O
	   'output|o|F=s' => \$outfile,
	   'compress|z=i' => \$zlevel,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

if ($version) {

  print STDERR
    ("${prog} v$VERSION by Bryan Jurish <moocow\@cpan.org>\n",
    );
  exit(0);
}


##======================================================================
## Main
srand($seed) if (defined($seed));

our $fsm = Gfsm::Automaton->new();
$fsm->is_transducer(1);
$fsm->is_weighted(1);
$fsm->semiring_type($Gfsm::SRTTropical);


##-- stupid way
($w_min,$w_max) = sort ($w_min,$w_max);
our $l_min = $epsilon ? 0 : 1;

$fsm->add_state()
  foreach (1..$n_states);

$fsm->add_arc(int(rand($n_states)), int(rand($n_states)), $l_min+int(rand($n_labels)), $l_min+int(rand($n_labels)), $w_min+($w_min==$w_max ? 0 : rand($w_max-$w_min)))
  foreach (1..$n_arcs);

$fsm->final_weight(int(rand($n_states)), $w_min+($w_min==$w_max ? 0 : rand($w_max-$w_min)))
  foreach (1..$n_finals);

$fsm->root(0) if ($n_states);
$fsm->_project(Gfsm::LSLower()) if ($acceptor);

##-- save
$fsm->save($outfile,$zlevel)
  or die("$prog: save failed to gfsm file '$outfile': $!");


__END__

##======================================================================
## Pods
=pod

=pod

=head1 NAME

gfsm-random-fsm.perl - create a random FST

=head1 SYNOPSIS

 gfsm-random-fsm.perl [OPTIONS]

 General Options:
  -help
  -version

 Topology Options:
  -acceptor , -transducer   # build FSA or FST (default=-transducer)
  -epsilon  , -noepsilon    # do/don't include epsilon labels (default=do)
  -n-states=N               # number of states
  -n-arcs=N                 # number of arcs
  -n-finals=N               # number of final states
  -n-labels=N               # number of labels
  -min-weight=W             # minimum weight (default=0)
  -max-weight=W             # maximum weight (default=0)

 I/O Options:
  -zlevel=ZLEVEL            # zlib compression level
  -output=GFSMFILE          # output automaton

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

Bryan Jurish E<lt>moocow@cpan.org<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Bryan Jurish

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
Gfsm(3perl)

=cut

