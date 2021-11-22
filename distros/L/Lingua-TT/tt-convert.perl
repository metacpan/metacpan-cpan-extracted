#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION  = "0.13";
our $encoding = undef;

our $iclass = 'Lingua::TT::Persistent';
our $imode = undef; ##-- default: guess
our $omode = undef; ##-- default: guess
our $iencoding = undef;
our $oencoding = undef;
our $outfile  = '-';

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   #'man|m'  => \$man,
	   #'version|V' => \$version,
	   #'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'input-class|ic=s' => \$iclass,
	   'input-mode|imode|im=s' => \$imode,
	   'output-mode|omode|om=s' => \$omode,
	   'output-file|outfile|output|o=s' => \$outfile,
	   'input-encoding|iencoding|ie=s' => \$iencoding,
	   'output-encoding|oencoding|oe=s' => \$oencoding,
	   'encoding|e=s' => sub { $iencoding=$oencoding=$_[1]; },
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'No dictionary file specified!'}) if (!@ARGV);

##----------------------------------------------------------------------
## Subs

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- load module if required
eval "use $iclass;";
die("$0; 'use $iclass' failed: $@") if ($@);

##-- load object
push(@ARGV,'-') if (!@ARGV);
our $infile = shift(@ARGV);
our $obj = $iclass->loadFile($infile,encoding=>$iencoding,mode=>$imode)
  or die("$0: $iclass->loadFile($infile) failed: $!");

##-- dump
$obj->saveFile($outfile,encoding=>$oencoding,mode=>$omode)
  or die("$0: ", (ref($obj)||$obj), "::saveFile($outfile) failed: $!");


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-convert.perl - convert persistent TT object files between formats

=head1 SYNOPSIS

 tt-convert.perl [OPTIONS] [TT_OBJ_FILE(s)]

 General Options:
   -help

 I/O Options:
   -iclass CLASS         ##-- input class (default=Lingua::TT::Persistent)
   -imode MODE           ##-- input mode (default=guess)
   -omode MODE           ##-- output mode (default=guess)
   -iencoding ENCODING   ##-- input encoding (default=raw)
   -oencoding ENCODING   ##-- output encoding (default=raw)
   -output FILE          ##-- output file (default=STDOUT)

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
