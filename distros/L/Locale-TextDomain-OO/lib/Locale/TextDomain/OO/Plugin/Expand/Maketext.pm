package Locale::TextDomain::OO::Plugin::Expand::Maketext; ## no critic (TidyCode)

use strict;
use warnings;
use Locale::Utils::PlaceholderMaketext;
use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.009';

requires qw(
    translate
    filter
    run_filter
);

has expand_maketext => (
    is      => 'rw',
    default => sub {
        return Locale::Utils::PlaceholderMaketext->new;
    },
);

sub maketext {
    my ($self, $msgid, @args) = @_;

    my $translation = $self->translate(undef, $msgid);
    $translation = $self->expand_maketext->expand_maketext(
        $translation,
        @args,
    );
    $self->filter
        and $self->run_filter(\$translation);

    return $translation;
}

sub maketext_p {
    my ($self, $msgctxt, $msgid, @args) = @_;

    my $translation = $self->translate($msgctxt, $msgid);
    $translation = $self->expand_maketext->expand_maketext(
        $translation,
        @args,
    );
    $self->filter
        and $self->run_filter(\$translation);

    return $translation;
}

BEGIN {
    no warnings qw(redefine); ## no critic (NoWarnings)

    # Dummy methods for string marking.
    my $dummy = sub {
        my (undef, @more) = @_;
        return wantarray ? @more : $more[0];
    };
    *Nmaketext   = $dummy;
    *Nmaketext_p = $dummy;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Plugin::Expand::Maketext - Additional maketext methods

$Id: Maketext.pm 487 2014-02-03 14:31:43Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Plugin/Expand/Maketext.pm $

=head1 VERSION

1.009

=head1 DESCRIPTION

This module provides additional maketext methods
like L<Locale::Maketext::Simple|Locale::Maketext::Simple>
to run that on projects
that use L<Locale::Maketext|Locale::Maketext> at the moment.

To run maketext with different context (msgctxt)
run method maketext_p.

=head1 SYNOPSIS

    my $loc = Locale::Text::TextDomain::OO->new(
        plugins => [ qw (
            Expand::Maketext
            ...
        )],
        ...
    );

Optional type formatting see
L<Locale::Utils::PlaceholderMaketext|Locale::Utils::PlaceholderMaketext>
for possible methods.

    $loc->expand_maketext->formatter_code($code_ref);

=head1 SUBROUTINES/METHODS

=head2 method expand_maketext

Returns the Locale::Utils::PlaceholderMaketext object
to be able to set some options.

    my $expander_object = $self->expand_maketext;

=head2 translation methods

=head3 method maketext

This method includes the expansion as 'quant' or '*'.

    print $loc->maketext(
        'Hello World!',
    );

    print $loc->maketext(
        'Hello [_1]!',
        'Steffen',
    );

    print $loc->maketext(
        '[quant,_1,file read,files read]',
        $num_files,
    );


=head3 method maketext_p (allows the context)

    print $loc->maketext_p (
        'time',
        'to',
    );

    print $loc->maketext_p (
        'destination',
        'to',
    );

    print $loc->maketext_p (
        'destination',
        'from [_1] to [_2]',
        'Chemnitz',
        'Erlangen',
    );

    print $loc->maketext_p(
        'maskulin',
        'Mr. [_1] has [*,_2,book,books].',
        $name,
        $books,
    );

=head3 methods Nmaketext, Nmaketext_p

The extractor looks for C<maketext('...>
and has no problem with C<<$loc->Nmaketext('...>>.

This is the idea of the N-Methods.

    $loc->Nmaketext('...');
    $loc->Nmaketext_p('...', '...');

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Locale::Utils::PlaceholderMaketext|Locale::Utils::PlaceholderMaketext>

L<Moo::Role|Moo::Role>

L<namespace::autoclean|namespace::autoclean>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 - 2014,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
