package Locale::TextDomain::OO::Extract::HTML; ## no critic (TidyCode)

use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef Str);
use namespace::autoclean;

our $VERSION = '2.004';

extends qw(
    Locale::TextDomain::OO::Extract::Base::RegexBasedExtractor
);
with qw(
    Locale::TextDomain::OO::Extract::Role::File
);

my $text_rule = qr{ \s* ( [^<]+ ) }xms;

## no critic (ComplexRegexes)
my $start_rule = qr{
    [<] [^>]*?
    \b class \s* [=] \s*
    (?:
        ["] [^"]*? \b (?: loc_ | __ | loc ) \b [^"]*? ["]
        |
        ['] [^']*? \b (?: loc_ | __ | loc ) \b [^']*? [']
    )
}xms;

my $rules = [
    # <input type="submit|button|checkbox|radio" class="... loc_|__|loc ..." value="text to extract" ...>
    [
        'begin',
        sub {
            my $content_ref = shift;

            my $regex = qr{
                [<] input \b
                (
                    .*? \b type \s* [=]
                    (?:
                        ["] ( button | checkbox | radio | submit ) ["]
                        | ['] ( button | checkbox | radio | submit ) [']
                    )
                    .*?
                )
                [>]
            }xms;
            $content_ref
                or return $regex;
            my ( $full_match, $inner, $type1, $type2 )
                = ${$content_ref} =~ m{ \G ( $regex ) }xms
                    or return;
            my $type = $type1 || $type2;
            if ( $type eq 'button' || $type eq 'submit' ) {
                $inner =~ m{ \b value \s* [=] \s* ["] ( [^"]+ ) ["] }xms
                    and return $full_match, $1;
                $inner =~ m{ \b value \s* [=] \s* ['] ( [^']+ ) ['] }xms
                    and return $full_match, $1;

            }
            elsif ( $type eq 'checkbox' || $type eq 'radio' ) {
                $inner =~ m{ \b title \s* [=] \s* ["] ( [^"]+ ) ["] }xms
                    and return $full_match, $1;
                $inner =~ m{ \b title \s* [=] \s* ['] ( [^']+ ) ['] }xms
                    and return $full_match, $1;
            }

            return;
        },
        'end',
    ],
    'or',
    # <... class="... loc_|__|loc ...' ... >text to extract<
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

    return;
}

sub stack_item_mapping {
    my $self = shift;

    my $match = $_->{match};
    @{$match}
        or return;

    my $string = shift @{$match};
    $string =~ s{ \s+ \z }{}xms;
    my ( $msgctxt, $msgid )
        = $string =~ m{ \A (?: ( .*? ) \s* \Q{CONTEXT_SEPARATOR}\E )? \s* ( .* ) \z }xms;
    $self->add_message({
        reference => ( sprintf '%s:%s', $self->filename, $_->{line_number} ),
        msgctxt   => $msgctxt,
        msgid     => $msgid,
    });

    return $self;
}

sub extract {
    my $self = shift;

    $self->start_rule($start_rule);
    $self->rules($rules);
    $self->preprocess;
    $self->SUPER::extract;
    for ( @{ $self->stack } ) {
        $self->stack_item_mapping($_);
    }

    return $self;
}

1;

__END__

=head1 NAME
Locale::TextDomain::OO::Extract::HTML
- Extracts internationalization data from HTML

$Id: HTML.pm 576 2015-04-12 05:48:58Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/extract/trunk/lib/Locale/TextDomain/OO/Extract/HTML.pm $

=head1 VERSION

2.004

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

=head1 SUBROUTINES/METHODS

=head2 method new

All parameters are optional.
See Locale::TextDomain::OO::Extract to replace the defaults.

    my $extractor = Locale::TextDomain::OO::Extract::HTML->new;

=head2 method extract

Call

    $extractor->filename('dir/filename for reference');
    $extractor->extract;
    
=head2 preprocess

Remove code between <!-- -->

    $self->preprocess;

=head2 method stack_item_mapping

    $self->stack_item_mapping($stack_item);

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

Copyright (c) 2014 - 2015,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
