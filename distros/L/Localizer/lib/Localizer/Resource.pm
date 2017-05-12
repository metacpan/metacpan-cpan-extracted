package Localizer::Resource;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Localizer::Style::Gettext;
use Localizer::BuiltinFunctions;

our $BUILTIN_FUNCTIONS = {
    numf     => \&Localizer::BuiltinFunctions::numf,
    numerate => \&Localizer::BuiltinFunctions::numerate,
    quant    => \&Localizer::BuiltinFunctions::quant,
    sprintf  => \&Localizer::BuiltinFunctions::sprintf,
};

use Class::Accessor::Lite 0.05 (
    rw => [qw(dictionary compiled precompile style functions)],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;

    unless (exists $args{dictionary}) {
        Carp::confess("Missing mandatory parameter: dictionary");
    }

    $args{style} ||= Localizer::Style::Gettext->new();

    my $functions = do {
        if (exists $args{functions}) {
            +{
                %$BUILTIN_FUNCTIONS,
                %{delete $args{functions}},
            };
        } else {
            $BUILTIN_FUNCTIONS
        }
    };

    my $self = bless {
        compiled   => +{},
        precompile => 1,
        functions  => $functions,
        %args,
    }, $class;

    # Compile dictionary data to CodeRef or ScalarRef
    if ($self->precompile) {
        for my $msgid (keys %{$self->dictionary}) {
            $self->_compile($msgid);
        }
    }

    return $self;
}

sub maketext {
    my ($self, $msgid, @args) = @_;

    my $compiled = $self->_compile($msgid);
    return unless defined $compiled;

    if (ref $compiled eq 'CODE') {
        return $compiled->($self, @args);
    } elsif (ref $compiled eq 'SCALAR') {
        return $$compiled;
    } else {
        die "SHOULD NOT REACH HERE";
    }
}

sub _compile {
    my ($self, $msgid) = @_;

    if (my $code = $self->compiled->{$msgid}) {
        return $code;
    }

    my $fmt = $self->dictionary->{$msgid};
    return unless $fmt;
    my $code = $self->style->compile($msgid, $fmt, $self->functions);
    $self->compiled->{$msgid} = $code;
    return $code;
}

1;

__END__

=for stopwords ja.properties precompile precompiles localizer maketext

=encoding utf-8

=head1 NAME

Localizer::Resource - Interface to manipulate Localizer

=head1 SYNOPSIS

    use Localizer::Resource;
    use Localizer::Style::Gettext;
    use Config::Properties;

    my $ja = Localizer::Resource->new(
        dictionary => +{ Config::Properties->new(
            file => 'ja.properties'
        )->properties },
        format => Localizer::Style::Gettext->new(),
        functions => {
            dubbil => sub { return $_[0] * 2 },
        },
    );
    say $ja->maketext("Hi, %1.", "John");        # => こんにちは、John。
    say $ja->maketext("Double: %dubbil(%1)", 7); # => 2倍: 14

Example of contents of ja.properties, like so;

    Hi,\ %1.=こんにちは、%1。
    Double\:\ %dubbil(%1)=2倍:\ %dubbil(%1)

=head1 DESCRIPTION

L<Localizer> is the yet another framework for localization. It is more simple than past localization framework.

This module is the interface to manipulate L<Localizer>.

=head1 METHODS

=over 4

=item * Localizer::Resource->new(%args | \%args)

Constructor. It makes Localizer client with C<%args>.

e.g.

    my $de = Localizer::Resource->new(
        dictionary => {
            'Hello, World!' => 'Hello, Welt!'
        }
        format => Localizer::Style::Gettext->new(),
        functions => {
            dubbil => sub { return $_[0] * 2 },
        },
        precompile => 0,
    );

=over 8

=item dictionary: Hash Reference

Dictionary data to localize.

=item format: Instance of Style Class

Format of dictionary. Now this module supports L<Localizer::Style::Gettext> (Gettext style) and L<Localizer::Style::Maketext> (Maketext style). Default value is L<Localizer::Style::Gettext>.

=item functions: Hash Reference

Register functions to call by dictionary. Please see also L<Localizer::Style::Gettext> and L<Localizer::Style::Maketext>.

=item precompile: Scalar Value

It precompiles dictionary data if this value is true. Default value is 1 (means always precompile).

=back

=item * $localizer->maketext($key);

Localize by dictionary data with key. If you give nonexistent key to this method, it returns undef.

=back

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

