use strict;
use warnings;
use Algorithm::NaiveBayes;
use Data::Dumper;

my $path     = '../sample.bin';
my $new_path = 'sample.bin.new';
my $nb       = Algorithm::NaiveBayes->new( purge => -1 );
my $data     = $nb->restore_state($path);

my $word_hash;
my $sum_hash;
while ( my ( $label, $ref ) = each %{ $data->{training_data}->{labels} } ) {
    my $train_count = $ref->{count};
    my $attr_count  = keys %{ $ref->{attributes} };
    for ( keys %{ $ref->{attributes} } ) {
        $word_hash->{$_}++;
        $sum_hash->{$label} += $ref->{attributes}->{$_};
    }
}

while ( my ( $label, $ref ) = each %{ $data->{training_data}->{labels} } ) {

    my $train_count = $ref->{count};
    my $attr_count  = keys %{ $ref->{attributes} };
    print $label, "\n";
    print "[ Train Count ]    : ", $train_count, "\n";
    print "[ Attribute Count ]: ", $attr_count,  "\n";

    print "-" x 100, "\n";
	print "[Attr_Score]  ";
	print "[Attr_Percent]  ";
	print "[Attr_Count]   ";
	print "[Ratio]   ";
	print "[Word]";
	print "\n";
    print "-" x 100, "\n";

    my $dec = 0;
    for (
        sort { $ref->{attributes}->{$b} <=> $ref->{attributes}->{$a} }
        keys %{ $ref->{attributes} }
        )
    {
        my $attr_score = $ref->{attributes}->{$_};
        my $attr_percent
            = $ref->{attributes}->{$_} / $sum_hash->{$label} * 100;
        my $attr_count = $word_hash->{$_};
        my $ratio      = $attr_percent / $attr_count;
        print sprintf( "%10.4f", $attr_score ), "\t",
            sprintf( "%10.4f", $attr_percent ), "\t",
            sprintf( "%03d",   $attr_count ),   "\t",
            sprintf( "%10.4f", $ratio ),        "\t",
            $_, "\n";
        if ( $ratio < 0.001 ) {
            $dec++;
            delete $ref->{attributes}->{$_};
        }
    }
    print "[ Size Down ] ";
    print $attr_count, " - ", $dec, " = ", $attr_count - $dec, "\n";
    print "=" x 100, "\n";
}

$data->train;
$data->save_state($new_path);