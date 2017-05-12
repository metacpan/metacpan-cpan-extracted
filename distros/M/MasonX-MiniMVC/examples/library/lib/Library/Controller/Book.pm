package Library::Controller::Book;

use strict;
use warnings;

sub default {
    my ($self, $m, @args) = @_;
    $m->notes("title", "MiniMVC Library Demo: Books");
    $m->comp("view/book/default.mhtml");
}

sub view {
    my ($self, $m, @args) = @_;
    $m->notes("title", "MiniMVC Library Demo: View Books");
    # ordinarily, now, we'd go fetch a book object using our Model and
    # then pass it through to the view, for display.  But we don't have
    # a model, so for now we'll just do something simpler.
    $m->comp("view/book/view.mhtml", book_id => shift @args);
}

sub search {
    my ($self, $m, @args) = @_;
    $m->notes("title", "MiniMVC Library Demo: Search Results");
    if (my $query = $m->request_args->{query}) { # search by form
        $m->comp("view/book/search_results.mhtml", query => $query);
    } elsif (@args) { # search by URL
        $m->comp("view/book/search_results.mhtml", query => join(" ", @args));
    } else {
        $m->notes("title", "MiniMVC Library Demo: Search");
        $m->comp("view/book/search_form.mhtml");
    }
}

1;
