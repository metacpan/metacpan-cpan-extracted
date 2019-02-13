#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
#use Lingua::TT::Dict;

use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION  = "0.12";
our $encoding = undef;
our $outfile  = '-';

our $cmp = 'asc';
our $keep_zero_weights=1;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   #'man|m'  => \$man,
	   #'version|V' => \$version,
	   #'verbose|v=i' => \$verbose,

	   ##-- misc
	   'ascending|asc|a' => sub {$cmp='asc';},
	   'descending|desc|dsc|d' => sub {$cmp='dsc';},
	   'keep-zero|zero!' => \$keep_zero_weights,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'encoding|e=s' => \$encoding,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>0,-msg=>'No dictionary file specified!'}) if (!@ARGV);

##----------------------------------------------------------------------
## Subs

sub acmp_asc { return $a->[1] <=> $b->[1] || $a->[0] cmp $b->[0]; }
sub acmp_dsc { return $b->[1] <=> $a->[1] || $a->[0] cmp $b->[0]; }
*acmp = \&acmp_asc;

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- i/o
push(@ARGV,'-') if (!@ARGV);
our $ttout = Lingua::TT::IO->toFile($outfile,encoding=>$encoding)
  or die("$0: open failed for output file '$outfile': $!");
our $outfh = $ttout->{fh};

{
  no warnings;
  *acmp = $cmp eq 'dsc' ? \&acmp_dsc : \&acmp_asc;
}

##-- process token files
foreach $infile (@ARGV ? @ARGV : '-') {
  $ttin = Lingua::TT::IO->fromFile($infile,encoding=>$encoding)
    or die("$0: open failed for '$infile': $!");
  $infh = $ttin->{fh};

  while (defined($_=<$infh>)) {
    next if (/^%%/ || /^$/);
    chomp;
    ($key,@a0) = split(/\t/,$_);
    $outfh->print(join("\t", $key,
		       map {"$_->[0]".(!$keep_zero_weights && $_->[1]==0 ? '' : "<$_->[1]>")}
		       sort acmp
		       map {/^(.*)\<([\+\-\d\.eE]+)\>$/ ? [$1,$2] : [$_,0]} @a0),
		  "\n");
  }
  $ttin->close;
}

##-- dump
$outfh->close();


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-dict-wsort.perl - sort values in tt dict files by fst-style weight

=head1 SYNOPSIS

 tt-dict-wsort.perl [OPTIONS] [DICT_FILE(s)]

 General Options:
   -help
   #-version
   #-verbose LEVEL

 I/O Options:
   -asc  , -desc        ##-- sort in ascending/descending order (default=-asc)
   -zero , -nozero      ##-- do/don't keep zero weights explicitly in output (default=do)
   -output FILE         ##-- default: STDOUT
   -encoding ENCODING   ##-- default: UTF-8

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
