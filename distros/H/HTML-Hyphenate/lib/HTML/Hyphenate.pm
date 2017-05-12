package HTML::Hyphenate;    # -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;

# $Id: Hyphenate.pm 387 2010-12-21 19:41:17Z roland $
# $Revision: 387 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/lib/HTML/Hyphenate.pm $
# $Date: 2010-12-21 20:41:17 +0100 (Tue, 21 Dec 2010) $

use 5.006000;
use utf8;
use charnames qw(:full);

our $VERSION = '0.05';

use Log::Log4perl qw(:easy get_logger);
use Set::Scalar;
use TeX::Hyphen;
use TeX::Hyphen::Pattern;
use HTML::Entities;
use HTML::TreeBuilder;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY              => q{};
Readonly::Scalar my $HYPHEN             => q{-};
Readonly::Scalar my $SOFT_HYPHEN        => qq{\N{SOFT HYPHEN}};
Readonly::Scalar my $ONE_LEVEL_UP       => -1;
Readonly::Scalar my $DEFAULT_MIN_LENGTH => 10;
Readonly::Scalar my $DEFAULT_MIN_PRE    => 2;
Readonly::Scalar my $DEFAULT_MIN_POST   => 2;
Readonly::Scalar my $DEFAULT_LANG       => q{en_us};

Readonly::Scalar my $HTML_ESCAPE      => undef;
Readonly::Scalar my $DEFAULT_INCLUDED => 1;
Readonly::Scalar my $DEFAULT_XML      => 1;

Readonly::Scalar my $LANG   => q{lang};
Readonly::Scalar my $TEXT   => q{text};
Readonly::Scalar my $NOBR   => q{nobr};
Readonly::Scalar my $PRE    => q{pre};
Readonly::Scalar my $NOWRAP => q{nowrap};
Readonly::Scalar my $STYLE  => q{style};
Readonly::Scalar my $CLASS  => q{class};

Readonly::Scalar my $LOG_TRAVERSE      => q{Traversing HTML element '%s'};
Readonly::Scalar my $LOG_LANGUAGE_SET  => q{Language changed to '%s'};
Readonly::Scalar my $LOG_PATTERN_FILE  => q{Using pattern file '%s'};
Readonly::Scalar my $LOG_TEXT_NODE     => q{Text node value '%s'};
Readonly::Scalar my $LOG_HYPHEN_TEXT   => q{Hyphenating text '%s'};
Readonly::Scalar my $LOG_HYPHEN_WORD   => q{Hyphenating word '%s' to '%s'};
Readonly::Scalar my $LOG_LOOKING_UP    => q{Looking up for %d class(es)};
Readonly::Scalar my $LOG_HTML_METHOD   => q{Using HTML passed to method '%s'};
Readonly::Scalar my $LOG_HTML_PROPERTY => q{Using HTML property '%s'};
Readonly::Scalar my $LOG_HTML_UNDEF    => q{HTML to hyphenate is undefined};
Readonly::Scalar my $LOG_NOT_HYPHEN    => q{No pattern found for '%s'};
## use critic

my $ANYTHING = qr/.*/xsm;

# HTML %Text attributes <http://www.w3.org/TR/REC-html40/index/attributes.html>
my $text_attr = Set::Scalar->new(qw/abbr alt label standby summary title/);

# Strip document root tags from a fragment added by HTML::TreeBuilder:
my $ROOT = qr{ ^<html>(?:<head></head>)??<body>(.*)</body></html>\s*$ }ixsm;

# Match inline style requesting not to wrap anyway:
my $STYLE_NOWRAP = qr/\bwhite-space\s*:\s*nowrap\b/xsm;

Log::Log4perl->easy_init($ERROR);
my $log = get_logger();

use Class::Meta::Express qw(class ctor has meta method);
use HTML::Hyphenate::TypeDef;

class {

    meta 'html-hyphenate';

    ctor 'new';

    has html             => ( is => 'string' );
    has style            => ( is => 'string' );
    has min_length       => ( is => 'integer', default => $DEFAULT_MIN_LENGTH );
    has min_pre          => ( is => 'integer', default => $DEFAULT_MIN_PRE );
    has min_post         => ( is => 'integer', default => $DEFAULT_MIN_POST );
    has output_xml       => ( is => 'integer', default => $DEFAULT_XML );
    has default_lang     => ( is => 'string', default => $DEFAULT_LANG );
    has default_included => ( is => 'integer', default => $DEFAULT_INCLUDED );
    has classes_included => ( is => 'arrayref', default => [] );
    has classes_excluded => ( is => 'arrayref', default => [] );

    has _hyphenators => ( is => 'hashref', default => {}, view => 'PRIVATE' );
    has _lang => ( is => 'string', view => 'PRIVATE' );
    has _tree => ( is => 'tree',   view => 'PRIVATE' );

    method hyphenated => \&__hyphenated;

    method _traverse_html => (
        code => \&__traverse_html,
        view => 'PRIVATE',
    );

    method _clean_html => (
        code => \&__clean_html,
        view => 'PRIVATE',
    );

    method _hyphen => (
        code => \&__hyphen,
        view => 'PRIVATE',
    );

    method _hyphen_word => (
        code => \&__hyphen_word,
        view => 'PRIVATE',
    );

    method _configure_lang => (
        code => \&__configure_lang,
        view => 'PRIVATE',
    );

    method _add_tex_hyphen_to_cache => (
        code => \&__add_tex_hyphen_to_cache,
        view => 'PRIVATE',
    );

    method _hyphenable_by_class => (
        code => \&__hyphenable_by_class,
        view => 'PRIVATE',
    );

    method _hyphenable => (
        code => \&__hyphenable,
        view => 'PRIVATE',
    );

    method _get_nearest_ancestor_level_by_classname => (
        code => \&__get_nearest_ancestor_level_by_classname,
        view => 'PRIVATE',
    );

    method _reset_tree => (
        code => \&__reset_tree,
        view => 'PRIVATE',
    );

};

sub __hyphenated {
    my ( $self, $html ) = @_;
    if ( defined $html ) {
        $log->debug( sprintf $LOG_HTML_METHOD, $html );
        $self->html($html);
    }
    else {
        $log->debug( sprintf $LOG_HTML_PROPERTY, $self->html );
    }
    if ( defined $self->html ) {
        $self->_traverse_html();
        return $self->_clean_html();
    }
    $log->warn($LOG_HTML_UNDEF);
    return;
}

sub __traverse_html {
    my ($self) = @_;
    $self->_reset_tree;
    $self->_tree->parse_content( $self->html );
    $self->_tree->objectify_text();
    $self->_tree->traverse(
        [
            sub {
                my $element = $_[0];
                $log->debug( sprintf $LOG_TRAVERSE, $element->tag() );
                $self->_configure_lang($element);
                if ( $element->attr($TEXT) ) {
                    if ( $self->_hyphenable($element) ) {
                        $log->debug( sprintf $LOG_TEXT_NODE,
                            $element->attr($TEXT) );
                        $element->attr( $TEXT,
                            $self->_hyphen( $element->attr($TEXT) ) );
                    }
                }
                else {
                    foreach my $attr ( $element->all_external_attr_names() ) {
                        if ( $text_attr->has($attr) ) {
                            $element->attr( $attr,
                                $self->_hyphen( $element->attr($attr) ) );
                        }
                    }
                }
                ## no critic qw(RequireExplicitInclusion ProhibitCallsToUnexportedSubs)
                return HTML::Element::OK;
                ## use critic
            },
            undef
        ]
    );
    return;
}

sub __clean_html {
    my ($self) = @_;
    $self->_tree->deobjectify_text();
    my $html =
        $self->output_xml
      ? $self->_tree->as_XML()
      : $self->_tree->as_HTML( $HTML_ESCAPE, $EMPTY, {} );
    $self->_reset_tree;
    $html =~ s/$ROOT/$1/xgism;
    return $html;
}

sub __hyphen {
    my ( $self, $text ) = @_;
    $log->debug( sprintf $LOG_HYPHEN_TEXT, $text );
    $text =~ s/(\w{@{[$self->min_length]},})/$self->_hyphen_word($1)/xsmeg;
    return $text;
}

sub __hyphen_word {
    my ( $self, $word ) = @_;
    if ( defined $self->_hyphenators->{ $self->_lang } ) {
        $log->debug( sprintf $LOG_HYPHEN_WORD,
            $word, $self->_hyphenators->{ $self->_lang }->visualize($word) );
        my $number = 0;
        foreach
          my $pos ( $self->_hyphenators->{ $self->_lang }->hyphenate($word) )
        {
            substr $word, $pos + $number, 0, $SOFT_HYPHEN;
            $number += length $SOFT_HYPHEN;
        }
    }
    else {
        $log->warn( sprintf $LOG_NOT_HYPHEN, $self->_lang );
    }
    return $word;
}

sub __configure_lang {
    my ( $self, $element ) = @_;
    my $lang = $element->attr_get_i($LANG);
    $lang ||= $element->attr_get_i(qq{xml:$LANG});
    my %hyphen_opts = (
        leftmin  => $self->min_pre,
        rightmin => $self->min_post,
    );
    defined $self->style
      && ( $hyphen_opts{style} = $self->style );
    defined $lang || ( $lang = $self->default_lang );
    if ( !defined $self->_lang || $lang ne $self->_lang ) {
        $self->_lang($lang);
        $log->debug( sprintf $LOG_LANGUAGE_SET, $lang );
        if ( !exists $self->_hyphenators->{$lang} ) {
            $self->_add_tex_hyphen_to_cache();
        }
    }
    return;
}

sub __add_tex_hyphen_to_cache {
    my ($self) = @_;
    my $thp = TeX::Hyphen::Pattern->new();
    $thp->label( $self->_lang );
    my $cache = $self->_hyphenators;
    if ( my $file = $thp->filename ) {
        $log->debug( sprintf $LOG_PATTERN_FILE, $file );
        ${$cache}{ $self->_lang } = TeX::Hyphen->new(
            file     => $file,
            leftmin  => $self->min_pre,
            rightmin => $self->min_post,
        );
        $self->_hyphenators($cache);
    }
    return;
}

sub __hyphenable_by_class {
    my ( $self, $element ) = @_;
    my $included_level = $ONE_LEVEL_UP;
    my $excluded_level = $ONE_LEVEL_UP;
    $self->default_included && $excluded_level--;
    $self->default_included || $included_level--;

    $included_level =
      $self->_get_nearest_ancestor_level_by_classname( $element,
        $self->classes_included, $included_level );
    $excluded_level =
      $self->_get_nearest_ancestor_level_by_classname( $element,
        $self->classes_excluded, $excluded_level );
    return !( $excluded_level > $included_level );
}

sub __hyphenable {
    my ( $self, $element ) = @_;
    return !( $element->is_inside($NOBR)
        || $element->is_inside($PRE)
        || $element->look_up( $NOWRAP, $ANYTHING )
        || $element->look_up( $STYLE,  $STYLE_NOWRAP )
        || !$self->_hyphenable_by_class($element) );
}

sub __get_nearest_ancestor_level_by_classname {
    my ( $self, $element, $ar_classnames, $level ) = @_;
    my $classnames = Set::Scalar->new( @{$ar_classnames} );
    $log->debug( sprintf $LOG_LOOKING_UP, $classnames->size );

    # Only looking up the tree if there is something to look for:
    if (
        $classnames
        && (
            my $container = $element->look_up(
                $CLASS => $ANYTHING,
                sub {
                    $_[0]
                      && $classnames->has( $_[0]->attr($CLASS) );
                }
            )
        )
      )
    {
        $level = $container->depth;
    }
    return $level;

}

sub __reset_tree {
    my ($self) = @_;
    $self->_tree && $self->_tree( $self->_tree->delete );
    my $tree = HTML::TreeBuilder->new();
    $tree->warn(1);
    $tree->store_pis(1);
    $self->_tree($tree);
    return;
}


1;

__END__

=encoding utf8

=for stopwords Ipenburg Readonly

=head1 NAME

HTML::Hyphenate - class for inserting soft hyphens into HTML.

=head1 VERSION

This is version 0.05.

=head1 SYNOPSIS

    use HTML::Hyphenate;

    $hyphenator = new HTML::Hyphenate();
    $html_with_soft_hyphens = $hyphenator->hyphenated($html);

    $hyphenator->html($html);
    $hyphenator->style($style); # czech or german

    $hyphenator->min_length(10);
    $hyphenator->min_pre(2);
    $hyphenator->min_post(2);
    $hyphenator->output_xml(1);
    $hyphenator->default_lang('en-us');
    $hyphenator->default_included(1);
    $hyphenator->classes_included(['shy']);
    $hyphenator->classes_excluded(['noshy']);

=head1 DESCRIPTION

Most HTML rendering engines used in web browsers don't figure out by
themselves how to hyphenate words when needed, but we can tell them how they
might do it by inserting soft hyphens into the words.

=head1 SUBROUTINES/METHODS

=over 4

=item HTML::Hyphenate-E<gt>new()

Constructs a new HTML::Hyphenate object.

=item $hyphenator-E<gt>hyphenated()

Returns the HTML including the soft hyphens.

=item $hyphenator->html();

Gets or sets the HTML to hyphenate.

=item $hyphenator->style();

Gets or sets the style to use for pattern usages in
L<TeX::Hyphen|TeX::Hyphen>. Can be C<czech> or C<german>.

=item $hyphenator->min_length();

Gets or sets the minimum word length required for having soft hyphens
inserted. Defaults to 10 characters.

=item $hyphenator->min_pre(2);

Gets or sets the minimum amount of characters in a word preserved before the
first soft hyphen. Defaults to 2 characters.

=item $hyphenator->min_post(2);

Gets or sets the minimum amount of characters in a word preserved after the
last soft hyphen. Defaults to 2 characters.

=item $hyphenator->output_xml(1);

Have L<HTML::TreeBuilder|HTML::TreeBuilder> output HTML in HTML or XML mode. 

=item $hyphenator->default_lang('en-us');

Gets or sets the default pattern to use when no language can be derived from
the HTML.

=item $hyphenator->default_included();

Gets or sets if soft hyphens should be included in the whole tree by default.
This can be used to insert soft hyphens only in parts of the HTML having
specific class names.

=item $hyphenator->classes_included();

Gets or sets a reference to an array of class names that will have soft
hyphens inserted.

=item $hyphenator->classes_excluded();

Gets or sets a reference to an array of class names that will not have soft
hyphens inserted.

=back

=head1 DEPENDENCIES

L<Class::Meta::Express|Class::Meta::Express>
L<Class::Meta::Type|Class::Meta::Type>
L<HTML::Entities|HTML::Entities>
L<HTML::Hyphenate::TypeDef|HTML::Hyphenate::TypeDef>
L<HTML::TreeBuilder|HTML::TreeBuilder>
L<Log::Log4perl|Log::Log4perl>
L<Readonly|Readonly>
L<Set::Scalar|Set::Scalar>
L<TeX::Hyphen|TeX::Hyphen>
L<TeX::Hyphen::Pattern|TeX::Hyphen::Pattern>
L<Test::More|Test::More>
L<Test::NoWarnings|Test::NoWarnings>

=head1 INCOMPATIBILITIES

=over 4

This module has the same limits as TeX::Hyphen, TeX::Hyphen::Pattern and
HTML::TreeBuilder.

=back

=head1 DIAGNOSTICS

This module uses Log::Log4perl for logging.

=over 4

=item * It warns when a language encountered in the HTML is not supported by
TeX::Hyphen::Pattern

=back

=head1 BUGS AND LIMITATIONS

=over 4

=item * Empty subclass test fails, this is probably a Class::Meta::Express
issue. The empty subclass can't be empty, it needs at least:

    use Class::Meta::Express;

    class {
        ctor 'new';
    };

=item * Perfect hyphenation can be more complicated than just inserting a
hyphen somewhere in a word, and sometimes requires semantics to get it right.
For example C<cafeetje> should be hyphenated as C<cafe-tje> and not
C<cafee-tje> and C<buurtje> can be hyphenated as C<buur-tje> or C<buurt-je>,
depending on it's meaning. While HTML could provide a bit more context (mainly
the language being used) than plain text to handle these issues, the initial
purpose of this module is to make it possible for HTML rendering engines that
support soft hyphens to be able to break long words over multiple lines to
avoid unwanted overflow.

=item * The hyphenation doesn't get better than TeX::Hyphenate and it
hyphenation patterns provide.

=item * The round trip from HTML source via HTML::Tree to HTML source might
introduce changes to the source, for example accented characters might be
transformed to HTML encoded entity equivalent.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The output is generated by L<HTML::TreeBuilder|HTML::TreeBuilder> and can be
either HTML or XML.

=head1 AUTHOR

Roland van Ipenburg  C<< <ipenburg@xs4all.nl> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 by Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
