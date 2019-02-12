#!/usr/bin/perl -w

use IO::File;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
use Text::Balanced qw(extract_codeblock extract_quotelike extract_multiple);

use lib '.';
use Lingua::TT;

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

our $VERSION = "0.11";

##-- program vars
our $progname     = basename($0);
our $outfile      = '-';
our $verbose      = 0;

our $format = '*';
#our $encoding = 'UTF-8'; ##-- default encoding (?)

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	  'help|h' => \$help,
	  'man|m'  => \$man,
	  'version|V' => \$version,
	  'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'format|fmt|f=s' => \$format,
	   'output|o=s' => \$outfile,
	  );

pod2usage({
	   -msg=>'Not enough arguments specified!',
	   -exitval=>1,
	   -verbose=>0,
	  }) if (@ARGV < 1);
pod2usage({
	   -exitval=>0,
	   -verbose=>0
	  }) if ($help);
pod2usage({
	   -exitval=>0,
	   -verbose=>1
	  }) if ($man);

if ($version || $verbose >= 1) {
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
package main;

## + format string:
##    FORMAT     ::= FIELDSPECS
##    FIELDSPECS ::= FIELDSPEC ["," FIELDSPECS]
##    FIELDSPEC  ::= FIELDNUM | "+" <constant-string> | "{" PERL_CODE "}"
##    FIELDNUM   ::= "*"
##                   | <literal-number-counting-from-1>
##                   | <startIndex>:<endIndex>
## + data format:
##    @fieldspecs = ($fs1,...,$fsN)
##    $fsi        = $string | $fs
##    $fs         = [ $startNum, $endNum+1 ] ##-- indices may be negative (count from back)
our @fieldspecs = qw();
our $pkgi = 0;
#foreach (split(/[\s\,]+/,$format))

@fields = (grep { $_ ne ',' }
	   extract_multiple($format,
			    [ \&extract_codeblock,
			      \&extract_quotelike,
			      qr([^\,]*),
			      qr(\,)
			    ])
	  );

foreach $field (@fields) {
  if ($field =~ s/^\+//) {
    ##-- constant literal string
    push(@fieldspecs, $field);
  }
  elsif ($field =~ m/^[\"\'](.*)[\"\']$/) {
    ##-- quoted string
    push(@fieldspecs, $1);
  }
  elsif ($field =~ m/^\{.*\}$/) {
    ##-- perl code
    ++$pkgi;
    my $coderef = eval "package TT_CUT_${pkgi}; sub process $field; \\\&process";
    die("$0: error compiling code-field '$field': $@") if ($@ || !$coderef);
    push(@fieldspecs, $coderef);
  }
  elsif ($field eq '*') {
    ##-- all
    push(@fieldspecs, [ 0, -1 ]);
  }
  elsif ($field =~ /^\s*(\-?\s*\d+)\s*$/) {
    ##-- single index
    my $pos = $1;
    push(@fieldspecs, [ $pos-1, $pos ]);
  }
  elsif ($field =~ /^\s*(\-?\s*\d*)\s*:\s*(\-?\s*\d*)\s*$/) {
    ##-- index range
    my ($start,$end) = ($1,$2);
    $start = 1  if (!defined($start) || $start eq '');
    $end   = -1 if (!defined($end) || $end eq '');
    push(@fieldspecs, [ $start-1, $end ]);
  }
  elsif ($field eq '*') {
    ##-- full index range
    push(@fieldspecs, [ 0, -1 ]);
  }
  else {
    die("$0: could not parse field spec '$field'");
  }
}

$ttin  = Lingua::TT::IO->new();
$ttout = Lingua::TT::IO->new->toFile($outfile,encoding=>undef)
  or die("$prog: open failed for '$outfile': $!");
our $outfh = $ttout->{fh};

our ($fspec,$tokin);
our ($last_was_eos);
our $tokout = Lingua::TT::Token->new;
foreach $ttfile (@ARGV) {
  $ttin->fromFile($ttfile,encoding=>undef)
    or die("$prog: open failed for '$ttfile': $!");
  our $infh = $ttin->{fh};

  while (defined($_=<$infh>)) {
    if (/^\%\%/ || /^$/) {
      $outfh->print($_); ##-- pass through comments & blank lines
      next;
    }
    @$tokout = qw();

    ##-- parse tokens
    s/\r?\n?$//;
    @$tokin = split(/\t/,$_);

    foreach $fspec (@fieldspecs) {
      if (!ref($fspec)) {
	##-- constant literal string
	push(@$tokout, $fspec);
      }
      elsif (ref($fspec) eq 'CODE') {
	##-- perl code
	$_ = $tokin;
	push(@$tokout, $fspec->($tokin));
      }
      elsif (ref($fspec) eq 'ARRAY') {
	##-- positional reference
	($start,$end) = @$fspec;
	if ($start < 0) { $start += @$tokin + 1; }
	if ($end < 0)   { $end += @$tokin + 1; }
	#$start = @$tokin if ($start > @$tokin);
	$end   = @$tokin if ($end > @$tokin);
	push(@$tokout, @$tokin[$start..($end-1)]);
      }
    }
    $outfh->print(join("\t",@$tokout), "\n");
  } continue {
    $last_was_eos = ($_ =~ /^$/);
  }
  $outfh->print("\n") if (!$last_was_eos);
  $ttin->close();
}

##-- cleanup
$ttout->close;

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-cut.perl - extract fields from .tt files

=head1 SYNOPSIS

 tt-cut.perl [OPTIONS] TT_FILE(s)

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -format FORMAT  , -f FORMAT
   -output OUTFILE , -o OUTFILE

 Formats:
   FORMAT     ::= FIELDSPECS
   FIELDSPECS ::= FIELDSPEC ["," FIELDSPECS]

   FIELDSPEC  ::= FIELDNUM
                  | "+" <constant-string>     ##-- no commas
                  | "'" <quoted-string> "'"   ##-- quotes may be escaped
                  | "{" PERL_CODE "}"         ##-- balanced '{', '}'

   FIELDNUM   ::= INDEX                       ##-- single index
                  | RANGE                     ##-- index range
                  | "*"                       ##-- alias for range 1:-1

   INDEX      ::= <positive-integer>          ##-- offset from start (>1)
                  | <negative-integer>        ##-- offset from end (<0)

   RANGE      ::= INDEX ":" INDEX             ##-- inclusive

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

