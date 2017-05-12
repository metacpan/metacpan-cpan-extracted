#
# This file is part of HTML-Builder
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package HTML::Builder;
{
  $HTML::Builder::VERSION = '0.008';
}

# ABSTRACT: A declarative approach to HTML generation

use v5.10;

use strict;
use warnings;

use Capture::Tiny 0.15 'capture_stdout';
use HTML::Tiny;
use Sub::Install;
use List::MoreUtils 'uniq';

# debugging...
#use Smart::Comments;

our $IN_TAG;


# HTML5 tags from:
# http://en.wikipedia.org/wiki/HTML5#Differences_from_HTML.C2.A04.01_and_XHTML.C2.A01.x
# 18 Feb 2012
#
# Other HTML tags from:
# http://www.w3schools.com/tags/default.asp
# 19 Feb 2012


# !--...--	Defines

sub html5_tags { qw{

    article aside audio bdo canvas command datalist details embed figcaption
    figure footer header hgroup keygen mark meter nav output progress rp rt
    ruby section source summary time video wbr

} }


sub html5_minimal_tags { q{ article aside footer header nav } }

# excl: s
sub deprecated_tags { qw{ applet basefont center dir font menu strike u xmp } }
sub depreciated_tags { deprecated_tags() }


sub conflicting_tags { {
    html_sub => 'sub',
    html_map => 'map',
    html_q   => 'q',
    html_tr  => 'tr',
} }

sub html_tags {

    # excl: sub map q tr

    return qw{

        a        abbr       acronym    address      area       b
        base     bdo        big        blockquote   body       br
        button   caption    cite       code         col        colgroup
        dd       del        dfn        div          dl         dt
        em       fieldset   form       frame        frameset   h1
        head     hr         html       i            iframe     img
        input    ins        kbd        label        legend     li
        link                meta       noframes     noscript   object
        ol       optgroup   option     p            param      pre
                 samp       script     select       small      span
                 strong     style                   sup        table
        tbody    td         textarea   tfoot        th         thead
        title               tt         ul           var

    };
}


sub form_tags { qw{

    form fieldset button input label optgroup option select textarea

}}


sub table_tags { qw{ table tr td th thead tbody tfoot } }


sub minimal_tags {
    return ('h1'..'h5', qw{
        div span p img script br ul ol li style a
    });
}


sub our_tags {
    my @tags = (
        html5_tags(),
        html_tags(),
        deprecated_tags(),
        (keys %{ conflicting_tags() }),
    );
    return uniq sort @tags;
}


sub _attr { die }

sub attr(&) {
    my $code = shift;

    ### in attr...
    _attr($code->());
}

sub _is_autoload_gen {
    my ($attr_href) = @_;

    return sub {
        shift;

        my $field = our $AUTOLOAD;
        $field =~ s/.*:://;

        # XXX
        $field =~ s/__/:/g;   # xml__lang  is 'foo' ====> xml:lang="foo"
        $field =~ s/_/-/g;    # http_equiv is 'bar' ====> http-equiv="bar"

        # Squash empty values, but not '0' values
        my $val = join ' ', grep { defined $_ && $_ ne '' } @_;

        #push @$attr_aref, $field => $val;
        $attr_href->{$field} = $val;

        return;
    };
}

sub _attr_gen {
    my ($attr_href) = @_;

    return sub {

        my %attrs = @_;
        ### %attrs
        @{$attr_href}{keys %attrs} = (values %attrs);

        return;
    };
}

sub tag($&) {
    my ($tag, $inner_coderef) = @_;

    state $h = HTML::Tiny->new;

    ### @_
    my %attrs = ();

    # This is almost completely stolen from Template::Declare::Tags, and
    # completely terrifying in that it confirms my dark suspicions on how
    # it was achieved over there.
    no warnings 'once', 'redefine';
    local *gets::AUTOLOAD = _is_autoload_gen(\%attrs);
    local *_attr = _attr_gen(\%attrs);
    my $inner = q{};
    my $stdout = capture_stdout { local $IN_TAG = 1; $inner .= $inner_coderef->() || q{} };

    my $return = $h->tag($tag, \%attrs, "$stdout$inner");

    ### $return
    if ($IN_TAG) {
        print $return;
        return q{};
    }
    else {
        return $return;
    }
}

use Sub::Exporter -setup => {

    exports => [ our_tags, 'attr', 'tag' ],
    groups  => {

        default     => ':minimal',

        minimal       => sub { _generate_group([       minimal_tags ], @_) },
        html5         => sub { _generate_group([         html5_tags ], @_) },
        html5_minimal => sub { _generate_group([ html5_minimal_tags ], @_) },
        deprecated    => sub { _generate_group([    deprecated_tags ], @_) },
        depreciated   => sub { _generate_group([    deprecated_tags ], @_) },
        table         => sub { _generate_group([         table_tags ], @_) },
        form          => sub { _generate_group([          form_tags ], @_) },
        header        => sub { _generate_group([qw{ header hgroup } ], @_) },
    },
};

sub _generate_group {
    my ($tags, $class, $group, $arg) = @_;

    return {
        attr => \&attr,
        map { my $tag = $_; $tag => sub(&) { unshift @_, $tag; goto \&tag } }
        @$tags
    };
}

{
    my $_install = sub {
        my ($subname, $tag) = @_;
        $tag ||= $subname;
        Sub::Install::install_sub({
            code => sub(&) { unshift @_, $tag; goto \&tag },
            as   => $tag,
        });
    };

    my $conflict = conflicting_tags;
    $_install->($_)  for our_tags;
    $_install->(@$_) for map { [ $_ => $conflict->{$_} ] } keys %$conflict;
}

!!42;

__END__

=pod

=encoding utf-8

=for :stopwords Chris Weyl Wikipedia

=head1 NAME

HTML::Builder - A declarative approach to HTML generation

=head1 VERSION

This document describes version 0.008 of HTML::Builder - released December 02, 2012 as part of HTML-Builder.

=head1 SYNOPSIS

    use HTML::Builder ':minimal';

    # $html is: <div id="main"><p>Something, huh?</p></div>
    my $html = div { id gets 'main'; p { 'Something, huh?' } };

=head1 DESCRIPTION

A quick and dirty set of helper functions to make generating small bits of
HTML a little less tedious.

=head1 FUNCTIONS

=head2 our_tags

A unique, sorted list of the HTML tags we know about (and handle).

=head2 tag($tag_name, $code_ref)

The actual function responsible for handling the tagging.  All of the helper
functions pass off to tag() (e.g. C<div()> is C<sub div(&) { unshift 'div';
goto \&tag }>).

=head2 html5_tags()

The list of tags we think are HTML5.

=head2 html_tags()

The list of tags we think are HTML ( < HTML5, that is).

=head2 deprecated_tags()

HTML elements considered to be deprecated.

=head2 our_tags()

The unique, sorted list of all tags returned by html5_tags() and html_tags().

=head2 html5_minimal_tags()

A minimal subset of HTML5 tags as returned by html5_tags():

    article aside footer header nav

=head2 conflicting_tags

Returns a HashRef of tags that conflict with Perl builtins: our named exports
for the tags are the keys; the tags themselves are the values.

=head2 form_tags

A list of tags related to forms, that will belong to the C<:form> group.

=head2 table_tags

A list of tags related to tables, that will belong to the C<:table> group.

=head2 minimal_tags

A list of tags we consider a "minimal" set.  These will belong to the
C<:minimal> group.

=head2 our_tags

The set of all the tags we know of.

=head2 attr(&)

An alternative to using C<gets> (or instances where it won't work, e.g. C<for
gets 'name'>).  Takes a coderef, expects that coderef to return a list of
attribute => value pairs, e.g.

    div {
        attr {
            id  => 'one',
            bip => 'two',
        };
    };

=for Pod::Coverage depreciated_tags

=head1 USAGE

Each supported HTML tag takes a coderef, executes it, and returns the output
the coderef writes to STDOUT with the return value appended.

That is:

    div { say h1 { 'Hi there! }; p { "Nice day, isn't it?" } }

Generates:

    <div><h1>Hi there!</h1><p>Nice day, isn't it?</p></div>

Element attributes are handled by specifying them with C<gets>.  e.g.:

    div { id gets 'main'; 'Hi!' }

Generates:

    <div id="main">Hi!</div>

L<gets> may be specified multiple times, for multiple attributes.

=head2 Nested Tags

When one tag function is called from within another, the nested tag will print
its output to STDOUT rather than returning it.  That means that this:

    div { print h1 { 'Hi there! }; p { "Nice day, isn't it?" } }

...and this:

    div { h1 { 'Hi there! }; p { "Nice day, isn't it?" } }

Behave identically, from the perspective of the caller.

=head1 RENAMING EXPORTED FUNCTIONS

This package uses L<Sub::Exporter>, so you can take advantage of the features
that package provides.  For example, if you wanted to import the tags in the
'minimal' group, but wanted to prefix each function with 'html_', you could
do:

    use HTML::Builder -minimal => { -prefix => 'html_' };

=head1 EXPORTED FUNCTIONS

Each tag we handle is capable of being exported, and called with a coderef.
This coderef is executed, and the return is wrapped in the tag.  Attributes on
the tag can be set from within the coderef by using L<gets>, a la C<id gets
'foo'>.

By default we export the C<:minimal> group.

=head2 Export Groups

=head3 :all

Everything not conflicting with Perl builtins.

This isn't an optimal group to use as-is -- it will cause a ton of functions
to be imported, including some that will conflict with several Perl builtins.
If you use this group, you are highly encouraged to supply a prefix for it,
like:

    use HTML::Builder -all => { -prefix => 'html_' };

=head3 :minimal

A basic set of the most commonly used tags:

    h1..h4 div p img span script br ul ol li style a

=head3 :html5

HTML5 tags (C<article>, C<header>, C<nav>, etc) -- or at least what Wikipedia
thinks are HTML5 tags.

=head3 :table

The table tags:

    table thead tbody tfoot tr th td

As C<tr> would conflict with a Perl builtin, it is recommended that this group
be imported with a prefix ('table_' would seem to suggest itself).

=head3 :header

Header tags:

    header hgroup

=head3 :form

Form tags:

    form fieldset button input label optgroup option select textarea

=head1 ACKNOWLEDGMENTS

This package was inspired by L<Template::Declare::Tags>... In particular, our
C<gets::AUTOLOAD> is pretty much a straight-up copy of Template::Declare::Tags'
C<is::AUTOLOAD>, with some modifications.  We also pass off to L<HTML::Tiny>,
and allow it to do the work of actually generating the output.  Thanks! :)

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<HTML::Tiny>

=item *

L<Template::Declare::Tags>

=item *

L<HTML::HTML5::Builder>

=back

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 CONTRIBUTOR

Olaf Alders <olaf@wundersolutions.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
