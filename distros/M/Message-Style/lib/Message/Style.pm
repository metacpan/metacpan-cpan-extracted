package Message::Style;
require 5.005;
use strict;
use vars qw( $VERSION @ISA );
# $Id: Style.pm,v 1.3 2004/10/26 15:53:37 abuse Exp $
$VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

#use Carp;
#use Data::Dumper;

=head1 NAME

Message::Style - Perl module to perform stylistic analysis of messages

=head1 SYNOPSIS

  use Message::Style;

  my $score=Message::Style::score(\@article);
  # or
  my $score=Message::Style::score(@article);

=head1 DESCRIPTION

This Perl library does an analysis of a RFC2822 format message
(typically email messages or Usenet posts) and produces a score that,
in the author's opinion, gives a good indication as to whether the
poster is a fsckwit, and therefore whether their message should be
ignored.

=head1 SCORING MECHANISM

This script takes a Usenet article (or other RFC822 formatted text)
and attempts to identify whether the sender is a fsckwit. It does this
by analysing quoting style, line length, spelling, and various other
criteria.

There are several things that are annoying about Usenet posts, the
scores are related to the "cost" of these. There are Byte Points
(bandwidth wasted in transmission of pointless material) and Line
Points (time wasted scrolling through pointless material). These, and
their justifications are:

=over 2

=item 1

Article has excessively long lines.

Long lines are wrapped by some newsreaders, truncated by others, or a
horizontal scrollbar is presented. Whatever the case, these cause
extra effort for the reader to scroll. A Line Point is given for every
block of 80 chars (or part) beyond char 80.

=item 2

Article is not completely in plain text.

Non-plain Content-Type, e.g. text/html, or a non-text Content-Encoding
is unreadable to many. Byte Points are given for the entire article.

=item 3

Article has a very large signature.

Signatures are generally a waste of bandwidth, and long ones need to
be paged through. It is considered bad form to have a signature larger
than the McQuary limit of 80x4. Because of that, Byte Points and Line
Points scored for every character and line outside the 80x4 box.

=item 4

Article contains a Big Ugly ASCII Graphic (BUAG)

BUAGs are those annoying graphics that always seem to come with "cute"
extralong signatures. These are warned of, but not scored since
they've already been accounted for in 3 (and also because BUAGs in the
body of the message are sometimes useful.)

=item 5

Article has incorrectly-formatted quoted material.

A quote is expected to precede the original material. Scoring is based
upon this. The first four lines of the quoted material doesn't score
at all. The original material is then counted for lines and bytes, and
half of each is also allowed for quoted material. Beyond that, Byte
and Line scores are applied. Top-posted articles are expected to score
badly from this heuristic.

=cut

# =item 6.
#
#Capitalisation. Score Byte and Line points (the latter by
#heuristic) for each capitalised letter beyond 20% of the original
#material. (Not yet done).

=back

In addition, Byte and Line scores are multipled by the number of
newsgroups crossposted to.

For final scoring, a Line point equals 40 Byte points.

=head1 FUNCTIONS

=over 4

=item B<score>

  my $score=Message::Style::score(@article);

Performs a scoring operation on the article, and returns the score.

=cut

sub score {
  my $aref=ref $_[0] ? $_[0] : \@_;

  # warning, neophyte code, only recently dredged up from the
  # archives, marginally cleaned-up, and turned into a CPANable module
    my @article=();
    my @header=();
    my %fault=();
    my %header=();
    my %meta=();
    my $t="";
    my ($lscore, $bscore)=(0,0);

  while(@$aref) {
    $_=shift @$aref;
    chomp;
    last unless length;
    push @header, $_;
  }

    @article=@$aref;
  chomp @article;

    # Firstly, the header is parsed. Folded lines are unfolded, and a
    # hash of header names vs. values is created. Dupes and duff
    # headers are noted.
    foreach(reverse @header) {
	# Join folded lines
	$t="$_$t";
	unless(/^[\t\ ]/) { # not folded
	    chomp $t;
	    if($t=~/^([A-Za-z0-9-]+)\: (.*)$/) {
		$fault{"Duplicated header: $1: $2"}++ if(exists $header{$1});
		$header{lc $1}=$2;
		$t="";
	    } else {
		$fault{"No colon-space in header ($t)"}++;
	    }
	}
    }

    # Check if this is a plain text posting or something else.

    if(defined $header{'content-type'}
       and $header{'content-type'}!~/^text\/plain/i) {
	$fault{"Non plaintext content: $header{'content-type'}"}++;
	$meta{isbinary}++;
    }

    if(defined $header{'content-transfer-encoding'}
       and $header{'content-transfer-encoding'}!~/^(7bit|8bit|quoted-printable)/i) {
	$fault{"Non plaintext encoding: $header{'content-transfer-encoding'}"}++;
	$meta{isbinary}++;
    }

    foreach my $line (@article) {
	# @words is a list of words in this line
	my @words=grep { $_ ne '' } split(/\s+/, $line);
	my $len=length $line; # For speed

	# Check for indentation, $qlevel contains level of indentation.
	# 0=original material, >=1 is quoted
	my $qlevel=0;
	$_=$line;
	s/\s+//g;
	$qlevel=length $1 if /(^\>*)/;

	# Check for long lines
	if(length($line)>80) {
	    $meta{toolong}++ if $len>80;
	    $meta{maxlen}=$len
		unless exists $meta{maxlen} and $meta{maxlen}>$len;
	    $lscore+=int($len/80);
	}
	
	if(scalar @words) { # Nonblank line
	    if($words[0]=~/^\>/) { # Quoted material
		$meta{qlines}++;
		$meta{qwords}+=scalar @words;
		$meta{qchars}+=length;
	    } else { # "Original" material
		$meta{olines}++;
		$meta{owords}+=scalar @words;
		$meta{ochars}+=length;
		foreach(@words) { # Crude check for BUAGs
		    if(/[^A-Za-z0-9]{3,}/) {
			next if m#(\.{3,3}|://)#;
			$meta{buag}++;
			last;
		    }
		}
	    }
	}

	# Check for and count signature
	if(exists $meta{hassig}) {
	    $meta{siglines}++;
	    if(exists $meta{siglines} && $meta{siglines}>4) {
		$lscore++;
		$bscore+=$len;
	    } elsif($len>80) {
		$fault{'Wide signature'}++;
		$lscore+=$len-80;
	    }
	}
	$meta{hassig}++ if(/^--\ ?$/);
	$fault{'Broken sigsep'}++
	    if($line eq '--');

#	if(/-----BEGIN PGP SIGNATURE-----/
#	   .. /-----END PGP SIGNATURE-----/) {
#	    $fault{'PGP signature'}++;
#	    next;
#	}

    }

    # Let's start moaning
    if(exists $meta{siglines} and $meta{siglines}>4) {
	$fault{"Signature is $meta{siglines} lines, should be four at most"}++;
	# Score already applied
    };

    if(exists $meta{buag} and $meta{buag}>10) {
	$fault{"Large BUAG/nontext present"}++;
	# No score, just a warning
    }

    if(exists $meta{toolong}) {
	$fault{"Overlong lines ($meta{toolong} of them), longest is $meta{maxlen} chars"}++;
	# Score already applied
    }

    if(exists $meta{isbinary}) {
	# Apply score to *whole* article
	map { $bscore+=length; $lscore++ } @header;
	map { $bscore+=length; $lscore++ } @article;
    }

  my $groups=1;
  $groups=($header{newsgroups}=~tr[,][,])+1
    if defined $header{newsgroups};
    my $score=int(($lscore*40+$bscore)*sqrt $groups);
    my $name=$header{from};

    if($lscore|$bscore) {
	$fault{"Score: $score"}++;
	$fault{"Lscore: $lscore, Bscore: $bscore, Groups: $groups"}++;
    }

  # You may correctly assume that this code was ripped from something
  # that used %fault, even though this package doesn't do anything
  # useful with it.

#  carp Dumper \@article, \%fault, \%meta;

  return $score;

  # end neophyte code. May @DEITY smile upon me one day to have the
  # tuits to clean up the code and turn it into a useful package.
}

=back

=head1 WARNINGS

This module is basically the result of ripping out the core of a
really nasty script I wrote early in my Perl career and wrapping the
minimum around it to pass CPAN muster. So the code is a bit crufty,
although it does certainly work and has heard of strict and warn.

It was however reasonably well-tested at the time thanks to plenty of
fsckwit source material on birmingham.misc / uk.local.birmingham.

=head1 SEE ALSO

=head1 AUTHOR

All code and documentation by Peter Corlett <abuse@cabal.org.uk>.

=head1 COPYRIGHT

Copyright (C) 2000-2004 Peter Corlett <abuse@cabal.org.uk>. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=cut
  
1;

