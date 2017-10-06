package Locale::Utils::PluralForms; ## no critic (TidyCode)

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

use English qw(-no_match_vars $EVAL_ERROR);
use HTML::Entities qw(decode_entities);
require LWP::UserAgent;
require Safe;

our $VERSION = '0.002';

has language => (
    is       => 'rw',
    isa      => 'Str',
    trigger  => \&_language,
);

has _all_plural_forms_url => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'http://docs.translatehouse.org/projects/localization-guide/en/latest/l10n/pluralforms.html',
);

has _all_plural_forms_html => (
    is       => 'rw',
    isa      => 'Str',
    default  => \&_get_all_plural_forms_html,
    lazy     => 1,
    clearer  => 'clear_all_plural_forms_html',
);

has all_plural_forms => (
    is       => 'rw',
    isa      => 'HashRef',
    default  => \&_get_all_plural_forms,
    lazy     => 1,
);

has plural_forms => (
    is      => 'rw',
    isa     => 'Str',
    default => 'nplurals=1; plural=0',
    lazy    => 1,
    trigger => \&_calculate_plural_forms,
);

has nplurals => (
    is       => 'rw',
    isa      => 'Int',
    default  => 1,
    lazy     => 1,
    init_arg => undef,
    writer   => '_nplurals',
);

has plural_code => (
    is       => 'rw',
    isa      => 'CodeRef',
    default  => sub { return sub { return 0 } },
    lazy     => 1,
    init_arg => undef,
    writer   => '_plural_code',
);

sub _get_all_plural_forms_html {
    my $self = shift;

    my $url = $self->_all_plural_forms_url;
    my $ua  = LWP::UserAgent->new;
    $ua->env_proxy;
    my $response = $ua->get($url);
    $response->is_success
        or confess "$url $response->status_line";

    return $response->decoded_content;
}

sub _get_all_plural_forms {
    my $self = shift;

    ## no critic (ComplexRegexes)
    my @match = $self->_all_plural_forms_html =~ m{
        <tr \s+ class="row- (?: even | odd ) ">
        \s*
        <td> ( [^<>]+ ) </td>
        \s*
        <td> ( [^<>]+ ) .*? </td>
        \s*
        <td> ( nplurals [^<>]+? ) [;]? </td>
        \s*
        </tr>
    }xmsg;
    ## use critic(ComplexRegexes)
    $self->clear_all_plural_forms_html;
    my %all_plural_forms;
    while ( my ($iso, $english_name, $plural_forms) = splice @match, 0, 3 ) { ## no critic (MagicNumbers)
        $english_name =~ s{ \s+ \z }{}xms;
        $all_plural_forms{ decode_entities($iso) } = {
            english_name => decode_entities($english_name),
            plural_forms => decode_entities($plural_forms),
        };
    }

    return \%all_plural_forms;
}

sub _language {
    my ($self, $language) = @_;

    my $all_plural_forms = $self->all_plural_forms;
    if ( exists $all_plural_forms->{$language} ) {
        return $self->plural_forms(
            $all_plural_forms->{$language}->{plural_forms}
        );
    }
    $language =~ s{_ .* \z}{}xms;
    if ( exists $all_plural_forms->{$language} ) {
        return $self->plural_forms(
            $all_plural_forms->{$language}->{plural_forms}
        );
    }

    return confess
        "Missing plural forms for language $language in all_plural_forms";
}

sub _calculate_plural_forms {
    my $self = shift;

    my $plural_forms = $self->plural_forms;
    $plural_forms =~ s{\b ( nplurals | plural | n ) \b}{\$$1}xmsg;
    my $safe = Safe->new;
    my $nplurals_code = <<"EOC";
        my \$n = 0;
        my (\$nplurals, \$plural);
        $plural_forms;
        \$nplurals;
EOC
    $self->_nplurals(
        $safe->reval($nplurals_code)
        or confess
            "Code of Plural-Forms $plural_forms is not safe, $EVAL_ERROR"
    );
    my $plural_code = <<"EOC";
        sub {
            my \$n = shift;
            my (\$nplurals, \$plural);
            $plural_forms;
            return \$plural || 0;
        }
EOC
    $self->_plural_code(
        $safe->reval($plural_code)
        or confess "Code $plural_forms is not safe, $EVAL_ERROR"
    );

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Locale::Utils::PluralForms - Utils to use plural forms

$Id: PluralForms.pm 382 2011-11-13 13:20:22Z steffenw $

$HeadURL: https://perl-gettext-oo.svn.sourceforge.net/svnroot/perl-gettext-oo/Locale-Utils-PluralForms/trunk/lib/Locale/Utils/PluralForms.pm $

=head1 VERSION

0.002

=head1 SYNOPSIS

    use Locale::Utils::PluralForms;

    my $obj = Locale::Utils::PluralForms->new;

Data downloaded from web

    $obj = Locale::Utils::PluralForms->new(
        language => 'en_GB', # fallbacks from given en_GB to en
    );

Data of given data structure

    $obj = Locale::Utils::PluralForms->new(
        all_plural_forms => {
            'en' => {
                english_name => 'English',
                plural_forms => 'nplurals=2; plural=(n != 1)',
            },
            # next languages
        },
    );

Getter

    my $language         = $obj->language;
    my $all_plural_forms = $obj->all_plural_forms;
    my $plural_forms     = $obj->plural_forms;
    my $nplurals         = $obj->nplurals;
    my $plural_code      = $obj->plural_code;
    my $plural           = $obj->plural_code->($number);

=head1 DESCRIPTION

=head2 Find plural forms for the language

This module helps to find the plural forms for all languages.
It downloads the plural forms for all languages from web.
Then it stores the extracted data
into a data structure named "all_plural_forms".

It is possible to fill that data structure
before method "language" is called first time
or to cache after first method call "language".

=head2 "plural" as subroutine

In the header of a PO- or MO-File
is an entry is called "Plural-Forms".
How many plural forms the language has, is described there in "nplurals".
The second Information in "Plural-Forms" describes as a formula,
how to choose the "plural".

This module compiles plural forms
to a code references in a secure way.

=head1 SUBROUTINES/METHODS

=head2 Find plural forms for the language

=head3 method language

Set the language to switch to the plural forms of that language.
"plural_forms" is set then and "nplurals" and "plural_code" will be calculated.

    $obj->language('de_AT'); # A fallback finds plural forms of language de
                             # because de_AT is not different.

Read the language back.

    $obj->language eq 'de_AT';

=head3 method all_plural_forms

Set the data structure.

    $obj->all_plural_forms({
        'de' => {
            english_name => 'German',
            plural_forms => 'nplurals=2; plural=(n != 1)',
        },
        # next languages
    });

Read the data structure back.

    my $hash_ref = $obj->all_plural_forms;

=head2 executable plural forms

=head3 method plural_forms

Set "plural_forms" if no "language" is set.
After that "nplurals" and "plural_code" will be calculated in a safe way.

    $obj->plural_forms('nplurals=1; plural=0');

Or read it back.

    my $plural_forms = $obj->plural_forms;

=head3 method nplurals

This method get back the calculated count of plurals.

If no "language" and no "plural_forms" is set,
the defaults for "nplurals" is:

    my $count = $obj->nplurals # returns: 1

There is no public setter for "nplurals"
and it is not possible to set them in the constructor.
Call method "language" or "plural_forms"
or set attribute "language" or "plural_forms" in the constructor.
After that "nplurals" will be calculated automaticly and safe.

=head2 method plural_code

This method get back the calculated code for the "plural"
to choose the correct "plural".

If no "language" and no "plural_forms" is set,
the defaults for plural_code is:

    my $code_ref = $obj->plural_code # returns: sub { return 0 }
    my $plural   = $obj->plural_code->($number); # returns 0

There is no public setter for "plural_code"
and it is not possible to set them in the constructor.
Call method "language" or "plural_forms"
or set attribute "language" or "plural_forms" in the constructor.
After that "plural_code" will be calculated automaticly and safe.

For the example plural forms C<'nplurals=2; plural=(n != 1)'>:

    $plural = $obj->plural_code->(0), # $plural is 1
    $plural = $obj->plural_code->(1), # $plural is 0
    $plural = $obj->plural_code->(2), # $plural is 1
    $plural = $obj->plural_code->(3), # $plural is 1
    ...

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run the *.pl files.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Moose|Moose>

L<MooseX::StrictConstructor|MooseX::StrictConstructor>

L<namespace::autoclean|namespace::autoclean>

L<English|English>

L<HTML::Entities|HTML::Entities>

L<LWP::UserAgent|LWP::UserAgent>

L<Safe|Safe>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

not known

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Gettext>

L<http://docs.translatehouse.org/projects/localization-guide/en/latest/l10n/pluralforms.html>

L<Locele::TextDomain|Locele::TextDomain>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 - 2017,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
