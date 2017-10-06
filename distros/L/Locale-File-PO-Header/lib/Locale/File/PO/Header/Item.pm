package Locale::File::PO::Header::Item; ## no critic (TidyCode)

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

our $VERSION = '0.004';

extends qw(Locale::File::PO::Header::Base);

has name => (
    is  => 'rw',
    isa => 'Str',
);

has default => (
    is      => 'rw',
    isa     => 'Str',
    default => q{},
);

has item => (
    is      => 'rw',
    isa     => 'Str|Undef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return $self->default;
    },
    trigger => sub {
        my ($self, $item, $current_item) = @_;

        return $self->trigger_helper({
            new     => $item,
            current => $current_item,
            default => scalar $self->default,
            writer  => 'item',
        });
    },
);

sub data {
    my ($self, $key, @args) = @_;

    return $self->item( @args ? $args[0] : () );
}

sub extract_msgstr {
    my ($self, $msgstr_ref) = @_;

    my $name = $self->name;
    ${$msgstr_ref} =~ s{
        ^
        \Q$name\E :
        \s*
        ( [^\n]*? )
        \s*
        $
    }{}xmsi;
    $self->item($1); ## no critic (CaptureWithoutTest)

    return;
};

sub lines {
    my $self = shift;

    length $self->item
        or return;

    return $self->format_line(
        '{name}: {item}',
        name => $self->name,
        item => $self->item,
    );
}

__PACKAGE__->meta->make_immutable;

# $Id: Utils.pm 602 2011-11-13 13:49:23Z steffenw $

1;
