package Games::Scrabble;

use strict;
use Carp;

require Exporter;

our $VERSION    = 0.99;
our @ISA        = qw( Exporter );
our @EXPORT_OK  = qw( validate generate );

sub validate {
    no warnings;
    my @words    = @{ pop @_ };	
    my $wordlist = $_[0] || $ENV{PWD} . "/wordlist";	
    my %valid;

    open ( my $fh, $wordlist ) || croak "Can not open wordfile.\n";

    while (<$fh>) {
	chomp;
	for my $w (@words) {
	    next if $valid{$w} == 1;
	    if ($w eq $_) {
		print qq|"$w" is valid.\n|;
		$valid{$w} = 1;
		last;
	    }
 	}
    }
    
    for my $w (@words) {
	print qq|"$w" is invalid.\n| unless $valid{$w} == 1;
    }
}

sub generate {
    no warnings;
    my $args     = shift;
    my $letters  = $args->{letters};
    my $re       = $args->{re} || "//";
    my $wordlist = $args->{wordlist} || $ENV{PWD} . "/wordlist";
    my $len;
    my $check_letters;
    my ($min_len, $max_len) = (split ",", $args->{len});
    $min_len ||= 2;
    $max_len ||= 7;
    
    croak "Not enough letters.\n" unless (length($letters) > 1);
    open ( my $fh, $wordlist ) || croak "Can not open wordfile.\n";

    LINE: while (<$fh>) {
	chomp;
        $len = length $_;
        next LINE if ($len > $max_len || $len < $min_len);
        $check_letters = $letters;
	
        next LINE unless (eval $re);

        for my $l (split //, $_) {
            next LINE unless ( $check_letters =~ s/$l// or 
			       $check_letters =~ s/\?//    );
        }
        print "$_\n";
    }

}

1;
__END__

=pod

=head1 NAME

B<Games::Scrabble> -- please use Games::Literati, for a complete
                      Literati/Scrabble resolver.

=head1 SYNOPSIS

    use Games::Scrabble;

=head1 DESCRIPTION


B<Games::Scrabble> provides functiones to validate and generate words 
of Scrabble game.
 
    validate($mywordlist, [word1, word2, word3...]). 

If mywordlist is not given, the 'wordlist' in current working 
directory will be used.  

    generate({ letters => "letters and blanks", 
	           len => "mininum_length, maximum_length", # default 2,7 
	            re => 'regexes',	    # use single quotes or q||! 
	      wordlist => "......."  } )

Print out scrabble words meet the requirements. B<len> represents minimum
and maximum length of the target word, B<re> represents the regex matches 
against the target words. use "?" to represent blank tiles.
B<wordlist> is optional, see validate() above.

Note that repeated letters should be B<all> listed, to indicate how many 
of them may be used.

Example 1:

    generate({letters => "aquabt?", 
                  len => "2,4", 
	           re => '/q/ && !/u/'});


    qat
    qats

use a(up to 2, actually 3 in this case, since ? can represent a), q, u, t, 
b and blank tiles to generate 2,3 or 4-letter words contain q but not u, 
and use 'wordlist' located in current working directory. 

Example 2:

    generate({letters => "??"});

find out all valid 2-letters.


Example 3:

    validate(["qat","qatw"]);

find out if "qat", "qatw" are acceptable.


=head1 AUTHOR

I<chichengzhang@hotmail.com>.

=cut

