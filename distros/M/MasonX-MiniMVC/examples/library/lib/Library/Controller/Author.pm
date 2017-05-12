package Library::Controller::Author;

use strict;
use warnings;

sub default {
    my ($self, $m, @args) = @_;
    $m->notes("title", "MiniMVC Library Demo: Authors");
    $m->comp("view/author/default.mhtml");
}

sub view {
    my ($self, $m, @args) = @_;
    $m->notes("title", "MiniMVC Library Demo: View Author");
    # ordinarily, now, we'd go fetch an author object using our Model and
    # then pass it through to the view, for display.  But we don't have
    # a model, so for now we'll just do something simpler.
    $m->comp("view/author/view.mhtml", author_id => shift @args);
}


1;
