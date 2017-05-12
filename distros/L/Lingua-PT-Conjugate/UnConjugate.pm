#!/usr/bin/perl -w
#
# Perl package exporting a function "unconj" that un-conjugates 
# Portuguese verbs. 
# 
# Author : Etienne Grossmann (etienne@isr.ist.utl.pt) 
# 
# Date   : September 1999 onwards.
#
# 
package Lingua::PT::UnConjugate ;

=head1 NAME

Lingua::PT::UnConjugate - Recognition of the conjugated forms of
portuguese verbs.

=head1 DESCRIPTION

This module provides functions for the recognition of the conjugated
forms of portuguese verbs.

=head1 BUGS

Composed tenses are not recognized. The verb list contains many
non-verbs that I have not removed yet. 

=cut

use Lingua::PT::Conjugate qw( conjug %long_tense ) ;

use Lingua::PT::Infinitives ;
use Lingua::PT::VerbSuffixes ;
import Lingua::PT::Accent_iso_8859_1 qw(asc2iso);
use Exporter ;
@ISA = qw(Exporter);
# Yes, this package is a namespace polluter. 
@EXPORT = qw( unconj ); 
@EXPORT_OK = qw( unconj list_entries string_entries ); 


BEGIN {
				# Suffixes and Infinitives.

    # ####################### VOCALS, CONSONANTS ##################### 
    # Vocals and Consonants   
    $vocs = "aeiouáàäâãéèëêíìïîóòöôõúùüû";
    $cons = 'qwrtypsdfghjklzxcvbnm';
    $letter = "ç$vocs$cons";
    $lpat = "[$letter]" ;
				# Equivalent accent-matching regexp
    %equiv = ( "a"=>"[aáàäâã]",
	       "á"=>"[aáàäâã]",
	       "à"=>"[aáàäâã]",
	       "ä"=>"[aáàäâã]",
	       "â"=>"[aáàäâã]",
	       "ã"=>"[aáàäâã]",
	       "e"=>"[eéèëê]",
	       "é"=>"[eéèëê]",
	       "è"=>"[eéèëê]",
	       "ë"=>"[eéèëê]",
	       "ê"=>"[eéèëê]",
	       "i"=>"[iíìïî]",
	       "í"=>"[iíìïî]",
	       "ì"=>"[iíìïî]",
	       "ï"=>"[iíìïî]",
	       "î"=>"[iíìïî]",
	       "o"=>"[oóòöôõ]",
	       "ó"=>"[oóòöôõ]",
	       "ò"=>"[oóòöôõ]",
	       "ö"=>"[oóòöôõ]",
	       "ô"=>"[oóòöôõ]",
	       "õ"=>"[oóòöôõ]",
	       "u"=>"[uúùüû]",
	       "ú"=>"[uúùüû]",
	       "ù"=>"[uúùüû]",
	       "ü"=>"[uúùüû]",
	       "û"=>"[uúùüû]",
	       "c"=>"[cç]",
	       "ç"=>"[cç]",
	       ) ;
    $equivk = join "", "[", keys(%equiv), "]" ;

				# Lower_case
    %mylc = split "",
    "ÇçÁáÀàÄäÂâÃãÉéÈèËëÊêÍíÌìÏïÎîÓóÒòÖöÔôÕõÚúÙùÜüÛû";  
    $mylck = join "",  "[", keys(%mylc), "]" ;
    # print "$equivk\n$mylck\n" ;

}

sub my_lc			# lc() for accentuated characters too 
{
    my $a = shift ;
    $a = lc($a) ;
    $a =~ s/($mylck)/$mylc{$1}/g ;
    return $a ;
}

# $r = regexify( $w ) 
# $r is a regex that will match any ending substring of $w 
sub regexify			
{
    my $r = shift ;
    my $r0 = $r ;
    while( $r =~ s/($lpat+)($lpat)/(\?:$1)\?$2/ ){}
    # print "regexify : $r0 -> $r\n" ;
    return $r ;
}

=head1 SYNOPSIS

=head1 C<$verb_forms = unconj( [-a] , $string )>

Attempts to recognize a conjugated form of a Portuguese verb, and
returns the result as a reference to hash : if the element

    C<$verb_forms-E<gt>{$infinitive}-E<gt>{$tense}-E<gt>[$person]>

is true, then the conjugation of the verb "$infinitive" at the tense
"$tense" and the person "$person" should yield "$string".

=head2 OPTIONS

The first argument may an option :

=over 4

=item -a : Try to match accentuation errors.

=item -A : If no match is found, try matching with option -a.

=back

=cut

sub unconj
{
    my $acc = 0 ;		# Check errors in accentuation ?
    my $ret = 0 ;		# Retry in case of failure ?
    while( $_[0] =~ /^-[aA]$/ )	# Get options
    {
	my $opt = shift ;
	$opt =~ s/-//;
	$acc = 1 if $opt =~ /a/ ;
	$ret = 1 if $opt =~ /A/ ;
	# print "unconj : option $opt\n" ;
    }
    my $v0 = shift ;
    # print "unconj : $v0\n" ;
    my $v = asc2iso( $v0 );	# No ascii-style accents
    $v = my_lc($v) ;
    # my @res = ();
    my %res = ();
    
    my $p = regexify( $v ) ;
    if( $acc )
    {
	## HERE : assume letters are isolated in $p
	$p =~ s/\b($equivk)\b/$equiv{$1}/g ;
	## print "$p\n" ;
    }
    my $p2 = "($p .*)" ;
    my @matches = $verb_suffixes =~ /^$p2/mg ;
    
    push @matches, " cfut,1,", " cfut,3," if $infinitives =~ /^$v$/m ;
    
    # print join "\n", @matches,"\n" ;
    foreach $m (@matches)
    {
	my ($s,$t,$p,$r) = $m =~ /^(\S*) (\w+),(\d+),(.*)/ ;
	my @endings = split ",",$r ;
	@endings = ("") unless @endings ;
	# print "Found $m ",0+@endings," endings\n";
	# print "-- $s, $t, $p, $r\n" ;
	my $root = $s ? substr( $v, 0, -length($s) ) : $v ;
	foreach (@endings)
	{
	    my $i = $root . $_ ;
	    # $i =~ s/r+r$/r/ ;	# Why?
	    ##print "Trying : $i, $t, $p, $root + $_\n" ;
	    next unless $infinitives =~ /^$i$/m ;
	    my $check = conjug("xs",$i,$t,$p) ;
	    $check =~ s/($equivk)/$equiv{$1}/g if $acc ;
	    # print "Check $check\n" if $acc ;
	    # print "Checking $i, $t, $p against $check\n" ;
	    next unless $v =~ /^$check$/ ;
	    # print "Found $i, $t, $p in $m\n" ;
	    # push @res , [$i, $t, $p] ; 
	    $res{$i}->{$t}->[$p] = 1 ;
	}
    }
    %res = %{unconj("-a",$v0)} if $ret && !$acc && !keys(%res) ;
    return \%res ;
}

=head1 C<@res = string_entries( ['l'], \%verb_forms )>

Convert a hash of recognized forms into a list of strings 
C<"$verb, $tense, $person">. 

If the first argument is a 'l', then long forms of verb names will
be used.

=cut

sub string_entries
{
    my $long = 0 ;
    if( $_[0] eq 'l' )		# Accept a "long verb name" option
    {
	$long = 1 ;
	shift ;
    }
    my $vdb = shift ;
    my ($w,$x,$y,$z);
    my @res = ();

    my $vcnt = 0 ;

    while( ($w,$x) = each %$vdb ) {
	next if $w eq " " ;
	next unless $w ;
	while( ($t,$y) = each %$x ) {
	    foreach $p (1..6)
	    {
		# print "." if $vcnt % 50 == 49 ;
		# print "\n".sprintf("%-6d ",$vcnt) 
		# if $vcnt %1000 == 999 ;
		next unless defined( $y->[$p] );
		# HERE : A bug ? If I don't check for "defined" the
		# first time $long_tense{$t} is used, it is undef'd.
		$t = $long_tense{$t} if $long   && 
		     defined( $long_tense{$t}  );
		push @res, "$w, $t, $p" ;
	    }
	}
    }
    return sort @res ;
}

=head1 C<@res = list_entries( ['l'], \%verb_forms )>

Convert a hash of recognized forms into a list of triplets 
C<[ $verb, $tense, $person ]>. 

If the first argument is a 'l', then long forms of verb names will
be used.

=cut
 
sub list_entries
{
    my $long = 0 ;
    if( $_[0] eq 'l' )		# Accept a "long verb name" option
    {
	$long = 1 ;
	shift ;
    }
    my $vdb = shift ;
    my ($w,$x,$y,$z);
    my @res = ();

    my $vcnt = 0 ;

    while( ($w,$x) = each %$vdb ) {
	next if $w eq " " ;
	next unless $w ;
	while( ($t,$y) = each %$x ) {
	    foreach $p (1..6)
	    {
		# print "." if $vcnt % 50 == 49 ;
		# print "\n".sprintf("%-6d ",$vcnt) 
		# if $vcnt %1000 == 999 ;
		next unless defined( $y->[$p] );
		$t = $long_tense{$t} if $long && 
		     defined( $long_tense{$t} );
		push @res, [$w, $t, $p ] ;
	    }
	}
    }
    return sort @res ;
}

=head1 SEE ALSO : unconj, conjug, treinar.

=head1 AUTHOR Etienne Grossmann, 1999 [etienne@isr.ist.utl.pt] 

=head1 CREDITS

Thanks to Soraia Almeida (salmeida@logos.it) from the Logos project
(http://www.logos.it) and Ulisses Pinto and José João Almeida from
Projecto Natura (http://shiva.di.uminho.pt/~jj/pln) who made Ispell
available.

A big part of the list of verb infinitives comes from files used in
Ispell (http://shiva.di.uminho.pt/~jj/pln) and in Logos
(http://www.verba.org, http://www.logos.it).  these projects. Some
verbs were removed and others added by hand.

=cut


1;





