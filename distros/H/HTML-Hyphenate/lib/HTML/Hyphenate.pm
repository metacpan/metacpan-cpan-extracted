# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2009-2019, Roland van Ipenburg
package HTML::Hyphenate v1.1.2;
use Moose;
use utf8;
use 5.014000;

use charnames qw(:full);

use Log::Log4perl qw(:easy get_logger);
use Set::Scalar;
use TeX::Hyphen;
use TeX::Hyphen::Pattern 0.100;
use Mojo::DOM;

use Readonly;
## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $DOT          => q{.};
Readonly::Scalar my $SOFT_HYPHEN  => qq{\N{SOFT HYPHEN}};
Readonly::Scalar my $CLASS_JOINER => q{, .};                # for CSS classnames
Readonly::Scalar my $ONE_LEVEL_UP => -1;

Readonly::Hash my %DEFAULT => (
    'MIN_LENGTH' => 10,
    'MIN_PRE'    => 2,
    'MIN_POST'   => 2,
    'LANG'       => q{en_us},
    'INCLUDED'   => 1,
);

# HTML %Text attributes <http://www.w3.org/TR/REC-html40/index/attributes.html>
# HTML5 text attributes <https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes>
my $text_attr =
  Set::Scalar->new(qw/abbr alt label list placeholder standby summary title/);

## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Hash my %LOG => (
    'TRAVERSE'      => q{Traversing HTML element '%s'},
    'LANGUAGE_SET'  => q{Language changed to '%s'},
    'PATTERN_FILE'  => q{Using pattern file '%s'},
    'TEXT_NODE'     => q{Text node value '%s'},
    'HYPHEN_TEXT'   => q{Hyphenating text '%s'},
    'HYPHEN_WORD'   => q{Hyphenating word '%s' to '%s'},
    'LOOKING_UP'    => q{Looking up for %d class(es)},
    'HTML_METHOD'   => q{Using HTML passed to method '%s'},
    'HTML_PROPERTY' => q{Using HTML property '%s'},
    'HTML_UNDEF'    => q{HTML to hyphenate is undefined},
    'NO_LANG'       => q{No language defined for '%s'},
    'NOT_HYPHEN'    => q{No pattern found for '%s'},
    'REGISTER'      => q{Registering TeX::Hyphen object for label '%s'},
);
## use critic

Log::Log4perl->easy_init($ERROR);
my $log = get_logger();

## no critic qw(ProhibitHashBarewords ProhibitCallsToUnexportedSubs ProhibitCallsToUndeclaredSubs)
has html  => ( is => 'rw', isa => 'Str' );
has style => ( is => 'rw', isa => 'Str' );
has min_length =>
  ( is => 'rw', isa => 'Int', default => $DEFAULT{'MIN_LENGTH'} );
has min_pre  => ( is => 'rw', isa => 'Int', default => $DEFAULT{'MIN_PRE'} );
has min_post => ( is => 'rw', isa => 'Int', default => $DEFAULT{'MIN_POST'} );
has default_lang => ( is => 'rw', isa => 'Str', default => $DEFAULT{'LANG'} );
has default_included =>
  ( is => 'rw', isa => 'Int', default => $DEFAULT{'INCLUDED'} );
has classes_included =>
  ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has classes_excluded =>
  ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has _hyphenators => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has _lang        => ( is => 'rw', isa => 'Str' );
has _dom         => ( is => 'rw', isa => 'Mojo::DOM' );
## use critic

## no critic qw(ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $LANG  => q{lang};
Readonly::Scalar my $TEXT  => q{text};
Readonly::Scalar my $TAG   => q{tag};
Readonly::Scalar my $RAW   => q{raw};
Readonly::Scalar my $PRE   => q{pre};
Readonly::Scalar my $CLASS => q{class};
## use critic

sub hyphenated {
    my ( $self, $html ) = @_;
    if ( defined $html ) {
        $log->debug( sprintf $LOG{'HTML_METHOD'}, $html );
        $self->html($html);
    }
    else {
        $log->debug( sprintf $LOG{'HTML_PROPERTY'}, $self->html );
    }
    if ( defined $self->html ) {
        $self->_reset_dom;
        $self->_dom->parse( $self->html );
        $self->_traverse_dom( $self->_dom->root );
        return $self->_clean_html();
    }
    $log->warn( $LOG{'HTML_UNDEF'} );
    return;
}

sub register_tex_hyphen {
    my ( $self, $label, $tex ) = @_;
    if ( defined $label && $tex->isa('TeX::Hyphen') ) {
        my $cache = $self->_hyphenators;
        $log->debug( sprintf $LOG{'REGISTER'}, $label );
        ${$cache}{$label} = $tex;
        $self->_hyphenators($cache);
    }
    return;
}

sub _traverse_dom {
    my ( $self, $node ) = @_;
    if ( $self->_hyphenable($node) ) {
        if ( $node->type eq $TAG ) {
            $log->debug( sprintf $LOG{'TRAVERSE'}, $node->tag );
            $self->_configure_lang($node);
            foreach my $attr ( keys %{ $node->attr } ) {
                if ( $text_attr->has($attr) ) {
                    $node->attr( $attr, $self->_hyphen( $node->attr($attr) ) );
                }
            }
        }
        elsif ( $TEXT eq $node->type || $RAW eq $node->type ) {
            if ( !defined $self->_lang ) {
                $self->_configure_lang($node);
            }
            $log->debug( sprintf $LOG{'TEXT_NODE'}, $node->to_string );
            $node->replace( $self->_hyphen( $node->to_string ) );
            return;
        }
    }
    for my $child ( $node->child_nodes->each ) {
        $self->_traverse_dom($child);
    }
    return;
}

sub _clean_html {
    my ($self) = @_;
    my $html = $self->_dom->to_string();
    $self->_reset_dom;
    return $html;
}

sub _hyphen {
    my ( $self, $text ) = @_;
    $log->debug( sprintf $LOG{'HYPHEN_TEXT'}, $text );
    $text =~ s/(\w{@{[$self->min_length]},})/$self->_hyphen_word($1)/xsmeg;
    return $text;
}

sub _hyphen_word {
    my ( $self, $word ) = @_;
    if ( defined $self->_lang ) {
        if ( defined $self->_hyphenators->{ $self->_lang } ) {
            $log->debug( sprintf $LOG{'HYPHEN_WORD'},
                $word,
                $self->_hyphenators->{ $self->_lang }->visualize($word) );
            my $number = 0;
            foreach my $pos (
                $self->_hyphenators->{ $self->_lang }->hyphenate($word) )
            {
                substr $word, $pos + $number, 0, $SOFT_HYPHEN;
                $number += length $SOFT_HYPHEN;
            }
        }
        else {
            $log->warn( sprintf $LOG{'NOT_HYPHEN'}, $self->_lang );
        }
    }
    else {
        $log->warn( sprintf $LOG{'NO_LANG'}, $word );
    }
    return $word;
}

sub _configure_lang {
    my ( $self, $element ) = @_;
    my $lang = $element->attr($LANG);
    $lang ||= $element->attr(qq{xml:$LANG});
    my %hyphen_opts = (
        q{leftmin}  => $self->min_pre,
        q{rightmin} => $self->min_post,
    );
    defined $self->style
      && ( $hyphen_opts{'style'} = $self->style );
    defined $lang || ( $lang = $self->default_lang );
    if ( !defined $self->_lang || $lang ne $self->_lang ) {
        $self->_lang($lang);
        $log->debug( sprintf $LOG{'LANGUAGE_SET'}, $lang );
        if ( !exists $self->_hyphenators->{$lang} ) {
            $self->_add_tex_hyphen_to_cache();
        }
    }
    return;
}

sub _add_tex_hyphen_to_cache {
    my ($self) = @_;
    my $thp = TeX::Hyphen::Pattern->new();
    $thp->label( $self->_lang );
    my $cache = $self->_hyphenators;
    if ( my $file = $thp->filename ) {
        $log->debug( sprintf $LOG{'PATTERN_FILE'}, $file );
        ${$cache}{ $self->_lang } = TeX::Hyphen->new(
            q{file}     => $file,
            q{leftmin}  => $self->min_pre,
            q{rightmin} => $self->min_post,
        );
        $self->_hyphenators($cache);
    }
    return;
}

sub _hyphenable_by_class {
    my ( $self, $node ) = @_;
    my $included_level = $ONE_LEVEL_UP;
    my $excluded_level = $ONE_LEVEL_UP;
    $self->default_included && $excluded_level--;
    $self->default_included || $included_level--;

    $included_level =
      $self->_get_nearest_ancestor_level_by_classname( $node,
        $self->classes_included, $included_level );
    $excluded_level =
      $self->_get_nearest_ancestor_level_by_classname( $node,
        $self->classes_excluded, $excluded_level );
    if ( $included_level == $excluded_level ) {
        return $self->default_included;
    }
    return !( $excluded_level > $included_level );
}

sub _hyphenable {
    my ( $self, $node ) = @_;
    return !( $node->ancestors($PRE)->size
        || !$self->_hyphenable_by_class($node) );
}

sub _get_nearest_ancestor_level_by_classname {
    my ( $self, $node, $ar_classnames, $level ) = @_;
    my $classnames = Set::Scalar->new( @{$ar_classnames} );
    $log->debug( sprintf $LOG{'LOOKING_UP'}, $classnames->size );
    if ( !$classnames->is_empty
        && ( $node->ancestors->size ) )
    {
        my $selector = $DOT . join $CLASS_JOINER, $classnames->members;
        my $nearest  = $node->ancestors($selector)->first;
        if ($nearest) {
            return $nearest->ancestors->size;
        }
    }
    return $level;

}

sub _reset_dom {
    my ($self) = @_;
    my $dom = Mojo::DOM->new();
    $self->_dom($dom);
    return;
}

1;

__END__

=encoding utf8

=for stopwords Ipenburg Readonly merchantability Mojolicious

=head1 NAME

HTML::Hyphenate - insert soft hyphens into HTML.

=head1 VERSION

This document describes HTML::Hyphenate version v1.1.2.

=head1 SYNOPSIS

    use HTML::Hyphenate;

    $hyphenator = new HTML::Hyphenate();
    $html_with_soft_hyphens = $hyphenator->hyphenated($html);

    $hyphenator->html($html);
    $hyphenator->style($style); # czech or german

    $hyphenator->min_length(10);
    $hyphenator->min_pre(2);
    $hyphenator->min_post(2);
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

=item $hyphenator->register_tex_hyphen(C<lang>, C<TeX::Hyphen>)

Registers a TeX::Hyphen object to handle the language defined by C<lang>.

=back

=head1 CONFIGURATION AND ENVIRONMENT

The output is generated by L<Mojo::DOM|Mojo::DOM>.

=head1 DEPENDENCIES

=over 4

=item * Perl 5.14 

=item * L<Moose|Moose>

=item * L<Mojolicious|Mojolicious> for L<Mojo::Dom|Mojo::Dom>

=item * L<Log::Log4perl|Log::Log4perl>

=item * L<Readonly|Readonly>

=item * L<Set::Scalar|Set::Scalar>

=item * L<TeX::Hyphen|TeX::Hyphen>

=item * L<TeX::Hyphen::Pattern|TeX::Hyphen::Pattern>

=back

=head1 INCOMPATIBILITIES

=over 4

This module has the same limits as TeX::Hyphen, TeX::Hyphen::Pattern and
Mojo::DOM.

=back

=head1 DIAGNOSTICS

This module uses Log::Log4perl for logging.

=over 4

=item * It warns when a language encountered in the HTML is not supported by
TeX::Hyphen::Pattern

=back

=head1 BUGS AND LIMITATIONS

=over 4

=item * Perfect hyphenation can be more complicated than just inserting a
hyphen somewhere in a word, and sometimes requires semantics to get it right.
For example C<cafeetje> should be hyphenated as C<cafe-tje> and not
C<cafee-tje> and C<buurtje> can be hyphenated as C<buur-tje> or C<buurt-je>,
depending on it's meaning. While HTML could provide a bit more context (mainly
the language being used) than plain text to handle these issues, the initial
purpose of this module is to make it possible for HTML rendering engines that
support soft hyphens to be able to break long words over multiple lines to
avoid unwanted overflow.

=item * The hyphenation doesn't get better than TeX::Hyphenate and it's
hyphenation patterns provide.

=item * The round trip from HTML source via Mojo::DOM to HTML source might
introduce changes to the source, for example accented characters might be
transformed to HTML encoded entity equivalents or Boolean attributes are
converted to a different notation.

=back

Please report any bugs or feature requests at
L<RT for rt.cpan.org|
https://rt.cpan.org/Dist/Display.html?Queue=HTML-Hyphenate>.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009-2019, Roland van Ipenburg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
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
