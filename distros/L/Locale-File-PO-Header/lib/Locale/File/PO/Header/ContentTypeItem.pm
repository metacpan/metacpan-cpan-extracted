package Locale::File::PO::Header::ContentTypeItem; ## no critic (TidyCode)

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
    isa     => 'HashRef',
    trigger => sub {
        my ($self, $arg_ref) = @_;

        $self->default_content_type( $arg_ref->{'Content-Type'} );
        $self->default_charset( $arg_ref->{charset} );

        return $arg_ref;
    },
);

has default_content_type => (
    is  => 'rw',
    isa => 'Str',
);

has default_charset => (
    is  => 'rw',
    isa => 'Str',
);

has content_type => (
    is      => 'rw',
    isa     => 'Str|Undef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return $self->default_content_type;
    },
    trigger => sub {
        my ($self, $content_type, $current_content_type) = @_;

        return $self->trigger_helper({
            new     => $content_type,
            current => $current_content_type,
            default => scalar $self->default_content_type,
            writer  => 'content_type',
        });
    },
);

has charset => (
    is      => 'rw',
    isa     => 'Str|Undef',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return $self->default_charset;
    },
    trigger => sub {
        my ($self, $charset, $current_charset) = @_;

        return $self->trigger_helper({
            new     => $charset,
            current => $current_charset,
            default => scalar $self->default_charset,
            writer  => 'charset',
        });
    },
);

sub header_keys {
    my $self = shift;

    return $self->name, 'charset';
}

sub data {
    my ($self, $key, @args) = @_;

    defined $key
        or confess 'Undefined key';
    my $value = @args ? $args[0] : ();
    if ( $key eq 'Content-Type' ) {
        return
            @args
            ? (
                $self->content_type( # set
                    ref $value eq 'HASH'
                    ? $value->{$key}
                    : $value
                )
            )
            : $self->content_type; # get
    }
    if ( $key eq 'charset' ) {
        return
            @args
            ? (
                $self->charset( # set
                    ref $value eq 'HASH'
                    ? $value->{$key}
                    : $value
                )
            )
            : $self->charset; # get
    }

    confess "Unknown key $key";
}

sub extract_msgstr {
    my ($self, $msgstr_ref) = @_;

    ${$msgstr_ref} =~ s{
        ^
        Content-Type :
        \s*
        ( [^;\n]*? ) ;
        \s*
        charset = ( \S* )
        \s*
        $
    }{}xmsi;
    $self->content_type($1); ## no critic (CaptureWithoutTest)
    $self->charset($2);      ## no critic (CaptureWithoutTest)

    return;
}

sub lines {
    my $self = shift;

    return $self->format_line(
        '{name}: {content_type}; charset={charset}',
        name         => $self->name,
        content_type => $self->content_type,
        charset      => $self->charset,
    );
}

__PACKAGE__->meta->make_immutable;

# $Id: Utils.pm 602 2011-11-13 13:49:23Z steffenw $

1;
