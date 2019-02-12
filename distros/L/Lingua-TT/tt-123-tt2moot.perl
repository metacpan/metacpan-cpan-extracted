#!/usr/bin/perl -w

use IO::File;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
#use File::Copy;

#use lib '.';
#use Lingua::TT;
#use Lingua::TT::Sort qw(:all);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.11";

our $verbose = 0;
our ($version);

##-- program vars
our $prog         = basename($0);
our $outfile      = '-';
our $eos          = '__$';

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	  'help|h' => \$help,
	  #'man|m'  => \$man,
	  'version|V' => \$version,
	  #'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'eos|E=s' => \$eos,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);

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

##-- open output file
open(OUT,">$outfile")
  or die("$prog: open failed for output file '$outfile': $!");
select OUT;

push(@ARGV,'-') if (!@ARGV);
while (defined($line=<>)) {
  $line =~ s/(?:\r?\n)+$//;
  @key = split(/\t/,$line);
  $f   = pop(@key);


  if (@key==3) {
    if ($key[0] eq $eos && $key[1] eq $eos && $key[2] eq $eos) {
      print $eos, "\t", 2*$f+1, "\n"; ##-- EOS: unigram hack
      next;
    }
    elsif ($key[0] eq $eos && $key[1] eq $eos) {
      next; #shift(@key); ##-- eos prefix: drop all but last
    }
    elsif ($key[1] eq $eos && $key[2] eq $eos) {
      next; #pop(@key); ##-- eos suffix: drop all but last
    }
  }
  elsif (@key==2) {
    next if ($key[0] eq $eos && $key[1] eq $eos);
  }
  elsif (@key==1) {
    next if ($key[0] eq $eos);
  }

  print join("\t", @key, $f), "\n";
}

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-123-tt2moot.perl - convert Lingua::TT verbose n-gram files to moot format

=head1 SYNOPSIS

 tt-123-tt2moot.perl [OPTIONS] VERBOSE_123_FILE(s)...

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -output OUTFILE    ##-- set output file (default=STDOUT)

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

