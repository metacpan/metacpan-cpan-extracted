package File::KDBX::Loader::KDB;
# ABSTRACT: Read KDB files

use warnings;
use strict;

use Encode qw(encode);
use File::KDBX::Constants qw(:header :cipher :random_stream :icon);
use File::KDBX::Error;
use File::KDBX::Util qw(:class :empty :io :uuid load_optional);
use File::KDBX;
use Ref::Util qw(is_arrayref is_hashref);
use Scalar::Util qw(looks_like_number);
use Time::Piece;
use boolean;
use namespace::clean;

extends 'File::KDBX::Loader';

our $VERSION = '0.902'; # VERSION

my $DEFAULT_EXPIRATION = Time::Piece->new(32503677839); # 2999-12-31 23:59:59

sub _read_headers { '' }

sub _read_body {
    my $self = shift;
    my $fh = shift;
    my $key = shift;
    my $buf = shift;

    load_optional('File::KeePass');

    $buf .= do { local $/; <$fh> };

    $key = $self->kdbx->composite_key($key, keep_primitive => 1);

    my $k = eval { File::KeePass->new->parse_db(\$buf, _convert_kdbx_to_keepass_master_key($key)) };
    if (my $err = $@) {
        throw 'Failed to parse KDB file', error => $err;
    }

    $k->unlock;
    $self->kdbx->key($key);

    return convert_keepass_to_kdbx($k, $self->kdbx);
}

# This is also used by File::KDBX::Dumper::KDB.
sub _convert_kdbx_to_keepass_master_key {
    my $key = shift;

    my @keys = @{$key->keys};
    if (@keys == 1 && !$keys[0]->can('filepath')) {
        return [encode('CP-1252', $keys[0]->{primitive})];     # just a password
    }
    elsif (@keys == 1) {
        return [undef, \$keys[0]->raw_key]; # just a keyfile
    }
    elsif (@keys == 2 && !$keys[0]->can('filepath') && $keys[1]->can('filepath')) {
        return [encode('CP-1252', $keys[0]->{primitive}), \$keys[1]->raw_key];
    }
    throw 'Cannot use this key to load a KDB file', key => $key;
}


sub convert_keepass_to_kdbx {
    my $k    = shift;
    my $kdbx = shift // File::KDBX->new;

    $kdbx->{headers} //= {};
    _convert_keepass_to_kdbx_headers($k->{header}, $kdbx);

    my @groups = @{$k->{groups} || []};
    if (@groups == 1) {
        $kdbx->{root} = _convert_keepass_to_kdbx_group($k->{groups}[0]);
    }
    elsif (1 < @groups) {
        my $root = $kdbx->{root} = {%{File::KDBX->_implicit_root}};
        for my $group (@groups) {
            push @{$root->{groups} //= []}, _convert_keepass_to_kdbx_group($group);
        }
    }

    $kdbx->entries
    ->grep({
        title       => 'Meta-Info',
        username    => 'SYSTEM',
        url         => '$',
        icon_id     => 0,
        -nonempty   => 'notes',
    })
    ->each(sub {
        _read_meta_stream($kdbx, $_);
        $_->remove(signal => 0);
    });

    return $kdbx;
}

sub _read_meta_stream {
    my $kdbx    = shift;
    my $entry   = shift;

    my $type = $entry->notes;
    my $data = $entry->binary_value('bin-stream');
    open(my $fh, '<', \$data) or throw "Failed to open memory buffer for reading: $!";

    if ($type eq 'KPX_GROUP_TREE_STATE') {
        read_all $fh, my $buf, 4 or goto PARSE_ERROR;
        my ($num) = unpack('L<', $buf);
        $num * 5 + 4 == length($data) or goto PARSE_ERROR;
        for (my $i = 0; $i < $num; ++$i) {
            read_all $fh, $buf, 5 or goto PARSE_ERROR;
            my ($group_id, $expanded) = unpack('L< C', $buf);
            my $uuid = _decode_uuid($group_id) // next;
            my $group = $kdbx->groups->grep({uuid => $uuid})->next;
            $group->is_expanded($expanded) if $group;
        }
    }
    elsif ($type eq 'KPX_CUSTOM_ICONS_4') {
        read_all $fh, my $buf, 12 or goto PARSE_ERROR;
        my ($num_icons, $num_entries, $num_groups) = unpack('L<3', $buf);
        my @icons;
        for (my $i = 0; $i < $num_icons; ++$i) {
            read_all $fh, $buf, 4 or goto PARSE_ERROR;
            my ($icon_size) = unpack('L<', $buf);
            read_all $fh, $buf, $icon_size or goto PARSE_ERROR;
            my $uuid = $kdbx->add_custom_icon($buf);
            push @icons, $uuid;
        }
        for (my $i = 0; $i < $num_entries; ++$i) {
            read_all $fh, $buf, 20 or goto PARSE_ERROR;
            my ($uuid, $icon_index) = unpack('a16 L<', $buf);
            next if !$icons[$icon_index];
            my $entry = $kdbx->entries->grep({uuid => $uuid})->next;
            $entry->custom_icon_uuid($icons[$icon_index]) if $entry;
        }
        for (my $i = 0; $i < $num_groups; ++$i) {
            read_all $fh, $buf, 8 or goto PARSE_ERROR;
            my ($group_id, $icon_index) = unpack('L<2', $buf);
            next if !$icons[$icon_index];
            my $uuid = _decode_uuid($group_id) // next;
            my $group = $kdbx->groups->grep({uuid => $uuid})->next;
            $group->custom_icon_uuid($icons[$icon_index]) if $group;
        }
    }
    else {
        alert "Ignoring unknown meta stream: $type\n", type => $type;
        return;
    }

    return;

    PARSE_ERROR:
    alert "Ignoring unparsable meta stream: $type\n", type => $type;
}

sub _convert_keepass_to_kdbx_headers {
    my $from = shift;
    my $kdbx = shift;

    my $headers = $kdbx->{headers} //= {};
    my $meta = $kdbx->{meta} //= {};

    $kdbx->{sig1}       = $from->{sig1};
    $kdbx->{sig2}       = $from->{sig2};
    $kdbx->{version}    = $from->{vers};

    my %enc_type = (
        rijndael    => CIPHER_UUID_AES256,
        aes         => CIPHER_UUID_AES256,
        twofish     => CIPHER_UUID_TWOFISH,
        chacha20    => CIPHER_UUID_CHACHA20,
        salsa20     => CIPHER_UUID_SALSA20,
        serpent     => CIPHER_UUID_SERPENT,
    );
    my $cipher_uuid = $enc_type{$from->{cipher} || ''} // $enc_type{$from->{enc_type} || ''};

    my %protected_stream = (
        rc4         => STREAM_ID_RC4_VARIANT,
        salsa20     => STREAM_ID_SALSA20,
        chacha20    => STREAM_ID_CHACHA20,
    );
    my $protected_stream_id = $protected_stream{$from->{protected_stream} || ''} || STREAM_ID_SALSA20;

    $headers->{+HEADER_COMMENT}                 = $from->{comment};
    $headers->{+HEADER_CIPHER_ID}               = $cipher_uuid if $cipher_uuid;
    $headers->{+HEADER_MASTER_SEED}             = $from->{seed_rand};
    $headers->{+HEADER_COMPRESSION_FLAGS}       = $from->{compression} // 0;
    $headers->{+HEADER_TRANSFORM_SEED}          = $from->{seed_key};
    $headers->{+HEADER_TRANSFORM_ROUNDS}        = $from->{rounds};
    $headers->{+HEADER_ENCRYPTION_IV}           = $from->{enc_iv};
    $headers->{+HEADER_INNER_RANDOM_STREAM_ID}  = $protected_stream_id;
    $headers->{+HEADER_INNER_RANDOM_STREAM_KEY} = $from->{protected_stream_key};
    $headers->{+HEADER_STREAM_START_BYTES}      = $from->{start_bytes} // '';

    # TODO for KeePass 1 files these are all not available. Leave undefined or set default values?
    $meta->{memory_protection}{protect_notes}       = boolean($from->{protect_notes});
    $meta->{memory_protection}{protect_password}    = boolean($from->{protect_password});
    $meta->{memory_protection}{protect_username}    = boolean($from->{protect_username});
    $meta->{memory_protection}{protect_url}         = boolean($from->{protect_url});
    $meta->{memory_protection}{protect_title}       = boolean($from->{protect_title});
    $meta->{generator}                              = $from->{generator} // '';
    $meta->{header_hash}                            = $from->{header_hash};
    $meta->{database_name}                          = $from->{database_name} // '';
    $meta->{database_name_changed}                  = _decode_datetime($from->{database_name_changed});
    $meta->{database_description}                   = $from->{database_description} // '';
    $meta->{database_description_changed}           = _decode_datetime($from->{database_description_changed});
    $meta->{default_username}                       = $from->{default_user_name} // '';
    $meta->{default_username_changed}               = _decode_datetime($from->{default_user_name_changed});
    $meta->{maintenance_history_days}               = $from->{maintenance_history_days};
    $meta->{color}                                  = $from->{color};
    $meta->{master_key_changed}                     = _decode_datetime($from->{master_key_changed});
    $meta->{master_key_change_rec}                  = $from->{master_key_change_rec};
    $meta->{master_key_change_force}                = $from->{master_key_change_force};
    $meta->{recycle_bin_enabled}                    = boolean($from->{recycle_bin_enabled});
    $meta->{recycle_bin_uuid}                       = $from->{recycle_bin_uuid};
    $meta->{recycle_bin_changed}                    = _decode_datetime($from->{recycle_bin_changed});
    $meta->{entry_templates_group}                  = $from->{entry_templates_group};
    $meta->{entry_templates_group_changed}          = _decode_datetime($from->{entry_templates_group_changed});
    $meta->{last_selected_group}                    = $from->{last_selected_group};
    $meta->{last_top_visible_group}                 = $from->{last_top_visible_group};
    $meta->{history_max_items}                      = $from->{history_max_items};
    $meta->{history_max_size}                       = $from->{history_max_size};
    $meta->{settings_changed}                       = _decode_datetime($from->{settings_changed});

    while (my ($key, $value) = each %{$from->{custom_icons} || {}}) {
        push @{$meta->{custom_icons} //= []}, {uuid => $key, data => $value};
    }
    while (my ($key, $value) = each %{$from->{custom_data} || {}}) {
        $meta->{custom_data}{$key} = {value => $value};
    }

    return $kdbx;
}

sub _convert_keepass_to_kdbx_group {
    my $from = shift;
    my $to   = shift // {};
    my %args = @_;

    $to->{times}{last_access_time}          = _decode_datetime($from->{accessed});
    $to->{times}{usage_count}               = $from->{usage_count} || 0;
    $to->{times}{expiry_time}               = _decode_datetime($from->{expires}, $DEFAULT_EXPIRATION);
    $to->{times}{expires}                   = defined $from->{expires_enabled}
                                                ? boolean($from->{expires_enabled})
                                                : boolean($to->{times}{expiry_time} <= gmtime);
    $to->{times}{creation_time}             = _decode_datetime($from->{created});
    $to->{times}{last_modification_time}    = _decode_datetime($from->{modified});
    $to->{times}{location_changed}          = _decode_datetime($from->{location_changed});
    $to->{notes}                            = $from->{notes} // '';
    $to->{uuid}                             = _decode_uuid($from->{id});
    $to->{is_expanded}                      = boolean($from->{expanded});
    $to->{icon_id}                          = $from->{icon} // ICON_FOLDER;
    $to->{name}                             = $from->{title} // '';
    $to->{default_auto_type_sequence}       = $from->{auto_type_default} // '';
    $to->{enable_auto_type}                 = _decode_tristate($from->{auto_type_enabled});
    $to->{enable_searching}                 = _decode_tristate($from->{enable_searching});
    $to->{groups}                           = [];
    $to->{entries}                          = [];

    if (!$args{shallow}) {
        for my $group (@{$from->{groups} || []}) {
            push @{$to->{groups}}, _convert_keepass_to_kdbx_group($group);
        }
        for my $entry (@{$from->{entries} || []}) {
            push @{$to->{entries}}, _convert_keepass_to_kdbx_entry($entry);
        }
    }

    return $to;
}

sub _convert_keepass_to_kdbx_entry {
    my $from = shift;
    my $to   = shift // {};
    my %args = @_;

    $to->{times}{last_access_time}          = _decode_datetime($from->{accessed});
    $to->{times}{usage_count}               = $from->{usage_count} || 0;
    $to->{times}{expiry_time}               = _decode_datetime($from->{expires}, $DEFAULT_EXPIRATION);
    $to->{times}{expires}                   = defined $from->{expires_enabled}
                                                ? boolean($from->{expires_enabled})
                                                : boolean($to->{times}{expiry_time} <= gmtime);
    $to->{times}{creation_time}             = _decode_datetime($from->{created});
    $to->{times}{last_modification_time}    = _decode_datetime($from->{modified});
    $to->{times}{location_changed}          = _decode_datetime($from->{location_changed});

    $to->{auto_type}{data_transfer_obfuscation} = $from->{auto_type_munge} || false;
    $to->{auto_type}{enabled}                   = boolean($from->{auto_type_enabled} // 1);

    my $comment = $from->{comment};
    my @auto_type = is_arrayref($from->{auto_type}) ? @{$from->{auto_type}} : ();

    if (!@auto_type && nonempty $from->{auto_type} && nonempty $from->{auto_type_window}
        && !is_hashref($from->{auto_type})) {
        @auto_type = ({window => $from->{auto_type_window}, keys => $from->{auto_type}});
    }
    if (nonempty $comment) {
        my @AT;
        my %atw = my @atw = $comment =~ m{ ^Auto-Type-Window((?:-?\d+)?): [\t ]* (.*?) [\t ]*$ }mxg;
        my %atk = my @atk = $comment =~ m{ ^Auto-Type((?:-?\d+)?): [\t ]* (.*?) [\t ]*$ }mxg;
        $comment =~ s{ ^Auto-Type(?:-Window)?(?:-?\d+)?: .* \n? }{}mxg;
        while (@atw) {
            my ($n, $w) = (shift(@atw), shift(@atw));
            push @AT, {window => $w, keys => exists($atk{$n}) ? $atk{$n} : $atk{''}};
        }
        while (@atk) {
            my ($n, $k) = (shift(@atk), shift(@atk));
            push @AT, {keys => $k, window => exists($atw{$n}) ? $atw{$n} : $atw{''}};
        }
        for (@AT) {
            $_->{'window'} //= '';
            $_->{'keys'} //= '';
        }
        my %uniq;
        @AT = grep {!$uniq{"$_->{'window'}\e$_->{'keys'}"}++} @AT;
        push @auto_type, @AT;
    }
    $to->{auto_type}{associations} = [
        map { +{window => $_->{window}, keystroke_sequence => $_->{keys}} } @auto_type,
    ];

    $to->{strings}{Notes}{value}        = $comment;
    $to->{strings}{UserName}{value}     = $from->{username};
    $to->{strings}{Password}{value}     = $from->{password};
    $to->{strings}{URL}{value}          = $from->{url};
    $to->{strings}{Title}{value}        = $from->{title};
    $to->{strings}{Notes}{protect}      = true if defined $from->{protected}{comment};
    $to->{strings}{UserName}{protect}   = true if defined $from->{protected}{username};
    $to->{strings}{Password}{protect}   = true if $from->{protected}{password} // 1;
    $to->{strings}{URL}{protect}        = true if defined $from->{protected}{url};
    $to->{strings}{Title}{protect}      = true if defined $from->{protected}{title};

    # other strings
    while (my ($key, $value) = each %{$from->{strings} || {}}) {
        $to->{strings}{$key} = {
            value => $value,
            $from->{protected}{$key} ? (protect => true) : (),
        };
    }

    $to->{override_url}     = $from->{override_url};
    $to->{tags}             = $from->{tags} // '';
    $to->{icon_id}          = $from->{icon} // ICON_PASSWORD;
    $to->{uuid}             = _decode_uuid($from->{id});
    $to->{foreground_color} = $from->{foreground_color} // '';
    $to->{background_color} = $from->{background_color} // '';
    $to->{custom_icon_uuid} = $from->{custom_icon_uuid};
    $to->{history}          = [];

    local $from->{binary} = {$from->{binary_name} => $from->{binary}}
        if nonempty $from->{binary} && nonempty $from->{binary_name} && !is_hashref($from->{binary});
    while (my ($key, $value) = each %{$from->{binary} || {}}) {
        $to->{binaries}{$key} = {value => $value};
    }

    if (!$args{shallow}) {
        for my $entry (@{$from->{history} || []}) {
            my $new_entry = {};
            push @{$to->{entries}}, _convert_keepass_to_kdbx_entry($entry, $new_entry);
        }
    }

    return $to;
}

sub _decode_datetime {
    local $_ = shift // return shift // gmtime;
    return Time::Piece->strptime($_, '%Y-%m-%d %H:%M:%S');
}

sub _decode_uuid {
    local $_ = shift // return;
    # Group IDs in KDB files are 32-bit integers
    return sprintf('%016x', $_) if length($_) != 16 && looks_like_number($_);
    return $_;
}

sub _decode_tristate {
    local $_ = shift // return;
    return boolean($_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Loader::KDB - Read KDB files

=head1 VERSION

version 0.902

=head1 DESCRIPTION

Read older KDB (KeePass 1) files. This feature requires an additional module to be installed:

=over 4

=item *

L<File::KeePass>

=back

=head1 FUNCTIONS

=head2 convert_keepass_to_kdbx

    $kdbx = convert_keepass_to_kdbx($keepass);
    $kdbx = convert_keepass_to_kdbx($keepass, $kdbx);

Convert a L<File::KeePass> to a L<File::KDBX>.

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
