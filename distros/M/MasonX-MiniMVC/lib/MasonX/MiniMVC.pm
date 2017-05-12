package MasonX::MiniMVC;

use warnings;
use strict;

=head1 NAME

MasonX::MiniMVC - Very simple MVC framework for HTML::Mason

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    # in your dhandler
    use MasonX::MiniMVC::Dispatcher;
    my $dispatcher = MasonX::MiniMVC::Dispatcher->new(\%controllers);
    $dispatcher->dispatch($m);

=head1 DESCRIPTION

The problem with Mason is that it's just way too tempting to include
application logic in your components.  It's hard, too, to figure out how
to lay out an application.  What do you put where?  How do you make
something that's not a horrible spaghetti tangle?

MasonX::MiniMVC is meant to solve most of these problems for simple
applications.  It's essentially the simplest thing I could come up with
that looks like MVC and stops your Mason components from becoming an
unmanageable pile of cruft.

=head2 Features

=over 4

=item *

A basic directory layout, showing you where to put stuff to keep it
under control.

=item *

Attractive, clean URLs in the form
http://example.com/foo/bar/baz. This hides implementation details (*.mhtml
filenames) and makes the URLs more search-engine (and human) friendly
than http://example.com/foo/bar.mhtml?id=baz.

=item *

Sample (albeit very slim) controller and model classes are provided.

=item *

Views are simple Mason components.

=back

=head1 Non-features

MasonX::MiniMVC isn't a full-blown MVC framework.  If you're looking for
something heavyweight, try Catalyst.

MiniMVC also makes some Mason behaviours difficult or impossible.  (Most
specifically, you just get one top-level autohandler.)

=head1 USING MINIMVC

=head2 Installation

First, install MasonX::MiniMVC.  I'll assume you've done that.  

Then C<cd> into the directory where you want your application to be --
probably your webserver's document root -- and run C<minimvc-install
MyApp>, replacing "MyApp" with the name of your own application.  Since
it'll be used as part of Perl module names, it needs to match C<^\w+$>.

This will create a basic layout for your app.  You should see output
something like this:

    Creating directory structure...
      lib/
      lib/MyApp/
      lib/MyApp/Controller/
      lib/MyApp/Model/
      t/
      view/
      view/sample/
    Creating stub/sample files...
      dhandler
      autohandler
      index.mhtml
      lib/MyApp/Dispatcher.pm
      lib/MyApp/Controller/Sample.pm
      lib/MyApp/Model/Sample.pm
      t/controller_sample.t
      t/model_sample.t
      view/default.mhtml
      view/sample/default.mhtml
      .htaccess
      view/.htaccess
      lib/.htaccess
      t/.htaccess

=head2 Further setup

=over 4

=item *

Set up Apache to handle the directory using HTML::Mason.  The provided
.htaccess file contains a "SetHandler" directive, but you might need to
provide an "AddHandler" in your httpd.conf.

=item *

Add library paths to the dhandler.  Currently there's an empty C<use
lib>, but you probably need to add the path to your MiniMVC lib
directory, i.e. C</some/directory/your-website/lib>.

=back

If everything's set up right, you should now be able to point a browser
at your application and see a stub/welcome page, with a link to a sample
controller-generated page.

=head1 APPLICATION DEVELOPMENT WITH MINIMVC

To build your application, the steps will be:

=over 4

=item 1.

Create model code in lib/MyApp/Model/, using Class::DBI, DBIx::Class, or
whatever other kind of ORM you like to use.  This will connect to your
database and provide an OO representation of the data.

=item 2.

Create a structure for your website, mapping URLs to controllers.  Edit
C<MyApp::Dispatcher> to create these mappings.  Typically you will create a
controller for each "noun", eg. users, posts, comments, or whatever is
appropriate to your site.

Here's an example taken from the example "library" application that
comes with the MiniMVC distribution:

    package Library::Dispatcher;

    use base MasonX::MiniMVC::Dispatcher;

    sub new {
        my ($class) = @_;
        my $self = $class->SUPER::new({
            'author'              => 'Library::Controller::Author',
            'book'                => 'Library::Controller::Book',
            'book/recommendation' => 'Library::Controller::Book::Recommendation',
        });
    }

    1;

=item 3.

Create controller classes for each item you listed in C<dhandler>.  Just
copy C<MyApp/Controller/Sample.pm> and edit appropriately.  Each
controller must have at least a C<default()> method, used to show the
"top level" page for that part of the site.

Here's an example C<default()> method:

    sub default {
        my ($self, $m, @args) = @_;
        $m->comp("view/book/default.mhtml");
    }


=item 4.

Add methods as you see fit.  For instance, you might have a C<Post.pm>
and create methods such as C<new()>, C<edit()>, C<view()>, etc.  A
HTTP request to http://example.com/post/new will call
C<MyApp::Post::new()>.  A request to http://example.com/post/view/42
will call C<MyApp::Post::view()> with 42 passed in as an argument.

Here's an example of a method that fetches data using the Model
classes, and displays the details:

    sub view {
        my ($self, $m, $id) = @_;
        my $book = Library::Model::Book->fetch($id);
        $m->comp("view/book/view.mhtml", book => $book);
    }

=item 5.

As you've seen in the previous steps, the webpage output is done through
a view file.  These live in C<view/>, and are displayed by calling
C<<$m->comp($view)>> from within the controller code.
You can pass args through C<<$m->comp()>> and they'll be accessible via
the Mason <%args> section in the view.

Using the above example, your book view might look like this:

    <%args>
    $book
    </%args>

    <h1><% $book->title %></h1>
    <p>
    Author: <% $book->author->name() %>
    </p>

=back

A fairly detailed sample application can be found in
C<examples/library/>, in the MiniMVC CPAN distribution.

For more examples, see L<MasonX::MiniMVC::Cookbook>.

=head1 AUTHOR

Kirrily "Skud" Robert, C<< <skud at cpan.org> >>

=head1 BUGS

The following are unimplemented or simply known not to work.  It's early
days yet.  Comments welcome, though.

=head2 autohandlers below the top level

You get one top-level autohandler for your app.  You can't have any
below that.

=head2 404s

I've got it doing a C<<$m->clear_and_abort(404)>> if it can't find a
controller for a URL, but it doesn't work for me under
HTML::Mason::CGIHandler.  Don't know whether or not it works under
full-blown mod_perl Mason, though.  Help wanted!

=head2 Other

Please report any bugs or feature requests to
C<bug-masonx-minimvc at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MasonX-MiniMVC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MasonX::MiniMVC

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MasonX-MiniMVC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MasonX-MiniMVC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MasonX-MiniMVC>

=item * Search CPAN

L<http://search.cpan.org/dist/MasonX-MiniMVC>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to:

Paul Fenwick for the autohandler hack to support notes().

=head1 COPYRIGHT & LICENSE

Copyright 2007 Kirrily "Skud" Robert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of MasonX::MiniMVC
