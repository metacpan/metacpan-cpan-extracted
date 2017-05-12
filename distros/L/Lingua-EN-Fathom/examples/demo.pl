#! /usr/local/bin/perl
# Demo script for Lingua::EN::Fathom.pm


use Lingua::EN::Fathom;

my $sample1 =
q{

In general, construction of pictograms follows the general procedure used in
constructing bar charts. But two special rules should be followed! First, all
of the picture units used must be of equal size. The comparisons must be made
wholly on the basis of the number of illustrations used and never by varying
the areas of the individual pictures used. The reason for this rule is obvious.

The human eye is grossly inadequate in comparing areas of geometric designs.
Second, the pictures or symbols used must appropriately depict the quantity to
be illustrated. A comparison of the navies of the world, for example, might
make use of miniature ship drawings. Cotton production might be shown by bales
of cotton. Obviously, the drawings used must be immediately interpreted by the
reader.

End.

};

my $sample2 =
q{
The second paragraph to analyse.
};

#-------------------------------------------------------------------------------

my $text = Lingua::EN::Fathom->new();
$text->analyse_block($sample1,1);
$text->analyse_block($sample2,1);

print($text->report,"\n");

%uniq_words = $text->unique_words;
foreach $word ( sort keys  %uniq_words )
{
	# print occurences of each unique word, followed by the word itself
	print("$uniq_words{$word}\t:$word\n");
}




