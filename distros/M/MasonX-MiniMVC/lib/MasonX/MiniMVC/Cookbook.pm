package MasonX::MiniMVC::Cookbook;

=head1 NAME

MasonX::MiniMVC::Cookbook -- examples of MiniMVC usage

=head1 DESCRIPTION

=head2 Build a static page

Create a controller method that looks like this:

    sub help {
        my ($self, $m) = @_;
        $m->comp("view/something/help.mhtml")
    }

Your C<help.mhtml> view file will (presumably) contain only static HTML.

=head2 Pass data to a dynamic page

Create a controller method that does most of the work of figuring out
the details, then passes a pile o' data to the view for display:

    sub details {
        my ($self, $m, $id) = @_;
        # let's pretend fetch() gives us a hashref...
        my $details = MyApp::Model::Whatever->fetch($id);
        $m->comp("view/something/details.mhtml", details => $details);
    }

The view looks something like this:

    <%args>
    %details
    </%args>

    <h1>Details for <% $details{title} %></h1>

    <p>
    Description: <% $details{description} %>
    </p>

=head2 Pick up data from the URL

In your controller, do:

    sub view {
        my ($self, $m, @args) = @_;
        # ...
    }

If the user requested the URL http://example.com/article/view/foo/bar/baz and
the controller for "article" is MyApp::Article, then this will call
C<MyApp::Article::view()> with C<@args> set to C<("foo", "bar", "baz")>.

=head2 Use data from a form submission

In your controller, do:

    sub add {
        my ($self, $m, @args) = @_;
        my %fields = $m->request_args();
    }

If you want a single form field, you can use C<$m->request_args->{$field}>.

=head2 Use data from either a form or a URL

Here's an example of combining the previous two techniques, taken from the
C<examples/library> demo included with the MiniMVC distro.

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

=head2 Change the overall look and feel

Edit the C<autohandler> file to include whatever HTML you want.

=head2 Add dynamic content (such as page title) to the autohandler

Use Mason's C<notes()> facility:

    $m->notes("key", "value");
    $m->notes("title", "Details for item $id");

Then, in the autohandler, do something like:

    <head>
        <title><% $m->notes("title") || "My Application" %></title>
    </head>


=head1 SEE ALSO

L<MasonX::MiniMVC>

=cut

1;
