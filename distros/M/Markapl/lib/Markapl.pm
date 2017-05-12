package Markapl;
use strict;
use warnings;
use Devel::Declare ();
use Sub::Install qw(install_sub);
use Markapl::Tags;
use Markapl::TagHandlers;
use String::BufferStack;
use HTML::Entities;

use 5.008;
our $VERSION = "0.14";

my $buffer;
sub buffer {
    $buffer = $_[1] if $_[1];
    $buffer ||= String::BufferStack->new( out_method => sub { join("", @_) });
}

sub template {
    my ($name, $code) = @_;
    my $caller = caller;
    install_sub({
        code => $code,
        into => $caller,
        as => $name
    });
}

sub outs_raw($) {
    my $str = shift;
    Markapl->buffer->append( $str );
    return '';
}

sub outs($) {
    my $str = shift;
    outs_raw encode_entities($str, '<>&"');
}

sub render {
    my ($self, $template, @vars) = @_;

    if (my $sub = $self->can($template)) {
        Markapl->buffer->push;
        $sub->($self, @vars);
        my $buf = Markapl->buffer->pop;
        Markapl->buffer->flush_output;
        return $buf
    } else {
        require Carp;
        Carp::croak( "no such template: $template in $self" );
    }
}

sub set {
    my ($self, $name, $value) = @_;

    if ($self->can("stash")) {
        $self->stash->{$name} = $value;
    }
    elsif ((my $caller = caller)->can("stash")) {
        $caller->stash->{$name} = $value;
    }
}

sub get {
    my ($self, $name) = @_;
    if (defined($name) && $self->can("stash")) {
        return $self->stash->{$name} || ""
    }
    $name = $self, $self = caller;
    $self->get($name);
}

sub import {
    my ($class) = @_;
    my $caller = caller;

    for my $name (qw(render outs outs_raw template get set)) {
        install_sub({
            code => $name,
            into => $caller,
        });
    }

    my $config = {};
    my $code_str = qq{package $caller; my \$stash = {}; sub stash { \$stash } };

    for my $tag ( Markapl::Tags->html() ) {
        $code_str .= qq{sub $tag (&);};
        $config->{$tag} = {
            const => Markapl::TagHandlers::tag_parser_for($tag)
        }
    }

    eval $code_str;

    Devel::Declare->setup_for($caller, $config);
}

1;
__END__

=head1 NAME

Markapl - Markup as Perl

=head1 VERSION

This document describes Markapl version 0.08

=head1 SYNOPSIS

    package MyView;
    use Markapl;

    template '/a/page.html' => sub {
        h1("#title") { "Hi" };
        p(".first") { "In the begining, lorem ipsum...." };
        p(style => "color: red;") { "But...." };
    }

    package main;
    my $output = MyView->render("/a/page.html");

=head1 TUTORIAL

Here's a short guide how to use this module. You can skip this
tutorial section if you're already using L<Template::Declare>, since
it's exactly the same.

First of all, you need a sole package for defining your templates,
let's call it "MyView" in the example.  Then you C<use Markapl> (but
not use base), which installs many helper subroutines into your
"MyView" package for declaring and rendering templates:


    package MyView;
    use Markapl;

To define a template, use C<template> function like this:

    template '/page.html' => sub {
        h1("#title") { "Hi" };
        p(".first") { "In the begining, lorem ipsum...." };
        p(style => "color: red;") { "But...." };
    }

To render it, call C<render> function:

    my $out = MyView->render("/page.html");

Besides these two functions, C<Markapl> also exports about another 120
tag functions that are named after HTML tags, for exapmle, h1, h2, h3,
div, p, and span. Almost all HTML tags are defined as a function.

In your template, if you say:

    h1 { "Hi" };

It'll be rendered as:

    <h1>Hi</h1>

The block after C<h1> is an anonymous sub-routine, and the return
value of which will become the content of the C<h1> tag.

If you want to add attributes to the tag, do it like this:

    div(id => "example", class => "lipsum") { "Lorem ipsum" };

Alternatively, you can use CSS selector syntax to quickly defined
id and class attribute:

    div("#example") { "Lorem ipsum" };

That only works when the attribute list contain exactly one string inside.

A special function C<outs> need to be used to concatenate strings with
inline elements:

    p {
        outs "Hello, ";
        a(href => "/users/gugod") { "gugod" };
    }

=head1 DESCRIPTION

This is a new try to use L<Devel::Declare> to change the Perl5
language. It learns pretty much everything from L<Template::Declare>,
and has similar interface. With only one difference: how element
attributes are defined.

In L<Template::Declare>, it goes like:

    h1 {
        id is "title";
        outs "Hi";
    };

In here, it is:

    h1(id => "title") { "Hi" };

Or a shorthand for "id" attribute:

    h1("#title") { "Hi" };

However, there are conflict between HTML tag names and perl builtin function /
ops, and the behaviour of which cannot (and better not) be altered by Markapl:

    link map q s sub tr

To generate markup with these tags, and C<"html_"> prefix to them, for instance:

    html_q { "I a quotation, but this tag is not supported by IE." }

It'll produce:

    <q>I a quotation, but this tag is not supported by IE.</q>

For tables, since there's absolutely no way to clobber "tr" in Perl
AFAIK (not without using source filter,) tr and td are both renamed
to row and cell, correspondly:

    table {
      row {
        cell { "gugod" };
        cell { "170cm" };
        cell { "100kg" };
      }
    }

It actually makes more sense. This idea is borrowed from
L<Template::Declare>

Several helper methods are defined in L<Markapl::Helpers>. Read the
documentation there too.

Smoe HTML5 tags allow value-less attributes like:

    <script async src="foo.js"></script>

To generate those, pass <undef> as the attribute value:

    script(src => "foo.js", async => undef);

=head1 INTERFACE 

=over

=item template($name, $code);

Defines a template.

=item render($name)

You need to call it as class method like,

   MyView->render("/foo.html");

Or

   render MyView, "/foo.html";

If you happen to like this style.

Doesn't support template variables yet. Stay tuned.

=item outs($str);

Should only be used inside a template body. It appends C<$str> to
current output buffer frame.

=item set($name, $value)

Store a value under given name in your view package stash. Should be used
as a class method like:

    MyView->set(title => "Greeting");

Think of it is assigning values to global template variables. C<$name>
must be a string and C<$value> can be any scalar. It could be a
reference to other structured data.

=item get($name)

Retriving a named value from the view package stash. This should only
be used in template as a function call, like:

    template 'index.html' => sub {
        h1 { get("title") }
    }

If you call it as a class method, it will still work:

    MyView->get("title")

=back

=head1 DEPENDENCIES

C<Devel::Declare>

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-markapl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, 2009, 2010, 2011, 2012 Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
