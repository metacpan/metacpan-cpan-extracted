# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Perl module to provide generic, language independent, interfaces to language data


package Lingua::Generic::Interface;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.30;
use Data::Identifier::Generate;

our $VERSION = v0.03;


#@returns Lingua::Generic::Interface::Word
sub new_word {
    my ($pkg, $language, $string, @opts) = @_;
    my $ret;

    croak 'Stray options passed' if scalar @opts;

    $language = _make_language($language);

    if (defined($language)) {
        if ($language->eq('1d668738-8aef-4cb4-a4ed-9368e872a93f')) {
            return Lingua::famibeib::Word->new(string => $string) if state $have_famibeib = eval {require Lingua::famibeib::Word};
        } elsif ($language->eq('f21986c8-baa1-5b7e-b357-2a76285c4778')) {
            return Lingua::TokiPona::Word->new(string => $string) if state $have_TokiPona = eval {require Lingua::TokiPona::Word};
        } elsif ($language->eq('8ca63437-1b1e-4a85-8512-02ba5c15a412')) {
            return Lingua::Lapine::Word->new(string => $string) if state $have_Lapine = eval {require Lingua::Lapine::Word};
        }
    }

    $ret = Lingua::Generic::Interface::_IMPL::GenericWord->new(string => $string);
    $ret->{natural_language} = $language;
    return $ret;
}

package Lingua::Generic::Interface::_IMPL::GenericWord {
    use parent 'Lingua::Generic::Interface::Word';
    use Carp;

    sub natural_language {
        my ($self, @opts) = @_;

        croak 'Stray options passed' if scalar @opts;
        return $self->{natural_language} // croak 'Unknown language';
    }
}


#@returns Lingua::Generic::Interface::Modifier
sub new_modifier {
    my ($pkg, $language, $input, @opts) = @_;
    my $string;
    my $id;
    my $ret;

    croak 'Stray options passed' if scalar @opts;

    if (ref $input) {
        $id = Data::Identifier->new(from => $input);
    } else {
        $string = $input;
    }

    $ret = bless {
        string => $string,
        id => $id,
    }, 'Lingua::Generic::Interface::_IMPL::GenericModifier';
    $ret->{natural_language} = _make_language($language);
    return $ret;
}

package Lingua::Generic::Interface::_IMPL::GenericModifier {
    use parent 'Lingua::Generic::Interface::Modifier';

    *natural_language = *Lingua::Generic::Interface::_IMPL::GenericWord::natural_language;

    sub eq {
        my ($self, $other, @opts) = @_;
        if (eval{$other->isa(__PACKAGE__)} && $self->isa(__PACKAGE__)) {
            if (defined($self->{id}) && defined($other->{id})) {
                return $self->{id}->eq($other->{id});
            }
        }
        return $self->SUPER::eq($other, @opts);
    }

    sub as {
        my ($self, $as, @opts) = @_;

        if (defined(my Data::Identifier $id = $self->{id})) {
            return $id if $as eq 'Data::Identifier' && scalar(@opts) == 0;
            return $id->as($as, @opts);
        }

        return $self->SUPER::as($as, @opts);
    }

    sub ise {
        my ($self, @opts) = @_;
        return $self->{id}->ise(@opts);
    }

    sub displayname {
        my ($self, @opts) = @_;

        if (defined($self->{id}) && !defined($self->{string})) {
            return $self->{id}->displayname(@opts);
        }

        return $self->SUPER::displayname(@opts);
    }
}


#@returns Lingua::Generic::Interface::Fragment
sub new_fragment {
    my ($pkg, $language, $input, @opts) = @_;
    my $string;
    my $id;
    my $ret;
    my @words;

    croak 'Stray options passed' if scalar @opts;

    if (ref $input) {
        @words = grep {$_->isa('Lingua::Generic::Interface::Word') or croak 'Invalid input'} @{$input};
    } elsif ($input =~ /^(?:[a-zA-Z\N{U+00E4}\N{U+00F6}\N{U+00FC}\N{U+00DF}\N{U+00E9}]+\s+)*[a-zA-Z\N{U+00E4}\N{U+00F6}\N{U+00FC}\N{U+00DF}\N{U+00E9}]+\z/i) {
        @words = map {$pkg->new_word($language => $_)} split /\s+/, $input;
    } else {
        croak 'Invalid input';
    }

    $ret = bless {
        words => \@words,
    }, 'Lingua::Generic::Interface::_IMPL::GenericFragmentOfWords';
    $ret->{natural_language} = _make_language($language);
    return $ret;
}
package Lingua::Generic::Interface::_IMPL::GenericFragmentOfWords {
    use parent 'Lingua::Generic::Interface::Fragment';
    use Carp;

    sub words {
        my ($self, @opts) = @_;
        croak 'Stray options passed' if scalar @opts;
        return @{$self->{words}};
    }

    sub natural_language {
        my ($self, @opts) = @_;

        croak 'Stray options passed' if scalar @opts;
        return $self->{natural_language} // $self->SUPER::natural_language(@opts);
    }
}

# ---- Private helpers ----
sub _make_language {
    my ($language) = @_;

    if (defined $language) {
        if (ref $language) {
            return Data::Identifier->new(from => $language)->null_to_undef;
        } else {
            if ($language eq 'tok') {
                # workaround for I18N::LangTags::List
                return state $tok = do {
                    eval { Data::Identifier::Generate->language('tok') }; # try to, maybe it is fixed at some point
                    Data::Identifier->new(uuid => 'f21986c8-baa1-5b7e-b357-2a76285c4778')->register;
                };
            }
            return Data::Identifier::Generate->language($language);
        }
    }

    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Generic::Interface - Perl module to provide generic, language independent, interfaces to language data

=head1 VERSION

version v0.03

=head1 SYNOPSIS

    use Lingua::Generic::Interface;

=head1 METHODS

=head2 new_word

    my Lingua::Generic::Interface::Word $word = Lingua::Generic::Interface->new_word($language, $string);
    # e.g.:
    my Lingua::Generic::Interface::Word $word = Lingua::Generic::Interface->new_word(de => 'Haus');

(experimental since v0.03)

Creates a word object using the given language and string.

This should only be used as a fallback in case no specific module for the given language is known/available.

The language can be given as a language tag (e.g. C<de>), or as a anything L<Data::Identifier/new> accepts via C<from>, or as C<undef>.
The L<Data::Identifier> of the language might or might not be cached and/or registered by this call.

This method may try to load a language support module specific to the given language.

=head2 new_modifier

    my Lingua::Generic::Interface::Modifier $modifier = Lingua::Generic::Interface->new_modifier($language, $input);

(experimental since v0.03)

This method is B<highly experimental>.

The language is given as per L</new_word>.

=head2 new_fragment

    my Lingua::Generic::Interface::Fragment $fragment = Lingua::Generic::Interface->new_fragment($language, $words);

(experimental since v0.03)

This method is B<highly experimental>.

The language is given as per L</new_word>.
If no language is given, it is tried to be computed from the given words.

C<$words> must be an array reference to values of type L<Lingua::Generic::Interface::Word>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
