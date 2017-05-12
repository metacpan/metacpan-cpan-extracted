package Locale::File::PO::Header::MailItem; ## no critic (TidyCode)

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;
use syntax qw(method);

our $VERSION = '0.001';

extends qw(Locale::File::PO::Header::Base);

has name => (
    is  => 'rw',
    isa => 'Str',
);

has mail_name => (
    is      => 'rw',
    isa     => 'Str|Undef',
    default => q{},
    trigger => method ($mail_name, $current_mail_name) {
        $self->trigger_helper({
            new     => $mail_name,
            current => $current_mail_name,
            default => q{},
            writer  => 'mail_name',
        });
    },
);

has mail_address => (
    is      => 'rw',
    isa     => 'Str|Undef',
    default => q{},
    trigger => method ($mail_address, $current_mail_address) {
        $self->trigger_helper({
            new     => $mail_address,
            current => $current_mail_address,
            default => q{},
            writer  => 'mail_address',
        });
    },
);

method header_keys {
    my $name = $self->name;
    return "${name}_name", "${name}_address";
}

method data ($key, @args) {
    defined $key
        or confess 'Undefined key';
    my $value = @args ? $args[0] : ();
    if ( $key =~ m{ _name \z }xms ) {
        return
            @args
            ? $self->mail_name( # set
                ref $value eq 'HASH'
                ? $value->{name}
                : $value
            )
            : $self->mail_name; # get
    }
    if ( $key =~ m{ _address \z }xms ) {
        return
            @args
            ? $self->mail_address( # set
                ref $value eq 'HASH'
                ? $value->{address}
                : $value
            )
            : $self->mail_address; #get
    }

    confess "Unknown key $key";
}

method extract_msgstr ($msgstr_ref) {
    my $name = $self->name;
    ${$msgstr_ref} =~ s{
        ^
        \Q$name\E :
        \s*
        ( [^<\n]*? )
        \s+
        < ( [^>\n]*? ) >
        \s*
        $
    }{}xmsi
    || ${$msgstr_ref} =~ s{
        ^
        \Q$name\E :
        \s*
        ( [^\n]*? )
        ()
        \s*
        $
    }{}xmsi;
    $self->mail_name($1);    ## no critic (CaptureWithoutTest)
    $self->mail_address($2); ## no critic (CaptureWithoutTest)

    return;
};

method lines {
    if ( ! length $self->mail_name && ! length $self->mail_address ) {
        return;
    }
    my $line = $self->format_line(
        '{name}: {mail_name} <{mail_address}>',
        name         => $self->name,
        mail_name    => $self->mail_name,
        mail_address => $self->mail_address,
    );
    $line =~ s{\s* <> \z}{}xms; # delete an empty mail address
    $line =~ s{\s+}{ }xmsg;     # delete space before a mail address

    return $line;
}

__PACKAGE__->meta->make_immutable;

# $Id: Utils.pm 602 2011-11-13 13:49:23Z steffenw $

1;
