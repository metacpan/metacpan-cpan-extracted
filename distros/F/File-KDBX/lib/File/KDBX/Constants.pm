package File::KDBX::Constants;
# ABSTRACT: All the KDBX-related constants you could ever want

# HOW TO add new constants:
#  1. Add it to the %CONSTANTS structure below.
#  2. List it in the pod at the bottom of this file in the section corresponding to its tag.
#  3. There is no step three.

use 5.010;
use warnings;
use strict;

use Exporter qw(import);
use File::KDBX::Util qw(int64);
use Scalar::Util qw(dualvar);
use namespace::clean -except => 'import';

our $VERSION = '0.903'; # VERSION

BEGIN {
    my %CONSTANTS = (
        magic   => {
            __prefix        => 'KDBX',
            SIG1            => 0x9aa2d903,
            SIG1_FIRST_BYTE => 0x03,
            SIG2_1          => 0xb54bfb65,
            SIG2_2          => 0xb54bfb67,
        },
        version => {
            __prefix    => 'KDBX_VERSION',
            _2_0        => 0x00020000,
            _3_0        => 0x00030000,
            _3_1        => 0x00030001,
            _4_0        => 0x00040000,
            _4_1        => 0x00040001,
            OLDEST      => 0x00020000,
            LATEST      => 0x00040001,
            MAJOR_MASK  => 0xffff0000,
            MINOR_MASK  => 0x0000ffff,
        },
        header  => {
            __prefix                => 'HEADER',
            END                     => dualvar(  0, 'end'),
            COMMENT                 => dualvar(  1, 'comment'),
            CIPHER_ID               => dualvar(  2, 'cipher_id'),
            COMPRESSION_FLAGS       => dualvar(  3, 'compression_flags'),
            MASTER_SEED             => dualvar(  4, 'master_seed'),
            TRANSFORM_SEED          => dualvar(  5, 'transform_seed'),
            TRANSFORM_ROUNDS        => dualvar(  6, 'transform_rounds'),
            ENCRYPTION_IV           => dualvar(  7, 'encryption_iv'),
            INNER_RANDOM_STREAM_KEY => dualvar(  8, 'inner_random_stream_key'),
            STREAM_START_BYTES      => dualvar(  9, 'stream_start_bytes'),
            INNER_RANDOM_STREAM_ID  => dualvar( 10, 'inner_random_stream_id'),
            KDF_PARAMETERS          => dualvar( 11, 'kdf_parameters'),
            PUBLIC_CUSTOM_DATA      => dualvar( 12, 'public_custom_data'),
        },
        compression => {
            __prefix    => 'COMPRESSION',
            NONE        => dualvar( 0, 'none'),
            GZIP        => dualvar( 1, 'gzip'),
        },
        cipher  => {
            __prefix        => 'CIPHER',
            UUID_AES128     => "\x61\xab\x05\xa1\x94\x64\x41\xc3\x8d\x74\x3a\x56\x3d\xf8\xdd\x35",
            UUID_AES256     => "\x31\xc1\xf2\xe6\xbf\x71\x43\x50\xbe\x58\x05\x21\x6a\xfc\x5a\xff",
            UUID_CHACHA20   => "\xd6\x03\x8a\x2b\x8b\x6f\x4c\xb5\xa5\x24\x33\x9a\x31\xdb\xb5\x9a",
            UUID_SALSA20    => "\x71\x6e\x1c\x8a\xee\x17\x4b\xdc\x93\xae\xa9\x77\xb8\x82\x83\x3a",
            UUID_SERPENT    => "\x09\x85\x63\xff\xdd\xf7\x4f\x98\x86\x19\x80\x79\xf6\xdb\x89\x7a",
            UUID_TWOFISH    => "\xad\x68\xf2\x9f\x57\x6f\x4b\xb9\xa3\x6a\xd4\x7a\xf9\x65\x34\x6c",
        },
        kdf     => {
            __prefix                    => 'KDF',
            UUID_AES                    => "\xc9\xd9\xf3\x9a\x62\x8a\x44\x60\xbf\x74\x0d\x08\xc1\x8a\x4f\xea",
            UUID_AES_CHALLENGE_RESPONSE => "\x7c\x02\xbb\x82\x79\xa7\x4a\xc0\x92\x7d\x11\x4a\x00\x64\x82\x38",
            UUID_ARGON2D                => "\xef\x63\x6d\xdf\x8c\x29\x44\x4b\x91\xf7\xa9\xa4\x03\xe3\x0a\x0c",
            UUID_ARGON2ID               => "\x9e\x29\x8b\x19\x56\xdb\x47\x73\xb2\x3d\xfc\x3e\xc6\xf0\xa1\xe6",
            PARAM_UUID                  => '$UUID',
            PARAM_AES_ROUNDS            => 'R',
            PARAM_AES_SEED              => 'S',
            PARAM_ARGON2_SALT           => 'S',
            PARAM_ARGON2_PARALLELISM    => 'P',
            PARAM_ARGON2_MEMORY         => 'M',
            PARAM_ARGON2_ITERATIONS     => 'I',
            PARAM_ARGON2_VERSION        => 'V',
            PARAM_ARGON2_SECRET         => 'K',
            PARAM_ARGON2_ASSOCDATA      => 'A',
            DEFAULT_AES_ROUNDS          => 100_000,
            DEFAULT_ARGON2_ITERATIONS   => 10,
            DEFAULT_ARGON2_MEMORY       => 1 << 16,
            DEFAULT_ARGON2_PARALLELISM  => 2,
            DEFAULT_ARGON2_VERSION      => 0x13,
        },
        random_stream   => {
            __prefix        => 'STREAM',
            ID_RC4_VARIANT  => 1,
            ID_SALSA20      => 2,
            ID_CHACHA20     => 3,
            SALSA20_IV      => "\xe8\x30\x09\x4b\x97\x20\x5d\x2a",

        },
        variant_map => {
            __prefix            => 'VMAP',
            VERSION             => 0x0100,
            VERSION_MAJOR_MASK  => 0xff00,
            TYPE_END            => 0x00,
            TYPE_UINT32         => 0x04,
            TYPE_UINT64         => 0x05,
            TYPE_BOOL           => 0x08,
            TYPE_INT32          => 0x0C,
            TYPE_INT64          => 0x0D,
            TYPE_STRING         => 0x18,
            TYPE_BYTEARRAY      => 0x42,
        },
        inner_header => {
            __prefix                => 'INNER_HEADER',
            END                     => dualvar( 0, 'end'),
            INNER_RANDOM_STREAM_ID  => dualvar( 1, 'inner_random_stream_id'),
            INNER_RANDOM_STREAM_KEY => dualvar( 2, 'inner_random_stream_key'),
            BINARY                  => dualvar( 3, 'binary'),
            BINARY_FLAG_PROTECT     => 1,
        },
        key_file    => {
            __prefix    => 'KEY_FILE',
            TYPE_BINARY => dualvar( 1, 'binary'),
            TYPE_HASHED => dualvar( 3, 'hashed'),
            TYPE_HEX    => dualvar( 2, 'hex'),
            TYPE_XML    => dualvar( 4, 'xml'),
        },
        history     => {
            __prefix            => 'HISTORY',
            DEFAULT_MAX_AGE     => 365,
            DEFAULT_MAX_ITEMS   => 10,
            DEFAULT_MAX_SIZE    => 6_291_456, # 6 MiB
        },
        iteration   => {
            ITERATION_BFS   => dualvar(1, 'bfs'),
            ITERATION_DFS   => dualvar(2, 'dfs'),
            ITERATION_IDS   => dualvar(3, 'ids'),
        },
        icon        => {
            __prefix            => 'ICON',
            PASSWORD            => dualvar(  0, 'Password'),
            PACKAGE_NETWORK     => dualvar(  1, 'Package_Network'),
            MESSAGEBOX_WARNING  => dualvar(  2, 'MessageBox_Warning'),
            SERVER              => dualvar(  3, 'Server'),
            KLIPPER             => dualvar(  4, 'Klipper'),
            EDU_LANGUAGES       => dualvar(  5, 'Edu_Languages'),
            KCMDF               => dualvar(  6, 'KCMDF'),
            KATE                => dualvar(  7, 'Kate'),
            SOCKET              => dualvar(  8, 'Socket'),
            IDENTITY            => dualvar(  9, 'Identity'),
            KONTACT             => dualvar( 10, 'Kontact'),
            CAMERA              => dualvar( 11, 'Camera'),
            IRKICKFLASH         => dualvar( 12, 'IRKickFlash'),
            KGPG_KEY3           => dualvar( 13, 'KGPG_Key3'),
            LAPTOP_POWER        => dualvar( 14, 'Laptop_Power'),
            SCANNER             => dualvar( 15, 'Scanner'),
            MOZILLA_FIREBIRD    => dualvar( 16, 'Mozilla_Firebird'),
            CDROM_UNMOUNT       => dualvar( 17, 'CDROM_Unmount'),
            DISPLAY             => dualvar( 18, 'Display'),
            MAIL_GENERIC        => dualvar( 19, 'Mail_Generic'),
            MISC                => dualvar( 20, 'Misc'),
            KORGANIZER          => dualvar( 21, 'KOrganizer'),
            ASCII               => dualvar( 22, 'ASCII'),
            ICONS               => dualvar( 23, 'Icons'),
            CONNECT_ESTABLISHED => dualvar( 24, 'Connect_Established'),
            FOLDER_MAIL         => dualvar( 25, 'Folder_Mail'),
            FILESAVE            => dualvar( 26, 'FileSave'),
            NFS_UNMOUNT         => dualvar( 27, 'NFS_Unmount'),
            MESSAGE             => dualvar( 28, 'Message'),
            KGPG_TERM           => dualvar( 29, 'KGPG_Term'),
            KONSOLE             => dualvar( 30, 'Konsole'),
            FILEPRINT           => dualvar( 31, 'FilePrint'),
            FSVIEW              => dualvar( 32, 'FSView'),
            RUN                 => dualvar( 33, 'Run'),
            CONFIGURE           => dualvar( 34, 'Configure'),
            KRFB                => dualvar( 35, 'KRFB'),
            ARK                 => dualvar( 36, 'Ark'),
            KPERCENTAGE         => dualvar( 37, 'KPercentage'),
            SAMBA_UNMOUNT       => dualvar( 38, 'Samba_Unmount'),
            HISTORY             => dualvar( 39, 'History'),
            MAIL_FIND           => dualvar( 40, 'Mail_Find'),
            VECTORGFX           => dualvar( 41, 'VectorGfx'),
            KCMMEMORY           => dualvar( 42, 'KCMMemory'),
            TRASHCAN_FULL       => dualvar( 43, 'Trashcan_Full'),
            KNOTES              => dualvar( 44, 'KNotes'),
            CANCEL              => dualvar( 45, 'Cancel'),
            HELP                => dualvar( 46, 'Help'),
            KPACKAGE            => dualvar( 47, 'KPackage'),
            FOLDER              => dualvar( 48, 'Folder'),
            FOLDER_BLUE_OPEN    => dualvar( 49, 'Folder_Blue_Open'),
            FOLDER_TAR          => dualvar( 50, 'Folder_Tar'),
            DECRYPTED           => dualvar( 51, 'Decrypted'),
            ENCRYPTED           => dualvar( 52, 'Encrypted'),
            APPLY               => dualvar( 53, 'Apply'),
            SIGNATURE           => dualvar( 54, 'Signature'),
            THUMBNAIL           => dualvar( 55, 'Thumbnail'),
            KADDRESSBOOK        => dualvar( 56, 'KAddressBook'),
            VIEW_TEXT           => dualvar( 57, 'View_Text'),
            KGPG                => dualvar( 58, 'KGPG'),
            PACKAGE_DEVELOPMENT => dualvar( 59, 'Package_Development'),
            KFM_HOME            => dualvar( 60, 'KFM_Home'),
            SERVICES            => dualvar( 61, 'Services'),
            TUX                 => dualvar( 62, 'Tux'),
            FEATHER             => dualvar( 63, 'Feather'),
            APPLE               => dualvar( 64, 'Apple'),
            W                   => dualvar( 65, 'W'),
            MONEY               => dualvar( 66, 'Money'),
            CERTIFICATE         => dualvar( 67, 'Certificate'),
            SMARTPHONE          => dualvar( 68, 'Smartphone'),
        },
        bool        => {
            FALSE   => !1,
            TRUE    => 1,
        },
        time        => {
            __prefix                    => 'TIME',
            SECONDS_AD1_TO_UNIX_EPOCH   => int64('62135596800'),
        },
        yubikey     => {
            YUBICO_VID              => dualvar( 0x1050, 'Yubico'),
            YUBIKEY_PID             => dualvar( 0x0010, 'YubiKey 1/2'),
            NEO_OTP_PID             => dualvar( 0x0110, 'YubiKey NEO OTP'),
            NEO_OTP_CCID_PID        => dualvar( 0x0111, 'YubiKey NEO OTP+CCID'),
            NEO_CCID_PID            => dualvar( 0x0112, 'YubiKey NEO CCID'),
            NEO_U2F_PID             => dualvar( 0x0113, 'YubiKey NEO FIDO'),
            NEO_OTP_U2F_PID         => dualvar( 0x0114, 'YubiKey NEO OTP+FIDO'),
            NEO_U2F_CCID_PID        => dualvar( 0x0115, 'YubiKey NEO FIDO+CCID'),
            NEO_OTP_U2F_CCID_PID    => dualvar( 0x0116, 'YubiKey NEO OTP+FIDO+CCID'),
            YK4_OTP_PID             => dualvar( 0x0401, 'YubiKey 4/5 OTP'),
            YK4_U2F_PID             => dualvar( 0x0402, 'YubiKey 4/5 FIDO'),
            YK4_OTP_U2F_PID         => dualvar( 0x0403, 'YubiKey 4/5 OTP+FIDO'),
            YK4_CCID_PID            => dualvar( 0x0404, 'YubiKey 4/5 CCID'),
            YK4_OTP_CCID_PID        => dualvar( 0x0405, 'YubiKey 4/5 OTP+CCID'),
            YK4_U2F_CCID_PID        => dualvar( 0x0406, 'YubiKey 4/5 FIDO+CCID'),
            YK4_OTP_U2F_CCID_PID    => dualvar( 0x0407, 'YubiKey 4/5 OTP+FIDO+CCID'),
            PLUS_U2F_OTP_PID        => dualvar( 0x0410, 'YubiKey Plus OTP+FIDO'),

            ONLYKEY_VID             => dualvar( 0x1d50, 'OnlyKey'),
            ONLYKEY_PID             => dualvar( 0x60fc, 'OnlyKey'),

            YK_EUSBERR              => dualvar( 0x01, 'USB error'),
            YK_EWRONGSIZ            => dualvar( 0x02, 'wrong size'),
            YK_EWRITEERR            => dualvar( 0x03, 'write error'),
            YK_ETIMEOUT             => dualvar( 0x04, 'timeout'),
            YK_ENOKEY               => dualvar( 0x05, 'no yubikey present'),
            YK_EFIRMWARE            => dualvar( 0x06, 'unsupported firmware version'),
            YK_ENOMEM               => dualvar( 0x07, 'out of memory'),
            YK_ENOSTATUS            => dualvar( 0x08, 'no status structure given'),
            YK_ENOTYETIMPL          => dualvar( 0x09, 'not yet implemented'),
            YK_ECHECKSUM            => dualvar( 0x0a, 'checksum mismatch'),
            YK_EWOULDBLOCK          => dualvar( 0x0b, 'operation would block'),
            YK_EINVALIDCMD          => dualvar( 0x0c, 'invalid command for operation'),
            YK_EMORETHANONE         => dualvar( 0x0d, 'expected only one YubiKey but serveral present'),
            YK_ENODATA              => dualvar( 0x0e, 'no data returned from device'),

            CONFIG1_VALID           => 0x01,
            CONFIG2_VALID           => 0x02,
            CONFIG1_TOUCH           => 0x04,
            CONFIG2_TOUCH           => 0x08,
            CONFIG_LED_INV          => 0x10,
            CONFIG_STATUS_MASK      => 0x1f,
        },
    );

    our %EXPORT_TAGS;
    my %seen;
    no strict 'refs'; ## no critic (ProhibitNoStrict)
    while (my ($tag, $constants) = each %CONSTANTS) {
        my $prefix = delete $constants->{__prefix};
        while (my ($name, $value) = each %$constants) {
            my $val = $value;
            $val = $val+0 if $tag eq 'icon'; # TODO
            $name =~ s/^_+//;
            my $full_name = $prefix ? "${prefix}_${name}" : $name;
            die "Duplicate constant: $full_name\n" if $seen{$full_name};
            *{$full_name} = sub() { $value };
            push @{$EXPORT_TAGS{$tag} //= []}, $full_name;
            $seen{$full_name}++;
        }
    }
}

our %EXPORT_TAGS;
push @{$EXPORT_TAGS{header}},       'to_header_constant';
push @{$EXPORT_TAGS{compression}},  'to_compression_constant';
push @{$EXPORT_TAGS{inner_header}}, 'to_inner_header_constant';
push @{$EXPORT_TAGS{icon}},         'to_icon_constant';

$EXPORT_TAGS{all} = [map { @$_ } values %EXPORT_TAGS];
our @EXPORT_OK = sort @{$EXPORT_TAGS{all}};

my %HEADER;
for my $header (
    HEADER_END, HEADER_COMMENT, HEADER_CIPHER_ID, HEADER_COMPRESSION_FLAGS,
    HEADER_MASTER_SEED, HEADER_TRANSFORM_SEED, HEADER_TRANSFORM_ROUNDS,
    HEADER_ENCRYPTION_IV, HEADER_INNER_RANDOM_STREAM_KEY, HEADER_STREAM_START_BYTES,
    HEADER_INNER_RANDOM_STREAM_ID, HEADER_KDF_PARAMETERS, HEADER_PUBLIC_CUSTOM_DATA,
) {
    $HEADER{$header} = $HEADER{0+$header} = $header;
}
sub to_header_constant { $HEADER{$_[0] // ''} }

my %COMPRESSION;
for my $compression (COMPRESSION_NONE, COMPRESSION_GZIP) {
    $COMPRESSION{$compression} = $COMPRESSION{0+$compression} = $compression;
}
sub to_compression_constant { $COMPRESSION{$_[0] // ''} }

my %INNER_HEADER;
for my $inner_header (
    INNER_HEADER_END, INNER_HEADER_INNER_RANDOM_STREAM_ID,
    INNER_HEADER_INNER_RANDOM_STREAM_KEY, INNER_HEADER_BINARY,
) {
    $INNER_HEADER{$inner_header} = $INNER_HEADER{0+$inner_header} = $inner_header;
}
sub to_inner_header_constant { $INNER_HEADER{$_[0] // ''} }

my %ICON;
for my $icon (
    ICON_PASSWORD, ICON_PACKAGE_NETWORK, ICON_MESSAGEBOX_WARNING, ICON_SERVER, ICON_KLIPPER,
    ICON_EDU_LANGUAGES, ICON_KCMDF, ICON_KATE, ICON_SOCKET, ICON_IDENTITY, ICON_KONTACT, ICON_CAMERA,
    ICON_IRKICKFLASH, ICON_KGPG_KEY3, ICON_LAPTOP_POWER, ICON_SCANNER, ICON_MOZILLA_FIREBIRD,
    ICON_CDROM_UNMOUNT, ICON_DISPLAY, ICON_MAIL_GENERIC, ICON_MISC, ICON_KORGANIZER, ICON_ASCII, ICON_ICONS,
    ICON_CONNECT_ESTABLISHED, ICON_FOLDER_MAIL, ICON_FILESAVE, ICON_NFS_UNMOUNT, ICON_MESSAGE, ICON_KGPG_TERM,
    ICON_KONSOLE, ICON_FILEPRINT, ICON_FSVIEW, ICON_RUN, ICON_CONFIGURE, ICON_KRFB, ICON_ARK,
    ICON_KPERCENTAGE, ICON_SAMBA_UNMOUNT, ICON_HISTORY, ICON_MAIL_FIND, ICON_VECTORGFX, ICON_KCMMEMORY,
    ICON_TRASHCAN_FULL, ICON_KNOTES, ICON_CANCEL, ICON_HELP, ICON_KPACKAGE, ICON_FOLDER,
    ICON_FOLDER_BLUE_OPEN, ICON_FOLDER_TAR, ICON_DECRYPTED, ICON_ENCRYPTED, ICON_APPLY, ICON_SIGNATURE,
    ICON_THUMBNAIL, ICON_KADDRESSBOOK, ICON_VIEW_TEXT, ICON_KGPG, ICON_PACKAGE_DEVELOPMENT, ICON_KFM_HOME,
    ICON_SERVICES, ICON_TUX, ICON_FEATHER, ICON_APPLE, ICON_W, ICON_MONEY, ICON_CERTIFICATE, ICON_SMARTPHONE,
) {
    $ICON{$icon} = $ICON{0+$icon} = $icon;
}
sub to_icon_constant { $ICON{$_[0] // ''} // ICON_PASSWORD }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::Constants - All the KDBX-related constants you could ever want

=head1 VERSION

version 0.903

=head1 SYNOPSIS

    use File::KDBX::Constants qw(:all);

    say KDBX_VERSION_4_1;

=head1 DESCRIPTION

This module provides importable constants related to KDBX. Constants can be imported individually or in groups
(by tag). The available tags are:

=over 4

=item *

L</:magic>

=item *

L</:version>

=item *

L</:header>

=item *

L</:compression>

=item *

L</:cipher>

=item *

L</:random_stream>

=item *

L</:kdf>

=item *

L</:variant_map>

=item *

L</:inner_header>

=item *

L</:key_file>

=item *

L</:history>

=item *

L</:icon>

=item *

L</:bool>

=item *

L</:time>

=item *

L</:yubikey>

=item *

C<:all> - All of the above

=back

View the source of this module to see the constant values (but really you shouldn't care).

=head1 FUNCTIONS

=head2 to_header_constant

    $constant = to_header_constant($number);
    $constant = to_header_constant($string);

Get a header constant from an integer or string value.

=head2 to_compression_constant

    $constant = to_compression_constant($number);
    $constant = to_compression_constant($string);

Get a compression constant from an integer or string value.

=head2 to_inner_header_constant

    $constant = to_inner_header_constant($number);
    $constant = to_inner_header_constant($string);

Get an inner header constant from an integer or string value.

=head2 to_icon_constant

    $constant = to_icon_constant($number);
    $constant = to_icon_constant($string);

Get an icon constant from an integer or string value.

=head1 CONSTANTS

=head2 :magic

Constants related to identifying the file types:

=over 4

=item C<KDBX_SIG1>

=item C<KDBX_SIG1_FIRST_BYTE>

=item C<KDBX_SIG2_1>

=item C<KDBX_SIG2_2>

=back

=head2 :version

Constants related to identifying the format version of a file:

=over 4

=item C<KDBX_VERSION_2_0>

=item C<KDBX_VERSION_3_0>

=item C<KDBX_VERSION_3_1>

=item C<KDBX_VERSION_4_0>

=item C<KDBX_VERSION_4_1>

=item C<KDBX_VERSION_OLDEST>

=item C<KDBX_VERSION_LATEST>

=item C<KDBX_VERSION_MAJOR_MASK>

=item C<KDBX_VERSION_MINOR_MASK>

=back

=head2 :header

Constants related to parsing and generating KDBX file headers:

=over 4

=item C<HEADER_END>

=item C<HEADER_COMMENT>

=item C<HEADER_CIPHER_ID>

=item C<HEADER_COMPRESSION_FLAGS>

=item C<HEADER_MASTER_SEED>

=item C<HEADER_TRANSFORM_SEED>

=item C<HEADER_TRANSFORM_ROUNDS>

=item C<HEADER_ENCRYPTION_IV>

=item C<HEADER_INNER_RANDOM_STREAM_KEY>

=item C<HEADER_STREAM_START_BYTES>

=item C<HEADER_INNER_RANDOM_STREAM_ID>

=item C<HEADER_KDF_PARAMETERS>

=item C<HEADER_PUBLIC_CUSTOM_DATA>

=back

=head2 :compression

Constants related to identifying the compression state of a file:

=over 4

=item C<COMPRESSION_NONE>

=item C<COMPRESSION_GZIP>

=back

=head2 :cipher

Constants related to ciphers:

=over 4

=item C<CIPHER_UUID_AES128>

=item C<CIPHER_UUID_AES256>

=item C<CIPHER_UUID_CHACHA20>

=item C<CIPHER_UUID_SALSA20>

=item C<CIPHER_UUID_SERPENT>

=item C<CIPHER_UUID_TWOFISH>

=back

=head2 :random_stream

Constants related to memory protection stream ciphers:

=over 4

=item C<STREAM_ID_RC4_VARIANT>

This is insecure and not implemented.

=item C<STREAM_ID_SALSA20>

=item C<STREAM_ID_CHACHA20>

=item C<STREAM_SALSA20_IV>

=back

=head2 :kdf

Constants related to key derivation functions and configuration:

=over 4

=item C<KDF_UUID_AES>

=item C<KDF_UUID_AES_CHALLENGE_RESPONSE>

This is what KeePassXC calls C<KDF_AES_KDBX4>.

=item C<KDF_UUID_ARGON2D>

=item C<KDF_UUID_ARGON2ID>

=item C<KDF_PARAM_UUID>

=item C<KDF_PARAM_AES_ROUNDS>

=item C<KDF_PARAM_AES_SEED>

=item C<KDF_PARAM_ARGON2_SALT>

=item C<KDF_PARAM_ARGON2_PARALLELISM>

=item C<KDF_PARAM_ARGON2_MEMORY>

=item C<KDF_PARAM_ARGON2_ITERATIONS>

=item C<KDF_PARAM_ARGON2_VERSION>

=item C<KDF_PARAM_ARGON2_SECRET>

=item C<KDF_PARAM_ARGON2_ASSOCDATA>

=item C<KDF_DEFAULT_AES_ROUNDS>

=item C<KDF_DEFAULT_ARGON2_ITERATIONS>

=item C<KDF_DEFAULT_ARGON2_MEMORY>

=item C<KDF_DEFAULT_ARGON2_PARALLELISM>

=item C<KDF_DEFAULT_ARGON2_VERSION>

=back

=head2 :variant_map

Constants related to parsing and generating KDBX4 variant maps:

=over 4

=item C<VMAP_VERSION>

=item C<VMAP_VERSION_MAJOR_MASK>

=item C<VMAP_TYPE_END>

=item C<VMAP_TYPE_UINT32>

=item C<VMAP_TYPE_UINT64>

=item C<VMAP_TYPE_BOOL>

=item C<VMAP_TYPE_INT32>

=item C<VMAP_TYPE_INT64>

=item C<VMAP_TYPE_STRING>

=item C<VMAP_TYPE_BYTEARRAY>

=back

=head2 :inner_header

Constants related to parsing and generating KDBX4 inner headers:

=over 4

=item C<INNER_HEADER_END>

=item C<INNER_HEADER_INNER_RANDOM_STREAM_ID>

=item C<INNER_HEADER_INNER_RANDOM_STREAM_KEY>

=item C<INNER_HEADER_BINARY>

=item C<INNER_HEADER_BINARY_FLAG_PROTECT>

=back

=head2 :key_file

Constants related to identifying key file types:

=over 4

=item C<KEY_FILE_TYPE_BINARY>

=item C<KEY_FILE_TYPE_HASHED>

=item C<KEY_FILE_TYPE_HEX>

=item C<KEY_FILE_TYPE_XML>

=back

=head2 :history

Constants for history-related default values:

=over 4

=item C<HISTORY_DEFAULT_MAX_AGE>

=item C<HISTORY_DEFAULT_MAX_ITEMS>

=item C<HISTORY_DEFAULT_MAX_SIZE>

=back

=head2 :iteration

Constants for searching algorithms.

=over 4

=item C<ITERATION_IDS> - Iterative deepening search

=item C<ITERATION_BFS> - Breadth-first search

=item C<ITERATION_DFS> - Depth-first search

=back

=head2 :icon

Constants for default icons used by KeePass password safe implementations:

=over 4

=item C<ICON_PASSWORD>

=item C<ICON_PACKAGE_NETWORK>

=item C<ICON_MESSAGEBOX_WARNING>

=item C<ICON_SERVER>

=item C<ICON_KLIPPER>

=item C<ICON_EDU_LANGUAGES>

=item C<ICON_KCMDF>

=item C<ICON_KATE>

=item C<ICON_SOCKET>

=item C<ICON_IDENTITY>

=item C<ICON_KONTACT>

=item C<ICON_CAMERA>

=item C<ICON_IRKICKFLASH>

=item C<ICON_KGPG_KEY3>

=item C<ICON_LAPTOP_POWER>

=item C<ICON_SCANNER>

=item C<ICON_MOZILLA_FIREBIRD>

=item C<ICON_CDROM_UNMOUNT>

=item C<ICON_DISPLAY>

=item C<ICON_MAIL_GENERIC>

=item C<ICON_MISC>

=item C<ICON_KORGANIZER>

=item C<ICON_ASCII>

=item C<ICON_ICONS>

=item C<ICON_CONNECT_ESTABLISHED>

=item C<ICON_FOLDER_MAIL>

=item C<ICON_FILESAVE>

=item C<ICON_NFS_UNMOUNT>

=item C<ICON_MESSAGE>

=item C<ICON_KGPG_TERM>

=item C<ICON_KONSOLE>

=item C<ICON_FILEPRINT>

=item C<ICON_FSVIEW>

=item C<ICON_RUN>

=item C<ICON_CONFIGURE>

=item C<ICON_KRFB>

=item C<ICON_ARK>

=item C<ICON_KPERCENTAGE>

=item C<ICON_SAMBA_UNMOUNT>

=item C<ICON_HISTORY>

=item C<ICON_MAIL_FIND>

=item C<ICON_VECTORGFX>

=item C<ICON_KCMMEMORY>

=item C<ICON_TRASHCAN_FULL>

=item C<ICON_KNOTES>

=item C<ICON_CANCEL>

=item C<ICON_HELP>

=item C<ICON_KPACKAGE>

=item C<ICON_FOLDER>

=item C<ICON_FOLDER_BLUE_OPEN>

=item C<ICON_FOLDER_TAR>

=item C<ICON_DECRYPTED>

=item C<ICON_ENCRYPTED>

=item C<ICON_APPLY>

=item C<ICON_SIGNATURE>

=item C<ICON_THUMBNAIL>

=item C<ICON_KADDRESSBOOK>

=item C<ICON_VIEW_TEXT>

=item C<ICON_KGPG>

=item C<ICON_PACKAGE_DEVELOPMENT>

=item C<ICON_KFM_HOME>

=item C<ICON_SERVICES>

=item C<ICON_TUX>

=item C<ICON_FEATHER>

=item C<ICON_APPLE>

=item C<ICON_W>

=item C<ICON_MONEY>

=item C<ICON_CERTIFICATE>

=item C<ICON_SMARTPHONE>

=back

=head2 :bool

Boolean values:

=over 4

=item C<FALSE>

=item C<TRUE>

=back

=head2 :time

Constants related to time:

=over 4

=item C<TIME_SECONDS_AD1_TO_UNIX_EPOCH>

=back

=head2 :yubikey

Constants related to working with YubiKeys:

=over 4

=item C<YUBICO_VID>

=item C<YUBIKEY_PID>

=item C<NEO_OTP_PID>

=item C<NEO_OTP_CCID_PID>

=item C<NEO_CCID_PID>

=item C<NEO_U2F_PID>

=item C<NEO_OTP_U2F_PID>

=item C<NEO_U2F_CCID_PID>

=item C<NEO_OTP_U2F_CCID_PID>

=item C<YK4_OTP_PID>

=item C<YK4_U2F_PID>

=item C<YK4_OTP_U2F_PID>

=item C<YK4_CCID_PID>

=item C<YK4_OTP_CCID_PID>

=item C<YK4_U2F_CCID_PID>

=item C<YK4_OTP_U2F_CCID_PID>

=item C<PLUS_U2F_OTP_PID>

=item C<ONLYKEY_VID>

=item C<ONLYKEY_PID>

=item C<YK_EUSBERR>

=item C<YK_EWRONGSIZ>

=item C<YK_EWRITEERR>

=item C<YK_ETIMEOUT>

=item C<YK_ENOKEY>

=item C<YK_EFIRMWARE>

=item C<YK_ENOMEM>

=item C<YK_ENOSTATUS>

=item C<YK_ENOTYETIMPL>

=item C<YK_ECHECKSUM>

=item C<YK_EWOULDBLOCK>

=item C<YK_EINVALIDCMD>

=item C<YK_EMORETHANONE>

=item C<YK_ENODATA>

=item C<CONFIG1_VALID>

=item C<CONFIG2_VALID>

=item C<CONFIG1_TOUCH>

=item C<CONFIG2_TOUCH>

=item C<CONFIG_LED_INV>

=item C<CONFIG_STATUS_MASK>

=back

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
