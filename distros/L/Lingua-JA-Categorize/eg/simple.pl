use strict;
use warnings;
use blib;
use HTML::Feature;
use Data::Dumper;
use Lingua::JA::Categorize;
use FindBin;

local $Data::Dumper::Terse  = 1;
local $Data::Dumper::Indent = 1;

my $feature = HTML::Feature->new(
    engines => [
        'HTML::Feature::Engine::LDRFullFeed',
        'HTML::Feature::Engine::GoogleADSection',
        'HTML::Feature::Engine::TagStructure',
    ]
);

my $datafile    = "$FindBin::RealBin/sample.bin";
my $categorizer = Lingua::JA::Categorize->new;
$categorizer->load($datafile);

loop();

sub loop {
    print "----\n";
    print "Input URL: ";
    my $url = <STDIN>;
    chomp $url;
    my $text = $feature->parse($url)->text;

    my $result = $categorizer->categorize($text);
    print "\n";

    print "Result(score) :\n";
    print Dumper $result->score;
    print "\n";

    print "Confidence : ";
    print $result->confidence, "\n";
    print "\n";

    print "UserExtention : ";
    print Dumper $result->user_extention, "\n";
    print "\n";

    loop();
}
