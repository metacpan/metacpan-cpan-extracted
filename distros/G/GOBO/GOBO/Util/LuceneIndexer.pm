package GOBO::Util::LuceneIndexer;
use Moose;
use strict;

use Lucene;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::NegatedStatement;
use GOBO::Node;
use GOBO::Parsers::OBOParser;

has index_writer => (is=>'rw',isa=>'Lucene::Index::IndexWriter');
has analyzer => (is=>'rw',isa=>'Lucene::Analysis::Standard::StandardAnalyzer');
has base_url => (is=>'rw',isa=>'Str', default=>sub{"http://obofoundry.org/obo/"});
has custom_hardwired_fields => (is=>'rw',isa=>'HashRef', default=>sub{{}});
has target_dir => (is=>'rw',isa=>'Str', default=>sub{"."});

sub open {
    my $self = shift;

    ## Same analyzer for everybody.
    my $analyzer = new Lucene::Analysis::Standard::StandardAnalyzer();
    $self->analyzer($analyzer);

    my $spot = $self->target_dir;
    my $store = Lucene::Store::FSDirectory->getDirectory("$spot/", 1);

    my $writer = new Lucene::Index::IndexWriter($store, $analyzer, 1);
    $self->index_writer($writer);
    return;
}

sub index_terms {
    my $self = shift;
    my $terms = shift || [];

    my $writer = $self->index_writer;
    my $base_url = $self->base_url;
    my $fh = $self->custom_hardwired_fields || {};

    foreach my $t (@$terms) {

        ## At a minimum, we need an id from the term information.
	my $id = $t->id || undef;
	next unless defined $id;

        ## Get the gimmies.
        my $label = $t->label || '';
        my $def = $t->definition || '';
        my $ns = $t->namespace || '';

        ## Cat synonyms, but put a little distance between them.
        my $synstr = join("\n", (map {$_->label} @{$t->synonyms || []}));

        ## TODO: Construct a (best guess) URL.
        my $ourl = "$base_url" . $id;

        ## Lucene ADD!
        my $doc = Lucene::Document->new;
        $doc->add(Lucene::Document::Field->Text(id => $id));
        $doc->add(Lucene::Document::Field->Text(namespace => $ns));
        $doc->add(Lucene::Document::Field->Text(label => $label));
        $doc->add(Lucene::Document::Field->Text(def => $def));
        $doc->add(Lucene::Document::Field->Text(synonym => $synstr));
        $doc->add(Lucene::Document::Field->Text(url => $ourl));
        foreach my $k (keys %$fh) {
            $doc->add(Lucene::Document::Field->Text($k => $fh->{$k}));
        }

        # Add to the store.
        $writer->addDocument($doc);
    }

}

sub close {
    my $self = shift;
    my $writer = $self->index_writer;

    $writer->optimize;
    $writer->close;
}


=head1 NAME

GOBO::Util::LuceneIndexer

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 REQUIREMENTS

Lucene


=cut

1;
