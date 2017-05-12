use Test::More tests => 1;

use Mail::QmailSend::MultilogParser;
use Data::Dumper;

my @items;
my $parser = Mail::QmailSend::MultilogParser->new(callback => sub { push @items, @_; });

open DATA, "testin/data.log";
$parser->parse(\*DATA);
close DATA;

is($#items, 70, "works");
