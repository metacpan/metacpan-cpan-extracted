package Locale::TextDomain::OO::Extract::YAML; ## no critic (TidyCode)

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
    my $hash_key_suffix = join "\n| ", (
        $list_if->('Gettext',        qr{ __     \b }xms),
        $list_if->('Maketext::Loc',  qr{ _loc   \b }xms),
        $list_if->('Gettext::Loc',   qr{ _loc_  \b }xms),
        $list_if->('BabelFish::Loc', qr{ _loc_b \b }xms),
    );
    $hash_key_suffix ||= '(?!)';

    return qr{
        ^ [ -]*
        (?: content | label | message | value )
        (?:
             $hash_key_suffix
        )
        [ ]* [:]
    }xms;
}

## no critic (ComplexRegexes)
my $text_rule
    = [
        [
            # '...'
            qr{
                [ ]*
                [']
                (
                    [^\\']*             # normal text
                    (?: \\ . [^\\']* )* # maybe followed by escaped char and normal text
                )
                [']
            }xms,
        ],
        'or',
        [
            # "..."
            qr{
                [ ]*
                ["]
                (
                    [^\\"]*             # normal text
                    (?: \\ . [^\\"]* )* # maybe followed by escaped char and normal text
                )
                ["]
            }xms,
        ],
        'or',
        [
            # ...
            qr{
                [ ]*
                (
                    .*? # normal text
                )
                [ ]* $
            }xms,
        ],
    ];

my $rules = [
    # content_loc: |
    #   text
    # ...
    [
        'begin',
        sub {
            my $content_ref = shift;

            my $regex = qr{
                ^ ( [ -]* )
                (?: content | label | message | value ) _ (?: _ | loc_b? | loc )
                [ ]* [:] [ ]* [|] [ ]* \n
            }xms;
            $content_ref
                or return $regex;
            # full match begins here
            my $pos = pos ${$content_ref};
            # begin of heredoc with |
            my ( $full_match, $indent ) = ${$content_ref} =~ m{ \G ( $regex ) }xms
                or return;
            # get heredoc lines
            pos ${$content_ref} = $pos + length $full_match;
            $indent =~ tr{-}{ };
            $indent .= q{ } x 2; # next indent level
            $regex = qr{
                ( [ ]* \n )                 # empty line
                | \Q$indent\E ( [^\n]* \n ) # text line
            }xms;
            my $heredoc = q{};
            while ( ( $full_match, my ( $empty_line, $text_line ) ) = ${$content_ref} =~ m{ \G ( $regex ) }xms ) {
                $heredoc .= $empty_line || $text_line;
                pos ${$content_ref} += length $full_match;
            }
            chomp $heredoc;
            # full match over all
            $full_match = substr
                ${$content_ref},
                $pos,
                ( pos ${$content_ref} ) - $pos;
            # reset pos for alternatives
            pos ${$content_ref} = $pos;

            return $full_match, $heredoc;
        },
        'end',
    ],
    'or',
    # content_loc: 'text ...'
    # label_loc_ : "text ..."
    # message__  : text ...
    # value__    : text ...
    # all combinations left after _ and right to : are possible
    [
        'begin',
        qr{
            ^ [ -]*
            (?: content | label | message | value ) _ (?: _ | loc_b? | loc )
            [ ]* [:]
        }xms,
        'and',
        $text_rule,
        'end',
    ],
];

# remove code after # on pos 1
sub preprocess {
    my $self = shift;

    my $content_ref = $self->content_ref;

    ${$content_ref} =~ s{ \r? \n }{\n}xmsg;
    ${$content_ref} =~ s{
        # "text with #" # comment
        (
            ["]
            [^\\"]*             # normal text
            (?: \\ . [^\\"]* )* # maybe followed by escaped char and normal text
            ["]
        ) [ ]* [#] [^\n]* ( \n | \z )
        |
        # 'text with #' # comment
        (
            [']
            [^\\']*             # normal text
            (?: \\ . [^\\']* )* # maybe followed by escaped char and normal text
            [']
        ) [ ]* [#] [^\n]* ( \n | \z )
        |
        # simple comment line
        [ ]* [#] [^\n]* ( \n | \z )
    }{
        $1   ? "$1$2"
        : $3 ? "$3$4"
        :      $5
    }xmsge;

    return;
}
## use critic (ComplexRegexes)

sub stack_item_mapping {
    my $self = shift;

    my $match = $_->{match};
    @{$match}
        or return;

    $self->add_message({
        reference => ( sprintf '%s:%s', $self->filename, $_->{line_number} ),
        domain    => $self->domain,
        msgid     => shift @{$match},
        category  => $self->category,
    });

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
Locale::TextDomain::OO::Extract::YAML
- Extracts internationalization data from HTML::FormFu field definition YAML file

$Id: YAML.pm 695 2017-09-02 09:24:08Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/extract/trunk/lib/Locale/TextDomain/OO/Extract/YAML.pm $

=head1 VERSION

2.011

=head1 DESCRIPTION

This module extracts internationalization data from Template code.

Implemented rules:

 # Maketext
 label_loc:'...'
 label_loc:"..."
 label_loc:...

 # Gettext
 label__:'...'
 label__:"..."
 label__:...

 # Gettext::Loc
 label_loc_:'...'
 label_loc_:"..."
 label_loc_:...

 # BabelFish::loc
 label_loc_b:'...'
 label_loc_b:"..."
 label_loc_b:...

Instead of C<label> also possible for C<content> and C<value>.

Whitespace is allowed everywhere.
Quote and escape any text like: C<' text {placeholder} \\ \' '>

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Extract::YAML;
    use Path::Tiny qw(path);

    my $extractor = Locale::TextDomain::OO::Extract::YAML->new(
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

    my $extractor = Locale::TextDomain::OO::Extract::YAML->new;

=head2 method filter

Ignore some of 'all' or define what to scan.
See SYNOPSIS and DESCRIPTION for how and what.

    my $array_ref = $extractor->filter;

    $extractor->filter(['all']); # the default

=head2 method preprocess (called by method extract)

This method removes all comments.

    $extractor->preprocess;

=head2 method stack_item_mapping (called by method extract)

This method maps the matched stuff as lexicon item.

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

L<Template|Template>

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
