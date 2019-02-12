#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::TextAlignment;
use Getopt::Long qw(:config no_ignore_case);
use Encode qw(encode_utf8 decode_utf8);
use File::Basename qw(basename);
use File::Temp qw(tempfile tempdir);
use File::Copy;
use Pod::Usage;

use open qw(:std :utf8);
use utf8;

use strict;

##------------------------------------------------------------------------------
## Constants & Globals
our $prog = basename($0);

##-- vars: I/O
our $tokenizer = 'waste';
our $outfile = "-";   ##-- default: stdout
our %ioargs = (encoding=>'utf8', compact=>1);

our $keeptmp = 0;

##------------------------------------------------------------------------------
## Command-line
our ($help);
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- I/O
	   'output|out|o=s' => \$outfile,
	   'tokenizer|tokenize|tok|t=s' => \$tokenizer,
	   'compact|C|z!' => \$ioargs{compact},
	   'prolix|P|expanded|x!'  => sub {$ioargs{compact}=!$_[1]},
	  );

pod2usage({-exitval=>0,-verbose=>0,}) if ($help);
#pod2usage({-message=>"Not enough arguments given!",-exitval=>0,-verbose=>0,}) if (@ARGV < 2);

##======================================================================
## MAIN

##-- args
push(@ARGV,'-') if (!@ARGV);
my $txtfile = shift(@ARGV);

##-- possibly spool stdin to tmpfile
my ($tmpfile,$tmpfh);
if ($txtfile eq '-') {
  ($tmpfh,$tmpfile) = File::Temp::tempfile("waste_txt2rtt_${$}_XXXX", SUFFIX=>'.txt', UNLINK=>!$keeptmp);
  binmode($_,':raw') foreach ($tmpfh,\*STDIN);
  File::Copy::copy(\*STDIN,$tmpfh);
  close($tmpfh);
  $txtfile = $tmpfile;
}

##-- tokenize
my ($ttfh,$ttfile) = File::Temp::tempfile("waste_txt2rtt_${$}_XXXX", SUFFIX=>'.tt', UNLINK=>!$keeptmp);
open(TOK, "-|",
     $tokenizer,
     ($tokenizer =~ 'waste'
      ? ('-v2', '-N', '-Otext,loc', (-r 'waste.rc' ? '-cwaste.rc' : qw()))
      : qw()),
     @ARGV, $txtfile)
  or die("$prog: failed to open pipe from tokenizer '$tokenizer': $!");
binmode($_,':raw') foreach ($ttfh,\*TOK);
File::Copy::copy(\*TOK, $ttfh);
close(TOK);
close($ttfh);

##-- align
our $ta = Lingua::TT::TextAlignment->new();
$ta->loadTextFile($txtfile,%ioargs)
  or die("$prog: failed to load text buffer from $txtfile: $!");
$ta->loadTTFile($ttfile,%ioargs)
  or die("$prog: failed to load TT data from $ttfile: $!");

##-- save
$ta->saveRttFile($outfile,%ioargs)
  or die("$prog: save failed to $outfile: $!");

__END__

=pod

=head1 NAME

tt-txt2rtt.perl - convert raw text to rtt(z) format

=head1 SYNOPSIS

 tt-txt2rtt.perl [LOCAL_OPTIONS] [TEXT_FILE=-] [-- TOKENIZER_OPTIONS...]

 Options:
  -help                  # this help message
  -output FILE           # specify output file (default='-' (STDOUT))
  -tokenize COMMAND      # specify tokenizer command (default='waste')
  -compact , -prolix     # compact or prolix output? (default=-compact)

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

Not yet written.

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

Merge 'true' input with token-wise scanner output.

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

perl(1),
...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut


