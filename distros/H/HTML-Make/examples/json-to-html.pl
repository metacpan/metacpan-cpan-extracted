#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use JSON::Parse 'parse_json';
use HTML::Make;
binmode STDOUT, ":utf8";
my $json =<<EOF;
{"words":[{"j_pron_only":"パイプ","word":"pipe"},{"word":"cutting","j_pron_only":"カティング"},{"word":"implement","j_pron_only":"インプリムント"}]}
EOF
my $p = parse_json ($json);
my $html = json_to_html ($p);
print $html->text ();
exit;

sub json_to_html
{
    my ($input) = @_;
    my $element;
    if (ref $input eq 'ARRAY') {
	$element = HTML::Make->new ('ol');
	for my $k (@$input) {
	    my $li = $element->push ('li');
	    $li->push (json_to_html ($k));
	}
    }
    elsif (ref $input eq 'HASH') {
	$element = HTML::Make->new ('table');
	for my $k (sort keys %$input) {
	    my $tr = $element->push ('tr');
	    $tr->push ('th', text => $k);
	    my $td = $tr->push ('td');
	    $td->push (json_to_html ($input->{$k}));
	}
    }
    else {
	$element = HTML::Make->new ('span', text => $input);
    }
    return $element;
}
