package Locale::File::PO::Header::ExtendedItem; ## no critic (TidyCode)

use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

use namespace::autoclean;
use syntax qw(method);

use Clone qw(clone);

our $VERSION = '0.001';

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

method data ($key, @args) {
    return $self->extended( @args ? $args[0] : () );
}

method extract_msgstr ($msgstr_ref) {
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

method lines {
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
