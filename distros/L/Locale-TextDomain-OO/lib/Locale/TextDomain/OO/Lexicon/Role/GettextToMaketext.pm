package Locale::TextDomain::OO::Lexicon::Role::GettextToMaketext; ## no critic (TidyCode)

use strict;
use warnings;
use Locale::Utils::PlaceholderMaketext;
use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.000';

sub gettext_to_maketext {
    my ($self, $messages_ref) = @_;

    my $formatter = Locale::Utils::PlaceholderMaketext->new;
    for my $value ( @{$messages_ref} ) {
        for ( qw( msgid msgstr ) ) {
            if ( exists $value->{$_} ) {
                $value->{$_}
                    = $formatter->gettext_to_maketext( $value->{$_} );
            }
        }
    }

    return $self;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::Lexicon::Role::GettextToMaketext - Style formatter

$Id: GettextToMaketext.pm 413 2013-10-27 13:12:20Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/Lexicon/Role/GettextToMaketext.pm $

=head1 VERSION

1.000

=head1 DESCRIPTION

This module provides a method to format from gettext style into maketext style.

=head1 SYNOPSIS

    with qw(
        Locale::TextDomain::OO::Lexicon::Role::GettextToMaketext
    );

=head1 SUBROUTINES/METHODS

=head2 method gettext_to_maketext

Formats msgid and msgstr if exists from gettext style into maketext style.

    $self->gettext_to_maketext($messages_ref);

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

none

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

Copyright (c) 2013,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
