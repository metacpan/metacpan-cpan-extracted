use Test;
plan tests => 1;
use strict;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::OBOWriter;
use GOBO::InferenceEngine;
#use GOBO::DBIC::GODBModel::Query;
#use GOBO::AmiGO::Indexes::AmiGOStatementIndex;
use FileHandle;

ok(1);
exit 0;

## Constructor.
my $q = GOBO::DBIC::GODBModel::Query->new({
    host => '127.0.0.1',
    #name => 'go_latest_lite',
    name => 'go',
    type => 'term_lazy',
                              });

my $g = new GOBO::Graph;
my $dbh; # connect to a test db TODO
bless $g->link_ix, 'GOBO::AmiGO::Indexes::AmiGOStatementIndex';
#bless $g, 'GOBO::AmiGO::Indexes::AmiGOStatementIndex';
$g->link_ix->query( $q );

my $links = $g->get_target_links('GO:0005634');

foreach my $link (@$links) {
    printf "$link\n";
}

# TODO...
