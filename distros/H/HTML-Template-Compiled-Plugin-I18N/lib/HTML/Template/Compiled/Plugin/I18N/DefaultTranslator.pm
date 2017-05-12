package HTML::Template::Compiled::Plugin::I18N::DefaultTranslator;

use strict;
use warnings;

use Carp qw(croak);
use HTML::Template::Compiled::Plugin::I18N;

our $VERSION = '1.02';

my $escape_ref = sub {
    my $string = shift;

    defined $string
        and return $string;

    return 'undef';
};

sub set_escape {
    my (undef, $code_ref) = @_;

    ref $code_ref eq 'CODE'
        or croak 'Coderef expected';
    $escape_ref = $code_ref;

    return;
}

sub get_escape {
    return $escape_ref;
}

sub translate {
    my (undef, $attr_ref) = @_;

    if ( exists $attr_ref->{escape} ) {
        my $escape = delete $attr_ref->{escape};
        ESCAPE_SCALAR:
        for ( qw(text plural) ) {
            exists $attr_ref->{$_}
                or next ESCAPE_SCALAR;
            $attr_ref->{$_} = HTML::Template::Compiled::Plugin::I18N->escape(
                $attr_ref->{$_},
                $escape,
            );
        }
        ESCAPE_ARRAYREF:
        for ( qw(maketext) ) {
            exists $attr_ref->{$_}
                or next ESCAPE_ARRAYREF;
            for my $value ( @{ $attr_ref->{$_} } ) {
                $value = HTML::Template::Compiled::Plugin::I18N->escape(
                    $value,
                    $escape,
                );
            }
        }
        ESCAPE_HASHREF:
        for ( qw(gettext) ) {
            exists $attr_ref->{$_}
                or next ESCAPE_HASHREF;
            for my $value ( values %{ $attr_ref->{$_} } ) {
                $value = HTML::Template::Compiled::Plugin::I18N->escape(
                    $value,
                    $escape,
                );
            }
        }
    }

    return join q{;}, map {
        exists $attr_ref->{$_}
        ? (
            "$_="
            . join q{,}, map {
                __PACKAGE__->get_escape()->($_);
            } (
                ref $attr_ref->{$_} eq 'ARRAY'
                ? @{ $attr_ref->{$_} }
                : ref $attr_ref->{$_} eq 'HASH'
                ? do {
                    my $key = $_;
                    map {
                        ( $_, $attr_ref->{$key}->{$_} );
                    } sort keys %{ $attr_ref->{$key} };
                }
                : $attr_ref->{$_}
            )
        )
        : ();
    } qw(
        context text plural count maketext gettext formatter unescaped
    );
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::I18N::DefaultTranslator
- an extremly simple translater class for the HTC plugin I18N

$Id: DefaultTranslator.pm 161 2009-12-03 09:05:54Z steffenw $

$HeadURL: https://htc-plugin-i18n.svn.sourceforge.net/svnroot/htc-plugin-i18n/trunk/lib/HTML/Template/Compiled/Plugin/I18N/DefaultTranslator.pm $

=head1 VERSION

1.02

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is very useful to run the application
before the real translator module has been finished.

The I18N plugin calls the class method translate of the translator class.
The given parameter is a hash reference of scalars, array or hash references.
The translator has to run the given escape code reference for all values.
To see the struct of the rest of this hash reference
the default translator simplifies to

 scalar=value;array=value1,value2;hash=key1,value1

Then the output is human readable.

There is only a simple problem with undefs.
Therefore the default translator has an extra escape.

=head1 SUBROUTINES/METHODS

=head2 class method set_escape

Set an escape code reference to run an extra escape for all the values.
The example describes the default to have no undefined values
in the maketext array reference or in the gettext hash.

    HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->set_escape(
        sub {
            my $string = shift;

            defined $string
                and return $string;

            return 'undef';
        },
    );

=head2 class method get_escape

Get back the current escape code reference for extra escape.

   $code_ref
       = HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->get_escape();

=head2 class method translate

Possible hash keys are

    context   (optional string)
    text      (string)
    plural    (optional string)
    count     (optional unsigned integer)
    maketext  (optional array reference)
    gettext   (optional hash reference)
    formatter (optional array reference)
    escape    (optional code reference)

The scalar values are defined or the hash key does not exists.
The array and hash references are references or the hash key does not exists.

    $string
        = HTML::Template::Compiled::Plugin::I18N::DefaultTranslator->translate({
            text => 'text',
            ...
        });

After a translation text and plural have to escape.

=head1 DIAGNOSTICS

none

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

Carp

=head1 INCOMPATIBILITIES

The output is not readable by a parser
but very good human readable during the application development.

=head1 BUGS AND LIMITATIONS

not known

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut