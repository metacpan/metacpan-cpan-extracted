package Lingua::EN::Contraction;

use Data::Dumper;
require Exporter;

@ISA = qw( Exporter );

@EXPORT_OK = qw(

  contraction
  contract_n_t
  contract_other

);

use warnings;
use strict;
#use diagnostics;


use vars qw(
  $VERSION
);


$VERSION = '0.104';

my @modal = 	qw(might must do does did should could can);
my @pronoun = 	qw(I you we he she it they);
my @that = 	qw(there this that);
my @other = 	qw(who what when where why how);
my @verbs =    qw(are is am was were will would have has had);

my $modal_re =   re_ify_list(@modal);
my $pronoun_re = re_ify_list(@pronoun);
my $that_re    = re_ify_list(@that);
my $other_re =   re_ify_list(@other);
my $verbs_re =   re_ify_list(@verbs);


my %list = ( 	     am   => ['I'], 
	             had  => [@pronoun, @that, @other],
	 	     would=> [@pronoun, @that, @other],
		     will => [@pronoun, @that, @other],
		     are  => [@pronoun, @other],
		     is   => [@pronoun, @that, @other],
		     has  => [@pronoun, @that, @other],
		     that => [@pronoun, @that, @other],
		     have => [@pronoun, @that, @other]
		   );
		



sub contraction {

	my $phrase = shift;

	# contract "not" before contracting other stuff...
	
	$phrase = contract_n_t($phrase);
	$phrase = contract_other($phrase);

	return $phrase;
}


sub contract_n_t {

		# MODAL-NOT -> MODAL-N_T (that is, "were not" becomes "weren't")
		# MODAL-PRONOUN-NOT -> MODAL-N_T-PRONOUN (that is, "were we not" becomes "weren't we")


	my $phrase = shift;

	$phrase =~ s/(can)(not)/$1 $2/ig;

	my $new_phrase = $phrase;

	
	
	while ($phrase =~ /(\b($modal_re|$verbs_re) ?($pronoun_re )?(not)\b)/ig) {
		my $orig_phrase = $1;
		my $_phrase = $1;
		
	
		if ( $_phrase =~ /\b($modal_re|$verbs_re) ?(not)\b/i  ) {
			my $m = $1;
			my $n = $2;
			if (my $m2 = N_T($m, $n)) {
				$_phrase =~ s/\b$m not\b/$m2/i;
			}
		}
		if ($_phrase =~ /($modal_re|$verbs_re) ($pronoun_re) (not)\b/i ) {
			my $p = $2; my $m = $1;
			my $n = $3;
			if (my $m2 = N_T($m, $n)) {
				$_phrase =~ s/\b$m $p not\b/$m2 $p/i;
			}
		}
		next if $orig_phrase eq $_phrase;
		$phrase =~ s/$orig_phrase/$_phrase/;
	}
	return $phrase;

}

sub contract_other {
	my $phrase = shift;

	while ($phrase =~ /\b(let us)/ig) {
		$phrase =~ s/\b(let) u(s)/$1'$2/i;
	}

	while ($phrase =~ /(\b([\w']*(?: not)?) ?($pronoun_re|$other_re|$modal_re|$that_re) ($verbs_re)\b)/ig) {
		#print "1 -> $1\n\t, 2-> $2, 3->$3, 4->$4\n";
		my $orig_phrase = $1;
		my $_phrase = $1;
		my $w1 = $2;
		my $w2 = $3;
		my $w3 = $4;

		# don't form contractions following modal verbs:
		# nobody ever says "could I've been walking?", they say "could I have been walking?".
		next if $w1 =~ /$modal_re/;

		my $ctrct_after = $list{lc($w3)} or next;
		next unless match_any($w2, @$ctrct_after);
		my $w3b = $w3;
		$w3b =~ s/.*(m|d|ll|re|s|t|ve)$/$1/i; 
		next if $w3b eq $w3;		

		$_phrase =~ s/($w2) ($w3)/$w2'$w3b/;

		next if $_phrase eq $orig_phrase;
		$phrase =~ s/$orig_phrase/$_phrase/;
	}
	return $phrase;
}



sub match_any {
	my $a = shift;
	my @b = @_;
	for (@b) { return 1 if $a =~ /\b$_\b/i ; }
	return undef;
}

sub N_T {

    #add contracted negation to modal verbs:
    my $modal       = shift;
    my $not 	    = shift;
    die "unexpected value for 'not'\n" unless $not =~ /not/i;

	# preserve orginal case for "NOT->N'T" and "not->n't"
	# but change case for "Not" -> "n't"

    my $n_t = 	$not =~ /N[oO]T/ ? "N'T":
		 		   "n't";

    if (lc($modal) eq 'am') {return "$modal $not"; }

	# cases where simply adding "n't" doesn't work:
	# will->won't, can->can't, shall->shan't
	# trying to preserve original case...

    elsif (lc($modal) eq 'will') {
		$modal =~ s/ll//i;
		$modal =~ tr/Ii/Oo/;	  
	  }

    elsif (lc($modal) eq 'can') {
		$modal =~ s/n//i;
	  }

    elsif (lc($modal) eq 'shall') {
		$modal =~ s/ll//i;
	  }
		
    my $answer = $modal . $n_t;

    return    $modal eq lc($modal) ? lc($answer):
	      $modal eq uc($modal) ? uc($answer):
	      $modal eq ucfirst($modal) ? ucfirst($answer):
				$answer;

}

sub re_ify_list {
	my $re = '\b(?:' . join("|", @_) . ')';
	$re = qr/$re/i;
}

1;

=head1 NAME

Lingua::EN::Contraction - Add apostrophes all over the place... 

=head1 SYNOPSIS

	use Lingua::EN::Contraction qw(contraction);

	$sentance = "No, I am not going to explain it. If you cannot figure it out, you did not want to know anyway...  :-)";
	 
	print contraction($sentance) ;


=head1 DESCRIPTION

A very simple, humble little module that adds apostrophes to your sentances for you.  There aren't any options, so if you 
don't like the way it contracts things then you'll have to change the code a bit.  It'll preserve capitalization, so if 
you feed it things like "DO NOT PANIC", you'll get "DON'T PANIC" out the other end.  

=head1 BUGS

=head1 TODO

=head1 AUTHOR

Russ Graham, russgraham@gmail.com

=cut

