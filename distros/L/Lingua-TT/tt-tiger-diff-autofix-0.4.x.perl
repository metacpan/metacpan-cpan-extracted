#!/usr/bin/perl -w

use lib '.';
use Lingua::TT;
use Lingua::TT::Diff;

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
our %diffargs     = qw();
our $fix_all = 0;

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'man|m'  => \$man,
	   'version|V' => \$version,
	   'verbose|v=i' => \$verbose,

	   ##-- I/O
	   'output|o=s' => \$outfile,
	   'all|force!' => \$fix_all,
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>1}) if ($man);
#pod2usage({-exitval=>0,-verbose=>1,-msg=>'Not enough arguments specified!'}) if (@ARGV < 2);

if ($version || $verbose >= 2) {
  print STDERR "$progname version $VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}

##----------------------------------------------------------------------
## subs

## $max1 = hunk_max1($hunk)
##   + not suitable for range
sub hunk_max1 {
  return $_->[2] > $_->[1] ? $_->[2] : $_->[1];
}

## $max2 = hunk_max2($hunk)
##   + not suitable for range
sub hunk_max2 {
  return $_->[4] > $_->[3] ? $_->[4] : $_->[3];
}

##--------------------------------------------------------------
## Subs: force-fix hunks

## \@fix = makefix(\@items1,\@items2, $which)
## \@fix = makefix(\@items1,\@items2, $which, ?$othertag)
##   + non-empty tokens only!
sub makefix {
  my ($items1,$items2,$which,$otag) = @_;
  $which = 1 if (!defined($which));

  my ($text,$tag,@ans);
  if ($which==1) {
    return [
	    map {
	      ($text,$tag)=split(/\t/,$_);
	      join("\t",
		   (defined($text) ? "~$text" : '~'),
		   (defined($tag)  ? "<$tag"  : qw()),
		   (defined($otag) ? ">$otag" : qw()))
	    } @$items1
	   ];
  }
  return [
	  map {
	    ($text,@ans)=split(/\t/,$_);
	    join("\t",
		 (defined($text) ? "~$text" : '~'),
		 ($otag ? ("<$otag",map {">$_"} @ans) : ("~$ans[0]",map {">$_"} @ans[1..$#ans])))
	  } @$items2
	 ];
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
push(@ARGV,'-') if (!@ARGV);

our $diff = Lingua::TT::Diff->new(%diffargs);
our $dfile = shift(@ARGV);
$diff->loadTextFile($dfile)
  or die("$0: load failed from '$dfile': $!");

##-- common vars
my ($seq1,$seq2,$hunks) = @$diff{qw(seq1 seq2 hunks)};
my ($op,$min1,$max1,$min2,$max2,$fix);
my (@items1,@items2);
my ($item1,$item2, $i1,$i2);


##--------------------------------------------------------------
## MAIN: heuristics
foreach $hunk (@$hunks) {
  ($op,$min1,$max1,$min2,$max2, $fix) = @$hunk;
  next if ($fix); ##-- already fixed
  @items1 = @$seq1[$min1..$max1];
  @items2 = @$seq2[$min2..$max2];

  ##-- dummy
  if (0) { ; }
  ##-- CHANGE: Numeric Grouping: $1 ~ ((%%*|CARD)+) & $2 ~ (*/CARD) -> $2
  elsif ($op eq 'c'
	 && @items1==(grep {/^\%\%/ || /^[\d\,]+\tCARD$/} @items1)
	 && @items2==1
	 && $items2[0] =~ /^\d[\d\,\_]+(?:\t.*)?\t\[CARD\](?:\t|$)/)
    {
      $item2 = $items2[0];
      $item2 =~ s/\t.*//;
      #$hunk->[5] = [(grep {/^\%\%/} @items1), "$item2\tCARD"];
      $hunk->[5] = makefix(\@items1,\@items2, 2,'CARD');
      $hunk->[6] = 'H:numGroup';
    }
  ##-- CHANGE: numCommaDash: $1 ~ (\d+,-/CARD) --> $1 + ">[CARD]"
  elsif ($op eq 'c'
	 && @items1==1
	 && @items2 >1
	 && $items1[0] =~ /^\d+\,\-\tCARD$/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2, 1);
      $hunk->[5][0] .= "\t>[CARD]";
      $hunk->[6] = 'H:numCommaDash';
    }
  ##-- CHANGE: ordinal grouping: $1 ~ ((*/CARD)+ *./ADJA) & $2 ~ (*/ORD) -> $2 + "<ADJA"
  elsif ($op eq 'c'
	 && @items1 >1
	 && @items2==1
	 && (@items1-1)==(grep {/^[\d\,]+\tCARD$/} @items1[0..($#items1-1)])
	 && $items1[$#items1] =~ /^[\d\,]+\.\tADJA$/
	 && $items2[0] =~ /^[\d\,\_]+\.\t\[ORD\]$/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2, 2,'ADJA');
      $hunk->[6] = 'H:ordGroup';
    }
  ##-- CHANGE: sick bad ugly & wrong num group + ord + eos (tiger s9285-9286)
  elsif ($op eq 'c'
	 && @items1==5
	 && @items2==2
	 && 4==(grep {$_=~/\tCARD$/} @items1[0,1,3,4])
	 && $items1[2] eq ".\t\$."
	 && $items2[0] =~ /^[\d\,\_]+\.\t\[ORD\]$/
	 && $items2[1] =~ /^[\d\,\_]+\t\[CARD\]$/
	 && $diff->{aux1}{$min1+3}
	)
    {
      (my $txt0 = $items2[0]) =~ s/\.\t.*$//;
      (my $txt1 = $items2[1]) =~ s/\t.*$//;
      $hunk->[5] = [
		    "$txt0\t<CARD\t>[CARD]", ".\t<\$.\t>[\$.]",
		    @{$diff->{aux1}{$min1+3}},
		    "$txt1\t<CARD\t>[CARD]"
		   ];
      $hunk->[6] = "H:numGroupEOS";
      delete($diff->{aux1}{$min1+3});
    }
  ##-- CHANGE: quote assimilation: $1 ~ (*/* ''/$() & 2 ~ (*'/- '/$() --> $1 [mantis bug #537]
  elsif ($op eq 'c'
	 && @items1==2
	 && @items2==2
	 && $items1[1] =~ /^\'\'\t\$\(/
	 && defined($w1 = ($items1[0] =~ /^(\S+)\t/ ? $1 : undef))
	 && $items2[0] eq "$w1'"
	 && $items2[1] =~ /^\'\t/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[5][1] .= "\t>$1" if ($items2[1]=~/\t(.*)$/);
      $hunk->[6] = "H:quotAssim";
    }
  ##-- CHANGE: timeGroup
  elsif ($op eq 'c'
	 && @items1==1
	 && @items2==2
	 && $items1[0] =~ /^[0-9]{1,2}\.[0-9]{2}\tCARD$/
	 && $items2[0] =~ /^[0-9]{1,2}\.\t\[ORD\]$/
	 && $items2[1] =~ /^[0-9]{2}\t\[CARD\]$/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[5][0] .= "\t>$1" if ($items2[1]=~/\t(.*)$/); ##-- analysis
      $hunk->[6] = "H:timeGroup";
    }
  ##-- CHANGE: mis-recognized ABBR at EOS
  elsif ($op eq 'c'
	 && @items1==2
	 && @items2==1
	 && $items1[1] =~ /^[[:punct:]]\t\$\.$/
	 && $items2[0] =~ /^[^\t]*[^[:punct:]]+[^\t]*[[:punct:]]\t.*(?:XY|\$ABBREV)/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[5][1] .= "\t>[\$\.]"; ##-- add analysis for EOS punctuation
      $hunk->[6] = "H:abbrEOS";
    }
  ##-- CHANGE: abbrNN : $1 ~ (*./NN) & $2 ~ (*/* ./$.) --> $1 + ">[XY] >[\$ABBREV]"
  elsif ($op eq 'c'
	 && @items1==1
	 && @items2==2
	 && $items1[0] =~ /\.\tNN$/
	 && $items2[1] eq ".\t[\$.]"
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[5][0] .= "\t>[XY]\t>[\$ABBREV]";
      $hunk->[6] = "H:abbrNN";
    }
  ##-- CHANGE: ordEOS: $1 ~ ((*/CARD)+ ./$.) & 2 ~ (*./ORD) --> (*/CARD ./$.) ##-- incorporates numGroup heuristics too
  elsif ($op eq 'c'
	 && @items1>=2
	 && @items2==1
	 && ((grep {/^[\d\_\,]+\tCARD$/} @items1[0..($#items1-1)])==(@items1-1))
	 && $items1[$#items1] =~ /^\.\t\$\.$/
	 && $items2[0] =~ /^[^\t]+\.\t\[ORD\]$/
	)
    {
      (my $txt0 = $items2[0]) =~ s/\.\t.*$//;
      $hunk->[5] = ["$txt0\t<CARD\t>[CARD]",".\t<\$.\t>\[\$\.]"];
      $hunk->[6] = "H:ordEOS";
    }
  ##-- CHANGE: ordNoEOS: $1 ~ (*./ADJA) & $2 ~ (*/CARD ./$.) --> $1 + ">[ORD]"
  elsif ($op eq 'c'
	 && @items1==1
	 && @items2==2
	 && $items1[0] =~ /^[\d\,\_]+\.\tADJA$/
	 && $items2[0] =~ /^[\d\,\_]+\t\[CARD\]$/
	 && $items2[1] eq ".\t[\$.]"
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[5][0] .= "\t>[ORD]"; ##-- apend "tokenizer"-supplied analysis
      $hunk->[6] = "H:ordNoEOS";
    }
  ##-- CHANGE: truncJoin: TRUNC truncation: $1 ~ (*-/*) & $2 ~ (*/* -/$() --> $1 + ">[TRUNC]"
  elsif ($op eq 'c'
	 && @items1==1
	 && @items2==2
	 && $items1[0] =~ /^[^\t]*\-\t/
	 && $items2[1] =~ /^\-\t/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[5][0] .= "\t>[TRUNC]"; ##-- append "tokenizer"-supplied analysis
      $hunk->[6] = "H:truncJoin";
    }
  ##-- CHANGE: aposNE : $1 ~ (d'Whosit/NE) & $2 ~ (d'/* Whosit/*) --> $2/NE
  elsif ($op eq 'c'
	 && @items1==1
	 && @items2==2
	 && ($items1[0] =~ /\tNE$/ || $items1[0] =~ /^[[:alpha:]]\'[[:upper:]][^\t]*\tADJA$/)
	 && $items2[0] =~ /^[[:alpha:]]\'$/
	 && $items2[1] !~ /\t/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,2,'NE');
      $hunk->[6] = 'H:aposNE';
    }
  ##-- CHANGE: slash-compound: $1 ~ (*\/*/(NN|NE)) --> $1
  elsif ($op eq 'c'
	 && @items1==1
	 && $items1[0] =~ /^[^\t]*\/[^\t]*\tN[NE]/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[6] = 'H:slashCompound';
    }
  ##-- CHANGE: quotCompound: $1 ~ (*'*-*/(NN|NE)) --> $1
  elsif ($op eq 'c'
	 && @items1==1
	 && $items1[0] =~ /^[^\t\']*\'[^\t\']\-[^\t\']*\tN[NE]/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[6] = 'H:quotCompound';
    }
  ##-- CHANGE: numRange: $1 ~ (\d+-\d+/CARD) & $2 ~ (*/* (*/*)+) --> $1 + ">[CARD]"
  elsif ($op eq 'c'
	 && @items1==1
	 && @items2 >1
	 && $items1[0] =~ /^[0-9,]+-[0-9,]+\tCARD$/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[5][0] .= "\t>[CARD]";
      $hunk->[6] = 'H:numRange';
    }
  ##-- CHANGE: aposGen: $1 ~ (*'s?/(NN|NE)) & $2 ~ (* 's?) --> $1
  elsif ($op eq 'c'
	 && @items1==1
	 && @items2==2
	 && (($items1[0] =~ /^[^\t]*\'s\tN[NE]$/ && $items2[$#items2] eq "'s")
	     ||
	     ($items1[0] =~ /^[^\t]*\'\tN[NE]$/ && $items2[$#items2] eq "'\t[\$,]"))
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[6] = 'H:aposGen';
    }
  ##-- CHANGE: dotEOS: $1 ~ (*/* ./$.) & 2 ~ (*./ORD) --> $1 + "<[$.]"
  elsif ($op eq 'c'
	 && @items1==2
	 && @items2==1
	 && $items1[1] eq ".\t\$."
	 && $items2[0] =~ /^[^\t]+\.\t\[ORD\]$/
	)
    {
      $hunk->[5] = makefix(\@items1,\@items2,1);
      $hunk->[5][1] .= "\t>[\$.]"; ##-- append "tokenizer"-supplied analysis
      $hunk->[6] = 'H:dotEOS';
    }
  ##-- DELETE: eosDel : $1 ~ (EOS) --> $1
  elsif ($op eq 'd' && @items1==1 && $items1[0] eq '')
    {
      @$hunk[5,6] = (makefix(\@items1,\@items2,1), 'H:eosDel');
    }
  ##-- INSERT: eosIns : $2 ~ (EOS) --> $1
  elsif ($op eq 'a' && @items2==1 && $items2[0] eq '')
    {
      @$hunk[5,6] = (makefix(\@items1,\@items2,1), 'H:eosIns');
    }
  ##-- MISC: force pseudo-$1
  elsif ($fix_all) {
    $hunk->[5] = makefix(\@items1,\@items2,1);
    $hunk->[6] = 'H:force';
  }
}




##--------------------------------------------------------------
## MAIN: save
$diff->saveTextFile($outfile)
  or die("$0: save failed to '$outfile': $!");


__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

tt-tiger-diff-autofix-0.4.x.perl - heuristically resolve some conflicts in TIGER - ToMaSoTaTh tt-diffs

=head1 SYNOPSIS

 tt-tiger-diff-auto.perl OPTIONS [TT_DIFF_FILE=-]

 General Options:
   -help
   -version
   -verbose LEVEL

 Other Options:
   -force               ##-- force any unhandled diff hunks to FIX=1
   -output FILE         ##-- output file (default: STDOUT)

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
