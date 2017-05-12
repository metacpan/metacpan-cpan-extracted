#!/usr/bin/perl -w

use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename);
use Pod::Usage;
use strict;

##------------------------------------------------------------------------------
## Constants & Globals
our $prog = basename($0);

our $outbase = undef;
our $labfile = undef;
our $sclfile = undef;

our $want_specials = 0;
our $sigma = '<sigma>';
our $epsilon = '<epsilon>';
our $category = '<category>';

##------------------------------------------------------------------------------
## Command-line
our ($help);
GetOptions(##-- General
	   'help|h' => \$help,
	   #'verbose|v=i' => \$verbose,
	   #'quiet|q' => sub { $verbose=0; },

	   ##-- I/O
	   'special-symbols|specials|L!' => \$want_specials,
	   'output|out|o=s' => \$outbase,

	   'lab-output|labout|lab|lo=s' => \$labfile,
	   'scl-output|sclout|scl|so=s' => \$sclfile,

	   'epsilon|eps|e=s' => \$epsilon,
	   'sigma|E' => \$sigma,
	   'category|cat|c=s' => \$category,
	  );

pod2usage({-exitval=>0,-verbose=>0,}) if ($help);
pod2usage({-message=>"No input symbol file given!",-exitval=>0,-verbose=>0,}) if (@ARGV < 1);

##------------------------------------------------------------------------------
## escaping

## $str = unescape($str_escaped)
sub unescape {
  my $s = shift;
  $s =~ s/\\n/\n/g;
  $s =~ s/\\r/\r/g;
  $s =~ s/\\t/\t/g;
#  $s =~ s/\\v/\v/g;
  $s =~ s/\\x([0-9a-f]{1,2})/chr($1)/gxi;
  $s =~ s/\\(.)/$1/g;
  return $s;
}

## @sl_uniq = sluniq(@sorted_list)
##  + sorts list
sub sluniq {
  my ($prev);
  return map {defined($prev) && $_ eq $prev ? qw() : ($prev=$_)} @_;
}

## @l_uniq = luniq(@list)
##  + sorts list
sub luniq {
  return sluniq(sort @_);
}


## DATA
##  %class2terms : ($class => \@terms, ...)
##  %cat2feat    : ($category => \@features, ...)
##  %sym2id      : ($term => $id, ...)
##  @id2sym      : ([$id] => $term, ...)

my (%class2terms,%cat2feat);
my %sym2id = ($epsilon=>0);
my @id2sym = ($epsilon);

## $id_or_empty = ensure_symbol($sym)
sub ensure_symbol {
  my $sym = shift;
  return $sym2id{$sym} if (exists $sym2id{$sym});
  return qw() if (exists $class2terms{$sym});
  return qw() if (exists $cat2feat{$sym});
  ##
  ##-- new symbol: create as terminal
  push(@id2sym,$sym);
  return $sym2id{$sym} = $#id2sym;
}

## @ids = ensure_symbols(@syms)
sub ensure_symbols {
  return map {ensure_symbol($_)} @_;
}

## @sorted = idsort(@terminals)
sub idsort {
  return sort {$sym2id{$a}<=>$sym2id{$b}} @_;
}

## @terms_nodups = terminals(@syms);
sub terminals {
  my @queue = (@_);
  my %terms = qw();
  my %visited = qw();
  my ($sym,$key);
  while (defined($sym=shift(@queue))) {
    next if (exists $visited{$sym});
    $visited{$sym}  = 1;
    if (exists $class2terms{$sym}) {
      push(@queue, @{$class2terms{$sym}});
    }
    elsif (defined $sym2id{$sym}) {
      $terms{$sym} = ++$key;
    }
    else {
      ensure_symbol($sym);
      $terms{$sym} = ++$key;
    }
  }
  return sort {$terms{$a}<=>$terms{$b}} keys %terms;
}


##------------------------------------------------------------------------------
## MAIN

##-- get filenames
our $symfile = shift;
die "$prog: could not read file symbols-file '$symfile' or '$symfile.sym'" if (!-r "$symfile" && !-r"$symfile.sym");
$symfile = "$symfile.sym" if (!-r $symfile);

($outbase = $symfile) =~ s/\.sym$// if (!$outbase);
$labfile = "$outbase.lab" if (!$labfile);
$sclfile = "$outbase.scl" if (!$sclfile);

##-- load symspec
open(my $symfh, "<", $symfile)
  or die("$prog: open failed for '$symfile': $!");

my ($class,@vals);
while (<$symfh>) {
  chomp;
  next if (/^\s*$/);
  ($class,@vals) = map {unescape($_)} split(/\s+/,$_);

  if ($class eq 'Category:') {
    ##-- category: parse features
    my $cat = shift @vals;
    $cat2feat{$cat} = [@vals];
    ensure_symbols(map {"_$_"} ($cat,@vals));
  }
  else {
    ##-- symbol class: parse it
    push(@{$class2terms{$class}}, terminals(@vals));
  }
}
close $symfh;

##-- maybe add lextools special symbols
if ($want_specials) {
  foreach my $spec (
		    {class=>'<boundary>', vals=>[qw($$ ++ ww aa ii), ',,', qw(.. !! ??)]},
		    {class=>undef,        vals=>[qw(<xml> </xml>)]},
		    {class=>'<accent>',   vals=>[qw(acc:+ acc:- acc:c)]},
		    {class=>'numval',     vals=>[
						 (map {"10^$_"} (0..20)),
						 (map {"20^$_"} (0..2)),
						 (map {"$_*"} (0..9)),
						]},
		    {class=>'multiplier', vals=>[(map {"$_*"} (0..9))],},
		    {class=>undef,          vals=>[qw(<bos> <eos>)]},
		   )
    {
      ensure_symbols(@{$spec->{vals}});
      push(@{$class2terms{$spec->{class}}}, idsort(terminals(@{$spec->{vals}}))) if (defined($spec->{class}));
    }
}


##-- set 'sigma' class
$class2terms{$sigma} = [@id2sym[1..$#id2sym]];

##-- dump (debug)
#use Data::Dumper;
#print STDERR Data::Dumper->Dump([\%class2terms,\%cat2feat,\%sym2id],[qw(class2terms cat2feat sym2id)]);

##-- dump (labels)
open(my $labfh, ">$labfile")
  or die("$prog: open failed for labels-file '$labfile': $!");
foreach (0..$#id2sym) {
  print $labfh $id2sym[$_],"\t",$_,"\n";
}
close $labfh;

##-- dump (superclasses)
open(my $sclfh, ">$sclfile")
  or die("$prog: open failed for labels-file '$labfile': $!");
foreach my $cls (sort keys %class2terms) {
  print $sclfh
    map {"$cls\t$_\n"}
    #sort {$a<=>$b}			##-- do NOT label-sort things here; it can mess up 1-1 correspondences for e.g. lexrulecomp "=>" operator
    @sym2id{@{$class2terms{$cls}}};
}
foreach my $cat (sort keys %cat2feat) {
  print $sclfh
    ("$category\t", $sym2id{"_$cat"}, "\n",
     (map {"_$cat\t".$sym2id{"_$_"}."\n"} @{$cat2feat{$cat}}),
    );
}
close $sclfh;


__END__

=pod

=head1 NAME

gfsm-makelabe.perl - split lextools symbol specification into *.lab and *.scl

=head1 SYNOPSIS

 gfsm-makelab.perl [OPTIONS] SYMFILE[.sym]

 Options:
  -h , -help                  # this help message
  -L , -special-symbols       # include lextools-style special symbols?
  -o , -output OUTBASE        # specify output basename (default=SYMFILE)
  -lo, -lab-output LABFILE    # specify lab-file output (default=OUTBASE.lab)
  -so, -scl-output SCLFILE    # specify scl-file output (default=OUTBASE.scl)

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

Split lextools-style symbol specifications (*.sym) into terminal labels (*.lab) and superclass labels (*.scl).

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

