package Locale::TextDomain::OO::Extract::JavaScript; ## no critic (TidyCode)

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
            || ! $filter_of{'!all'} && $filter_of{$key};
        return $condition ? @list : ();
    };
    my $with_bracket = join "\n| ", (
        $list_if->('Gettext',                           '__? n? p? x?',
                                                        'n? p? gettext'),
        $list_if->('Gettext::DomainAndCategory',        '__? d? c? n? p? x?',
                                                        'd? c? n? p? gettext'),
        $list_if->('Gettext::Loc',                      'loc_ n? p? x?'),
        $list_if->('Gettext::Loc::DomainAndCategory',   'loc_ d? c? n? p? x?'),
        $list_if->('BabelFish::Loc',                    'loc_b p?'),
        $list_if->('BabelFish::Loc::DomainAndCategory', 'loc_b d? c? p?'),
    );
    $with_bracket ||= '(?!)';

    return qr{
        \b N?
        (?: $with_bracket ) \s* [(]
    }xms;
}

my $category_rule
    = my $context_rule
    = my $domain_rule
    = my $plural_rule
    = my $singular_rule
    = my $text_rule
    = [
        [
            # "text with 0 .. n escaped chars"
            qr{
                \s* ["]
                (
                    [^\\"]*              # normal text
                    (?: \\ . [^\\"]* )*  # maybe followed by escaped char and normal text
                )
                ["]
            }xms,
        ],
        'or',
        [
            # 'text with 0 .. n escaped chars'
            qr{
                \s* [']
                (
                    [^\\']*              # normal text
                    (?: \\ . [^\\']* )*  # maybe followed by escaped char and normal text
                )
                [']
            }xms,
        ],
    ];
my $comma_rule = qr{ \s* [,] }xms;
my $count_rule = qr{ \s* ( [^,)]+ ) }xms;
my $close_rule = qr{ \s* [,]? \s* ( [^)]* ) [)] }xms;

my $rules = [
    # loc_, _, __
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( x? ) \s* [(] }xms,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( n x? ) \s* [(] }xms,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( p x? ) \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( np x? ) \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $close_rule,
        'end',
    ],

    # loc_d, _d, __d
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( d x? ) \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( dn x? ) \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( dp x? ) \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( dnp x? ) \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $close_rule,
        'end',
    ],

    # loc_c, _c, __c
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( c x? ) \s* [(] }xms,
        'and',
        $text_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( cn x? ) \s* [(] }xms,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( cp x? ) \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( cnp x? ) \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],

    # loc_dc, _dc, __dc
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( dc x? ) \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( dcn x? ) \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( dcp x? ) \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? (?: loc_ | __? ) ( dcnp x? ) \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],

    # loc_b... (BabelFish)
    'or',
    [
        'begin',
        qr{ \b N? loc_b () \s* [(] }xms,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    # babelfish loc_bp
    [
        'begin',
        qr{ \b N? loc_b ( p ) \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],

    # gettext
    'or',
    [
        'begin',
        qr{ \b N? () gettext \s* [(] }xms,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( n ) gettext \s* [(] }xms,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( p ) gettext \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( np ) gettext \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $close_rule,
        'end',
    ],

    # dgettext
    'or',
    [
        'begin',
        qr{ \b N? ( d ) gettext \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( dn ) gettext \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( dp ) gettext \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( dnp ) gettext \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $close_rule,
        'end',
    ],

    # cgettext
    'or',
    [
        'begin',
        qr{ \b N? ( c ) gettext \s* [(] }xms,
        'and',
        $text_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( cn ) gettext \s* [(] }xms,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( cp ) gettext \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( cnp ) gettext \s* [(] }xms,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],

    # dcgettext
    'or',
    [
        'begin',
        qr{ \b N? ( dc ) gettext \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( dcn ) gettext \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( dcp ) gettext \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $text_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
    'or',
    [
        'begin',
        qr{ \b N? ( dcnp ) gettext \s* [(] }xms,
        'and',
        $domain_rule,
        'and',
        $comma_rule,
        'and',
        $context_rule,
        'and',
        $comma_rule,
        'and',
        $singular_rule,
        'and',
        $comma_rule,
        'and',
        $plural_rule,
        'and',
        $comma_rule,
        'and',
        $count_rule,
        'and',
        $comma_rule,
        'and',
        $category_rule,
        'and',
        $close_rule,
        'end',
    ],
];

# remove comment code
sub preprocess {
    my $self = shift;

    my $content_ref = $self->content_ref;

    ${$content_ref} =~ s{ // [^\n]* $ }{}xmsg;
    ${$content_ref} =~ s{
        / [*] ( .*? ) [*] /
    }
    {
        join q{}, $1 =~ m{ ( \n ) }xmsg;
    }xmsge;

    return $self;
}

sub interpolate_escape_sequence {
    my ( undef, $string ) = @_;

    # nothing to interpolate
    defined $string
        or return $string;

    my %char_of = (
        b => "\b",
        f => "\f",
        n => "\n",
        r => "\r",
        t => "\t",
    );
    ## no critic (ComplexRegexes)
    $string =~ s{
        \\
        (?:
            ( [bfnrt] )           # Backspace
                                  # Form feed
                                  # New line
                                  # Carriage return
                                  # Horizontal tab
            | u ( [\dA-Fa-f]{4} ) # Unicode sequence (4 hex digits: dddd)
            | x ( [\dA-Fa-f]{2} ) # Hexadecimal sequence (2 digits: dd)
            |   ( [0-3][0-7]{2} ) # Octal sequence (3 digits: ddd)
            | (.)                 # Backslash itself
                                  # Single quotation mark
                                  # Double quotation mark
                                  # anything else that needs no escape
        )
    }{
        $1   ? $char_of{$1}
        : $2 ? chr hex $2
        : $3 ? chr hex $3
        : $4 ? chr oct $4
        :      $5
    }xmsge;
    ## use critic (ComplexRegexes)

    return $string;
}

sub stack_item_mapping {
    my $self = shift;

    my $match = $_->{match};
    my $extra_parameter = shift @{$match};
    @{$match}
        or return;

    my $count;
    $self->add_message({
        reference    => ( sprintf '%s:%s', $self->filename, $_->{line_number} ),
        domain       => $extra_parameter =~ m{ d }xms
            ? scalar $self->interpolate_escape_sequence( shift @{$match} )
            : $self->domain,
        msgctxt      => $extra_parameter =~ m{ p }xms
            ? scalar $self->interpolate_escape_sequence( shift @{$match} )
            : undef,
        msgid        => scalar $self->interpolate_escape_sequence( shift @{$match} ),
        msgid_plural => $extra_parameter =~ m{ n }xms
            ? do {
                my $plural = $self->interpolate_escape_sequence( shift @{$match} );
                $count = shift @{$match};
                $plural;
            }
            : undef,
        category     => $extra_parameter =~ m{ c }xms
            ? scalar $self->interpolate_escape_sequence( shift @{$match} )
            : $self->category,
        automatic    => do {
            my $placeholders = shift @{$match};
            my $string = join ', ', map { ## no critic (MutatingListFunctions)
                defined $_
                ? do {
                    s{ \s+ }{ }xmsg;
                    s{ \s+ \z }{}xms;
                    length $_ ? $_ : ();
                }
                : ();
            } ( $count, $placeholders );
            $string =~ s{ \A ( .{70} ) .+ \z }{$1 ...}xms;
            $string;
        },
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
Locale::TextDomain::OO::Extract::JavaScript
- Extracts internationalization data from JavaScript code

$Id: JavaScript.pm 693 2017-09-02 09:20:30Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/extract/trunk/lib/Locale/TextDomain/OO/Extract/JavaScript.pm $

=head1 VERSION

2.011

=head1 DESCRIPTION

This module extracts internationalization data from JavaScript code.

Implemented rules:

 # Gettext::Loc
 loc_('...
 loc_x('...
 loc_n('...
 loc_nx('...
 loc_p('...
 loc_px('...
 loc_np('...
 loc_npx('...

 # Gettext::Loc::DomainAndCategory
 loc_d('...
 loc_dx('...
 loc_dn('...
 loc_dnx('...
 loc_dp('...
 loc_dpx('...
 loc_dnp('...
 loc_dnpx('...

 loc_c('...
 loc_cx('...
 loc_cn('...
 loc_cnx('...
 loc_cp('...
 loc_cpx('...
 loc_cnp('...
 loc_cnpx('...

 loc_dc('...
 loc_dcx('...
 loc_dcn('...
 loc_dcnx('...
 loc_dcp('...
 loc_dcpx('...
 loc_dcnp('...
 loc_dcnpx('...

 # BabelFish::Loc
 loc_b('...
 loc_bp('...

 # BabelFish::Loc::DomainAndCategory
 loc_bd('...
 loc_bdp('...

 loc_bc('...
 loc_bcp('...

 loc_bdc('...
 loc_bdcp('...

 # Gettext
 _('...
 _x('...
 _n('...
 _nx('...
 _p('...
 _px('...
 _np('...
 _npx('...

 __('...
 __x('...
 __n('...
 __nx('...
 __p('...
 __px('...
 __np('...
 __npx('...

 gettext('...
 ngettext('...
 pgettext('...
 npgettext('...

 # Gettext::DomainAndCategory
 _d('...
 _dx('...
 _dn('...
 _dnx('...
 _dp('...
 _dpx('...
 _dnp('...
 _dnpx('...

 _c('...
 _cx('...
 _cn('...
 _cnx('...
 _cp('...
 _cpx('...
 _cnp('...
 _cnpx('...

 _dc('...
 _dcx('...
 _dcn('...
 _dcnx('...
 _dcp('...
 _dcpx('...
 _dcnp('...
 _dcnpx('...

 __d('...
 __dx('...
 __dn('...
 __dnx('...
 __dp('...
 __dpx('...
 __dnp('...
 __dnpx('...

 __c('...
 __cx('...
 __cn('...
 __cnx('...
 __cp('...
 __cpx('...
 __cnp('...
 __cnpx('...

 __dc('...
 __dcx('...
 __dcn('...
 __dcnx('...
 __dcp('...
 __dcpx('...
 __dcnp('...
 __dcnpx('...

 dgettext('...
 dngettext('...
 dpgettext('...
 dnpgettext('...

 cgettext('...
 cngettext('...
 cpgettext('...
 cnpgettext('...

 dcgettext('...
 dcngettext('...
 dcpgettext('...
 dcnpgettext('...

Whitespace is allowed everywhere.
Quote and escape any text like: C<' text {placeholder} \\ \' ' or " text {placeholder} \\ \" }>
Also possible all functions with N in front like Nloc_, N__, Ngettext, ... to prepare only.

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Extract::JavaScript;
    use Path::Tiny qw(path);

    my $extractor = Locale::TextDomain::OO::Extract::JavaScript->new(
        # optional filter parameter, the default is ['all'],
        # the following means:
        # extract for all plugins but not for Plugin
        # Locale::TextDomain::OO::Plugin::BabelFish::Loc
        filter => [ qw( all !BabelFish::Loc ) ],
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

    my $extractor = Locale::TextDomain::OO::Extract::JavaScript->new;

=head2 method filter

Ignore some of 'all' or define what to scan.
See SYNOPSIS and DESCRIPTION for how and what.

    my $array_ref = $extractor->filter;

    $extractor->filter(['all']); # the default

=head2 method preprocess (called by method extract)

This method removes all comments.

    $extractor->preprocess;

=head2 method interpolate_escape_sequence (called by method extract)

This method helps e.g. \n to be a real newline in string.

    $string = $extractor->interpolate_escape_sequence($string);

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

L<http://sourceforge.net/projects/jsgettext.berlios/>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
