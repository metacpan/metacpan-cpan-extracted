package Locale::TextDomain::OO::Extract::HTML; ## no critic (TidyCode MainComplexity)

use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef Str);
use namespace::autoclean;

our $VERSION = '2.011';

extends qw(
    Locale::TextDomain::OO::Extract::Base::RegexBasedExtractor
);
with qw(
    Locale::TextDomain::OO::Extract::Role::File
);

has filter => (
    is      => 'rw',
    isa     => ArrayRef[Str],
    lazy    => 1,
    default => sub {[ 'all' ]},
);

sub _filtered_start_rule {
    my $self = shift;

    my %filter_of = map { $_ => 1 } @{ $self->filter };
    my $list_if = sub {
        my ( $key, @list ) = @_;
        my $condition
            = $filter_of{all} && ! $filter_of{"!$key"}
            || $filter_of{$key};
        return $condition ? @list : ();
    };
    my $with_bracket = join "\n| ", (
        $list_if->('Gettext',      qr{ ["] [^"]*? \b __   \b [^"]*? ["] }xms,
                                   qr{ ['] [^']*? \b __   \b [^']*? ['] }xms),
        $list_if->('Gettext::Loc', qr{ ["] [^"]*? \b loc_ \b [^"]*? ["] }xms,
                                   qr{ ['] [^']*? \b loc_ \b [^']*? ['] }xms),
        $list_if->('Maketext',     qr{ ["] [^"]*? \b loc  \b [^"]*? ["] }xms,
                                   qr{ ['] [^']*? \b loc  \b [^']*? ['] }xms),
    );
    $with_bracket ||= '(?!)';

    return qr{
        [<] [^>]*?
        \b class \s* [=] \s*
        (?: $with_bracket )
    }xms;
}

## no critic (ComplexRegexes)
my $text_rule = qr{ \s* ( [^<]+ ) }xms;

my $rules = [
    # <input class="... loc_|__|loc ..." ... placeholder="text to extract" ... />
    # <input class="... loc_|__|loc ..." ... title="text to extract" ... />
    # <input class="... loc_|__|loc ..." ... value="text to extract" ... />
    [
        'begin',
        sub {
            my $content_ref = shift;

            my $regex = qr{
                [<] input \b
                ( [^>]* )
                />
            }xms;
            $content_ref
                or return $regex;
            my ( $full_match, $inner )
                = ${$content_ref} =~ m{ \G ( $regex ) }xms
                    or return;

            my @match = (
                $inner =~ m{ \b placeholder \s* [=] \s* ["] ( [^"]+ ) ["] }xms,
                $inner =~ m{ \b placeholder \s* [=] \s* ['] ( [^']+ ) ['] }xms,
                $inner =~ m{ \b title \s* [=] \s* ["] ( [^"]+ ) ["] }xms,
                $inner =~ m{ \b title \s* [=] \s* ['] ( [^']+ ) ['] }xms,
                (
                    $inner =~ m{ \b type \s* [=] \s* ["] (?: submit | reset | button ) ["] }xms
                    || $inner =~ m{ \b type \s* [=] \s* ['] (?: submit | reset | button ) ['] }xms
                )
                ? (
                    $inner =~ m{ \b value \s* [=] \s* ["] ( [^"]+ ) ["] }xms
                    ? $1
                    : $inner =~ m{ \b value \s* [=] \s* ['] ( [^']+ ) ['] }xms
                    ? $1
                    : ()
                )
                : (),
            );
            @match
                and return +( $full_match, @match );

            return;
        },
        'end',
    ],
    'or',
    # <textarea
    #   class="... loc_|__|loc ..."
    #   placeholder="text to extract"
    #   ...
    # ></textarea>
    [
        'begin',
        sub {
            my $content_ref = shift;

            my $regex = qr{
                [<] textarea \b
                ( [^>]* )
                [>]
            }xms;
            $content_ref
                or return $regex;
            my ( $full_match, $inner )
                = ${$content_ref} =~ m{ \G ( $regex ) }xms
                    or return;
                $inner =~ m{ \b placeholder \s* [=] \s* ["] ( [^"]+ ) ["] }xms
                    and return +( $full_match, $1 );
                $inner =~ m{ \b placeholder \s* [=] \s* ['] ( [^']+ ) ['] }xms
                    and return +( $full_match, $1 );

            return;
        },
        'end',
    ],
    'or',
    # <img class="... loc_|__|loc ..." ... alt="text to extract" ... />
    [
        'begin',
        sub {
            my $content_ref = shift;

            my $regex = qr{
                [<] img \b
                ( [^>]* )
                />
            }xms;
            $content_ref
                or return $regex;
            my ( $full_match, $inner )
                = ${$content_ref} =~ m{ \G ( $regex ) }xms
                    or return;

            my @match = (
                $inner =~ m{ \b alt \s* [=] \s* ["] ( [^"]+ ) ["] }xms,
                $inner =~ m{ \b alt \s* [=] \s* ['] ( [^']+ ) ['] }xms,
            );
            @match
                and return +( $full_match, @match );

            return;
        },
        'end',
    ],
    'or',
    # <a class="... loc_|__|loc ..." ... title="text to extract" ... >text_to_extract</a>
    [
        'begin',
        sub {
            my $content_ref = shift;

            my $regex = qr{
                [<] [a] \b
                ( [^>]* )
                [>]
                ( [^<]* )
            }xms;
            $content_ref
                or return $regex;
            my ( $full_match, $inner, $text )
                = ${$content_ref} =~ m{ \G ( $regex ) }xms
                    or return;

            my @match = (
                $inner =~ m{ \b title \s* [=] \s* ["] ( [^"]+ ) ["] }xms,
                $inner =~ m{ \b title \s* [=] \s* ['] ( [^']+ ) ['] }xms,
            );
            @match
                and return +( $full_match, $text, @match );

            return;
        },
        'end',
    ],
    'or',
    # <button class="... loc_|__|loc ..." ... title="text to extract" ... >text_to_extract</button>
    [
        'begin',
        sub {
            my $content_ref = shift;

            my $regex = qr{
                [<] button \b
                ( [^>]* )
                [>]
                ( [^<]* )
            }xms;
            $content_ref
                or return $regex;
            my ( $full_match, $inner, $text )
                = ${$content_ref} =~ m{ \G ( $regex ) }xms
                    or return;

            my @match = (
                $inner =~ m{ \b title \s* [=] \s* ["] ( [^"]+ ) ["] }xms,
                $inner =~ m{ \b title \s* [=] \s* ['] ( [^']+ ) ['] }xms,
            );
            @match
                and return +( $full_match, $text, @match );

            return;
        },
        'end',
    ],
    'or',
    # < class="... loc_|__|loc ..." ... title="text to extract" ... >text_to_extract<
    [
        'begin',
        sub {
            my $content_ref = shift;

            my $regex = qr{
                [<] \w+ \b
                ( [^>]* )
                [>]
                ( [^<]* )
            }xms;
            $content_ref
                or return $regex;
            my ( $full_match, $inner, $text )
                = ${$content_ref} =~ m{ \G ( $regex ) }xms
                    or return;


            my @match = (
                $inner =~ m{ \b title \s* [=] \s* ["] ( [^"]+ ) ["] }xms,
                $inner =~ m{ \b title \s* [=] \s* ['] ( [^']+ ) ['] }xms,
                $text,
            );
            @match
                and return +( $full_match, @match );

            return;
        },
        'end',
    ],
    'or',
    # <... class="... loc_|__|loc ..." ... >text to extract<
    [
        'begin',
        qr{
            [<] [^>]*?
            \b class \s* [=] \s* ["] [^"]*?
            \b (?: loc_ | __ | loc ) \b
            [^"]*? ["]
            [^>]* [>]
        }xms,
        'and',
        $text_rule,
        'end',
    ],
    'or',
    # <... class='... loc_|__|loc ...' ... >text to extract<
    [
        'begin',
        qr{
            [<] [^>]*?
            \b class \s* [=] \s* ['] [^']*?
            \b (?: loc_ | __ | loc ) \b
            [^']*? [']
            [^>]* [>]
        }xms,
        'and',
        $text_rule,
        'end',
    ],
];
## use critic (ComplexRegexes)

# remove code between <!-- -->
sub preprocess {
    my $self = shift;

    my $content_ref = $self->content_ref;

    ${$content_ref} =~ s{ \r? \n }{\n}xmsg;
    ${$content_ref} =~ s{ <!-- ( .*? ) --> }{
        join q{}, $1 =~ m{ ( \n ) }xmsg
    }xmsge;

    return $self;
}

sub stack_item_mapping {
    my $self = shift;

    my $match = $_->{match};
    @{$match}
        or return;

    while ( my $string = shift @{$match} ) {
        $string =~ s{ \s+ \z }{}xms;
        my ( $msgctxt, $msgid )
            = $string =~ m{ \A (?: ( .*? ) \s* \Q{CONTEXT_SEPARATOR}\E )? \s* ( .* ) \z }xms;
        $self->add_message({
            reference => ( sprintf '%s:%s', $self->filename, $_->{line_number} ),
            msgctxt   => $msgctxt,
            msgid     => $msgid,
        });
    }

    return;
}

sub extract {
    my $self = shift;

    $self->start_rule( $self->_filtered_start_rule );
    $self->rules($rules);
    $self->preprocess;
    $self->SUPER::extract;
    for ( @{ $self->stack } ) {
        $self->stack_item_mapping;
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME
Locale::TextDomain::OO::Extract::HTML
- Extracts internationalization data from HTML

$Id: HTML.pm 693 2017-09-02 09:20:30Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/extract/trunk/lib/Locale/TextDomain/OO/Extract/HTML.pm $

=head1 VERSION

2.011

=head1 DESCRIPTION

This module extracts internationalization data from HTML.

Implemented rules:

Gettext::Loc

 <any_tag ... class="... loc_ ..." ... >text to extract<
 <any_tag ... class="... loc_ ..." ... >context{CONTEXT_SEPARATOR}text to extract<

Gettext

 <any_tag ... class="... __ ..." ... >text to extract<
 <any_tag ... class="... __ ..." ... >context{CONTEXT_SEPARATOR}text to extract<

Maketext

 <any_tag ... class="... loc ..." ... >text to extract<
 <any_tag ... class="... loc ..." ... >context{CONTEXT_SEPARATOR}text to extract<

Whitespace is allowed everywhere.

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Extract::HTML;
    use Path::Tiny qw(path);

    my $extractor = Locale::TextDomain::OO::Extract::HTML->new(
        # optional filter parameter, the default is ['all'],
        # the following means:
        # extract for all plugins but not for Plugin
        # Locale::TextDomain::OO::Plugin::Maketext
        filter => [ qw(
            all
            !Maketext
        ) ],
    );
    for ( @files ) {
        $extractor->clear;
        $extractor->filename($_);            # dir/filename for reference
        $extractor->content_ref( \( path($_)->slurp_utf8 ) );
        $extractor->project('my project');   # set or default undef is used
        $extractor->category('LC_MESSAGES'); # set or default q{} is used
        $extractor->domain('my domain');     # set or default q{} is used
        $extractor->extract;
    }
    ... = $extractor->lexicon_ref;

=head1 SUBROUTINES/METHODS

=head2 method new

All parameters are optional.
See Locale::TextDomain::OO::Extract to replace the defaults.

    my $extractor = Locale::TextDomain::OO::Extract::HTML->new;

=head2 method filter

Ignore some of 'all' or define what to scan.
See SYNOPSIS and DESCRIPTION for how and what.

    my $array_ref = $extractor->filter;

    $extractor->filter(['all']); # the default

=head2 method preprocess (called by method extract)

Remove code between <!-- -->

    $extractor->preprocess;

=head2 method stack_item_mapping (called by method extract)

    $extractor->stack_item_mapping;

=head2 method extract

This method runs the extraction.

    $extractor->extract;

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Moo|Moo>

L<MooX::Types::MooseLike::Base|MooX::Types::MooseLike::Base>

L<namespace::autoclean|namespace::autoclean>

L<Locale::TextDomain::OO::Extract::Base::RegexBasedExtractor|Locale::TextDomain::OO::Extract::Base::RegexBasedExtractor>

L<Locale::TextDomain::OO::Extract::Role::File|Locale::TextDomain::OO::Extract::Role::File>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

L<HTML::Zoom|HTML::Zoom>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
