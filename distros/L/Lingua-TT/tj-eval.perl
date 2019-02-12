#!/usr/bin/perl -w

use IO::File;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
use Text::Balanced qw(extract_codeblock extract_quotelike extract_multiple);
use JSON::XS;

use lib '.';
use Lingua::TT;

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.11";

##-- program vars
our $prog         = basename($0);
our $outfile      = '-';
our $verbose      = 0;

our $encoding = undef; ##-- default encoding (?)
our $code_byline = undef;
our $doprint = 1;

our $want_cmts = 0;
our $want_eos  = 0;
our $want_canonical = 0;

our $jxs = JSON::XS->new->utf8(0)->allow_nonref(1);

our @eval_begin = qw();
our @eval_end   = qw();

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	  'help|h' => \$help,
	  #'man|m'  => \$man,
	  'version|V' => \$version,
	  'verbose|v=i' => \$verbose,

	   ##-- code
	   'begin|B=s' => \@eval_begin,
	   'end|E=s' => \@eval_end,
	   'use|M=s' => sub {push(@eval_begin,"use $_[1];")},

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'comments|cmts|c!' => \$want_cmts,
	   'canonical|canon|C' => \$want_canonical,
	   'eos|s!' => \$want_eos,
	   'print|p!' => \$doprint,
	  );

pod2usage({-msg=>'Not enough arguments specified!',-exitval=>1,-verbose=>0}) if (@ARGV < 1);
pod2usage({-exitval=>0,-verbose=>0}) if ($help);
#pod2usage({-exitval=>0,-verbose=>1}) if ($man);

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
our $ttout = Lingua::TT::IO->new->toFile($outfile)
  or die("$prog: open failed for '$outfile': $!");
our $outfh = $ttout->{fh};
binmode($outfh,':utf8');
select($outfh);

$jxs->canonical(1) if ($want_canonical);

##-- pre compile eval sub
##  + vars:
##      $ARGV : current file
##      $ttin : input Lingua::TT::IO object
##      $infh : input filehandle
##      $outfh: output filehandle (select()ed)
##      $_    : current line (chomped)
##      $t    : current token text
##      $j    : current json object
##      $d    : document attributes (read-only)
##      $s    : sentence attributes (read-only)
our ($infile,$ttin,$infh, $t,$j,$s,$d);
$code_byline = shift;
our $dofile_code = q(
sub {
  ##-- BEGIN user initial code
  ).(@eval_begin ? join(";\n",@eval_begin) : '').q(
  ##-- END user initial code

  while (defined($_=<$infh>)) {
    if (m/^\%\%\\$TJ:DOC=(.*)/)    { $d = $jxs->decode($1); }
    elsif (m/^\%\%\\$TJ:SENT=(.*)/) { $s = $jxs->decode($1); }
    if ((!$want_cmts && m/^\%\%/) || (!$want_eos && m/^$/)) {
      print if ($doprint);
      next;
    }
    s/\R\z//s;
    ($t,$j0)=split(/\t/,$_,2);
    $j = $j0 ? $jxs->decode($j0) : undef;
    ##-- BEGIN user code
    ).$code_byline.q(;
    ##-- END user code
    ).($doprint ? 'print join("\t",grep {defined($_)} $t, (defined($j) ? $jxs->encode($j) : qw())), "\n";' : '').q(
  }

  ##-- BEGIN user final code
  ).(@eval_end ? join(";\n",@eval_end) : '').q(
  ##-- END user final code
});
vmsg(3,"$prog: DEBUG: User code sub\n",
     map {"$prog: DEBUG: $_\n"} split(/\n/,$dofile_code));
our $dofile_sub = eval $dofile_code;
die("$prog: could not pre-compile sub: $@") if ($@ || !$dofile_sub);


push(@ARGV,'-') if (!@ARGV);
foreach $infile (@ARGV) {
  $ttin = Lingua::TT::IO->fromFile($infile)
    or die("$prog: open failed for '$infile': $!");
  $infh = $ttin->{fh};
  binmode($infh,':utf8');

  $dofile_sub->();
  $ttin->close();
}

##-- cleanup
$ttout->close;

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tj-eval.perl - eval perl code for each line of .tj files

=head1 SYNOPSIS

 tj-eval.perl [OPTIONS] PERLCODE [TJ_FILE(s)...]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -begin CODE        ##-- eval CODE before processing each file
   -end CODE          ##-- eval CODE after processing each file
   -use MODULE	      ##-- alias for -begin="use MODULE;"
   -eos  , -noeos     ##-- do/don't eval CODe for eos lines (default=don't)
   -cmts , -nocmts    ##-- do/don't eval CODE for comment lines (default=don't)
   -canon, -nocanon   ##-- do/don't ensure "canonical" output (default=don't)
   -noprint           ##-- don't implicitly print line data
   -output OUTFILE    ##-- set output file


 Perl Variables:
   $infile : current file
   $ttin   : input Lingua::TT::IO object
   $infh   : input filehandle
   $outfh  : output filehandle (select()ed)
   $_      : current line (chomped)
   $d      : current document attributes (read-only)
   $s      : current sentence attributes (read-only)
   $t      : current token text
   $j      : current json object
   $j0     : current json string

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

