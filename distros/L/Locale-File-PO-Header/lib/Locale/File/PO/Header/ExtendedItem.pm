package Locale::File::PO::Header::ExtendedItem; ## no critic (TidyCode)

use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Clone qw(clone);

our $VERSION = '0.004';

extends qw(Locale::File::PO::Header::Base);

has name => (
    is  => 'rw',
    isa => 'Str',
);

subtype ExtendedArray => as 'ArrayRef[Str]' => where {
    @{$_} % 2 == 0;
};

has extended => (
    is  => 'rw',
    isa => 'ExtendedArray|Undef',
);

sub data {
    my ($self, $key, @args) = @_;

    return $self->extended( @args ? $args[0] : () );
}

sub extract_msgstr {
    my ($self, $msgstr_ref) = @_;

    my @extended;
    while (
        ${$msgstr_ref} =~ s{
            ^
            ( [^:\n]*? ) :
            \s*
            ( [^\n]*? )
            \s*
            $
        }{}xms
    ) {
        push @extended, $1, $2;
    }
    $self->extended( @extended ? \@extended : undef );

    return;
}

sub lines {
    my $self = shift;

    my $extended = $self->extended;
    defined $extended
        or return;

    $extended = clone($extended);
    my @lines;
    while ( my ($name, $value) = splice @{$extended}, 0, 2 ) {
        push @lines, $self->format_line(
            '{name}: {value}',
            name  => $name,
            value => $value,
        );
    }

    return @lines;
}

__PACKAGE__->meta->make_immutable;

# $Id:$

1;
