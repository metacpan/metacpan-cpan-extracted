package File::KDBX::Dumper::XML;
# ABSTRACT: Dump unencrypted XML KeePass files

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Crypt::Misc 0.029 qw(encode_b64);
use Encode qw(encode);
use File::KDBX::Constants qw(:version :time);
use File::KDBX::Error;
use File::KDBX::Util qw(:class :int erase_scoped gzip snakify);
use IO::Handle;
use Scalar::Util qw(blessed isdual looks_like_number);
use Time::Piece 1.33;
use XML::LibXML;
use boolean;
use namespace::clean;

extends 'File::KDBX::Dumper';

our $VERSION = '0.906'; # VERSION


has allow_protection => 1;
has binaries => sub { $_[0]->kdbx->version < KDBX_VERSION_4_0 };
has 'compress_binaries';
has 'compress_datetimes';

sub header_hash { $_[0]->{header_hash} }

sub _binaries_written { $_[0]->{_binaries_written} //= {} }

sub _random_stream { $_[0]->{random_stream} //= $_[0]->kdbx->random_stream }

sub _dump {
    my $self = shift;
    my $fh   = shift;

    $self->_write_inner_body($fh, $self->header_hash);
}

sub _write_inner_body {
    my $self = shift;
    my $fh   = shift;
    my $header_hash = shift;

    my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');
    $dom->setStandalone(1);

    my $doc = XML::LibXML::Element->new('KeePassFile');
    $dom->setDocumentElement($doc);

    my $meta = XML::LibXML::Element->new('Meta');
    $doc->appendChild($meta);
    $self->_write_xml_meta($meta, $header_hash);

    my $root = XML::LibXML::Element->new('Root');
    $doc->appendChild($root);
    $self->_write_xml_root($root);

    $dom->toFH($fh, 1);
}

sub _write_xml_meta {
    my $self = shift;
    my $node = shift;
    my $header_hash = shift;

    my $meta = $self->kdbx->meta;
    local $meta->{generator}    = $self->kdbx->user_agent_string // __PACKAGE__;
    local $meta->{header_hash}  = $header_hash;

    $self->_write_xml_from_pairs($node, $meta,
        Generator                   => 'text',
        $self->kdbx->version < KDBX_VERSION_4_0 && defined $meta->{header_hash} ? (
            HeaderHash              => 'binary',
        ) : (),
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
        MemoryProtection            => \&_write_xml_memory_protection,
        CustomIcons                 => \&_write_xml_custom_icons,
        RecycleBinEnabled           => 'bool',
        RecycleBinUUID              => 'uuid',
        RecycleBinChanged           => 'datetime',
        EntryTemplatesGroup         => 'uuid',
        EntryTemplatesGroupChanged  => 'datetime',
        LastSelectedGroup           => 'uuid',
        LastTopVisibleGroup         => 'uuid',
        HistoryMaxItems             => 'number',
        HistoryMaxSize              => 'number',
        $self->kdbx->version >= KDBX_VERSION_4_0 ? (
            SettingsChanged         => 'datetime',
        ) : (),
        $self->kdbx->version < KDBX_VERSION_4_0 || $self->binaries ? (
            Binaries                => \&_write_xml_binaries,
        ) : (),
        CustomData                  => \&_write_xml_custom_data,
    );
}

sub _write_xml_memory_protection {
    my $self = shift;
    my $node = shift;

    my $memory_protection = $self->kdbx->meta->{memory_protection};

    $self->_write_xml_from_pairs($node, $memory_protection,
        ProtectTitle            => 'bool',
        ProtectUserName         => 'bool',
        ProtectPassword         => 'bool',
        ProtectURL              => 'bool',
        ProtectNotes            => 'bool',
        # AutoEnableVisualHiding  => 'bool',
    );
}

sub _write_xml_binaries {
    my $self = shift;
    my $node = shift;

    my $kdbx = $self->kdbx;

    my $new_ref = keys %{$self->_binaries_written};
    my $written = $self->_binaries_written;

    my $entries = $kdbx->entries(history => 1);
    while (my $entry = $entries->next) {
        for my $key (keys %{$entry->binaries}) {
            my $binary = $entry->binaries->{$key};
            if (defined $binary->{ref} && defined $kdbx->binaries->{$binary->{ref}}) {
                $binary = $kdbx->binaries->{$binary->{ref}};
            }

            if (!defined $binary->{value}) {
                alert "Skipping binary which has no value: $key", key => $key;
                next;
            }

            my $hash = digest_data('SHA256', $binary->{value});
            if (defined $written->{$hash}) {
                # nothing
            }
            else {
                my $binary_node = $node->addNewChild(undef, 'Binary');
                $binary_node->setAttribute('ID', _encode_text($new_ref));
                $binary_node->setAttribute('Protected', _encode_bool(true)) if $binary->{protect};
                $self->_write_xml_compressed_content($binary_node, \$binary->{value}, $binary->{protect});
                $written->{$hash} = $new_ref++;
            }
        }
    }
}

sub _write_xml_compressed_content {
    my $self = shift;
    my $node = shift;
    my $value = shift;
    my $protect = shift;

    my @cleanup;

    my $encoded;
    if (utf8::is_utf8($$value)) {
        $encoded = encode('UTF-8', $$value);
        push @cleanup, erase_scoped $encoded;
        $value = \$encoded;
    }

    my $should_compress = $self->compress_binaries;
    my $try_compress = $should_compress || !defined $should_compress;

    my $compressed;
    if ($try_compress) {
        $compressed = gzip($$value);
        push @cleanup, erase_scoped $compressed;

        if ($should_compress || length($compressed) < length($$value)) {
            $value = \$compressed;
            $node->setAttribute('Compressed', _encode_bool(true));
        }
    }

    my $encrypted;
    if ($protect) {
        $encrypted = $self->_random_stream->crypt($$value);
        push @cleanup, erase_scoped $encrypted;
        $value = \$encrypted;
    }

    $node->appendText(_encode_binary($$value));
}

sub _write_xml_custom_icons {
    my $self = shift;
    my $node = shift;

    my $custom_icons = $self->kdbx->custom_icons;

    for my $icon (@$custom_icons) {
        $icon->{uuid} && $icon->{data} or next;
        my $icon_node = $node->addNewChild(undef, 'Icon');

        $self->_write_xml_from_pairs($icon_node, $icon,
            UUID                        => 'uuid',
            Data                        => 'binary',
            KDBX_VERSION_4_1 <= $self->kdbx->version ? (
                Name                    => 'text',
                LastModificationTime    => 'datetime',
            ) : (),
        );
    }
}

sub _write_xml_custom_data {
    my $self = shift;
    my $node = shift;
    my $custom_data = shift || {};

    for my $key (sort keys %$custom_data) {
        my $item = $custom_data->{$key};
        my $item_node = $node->addNewChild(undef, 'Item');

        local $item->{key} = $key if !defined $item->{key};

        $self->_write_xml_from_pairs($item_node, $item,
            Key     => 'text',
            Value   => 'text',
            KDBX_VERSION_4_1 <= $self->kdbx->version ? (
                LastModificationTime    => 'datetime',
            ) : (),
        );
    }
}

sub _write_xml_root {
    my $self = shift;
    my $node = shift;
    my $kdbx = $self->kdbx;

    my $guard = $kdbx->unlock_scoped;

    if (my $group = $kdbx->root) {
        my $group_node = $node->addNewChild(undef, 'Group');
        $self->_write_xml_group($group_node, $group->_committed);
    }

    undef $guard;   # re-lock if needed, as early as possible

    my $deleted_objects_node = $node->addNewChild(undef, 'DeletedObjects');
    $self->_write_xml_deleted_objects($deleted_objects_node);
}

sub _write_xml_group {
    my $self = shift;
    my $node = shift;
    my $group = shift;

    $self->_write_xml_from_pairs($node, $group,
        UUID                    => 'uuid',
        Name                    => 'text',
        Notes                   => 'text',
        KDBX_VERSION_4_1 <= $self->kdbx->version ? (
            Tags                => 'text',
        ) : (),
        IconID                  => 'number',
        defined $group->{custom_icon_uuid} ? (
            CustomIconUUID      => 'uuid',
        ) : (),
        Times                   => \&_write_xml_times,
        IsExpanded              => 'bool',
        DefaultAutoTypeSequence => 'text',
        EnableAutoType          => 'tristate',
        EnableSearching         => 'tristate',
        LastTopVisibleEntry     => 'uuid',
        KDBX_VERSION_4_0 <= $self->kdbx->version ? (
            CustomData          => \&_write_xml_custom_data,
        ) : (),
        KDBX_VERSION_4_1 <= $self->kdbx->version ? (
            PreviousParentGroup => 'uuid',
        ) : (),
    );

    for my $entry (@{$group->entries}) {
        my $entry_node = $node->addNewChild(undef, 'Entry');
        $self->_write_xml_entry($entry_node, $entry->_committed);
    }

    for my $group (@{$group->groups}) {
        my $group_node = $node->addNewChild(undef, 'Group');
        $self->_write_xml_group($group_node, $group->_committed);
    }
}

sub _write_xml_entry {
    my $self        = shift;
    my $node        = shift;
    my $entry       = shift;
    my $in_history  = shift;

    $self->_write_xml_from_pairs($node, $entry,
        UUID                    => 'uuid',
        IconID                  => 'number',
        defined $entry->{custom_icon_uuid} ? (
            CustomIconUUID      => 'uuid',
        ) : (),
        ForegroundColor         => 'text',
        BackgroundColor         => 'text',
        OverrideURL             => 'text',
        Tags                    => 'text',
        Times                   => \&_write_xml_times,
        KDBX_VERSION_4_1 <= $self->kdbx->version ? (
            QualityCheck        => 'bool',
            PreviousParentGroup => 'uuid',
        ) : (),
    );

    for my $key (sort keys %{$entry->{strings} || {}}) {
        my $string = $entry->{strings}{$key};
        my $string_node = $node->addNewChild(undef, 'String');
        local $string->{key} = $string->{key} // $key;
        $self->_write_xml_entry_string($string_node, $string);
    }

    my $kdbx = $self->kdbx;
    my $new_ref = keys %{$self->_binaries_written};
    my $written = $self->_binaries_written;

    for my $key (sort keys %{$entry->{binaries} || {}}) {
        my $binary = $entry->binaries->{$key};
        if (defined $binary->{ref} && defined $kdbx->binaries->{$binary->{ref}}) {
            $binary = $kdbx->binaries->{$binary->{ref}};
        }

        if (!defined $binary->{value}) {
            alert "Skipping binary which has no value: $key", key => $key;
            next;
        }

        my $binary_node = $node->addNewChild(undef, 'Binary');
        $binary_node->addNewChild(undef, 'Key')->appendText(_encode_text($key));
            my $value_node = $binary_node->addNewChild(undef, 'Value');

        my $hash = digest_data('SHA256', $binary->{value});
        if (defined $written->{$hash}) {
            # write reference
            $value_node->setAttribute('Ref', _encode_text($written->{$hash}));
        }
        else {
            # write actual binary
            $value_node->setAttribute('Protected', _encode_bool(true)) if $binary->{protect};
            $self->_write_xml_compressed_content($value_node, \$binary->{value}, $binary->{protect});
            $written->{$hash} = $new_ref++;
        }
    }

    $self->_write_xml_from_pairs($node, $entry,
        AutoType => \&_write_xml_entry_auto_type,
    );

    $self->_write_xml_from_pairs($node, $entry,
        KDBX_VERSION_4_0 <= $self->kdbx->version ? (
            CustomData => \&_write_xml_custom_data,
        ) : (),
    );

    if (!$in_history) {
        if (my @history = @{$entry->history}) {
            my $history_node = $node->addNewChild(undef, 'History');
            for my $historical (@history) {
                my $historical_node = $history_node->addNewChild(undef, 'Entry');
                $self->_write_xml_entry($historical_node, $historical->_committed, 1);
            }
        }
    }
}

sub _write_xml_entry_auto_type {
    my $self = shift;
    my $node = shift;
    my $autotype = shift;

    $self->_write_xml_from_pairs($node, $autotype,
        Enabled                 => 'bool',
        DataTransferObfuscation => 'number',
        DefaultSequence         => 'text',
    );

    for my $association (@{$autotype->{associations} || []}) {
        my $association_node = $node->addNewChild(undef, 'Association');
        $self->_write_xml_from_pairs($association_node, $association,
            Window              => 'text',
            KeystrokeSequence   => 'text',
        );
    }
}

sub _write_xml_times {
    my $self = shift;
    my $node = shift;
    my $times = shift;

    $self->_write_xml_from_pairs($node, $times,
        LastModificationTime    => 'datetime',
        CreationTime            => 'datetime',
        LastAccessTime          => 'datetime',
        ExpiryTime              => 'datetime',
        Expires                 => 'bool',
        UsageCount              => 'number',
        LocationChanged         => 'datetime',
    );
}

sub _write_xml_entry_string {
    my $self = shift;
    my $node = shift;
    my $string = shift;

    my @cleanup;

    my $kdbx = $self->kdbx;
    my $key = $string->{key};

    $node->addNewChild(undef, 'Key')->appendText(_encode_text($key));
    my $value_node = $node->addNewChild(undef, 'Value');

    my $value = $string->{value} || '';

    my $memory_protection = $kdbx->meta->{memory_protection};
    my $memprot_key = 'protect_' . snakify($key);
    my $protect = $string->{protect} || $memory_protection->{$memprot_key};

    if ($protect) {
        if ($self->allow_protection) {
            my $encoded;
            if (utf8::is_utf8($value)) {
                $encoded = encode('UTF-8', $value);
                push @cleanup, erase_scoped $encoded;
                $value = $encoded;
            }

            $value_node->setAttribute('Protected', _encode_bool(true));
            $value = _encode_binary($self->_random_stream->crypt(\$value));
        }
        else {
            $value_node->setAttribute('ProtectInMemory', _encode_bool(true));
            $value = _encode_text($value);
        }
    }
    else {
        $value = _encode_text($value);
    }

    $value_node->appendText($value) if defined $value;
}

sub _write_xml_deleted_objects {
    my $self = shift;
    my $node = shift;

    my $objects = $self->kdbx->deleted_objects;

    for my $uuid (sort keys %{$objects || {}}) {
        my $object = $objects->{$uuid};
        local $object->{uuid} = $uuid;
        my $object_node = $node->addNewChild(undef, 'DeletedObject');
        $self->_write_xml_from_pairs($object_node, $object,
            UUID            => 'uuid',
            DeletionTime    => 'datetime',
        );
    }
}

##############################################################################

sub _write_xml_from_pairs {
    my $self = shift;
    my $node = shift;
    my $hash = shift;
    my @spec = @_;

    while (@spec) {
        my ($name, $type) = splice @spec, 0, 2;
        my $key = snakify($name);

        if (ref $type eq 'CODE') {
            my $child_node = $node->addNewChild(undef, $name);
            $self->$type($child_node, $hash->{$key});
        }
        else {
            next if !exists $hash->{$key};
            my $child_node = $node->addNewChild(undef, $name);
            $type = 'datetime_binary' if $type eq 'datetime' && $self->compress_datetimes;
            $child_node->appendText(_encode_primitive($hash->{$key}, $type));
        }
    }
}

##############################################################################

sub _encode_primitive { goto &{__PACKAGE__."::_encode_$_[1]"} }

sub _encode_binary {
    return '' if !defined $_[0] || (ref $_[0] && !defined $$_[0]);
    return encode_b64(ref $_[0] ? $$_[0] : $_[0]);
}

sub _encode_bool {
    local $_ = shift;
    return $_ ? 'True' : 'False';
}

sub _encode_datetime {
    local $_ = shift;
    return $_->strftime('%Y-%m-%dT%H:%M:%SZ');
}

sub _encode_datetime_binary {
    local $_ = shift;
    my $seconds_since_ad1 = $_ + TIME_SECONDS_AD1_TO_UNIX_EPOCH;
    my $buf = pack_Ql($seconds_since_ad1->epoch);
    return eval { encode_b64($buf) };
}

sub _encode_tristate {
    local $_ = shift // return 'null';
    return $_ ? 'True' : 'False';
}

sub _encode_number {
    local $_ = shift // return;
    looks_like_number($_) || isdual($_) or throw 'Expected number', text => $_;
    return _encode_text($_+0);
}

sub _encode_text {
    return '' if !defined $_[0];
    return $_[0];
}

sub _encode_uuid { _encode_binary(@_) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Dumper::XML - Dump unencrypted XML KeePass files

=head1 VERSION

version 0.906

=head1 ATTRIBUTES

=head2 allow_protection

    $bool = $dumper->allow_protection;

Get whether or not protected strings and binaries should be written in an encrypted stream. Default: C<TRUE>

=head2 binaries

    $bool = $dumper->binaries;

Get whether or not binaries within the database should be written. Default: C<TRUE>

=head2 compress_binaries

    $tristate = $dumper->compress_binaries;

Get whether or not to compress binaries. Possible values:

=over 4

=item *

C<TRUE> - Always compress binaries

=item *

C<FALSE> - Never compress binaries

=item *

C<undef> - Compress binaries if it results in smaller database sizes (default)

=back

=head2 compress_datetimes

    $bool = $dumper->compress_datetimes;

Get whether or not to write compressed datetimes. Datetimes are traditionally written in the human-readable
string format of C<1970-01-01T00:00:00Z>, but they can also be written in a compressed form to save some
bytes. The default is to write compressed datetimes if the KDBX file version is 4+, otherwise use the
human-readable format.

=head2 header_hash

    $octets = $dumper->header_hash;

Get the value to be written as the B<HeaderHash> in the B<Meta> section. This is the way KDBX3 files validate
the authenticity of header data. This is unnecessary and should not be used with KDBX4 files because that
format uses HMAC-SHA256 to detect tampering.

L<File::KDBX::Dumper::V3> automatically calculates the header hash an provides it to this module, and plain
XML files which don't have a KDBX wrapper don't have headers and so should not have a header hash. Therefore
there is probably never any reason to set this manually.

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
