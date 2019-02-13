#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Packed;

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

our %opts_common = (
		    badqid => 0,
		    badsym => '',
		    fast => 1, ##-- -fast helps a lot for unpack()
		   );
our %opts_from = (
		  packfmt=>'N',
		  delim=>'',
		 );
our %opts_to = (
		packfmt=>'N',
		delim=>'',
	       );

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'buffer|buf|fast!' => \$opts_common{fast},
	   'slow|paranoid' => sub { $opts_common{fast}=!$_[1]; },
	   'output|o=s' => \$outfile,
	   'from|unpackfmt|unpack|u=s' => \$opts_from{packfmt},
	   'from-delim|unpack-delim|ud:s' => \$opts_from{delim},
	   'to|packfmt|pack|p=s' => \$opts_to{packfmt},
	   'to-delim|pack-delim|pd:s' => \$opts_to{delim},
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'No ENUM specified!'}) if (!@ARGV);
#$enumfile = shift;

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

##-- guts
our $pk_from = Lingua::TT::Packed->new(%opts_common,%opts_from)
  or die("$prog: could not create source Packed object: $!");
our $pk_to   = Lingua::TT::Packed->new(%opts_common,%opts_to)
  or die("$prog: could not create sink Packed object: $!");

push(@ARGV,'-') if (!@ARGV);
foreach $infile (@ARGV) {
  $pk_from->loadFile($infile)
    or die("$prog: load failed for input file '$infile': $!")
}
$pk_to->ids($pk_from->ids);
$pk_to->saveFile($outfile)
  or die("$prog: save failed to '$outfile': $!");


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-repack.perl - recode packed tt files

=head1 SYNOPSIS

 tt-repack.perl [OPTIONS] [PACKED_FILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -unpack       TEMPLATE ##-- input pack template (default='N')
   -unpack-delim DELIM    ##-- input delimiter (default='')
   -pack         TEMPLATE ##-- output pack template (default='N')
   -pack-delim   DELIM    ##-- output delimiter (default='')
   -output FILE           ##-- output file (default=STDOUT)

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
