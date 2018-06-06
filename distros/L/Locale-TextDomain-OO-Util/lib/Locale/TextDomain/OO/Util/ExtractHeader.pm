package Locale::TextDomain::OO::Util::ExtractHeader; ## no critic (TidyCode)

use strict;
use warnings;
use 5.010;

use Carp qw(confess);
use English qw(-no_match_vars $EVAL_ERROR);
use namespace::autoclean;

our $VERSION = '4.001';

sub instance {
    return __PACKAGE__;
}

my $really_compile_formula = sub {
    my ($formula) = @_;

    ## no critic (ComplexRegexes EnumeratedClasses EscapedMetacharacters)
    $formula =~ m{
        \A \s*+ (?&expr) \z
        (?(DEFINE)
            (?<term>
                (?>
                    (?> ~ | ! (?! = ) | - (?! [\-=] ) | \+ (?! [+=] ) ) \s*+
                )*+

                (?>
                    [1-9] [0-9]*+ \b
                |
                    0 0*+ \b
                |
                    n \b
                |
                    \( \s*+ (?&expr) \)
                )
                \s*+
            )
            (?<expr>
                (?&term)
                (?>
                    (?>
                        \? \s*+ (?&expr) :
                    |
                        \|\| | &&
                    |
                        == | !=
                    |
                        << (?! = ) | >> (?! = )
                    |
                        <= | >=
                    |
                        < (?! [<=] ) | > (?! [>=] )
                    |
                        - (?! [-=] )
                    |
                        \+ (?! [+=] )
                    |
                        \| (?! [|=] )
                    |
                        & (?! [&=] )
                    |
                        / (?! [/*=] )
                    |
                        [\^*%] (?! = )
                    )
                    \s*+
                    (?&term)
                )*+
            )
        )
    }xms
        or confess "Invalid formula: $formula";
    ## use critic (ComplexRegexes EnumeratedClasses EscapedMetacharacters)

    $formula =~ s{ \b n \b }{\$n}xmsg;
    my $sub = eval "sub { my \$n = shift; use integer; 0 + ($formula) }" ## no critic (StringyEval)
        or confess "Internal error: $formula: $EVAL_ERROR";

    return $sub;
};

my %compiled_formula_cache;
my $compile_formula = sub {
    my $formula = shift;

    return $compiled_formula_cache{$formula} ||= $really_compile_formula->($formula);
};

sub extract_header_msgstr {
    my ( undef, $header_msgstr ) = @_;

    defined $header_msgstr
        or confess 'Header is not defined';
    ## no critic (ComplexRegexes EnumeratedClasses)
    my ( $plural_forms, $nplurals, $plural ) = $header_msgstr =~ m{
        ^
        Plural-Forms:
        [ ]*
        (
            nplurals [ ]* [=] [ ]* ([0-9]+)   [ ]* [;]
            [ ]*
            plural   [ ]* [=] [ ]* ([^;\n]+) [ ]* [;]?
            [ ]*
        )
        $
    }xms
        or confess 'Plural-Forms not found in header';
    ## use critic (ComplexRegexes EnumeratedClasses)
    my ( $charset ) = $header_msgstr =~ m{
        ^
        Content-Type:
        [^;]+ [;] [ ]*
        charset [ ]* = [ ]*
        ( [^ ]+ )
        [ ]*
        $
    }xms
        or confess 'Content-Type with charset not found in header';
    my ( $lexicon_class ) = $header_msgstr =~ m{
        ^ X-Lexicon-Class: \s* ( \S* ) \s* $
    }xms;
    # ToDo: remove because multiplural was a too complicated idea
    ## no critic (EnumeratedClasses)
    my ( $multiplural_nplurals ) = $header_msgstr =~ m{
        ^ X-Multiplural-Nplurals: [ ]* ( [0-9]+ ) [ ]* $
    }xms;
    ## use critic (EnumeratedClasses)

    return {(
        nplurals                 => 0 + $nplurals,
        plural                   => $plural,
        plural_code              => $compile_formula->($plural),
        charset                  => $charset,
        ! $lexicon_class ? () : (
            lexicon_class        => $lexicon_class,
        ),
        # ToDo: remove because multiplural was a too complicated idea
        ! $multiplural_nplurals ? () : (
            multiplural_nplurals => $multiplural_nplurals,
        ),
    )};
}

1;

__END__

=head1 NAME
Locale::TextDomain::OO::Util::ExtractHeader - Gettext header extractor

=head1 VERSION

4.001

$Id: ExtractHeader.pm 600 2015-07-01 04:58:40Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/Locale-TextDomain-OO-Util/trunk/lib/Locale/TextDomain/OO/Util/ExtractHeader.pm $

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Util::ExtractHeader;

    my $extractor = Locale::TextDomain::OO::Util::ExtractHeader->instance;

=head1 DESCRIPTION

This module is extracts charset and plural date from gettext header.

=head1 SUBROUTINES/METHODS

=head2 method instance

See SYNOPSIS. This method returns a value you can call C<extract_header_msgstr>
on.

=head2 method extract_header_msgstr

    $hash_ref = $extractor->extract_header_msgstr($header_msgstr);

That hash_ref contains:

    nplurals      => $count_of_plural_forms,
    plural        => $the_original_formula,
    plural_code   => $code_ref__to_select_the_right_plural_form,
    charset       => $charset,
    lexicon_class => 'from X-Lexicon-Class',

=head1 EXAMPLE

See the F<*.pl> files in the F<example> directory in this distribution.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<English|English>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDomain::OO|Locale::TextDomain::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 - 2018,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
