package File::KDBX::Loader::XML;
# ABSTRACT: Load unencrypted XML KeePass files

use warnings;
use strict;

use Crypt::Misc 0.029 qw(decode_b64);
use Encode qw(decode);
use File::KDBX::Constants qw(:version :time);
use File::KDBX::Error;
use File::KDBX::Safe;
use File::KDBX::Util qw(:class :int :text gunzip erase_scoped);
use Scalar::Util qw(looks_like_number);
use Time::Piece 1.33;
use XML::LibXML::Reader;
use boolean;
use namespace::clean;

extends 'File::KDBX::Loader';

our $VERSION = '0.906'; # VERSION

has '_reader',  is => 'ro';
has '_safe',    is => 'ro', default => sub { File::KDBX::Safe->new(cipher => $_[0]->kdbx->random_stream) };

sub _read {
    my $self = shift;
    my $fh   = shift;

    $self->_read_inner_body($fh);
}

sub _read_inner_body {
    my $self = shift;
    my $fh   = shift;

    my $reader = $self->{_reader} = XML::LibXML::Reader->new(IO => $fh);

    delete $self->{_safe};
    my $root_done;

    my $pattern = XML::LibXML::Pattern->new('/KeePassFile/Meta|/KeePassFile/Root');
    while ($reader->nextPatternMatch($pattern) == 1) {
        next if $reader->nodeType != XML_READER_TYPE_ELEMENT;
        my $name = $reader->localName;
        if ($name eq 'Meta') {
            $self->_read_xml_meta;
        }
        elsif ($name eq 'Root') {
            if ($root_done) {
                alert 'Ignoring extra Root element in KeePass XML file', line => $reader->lineNumber;
                next;
            }
            $self->_read_xml_root;
            $root_done = 1;
        }
    }

    if ($reader->readState == XML_READER_ERROR) {
        throw 'Failed to parse KeePass XML';
    }

    $self->kdbx->_safe($self->_safe) if $self->{_safe};

    $self->_resolve_binary_refs;
}

sub _read_xml_meta {
    my $self = shift;

    $self->_read_xml_element($self->kdbx->meta,
        Generator                   => 'text',
        HeaderHash                  => 'binary',
        DatabaseName                => 'text',
        DatabaseNameChanged         => 'datetime',
        DatabaseDescription         => 'text',
        DatabaseDescriptionChanged  => 'datetime',
        DefaultUserName             => 'text',
        DefaultUserNameChanged      => 'datetime',
        MaintenanceHistoryDays      => 'number',
        Color                       => 'text',
        MasterKeyChanged            => 'datetime',
        MasterKeyChangeRec          => 'number',
        MasterKeyChangeForce        => 'number',
        MemoryProtection            => \&_read_xml_memory_protection,
        CustomIcons                 => \&_read_xml_custom_icons,
        RecycleBinEnabled           => 'bool',
        RecycleBinUUID              => 'uuid',
        RecycleBinChanged           => 'datetime',
        EntryTemplatesGroup         => 'uuid',
        EntryTemplatesGroupChanged  => 'datetime',
        LastSelectedGroup           => 'uuid',
        LastTopVisibleGroup         => 'uuid',
        HistoryMaxItems             => 'number',
        HistoryMaxSize              => 'number',
        SettingsChanged             => 'datetime',
        Binaries                    => \&_read_xml_binaries,
        CustomData                  => \&_read_xml_custom_data,
    );
}

sub _read_xml_memory_protection {
    my $self = shift;
    my $meta = shift // $self->kdbx->meta;

    return $self->_read_xml_element(
        ProtectTitle            => 'bool',
        ProtectUserName         => 'bool',
        ProtectPassword         => 'bool',
        ProtectURL              => 'bool',
        ProtectNotes            => 'bool',
        AutoEnableVisualHiding  => 'bool',
    );
}

sub _read_xml_binaries {
    my $self = shift;
    my $kdbx = $self->kdbx;

    my $binaries = $self->_read_xml_element(
        Binary  => sub {
            my $self = shift;
            my $id          = $self->_read_xml_attribute('ID');
            my $compressed  = $self->_read_xml_attribute('Compressed', 'bool', false);
            my $protected   = $self->_read_xml_attribute('Protected', 'bool', false);
            my $data        = $self->_read_xml_content('binary');

            my $binary = {
                value   => $data,
                $protected ? (protect => true) : (),
            };

            if ($protected) {
                # if compressed, decompress later when the safe is unlocked
                $self->_safe->add_protected($compressed ? \&gunzip : (), $binary);
            }
            elsif ($compressed) {
                $binary->{value} = gunzip($data);
            }

            $id => $binary;
        },
    );

    $kdbx->binaries({%{$kdbx->binaries}, %$binaries});
    return (); # do not add to meta
}

sub _read_xml_custom_data {
    my $self = shift;

    return $self->_read_xml_element(
        Item    => sub {
            my $self = shift;
            my $item = $self->_read_xml_element(
                Key                     => 'text',
                Value                   => 'text',
                LastModificationTime    => 'datetime',  # KDBX4.1
            );
            $item->{key} => $item;
        },
    );
}

sub _read_xml_custom_icons {
    my $self = shift;

    return $self->_read_xml_element([],
        Icon    => sub {
            my $self = shift;
            $self->_read_xml_element(
                UUID                    => 'uuid',
                Data                    => 'binary',
                Name                    => 'text',      # KDBX4.1
                LastModificationTime    => 'datetime',  # KDBX4.1
            );
        },
    );
}

sub _read_xml_root {
    my $self = shift;
    my $kdbx = $self->kdbx;

    my $root = $self->_read_xml_element(
        Group           => \&_read_xml_group,
        DeletedObjects  => \&_read_xml_deleted_objects,
    );

    $kdbx->deleted_objects($root->{deleted_objects});
    $kdbx->root($root->{group}) if $root->{group};
}

sub _read_xml_group {
    my $self = shift;

    return $self->_read_xml_element({entries => [], groups => []},
        UUID                    => 'uuid',
        Name                    => 'text',
        Notes                   => 'text',
        Tags                    => 'text',  # KDBX4.1
        IconID                  => 'number',
        CustomIconUUID          => 'uuid',
        Times                   => \&_read_xml_times,
        IsExpanded              => 'bool',
        DefaultAutoTypeSequence => 'text',
        EnableAutoType          => 'tristate',
        EnableSearching         => 'tristate',
        LastTopVisibleEntry     => 'uuid',
        CustomData              => \&_read_xml_custom_data, # KDBX4
        PreviousParentGroup     => 'uuid',  # KDBX4.1
        Entry                   => [entries => \&_read_xml_entry],
        Group                   => [groups  => \&_read_xml_group],
    );
}

sub _read_xml_entry {
    my $self = shift;

    my $entry = $self->_read_xml_element({strings => [], binaries => []},
        UUID                => 'uuid',
        IconID              => 'number',
        CustomIconUUID      => 'uuid',
        ForegroundColor     => 'text',
        BackgroundColor     => 'text',
        OverrideURL         => 'text',
        Tags                => 'text',
        Times               => \&_read_xml_times,
        AutoType            => \&_read_xml_entry_auto_type,
        PreviousParentGroup => 'uuid',  # KDBX4.1
        QualityCheck        => 'bool',  # KDBX4.1
        String              => [strings  => \&_read_xml_entry_string],
        Binary              => [binaries => \&_read_xml_entry_binary],
        CustomData          => \&_read_xml_custom_data, # KDBX4
        History             => sub {
            my $self = shift;
            return $self->_read_xml_element([],
                Entry   => \&_read_xml_entry,
            );
        },
    );

    my %strings;
    for my $string (@{$entry->{strings} || []}) {
        $strings{$string->{key}} = $string->{value};
    }
    $entry->{strings} = \%strings;

    my %binaries;
    for my $binary (@{$entry->{binaries} || []}) {
        $binaries{$binary->{key}} = $binary->{value};
    }
    $entry->{binaries} = \%binaries;

    return $entry;
}

sub _read_xml_times {
    my $self = shift;

    return $self->_read_xml_element(
        LastModificationTime    => 'datetime',
        CreationTime            => 'datetime',
        LastAccessTime          => 'datetime',
        ExpiryTime              => 'datetime',
        Expires                 => 'bool',
        UsageCount              => 'number',
        LocationChanged         => 'datetime',
    );
}

sub _read_xml_entry_string {
    my $self = shift;

    return $self->_read_xml_element(
        Key     => 'text',
        Value   => sub {
            my $self = shift;

            my $protected           = $self->_read_xml_attribute('Protected', 'bool', false);
            my $protect_in_memory   = $self->_read_xml_attribute('ProtectInMemory', 'bool', false);
            my $protect             = $protected || $protect_in_memory;

            my $val = $self->_read_xml_content($protected ? 'binary' : 'text');

            my $string = {
                value   => $val,
                $protect ? (protect => true) : (),
            };

            $self->_safe->add_protected(sub { decode('UTF-8', $_[0]) }, $string) if $protected;

            $string;
        },
    );
}

sub _read_xml_entry_binary {
    my $self = shift;

    return $self->_read_xml_element(
        Key     => 'text',
        Value   => sub {
            my $self = shift;

            my $ref = $self->_read_xml_attribute('Ref');
            my $compressed  = $self->_read_xml_attribute('Compressed', 'bool', false);
            my $protected = $self->_read_xml_attribute('Protected', 'bool', false);
            my $binary = {};

            if (defined $ref) {
                $binary->{ref} = $ref;
            }
            else {
                $binary->{value} = $self->_read_xml_content('binary');
                $binary->{protect} = true if $protected;

                if ($protected) {
                    # if compressed, decompress later when the safe is unlocked
                    $self->_safe->add_protected($compressed ? \&gunzip : (), $binary);
                }
                elsif ($compressed) {
                    $binary->{value} = gunzip($binary->{value});
                }
            }

            $binary;
        },
    );
}

sub _read_xml_entry_auto_type {
    my $self = shift;

    return $self->_read_xml_element({associations => []},
        Enabled                 => 'bool',
        DataTransferObfuscation => 'number',
        DefaultSequence         => 'text',
        Association             => [associations => sub {
            my $self = shift;
            return $self->_read_xml_element(
                Window              => 'text',
                KeystrokeSequence   => 'text',
            );
        }],
    );
}

sub _read_xml_deleted_objects {
    my $self = shift;

    return $self->_read_xml_element(
        DeletedObject   => sub {
            my $self = shift;
            my $object = $self->_read_xml_element(
                UUID            => 'uuid',
                DeletionTime    => 'datetime',
            );
            $object->{uuid} => $object;
        }
    );
}

##############################################################################

sub _resolve_binary_refs {
    my $self = shift;
    my $kdbx = $self->kdbx;

    my $pool = $kdbx->binaries;

    my $entries = $kdbx->entries(history => 1);
    while (my $entry = $entries->next) {
        while (my ($key, $binary) = each %{$entry->binaries}) {
            my $ref = $binary->{ref} // next;
            next if defined $binary->{value};

            my $data = $pool->{$ref};
            if (!defined $data || !defined $data->{value}) {
                alert "Found a reference to a missing binary: $key", key => $key, ref => $ref;
                next;
            }
            $binary->{value} = $data->{value};
            $binary->{protect} = true if $data->{protect};
            delete $binary->{ref};
        }
    }
}

##############################################################################

sub _read_xml_element {
    my $self = shift;
    my $args = @_ % 2 == 1 ? shift : {};
    my %spec = @_;

    my $reader = $self->_reader;
    my $path = $reader->nodePath;
    $path =~ s!\Q/text()\E$!!;

    return $args if $reader->isEmptyElement;

    my $store = ref $args eq 'CODE' ? $args
    : ref $args eq 'HASH' ? sub {
        my ($key, $val) = @_;
        if (ref $args->{$key} eq 'HASH') {
            $args->{$key}{$key} = $val;
        }
        elsif (ref $args->{$key} eq 'ARRAY') {
            push @{$args->{$key}}, $val;
        }
        else {
            exists $args->{$key}
                and alert 'Overwriting value', node => $reader->nodePath, line => $reader->lineNumber;
            $args->{$key} = $val;
        }
    } : ref $args eq 'ARRAY' ? sub {
        my ($key, $val) = @_;
        push @$args, $val;
    } : sub {};

    my $pattern = XML::LibXML::Pattern->new("${path}|${path}/*");
    while ($reader->nextPatternMatch($pattern) == 1) {
        last if $reader->nodePath eq $path && $reader->nodeType == XML_READER_TYPE_END_ELEMENT;
        next if $reader->nodeType != XML_READER_TYPE_ELEMENT;

        my $name = $reader->localName;
        my $key  = snakify($name);
        my $type = $spec{$name};
        ($key, $type) = @$type if ref $type eq 'ARRAY';

        if (!defined $type) {
            exists $spec{$name} or alert "Ignoring unknown element: $name",
                node => $reader->nodePath,
                line => $reader->lineNumber;
            next;
        }

        if (ref $type eq 'CODE') {
            my @result = $self->$type($args, $reader->nodePath);
            if (@result == 2) {
                $store->(@result);
            }
            elsif (@result == 1) {
                $store->($key, @result);
            }
        }
        else {
            $store->($key, $self->_read_xml_content($type));
        }
    }

    return $args;
}

sub _read_xml_attribute {
    my $self = shift;
    my $name = shift;
    my $type = shift // 'text';
    my $default = shift;
    my $reader = $self->_reader;

    return $default if !$reader->hasAttributes;

    my $value = trim($reader->getAttribute($name));
    if (!defined $value) {
        # try again after reading in all the attributes
        $reader->moveToFirstAttribute;
        while ($self->_reader->readAttributeValue == 1) {}
        $reader->moveToElement;

        $value = trim($reader->getAttribute($name));
    }

    return $default if !defined $value;

    my $decoded = eval { _decode_primitive($value, $type) };
    if (my $err = $@) {
        ref $err and $err->details(attribute => $name, node => $reader->nodePath, line => $reader->lineNumber);
        throw $err
    }

    return $decoded;
}

sub _read_xml_content {
    my $self = shift;
    my $type = shift;
    my $reader = $self->_reader;

    $reader->read if !$reader->isEmptyElement;  # step into element
    return '' if !$reader->hasValue;

    my $content = trim($reader->value);

    my $decoded = eval { _decode_primitive($content, $type) };
    if (my $err = $@) {
        ref $err and $err->details(node => $reader->nodePath, line => $reader->lineNumber);
        throw $err;
    }

    return $decoded;
}

##############################################################################

sub _decode_primitive { goto &{__PACKAGE__."::_decode_$_[1]"} }

sub _decode_binary {
    local $_ = shift;
    return '' if !defined || (ref && !defined $$_);
    $_ = eval { decode_b64(ref $_ ? $$_ : $_) };
    my $err = $@;
    my $cleanup = erase_scoped $_;
    $err and throw 'Failed to parse binary', error => $err;
    return $_;
}

sub _decode_bool {
    local $_ = shift;
    return true  if /^True$/i;
    return false if /^False$/i;
    return false if length($_) == 0;
    throw 'Expected boolean', text => $_;
}

sub _decode_datetime {
    local $_ = shift;

    if (/^[A-Za-z0-9\+\/\=]+$/) {
        my $binary = eval { decode_b64($_) };
        if (my $err = $@) {
            throw 'Failed to parse binary datetime', text => $_, error => $err;
        }
        throw $@ if $@;
        $binary .= \0 x (8 - length($binary)) if length($binary) < 8;
        my ($seconds_since_ad1) = unpack_Ql($binary);
        my $epoch = $seconds_since_ad1 - TIME_SECONDS_AD1_TO_UNIX_EPOCH;
        return gmtime($epoch);
    }

    my $dt = eval { Time::Piece->strptime($_, '%Y-%m-%dT%H:%M:%SZ') };
    if (my $err = $@) {
        throw 'Failed to parse datetime', text => $_, error => $err;
    }
    return $dt;
}

sub _decode_tristate {
    local $_ = shift;
    return undef if /^null$/i;
    my $tristate = eval { _decode_bool($_) };
    $@ and throw 'Expected tristate', text => $_, error => $@;
    return $tristate;
}

sub _decode_number {
    local $_ = shift;
    $_ = _decode_text($_);
    looks_like_number($_) or throw 'Expected number', text => $_;
    return $_+0;
}

sub _decode_text {
    local $_ = shift;
    return '' if !defined;
    return $_;
}

sub _decode_uuid {
    local $_ = shift;
    my $uuid = eval { _decode_binary($_) };
    $@ and throw 'Expected UUID', text => $_, error => $@;
    length($uuid) == 16 or throw 'Invalid UUID size', size => length($uuid);
    return $uuid;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Loader::XML - Load unencrypted XML KeePass files

=head1 VERSION

version 0.906

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
