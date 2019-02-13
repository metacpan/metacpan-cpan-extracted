#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);


##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.12";

##-- program vars
our $progname     = basename($0);
our $verbose      = 1;

our $outfile      = '-';
our $encoding     = undef;

our $want_cmts = 0;
our $want_data = 0;
our $want_eos  = 0;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'comments|cmts|c!' => \$want_cmts,
	   'analyses|data|d!' => \$want_data,
	   'eos|s!' => \$want_eos,
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	  );

pod2usage({
	   -exitval=>0,
	   -verbose=>0
	  }) if ($help);
pod2usage({
	   -exitval=>0,
	   -verbose=>1
	  }) if ($man);

if ($version || $verbose >= 2) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
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
push(@ARGV, '-') if (!@ARGV);
our $ttout = Lingua::TT::IO->toFile($outfile,encoding=>$encoding)
  or die("$0: open failed for output file '$outfile': $!");
our $outfh = $ttout->{fh};

our $last_was_eos = 1;
my ($infh,$line);
foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile,encoding=>$encoding)
    or die("$0: open failed for input file '$infile': $!");
  $infh = $ttin->{fh};

  while (defined($_=<$infh>)) {
    if (/^$/) {
      $outfh->print($_) if (!$last_was_eos || $want_eos);
      $last_was_eos = 1;
    }
    elsif (/^\%\%/) {
      $outfh->print($_) if ($want_cmts);
      next;
    }
    else {
      s/[\t\r\n].*$/\n/s if (!$want_data); ##-- truncate all but first field
      $outfh->print($_);
      $last_was_eos = 0;
    }
  }
}
$outfh->print("\n") if (!$last_was_eos && !$want_eos);
$ttout->close();


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-normalize.perl - normalize tt files

=head1 SYNOPSIS

 tt-normalize.perl OPTIONS [TTFILE(s)]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -cmts , -nocmts      ##-- do/don't output comments (default=don't)
   -data , -nodata      ##-- do/don't output non-text data (default=don't)
   -eos  , -noeos       ##-- do/don't output redundant sentence boundaries (default=don't)
   -encoding ENC        ##-- output encoding (default=raw)
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
