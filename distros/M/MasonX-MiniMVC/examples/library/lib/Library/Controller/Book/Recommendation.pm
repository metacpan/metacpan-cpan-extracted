package Library::Controller::Book::Recommendation;

use strict;
use warnings;

sub default {
    my ($self, $m, @args) = @_;
    $m->notes("title", "MiniMVC Library Demo: Recommendations");
    $m->comp("view/book/recommendation/default.mhtml");
}

sub view {
    my ($self, $m, @args) = @_;
    $m->notes("title", "MiniMVC Library Demo: View Recommendation");
    # ordinarily, now, we'd go fetch a recommendation object using our Model 
    # and then pass it through to the view, for display.  But we don't have
    # a model, so for now we'll just do something simpler.
    $m->comp("view/book/recommendation/view.mhtml", recommendation_id => shift @args);
}

1;
