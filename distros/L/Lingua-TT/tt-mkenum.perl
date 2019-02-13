#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Enum;
use Lingua::TT::Unigrams;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);


##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.12";

##-- program vars
our $prog     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our $encoding     = undef;
our $enum_ids     = 0;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	   'enum-ids|ids|ei!' => \$enum_ids,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);

if ($version || $verbose >= 2) {
  print STDERR "$prog version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## Subs: messages
##----------------------------------------------------------------------

# undef = vmsg($level,@msg)
#  + print @msg to STDERR if $verbose >= $level
sub vmsg {
  my $level = shift;
  print STDERR (@_) if ($verbose >= $level);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- unigrams
push(@ARGV,'-') if (!@ARGV);
our $ug = undef;
foreach $ugfile (@ARGV) {
  $ugin = Lingua::TT::Unigrams->loadNativeFile($ugfile,encoding=>$encoding)
    or die("$prog: load failed for unigrams file '$ugin': $!");

  if (!defined($ug)) {
    $ug = $ugin;
  } else {
    $ug->add($ugin)
      or die("$prog: add failed for unigrams file '$ugin': $!");
  }
}
our $wf = $ug->{wf};

##-- make enum
our %sym2id = qw();
our @id2sym = qw();
our $enum = Lingua::TT::Enum->new(sym2id=>\%sym2id,id2sym=>\@id2sym);
our $id   = 0;
foreach $w (sort {$wf->{$b} <=> $wf->{$a}} keys %$wf) {
  $sym2id{$w}=$id;
  $id2sym[$id]=$w;
  ++$id;
}
$enum->{size} = $id;

##-- dump enum
$enum->saveNativeFile($outfile,encoding=>$encoding,noids=>(!$enum_ids))
  or die("$prog: save failed to '$outfile': $!");


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-mkenum.perl - create enum files from unigram counts

=head1 SYNOPSIS

 tt-mkenum.perl [OPTIONS] [1GFILES(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -ids  , -noids       ##-- do/don't store ids in output enum (default=don't)
   -encoding ENC        ##-- input encoding (default=raw)
   -output FILE         ##-- output file (default=STDOUT)

=cut

###############################################################
## OPTIONS
###############################################################
=pod

=head1 OPTIONS

=cut

###############################################################
# General Options
###############################################################
=pod

=head2 General Options

=over 4

=item -help

Display a brief help message and exit.

=item -version

Display version information and exit.

=item -verbose LEVEL

Set verbosity level to LEVEL.  Default=1.

=back

=cut


###############################################################
# Other Options
###############################################################
=pod

=head2 Other Options

=over 4

=item -someoptions ARG

Example option.

=back

=cut


###############################################################
# Bugs and Limitations
###############################################################
=pod

=head1 BUGS AND LIMITATIONS

Probably many.

=cut


###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 SEE ALSO

perl(1).

=cut
