# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Base;

use v5.16;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(blessed);

use Data::Identifier v0.08;

use constant { # Taken from Data::Identifier
    RE_UUID     => qr/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/,
    RE_OID      => qr/^[0-2](?:\.(?:0|[1-9][0-9]*))+$/,
    RE_URI      => qr/^[a-zA-Z][a-zA-Z0-9\+\.\-]+/,

    WK_WM_NONE  => '7b177183-083c-4387-abd3-8793eb647373',
    WK_FINAL    => 'f418cdb9-64a7-4f15-9a18-63f7755c5b47',
};

our $VERSION = v0.07;

our %_digest_name_converter = ( # stolen from Data::URIID::Result
    fc('md5')   => 'md-5-128',
    fc('sha1')  => 'sha-1-160',
    fc('sha-1') => 'sha-1-160',
    fc('ripemd-160') => 'ripemd-1-160',
    (map {
        fc('sha'.$_)   => 'sha-2-'.$_,
        fc('sha-'.$_)  => 'sha-2-'.$_,
        fc('sha3-'.$_) => 'sha-3-'.$_,
        } qw(224 256 384 512)),
);

our %_digest_info_extra = (
    'md-5-128'  => {rfc9530 => 'md5'},
    'sha-1-160' => {rfc9530 => 'sha'},
    'sha-2-256' => {rfc9530 => 'sha-256'},
    'sha-2-512' => {rfc9530 => 'sha-512'},
);

our %_mediatypes = ( # Copied from tags-universal
    'application/gzip'                                          => 'a8bb3d20-e983-5060-8c63-95b35e9ca56a',
    'application/http'                                          => '282ff2fd-0e1b-5b34-bda7-9c44b6ef7dc6',
    'application/json'                                          => 'c9e61b78-a0bd-5939-9aaa-8f0d08e5a4dc',
    'application/ld+json'                                       => '999e546d-8dfe-5961-aa5f-bf5cbd0a7037',
    'application/octet-stream'                                  => '4076d9f9-ca42-5976-b41b-e54aa912ccf3',
    'application/ogg'                                           => 'f4a4beee-e0f4-567a-ada4-a15d387a953c',
    'application/pdf'                                           => '03e6c035-e046-5b7e-a016-55b51c4836ea',
    'application/postscript'                                    => '85224b06-7548-5319-b635-4b37dc78880d',
    'application/vnd.debian.binary-package'                     => '026b4c07-00ab-581d-a493-73e0b9b1cff9',
    'application/vnd.oasis.opendocument.base'                   => '319de973-68e2-5a01-af87-6fe4a5b800c6',
    'application/vnd.oasis.opendocument.chart'                  => '271d085d-1a51-5795-86f5-e6849166cbf6',
    'application/vnd.oasis.opendocument.chart-template'         => 'e8d5322b-0d40-5e3d-a754-4dd0ee6a4bb9',
    'application/vnd.oasis.opendocument.formula'                => 'e771c71d-f4b8-56a7-b299-1ede808b91d0',
    'application/vnd.oasis.opendocument.formula-template'       => '4b9eb9eb-786d-5831-89e1-edcba46a2bb6',
    'application/vnd.oasis.opendocument.graphics'               => '322c5088-84c9-59aa-a828-ffe183557457',
    'application/vnd.oasis.opendocument.graphics-template'      => '76d3335e-a49e-54ec-bec5-8e3bb46d8412',
    'application/vnd.oasis.opendocument.image'                  => '869257aa-b61f-5210-af8a-d9a33c356629',
    'application/vnd.oasis.opendocument.image-template'         => '60d259d0-4d58-59c8-81f7-9725f960d415',
    'application/vnd.oasis.opendocument.presentation'           => '7a4abd3a-89ec-53e9-b29d-64c6e2dcdaf4',
    'application/vnd.oasis.opendocument.presentation-template'  => 'b16ebfdd-1b4f-5713-829b-5b35e7a06839',
    'application/vnd.oasis.opendocument.spreadsheet'            => '975706e1-44c3-55d1-b03a-978954a46f3e',
    'application/vnd.oasis.opendocument.spreadsheet-template'   => '52f3046b-e8e4-5c74-8860-b683f1554ad2',
    'application/vnd.oasis.opendocument.text'                   => 'b03df4f0-3f52-5ce0-b3e0-42dd911d244a',
    'application/vnd.oasis.opendocument.text-master'            => '21415b27-ce2a-5b5d-bb98-569ce922c97c',
    'application/vnd.oasis.opendocument.text-master-template'   => '889508ab-6a78-5337-b13a-756a8232baae',
    'application/vnd.oasis.opendocument.text-template'          => '8f0bfe22-f343-5cbb-98c7-d826d0f31e63',
    'application/vnd.oasis.opendocument.text-web'               => '83baa5da-8956-51ff-8ec1-41aee5d5b1eb',
    'application/xhtml+xml'                                     => 'e553c22e-542b-50d8-9abb-aa36625be67e',
    'application/xml'                                           => '371b035f-45b7-5ba2-9d3e-811bf3b937bc',
    'audio/flac'                                                => 'a7ea86ac-4938-5adc-8544-b4908e21c7e4',
    'audio/matroska'                                            => 'e5eae178-ccf2-5659-b23a-3d0d936be8a2',
    'audio/ogg'                                                 => 'ef171c40-2b55-572a-b66f-3d4ecb8182a5',
    'image/gif'                                                 => 'b5ec5cdd-2811-5e51-8b0e-b07d0bd2b570',
    'image/jpeg'                                                => 'c1e9e865-4653-5037-97f3-06c0c1c061a5',
    'image/png'                                                 => '7c859f1d-693b-5070-a928-dfd051a4f93d',
    'image/svg+xml'                                             => '3970f481-591e-530a-b962-a2e87b2efde2',
    'image/webp'                                                => 'd71ad7ca-abd5-59e5-a360-086aa1f39ad0',
    'message/http'                                              => '3f59f23e-d5ca-5f6d-a70e-05aa4d952f36',
    'text/html'                                                 => 'ecd556c0-7ecb-5b88-ab0a-ec4e09d61782',
    'text/plain'                                                => '552ec0dc-8678-5657-9422-8a71ea8e5cd0',
    'video/matroska'                                            => '6155907c-d116-5d88-8d60-850753015fca',
    'video/matroska-3d'                                         => '46ce8e26-b8e3-5cf6-a534-9d1d6dbcae72',
    'video/ogg'                                                 => 'f14a9d8d-daf4-52aa-9ff8-e0815a3e5b65',
    'video/webm'                                                => '0ee63dad-e52f-5c62-9c32-e6b872b828c7',
);

my %_inverse_mediatypes = map {$_mediatypes{$_} => $_} keys %_mediatypes;

my %_ise_re = (
    uuid => RE_UUID,
    oid  => RE_OID,
    uri  => RE_URI,
);

my %_known_digest_algos = map {$_ => undef} (
    values(%_digest_name_converter),
    qw(md-4-128 ripemd-1-160 tiger-1-192 tiger-2-192),
);


my %_ise_keys = map {$_ => 1} qw(ise uuid oid uri);
my %_data_identifier_keys = map {$_ => 1} keys %_ise_keys;

my %_properties = (
    uuid        => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_uuid tagpool_directory_setting_tag uuid(xattr_utag_ise) uuid(db_inode_tag) :self dev_disk_by_uuid tagpool_pool_uuid)], rawtype => 'uuid'},
    oid         => {loader => \&_load_aggregate, sources => [qw(::Inode oid(xattr_utag_ise) oid(db_inode_tag))], rawtype => 'oid'},
    uri         => {loader => \&_load_aggregate, sources => [qw(::Inode uri(xattr_utag_ise) uri(db_inode_tag))], rawtype => 'uri'},
    ise         => {loader => \&_load_aggregate, sources => [qw(:self uuid oid uri ::Inode xattr_utag_ise ::Base data_uriid_ise)], rawtype => 'ise'},
    inodeise    => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_uuid tagpool_directory_setting_tag xattr_utag_ise db_inode_tag)], rawtype => 'ise'},
    contentise  => {loader => \&_load_aggregate, sources => [qw(::Inode content_sha_1_160_sha_3_512_uuid content_sha_3_512_uuid)], rawtype => 'ise'},

    size        => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_size xattr_utag_final_file_size xattr_utag_final_file_hash_size st_size ::Base data_tagdb_size)]},
    title       => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_title        tagpool_directory_title         xattr_dublincore_title dotcomments_caption ::Deep pdf_info_title odf_info_title audio_scan_title)]},
    comment     => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_comment      tagpool_directory_comment       xattr_xdg_comment      dotcomments_note)]},
    description => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_description  tagpool_directory_description   xattr_dublincore_description)]},
    displayname => {loader => \&_load_aggregate, sources => [qw(:self   title link_basename_clean dev_disk_by_label dev_mapper_name dev_name data_uriid_attr_displayname)]},
    mediatype   => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_mediatype xattr_utag_final_file_encoding magic_mediatype ::Base data_uriid_attr_media_subtype data_tagdb_encoding)], rawtype => 'mediatype'},
    writemode   => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_write_mode xattr_utag_write_mode)], rawtype => 'ise'},
    pages       => {loader => \&_load_aggregate, sources => [qw(::Deep pdf_pages odf_stats_meta_page_count)]},

    thumbnail   => {loader => \&_load_aggregate, sources => [qw(::Link link_thumbnail ::Inode tagpool_file_thumbnail)], rawtype => 'filename'},
    finalmode   => {loader => \&_load_aggregate, sources => [qw(::Inode tagpool_file_finalmode xattr_utag_final_mode)], rawtype => 'ise'},
    hidden      => {loader => \&_load_aggregate, sources => [qw(::Link link_dotfile ::Inode ntfs_file_attribute_hidden)], rawtype => 'bool', towards => 1},
    system      => {loader => \&_load_aggregate, sources => [qw(::Inode ntfs_file_attribute_system)], rawtype => 'bool', towards => 1},
    readonly    => {loader => \&_load_readonly, rawtype => 'bool'},

    fetchurl    => {loader => \&_load_aggregate, sources => [qw(:self tagpool_file_original_url xattr_xdg_origin_url zonetransfer_hosturl)]},

    # TODO: displaycolour icontext charset (hash) (mediatype / encoding)

    data_tagdb_size         => {loader => \&_load_data_tagdb},
    data_tagdb_displayname  => {loader => \&_load_data_tagdb},
    data_tagdb_fetch_uri    => {loader => \&_load_data_tagdb, rawtype => 'uri'},
    data_tagdb_encoding     => {loader => \&_load_data_tagdb, rawtype => 'Data::TagDB::Tag'},
    data_tagdb_charset      => {loader => \&_load_data_tagdb, rawtype => 'Data::TagDB::Tag'},
);

my @_digest_preload_properties = qw(xattr_utag_final_file_hash xattr_utag_final_file_size tagpool_file_size);

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    croak 'No instance is given' unless defined $self->{instance};

    $self->{properties} //= {}; # empty list.

    return $self;
}


sub get {
    my ($self, $key, %opts) = @_;
    my $info = $self->{properties}{$key} // $_properties{$key};
    my $rawtype = $info->{rawtype};
    my $pv = $self->{properties_values} //= {};
    my $v;
    my $res;
    my $as;
    my $lifecycle;

    unless (defined $info) {
        return $opts{default} if exists $opts{default};
        croak 'Unknown key '.$key;
    }

    $as = $opts{as} //= $info->{default_as} // 'raw';
    $lifecycle = $opts{lifecycle} //= 'current';

    $pv = $pv->{$lifecycle} //= {};

    # load the value if needed.
    if ((!defined($pv->{$key}) || (ref($pv->{$key}) eq 'HASH' && !scalar(%{$pv->{$key}}))) && defined(my $loader = $info->{loader})) {
        $loader = $self->can($loader) unless ref $loader;
        $self->$loader($key, %opts, list => undef);
    }

    $v = $pv->{$key} //= {};

    if ($opts{list}) {
        my $default = delete $opts{default};

        delete $opts{list};

        if (ref($v) eq 'ARRAY') {
            my @list;
            my $error;

            foreach my $entry (@{$v}) {
                local $pv->{$key} = $entry;
                my $val = $self->get($key, %opts, default => undef);

                if (defined $val) {
                    push(@list, $val);
                } else {
                    $error = 1;
                    last;
                }
            }

            if ($error) {
                return @{$default} if defined $default;
                $v = {}; # handle like an empty entry.
            } else {
                return @list;
            }
        } else {
            my $val = $self->get($key, %opts, default => undef);

            #warn sprintf('key=%s, v=%s, val=%s, default=%s', $key, $v, $val // '<undef>', $default // '<undef>');
            if (defined $val) {
                return ($val);
            } else {
                return @{$default} if defined $default;
                #confess 'Doof';
                $v = {}; # handle like an empty entry.
            }
        }
    } elsif (ref($v) eq 'ARRAY') {
        $v = {}; # handle like an empty entry.
    }

    # Update rawtype as needed:
    $rawtype = $v->{rawtype} // $rawtype;

    # Try: Check if we have what we want.
    $res = $v->{$as};

    # Try: Check if we can convert (rawtype, raw) to what we want.
    if (!defined($res) && defined($rawtype) && defined(my $raw = $v->{raw})) {
        if ($rawtype eq $as) {
            $res = $raw;
        } elsif ($rawtype eq 'unixts' && $as eq 'DateTime') {
            require DateTime;
            $res = DateTime->from_epoch(epoch => $raw, time_zone => 'UTC');
        } elsif ($rawtype eq 'ise' && defined(my $re = $_ise_re{$as})) {
            $res = $raw if $raw =~ $re;
        } elsif ($_data_identifier_keys{$rawtype} && $as eq 'Data::Identifier') {
            $res = Data::Identifier->new($rawtype => $raw);
        } elsif ($_ise_keys{$rawtype} && $as eq 'Data::URIID::Result') {
            $res = $self->instance->extractor->lookup(ise => $raw);
        } elsif ($rawtype eq 'filename' && $as eq 'File::Information::Link') {
            $res = $self->instance->for_link($raw);
        } elsif ($rawtype eq 'filename' && ($as eq 'IO::Handle' || $as eq 'IO::File')) {
            require IO::File;
            $res = IO::File->new($raw, 'r');
        } elsif (exists($_ise_re{$rawtype}) && $as eq 'Data::TagDB::Tag' && $self->instance->db) {
            $res = eval {$self->instance->db->tag_by_id($rawtype => $raw)};
        }

        $v->{$as} = $res if defined($res) && $as !~ /^IO::/; # Cache unless it is a file handle.
    }

    if (!defined($res) && blessed($v->{raw})) {
        $res = eval {$v->{raw}->Data::Identifier::as($as, db => $self->db, extractor => $self->extractor)};
    }

    # Try: Check if we have a Data::Identifier and want a sid.
    if (!defined($res) && $as eq 'sid' && defined(my $identifier = $v->{'Data::Identifier'})) {
        $v->{sid} = $res if defined($res = eval {$identifier->sid});
    }

    # Try: Check if we can manage to get hold of a ISE in some way.
    if (!defined($res) && !defined($v->{ise}) && defined($rawtype) && $rawtype eq 'ise') {
        $v->{ise} = $v->{raw};
    }
    if (!defined($res) && !defined($v->{ise})) {
        foreach my $key (keys %_ise_re) {
            last if defined($v->{ise} = $v->{$key});
            last if defined($rawtype) && $rawtype eq $key && defined($v->{ise} = $v->{raw});
        }
    }
    if (!defined($res) && !defined($v->{ise}) && ($rawtype // '') eq 'mediatype') {
        $v->{ise} = $_mediatypes{$v->{raw} // ''};
    }
    if (!defined($res) && !defined($v->{ise})) {
        foreach my $source_type (qw(Data::Identifier Data::URIID::Result Data::URIID::Colour Data::TagDB::Tag)) {
            if (defined(my $obj = $v->{$source_type})) {
                last if defined($v->{ise} = eval {$obj->ise});
            }
            if (defined($rawtype) && $rawtype eq $source_type && defined(my $obj = $v->{raw})) {
                last if defined($v->{ise} = eval {$obj->ise});
            }
        }
    }

    delete $v->{ise} unless defined $v->{ise}; # TODO: Figure out where it is set to undef

    # Try: Check if we have an ISE and can convert that to what we want.
    if (!defined($res) && defined(my $ise = $v->{ise})) {
        if ($as eq 'Data::Identifier') {
            $res = Data::Identifier->new(ise => $ise);
        } elsif ($as eq 'Data::URIID::Result') {
            $res = $self->instance->extractor->lookup(ise => $ise);
        } elsif ($as eq 'Data::TagDB::Tag' && $self->instance->db) {
            foreach my $type (keys %_ise_re) {
                if ($ise =~ $_ise_re{$type}) {
                    $res = eval {$self->instance->db->tag_by_id($type => $ise)} and last;
                }
            }
        } elsif (defined(my $re = $_ise_re{$as})) {
            $res = $ise if $ise =~ $re;
        } elsif ($as eq 'sid') {
            my $identifier = $v->{'Data::Identifier'} = Data::Identifier->new(ise => $ise);
            $res = eval {$identifier->sid};
        } elsif ($as eq 'mediatype') {
            $res = $_inverse_mediatypes{$ise};
        }

        $v->{$as} = $res if defined($res) && $as !~ /^IO::/; # Cache unless it is a file handle.
    }

    return $res if defined $res;

    return $opts{default} if exists $opts{default};

    confess 'Cannot get value for key '.$key;
}


sub property_info {
    my ($self, @algos) = @_;
    my @ret;

    unless ($self->{property_info}) {
        my %properties = map {$_ => {
                name => $_,
            }} keys %{$self->{properties}}, keys %_properties;
        $self->{property_info} = \%properties;
    }

    @algos = keys %{$self->{property_info}} unless scalar @algos;

    croak 'Request for more than one property in scalar context' if !wantarray && scalar(@algos) != 1;

    @ret = map{
        $self->{property_info}{$_} ||
        croak 'Unknown property: '.$_
    } @algos;

    if (wantarray) {
        return @ret;
    } else {
        return $ret[0];
    }
}


sub digest {
    my ($self, $key, %opts) = @_;
    my $as = $opts{as} // 'hex';
    my $lifecycle = $opts{lifecycle} //= 'current';
    my $value;

    # convert L<Digest> name into utag name if needed:
    $key = $_digest_name_converter{fc($key)} // $key;

    # Check utag name:
    if ($key !~ /^[a-z]+-[0-9]+-[1-9][0-9]*$/) {
        croak sprintf('Unknown digest format "%s"', $key);
    }

    foreach my $property (@_digest_preload_properties) {
        eval {$self->get($property, lifecycle => $lifecycle)};
    }

    $value = $self->{digest}{$lifecycle}{$key};

    if (!defined($value) && $lifecycle eq 'current' && $self->isa('File::Information::Inode') && !$opts{no_defaults}) {
        my $size = $self->get('size', default => undef);
        my $limit = $self->instance->{digest_sizelimit};

        if (defined($size) && ($limit == -1 || $size <= $limit)) {
            my $digest;

            eval {
                if ($key eq 'md-5-128') {
                    require Digest;
                    $digest = Digest->new('MD5');
                } elsif ($key eq 'sha-1-160') {
                    require Digest;
                    $digest = Digest->new('SHA-1');
                } elsif ($key eq 'ripemd-1-160') {
                    require Digest;
                    $digest = Digest->new('RIPEMD-160');
                } elsif ($key =~ /^sha-2-(224|256|384|512)$/) {
                    require Digest;
                    $digest = Digest->new('SHA-'.$1);
                } elsif ($key =~ /^sha-3-(224|256|384|512)$/) {
                    require Digest::SHA3;
                    $digest = Digest::SHA3->new($1);
                }
            };

            if (defined $digest) {
                eval {
                    my $fh = $self->_get_fh;

                    if (defined $fh) {
                        $digest->addfile($fh);
                        $self->{digest}{$lifecycle}{$key} = $value = $digest->hexdigest;
                    }
                };
            }
        }
    }

    unless (defined $value) {
        return $opts{default} if exists $opts{default};
        croak 'No such value for digest '.$key;
    }

    if ($as eq 'hex') {
        return $value;
    } elsif ($as eq 'binary') {
        return pack('H*', $value);
    } elsif ($as eq 'base64' || $as eq 'b64') {
        require MIME::Base64;
        return MIME::Base64::encode(pack('H*', $value), '') =~ s/=+$//r;
    } elsif ($as eq 'base64_padded') {
        require MIME::Base64;
        return MIME::Base64::encode(pack('H*', $value), '');
    } elsif ($as eq 'utag') {
        if (defined(my $size = $self->get('size', lifecycle => $lifecycle, default => undef))) {
            if ($size > 0) {
                return sprintf('v0 %s bytes 0-%u/%u %s', $key, $size - 1, $size, $value);
            } else {
                return sprintf('v0 %s bytes 0-/%u %s', $key, $size, $value);
            }
        }

        return sprintf('v0 %s bytes 0-/* %s', $key, $value);
    } elsif ($as eq 'Digest') {
        require Data::URIID::Digest;
        return Data::URIID::Digest->_new($value); # Not public API but developed by same developers as this module.
                                                  # DO NOT USE THIS IN YOUR CODE!
    }

    croak sprintf('Cannot convert from type "%s" to "%s" for digest "%s"', 'hex', $as, $key);
}



#@returns File::Information::VerifyBase
sub verify {
    my ($self, %opts) = @_;
    require File::Information::VerifyResult;
    return File::Information::VerifyResult->_new(base => $self, instance => $self->instance, %opts{'lifecycle_from', 'lifecycle_to', 'base_from', 'base_to'});
}


sub uuid            { return $_[0]->get('uuid',             @_[1..$#_]); }
sub oid             { return $_[0]->get('oid',              @_[1..$#_]); }
sub uri             { return $_[0]->get('uri',              @_[1..$#_]); }
sub ise             { return $_[0]->get('ise',              @_[1..$#_]); }
sub displayname     { return $_[0]->get('displayname',      @_[1..$#_]); }
sub displaycolour   { return $_[0]->get('displaycolour',    @_[1..$#_]); }
sub icontext        { return $_[0]->get('icontext',         @_[1..$#_]); }
sub description     { return $_[0]->get('description',      @_[1..$#_]); }



#@returns File::Information
sub instance {
    my ($self) = @_;
    return $self->{instance};
}


#@returns Data::URIID
sub extractor {
    my ($self, @args) = @_;
    return $self->{extractor} //= $self->instance->extractor(@args);
}

#@returns Data::TagDB
sub db {
    my ($self, @args) = @_;
    return $self->{db} //= $self->instance->db(@args);
}

sub digest_info {
    my ($self, @args) = @_;
    return $self->instance->digest_info(@args);
}

#@returns File::Information::Editor
sub editor {
    my ($self) = @_;
    require File::Information::Editor;
    return File::Information::Editor->_new(parent => $self);
}

# ----------------
sub _set_digest_utag {
    my ($self, $lifecycle, $v, $given_size) = @_;
    my %digest;

    eval {
        while ($v =~ s/^(v0m?) ([a-z]+)-([0-9]+)-([0-9]+) bytes 0-([0-9]+)\/([0-9]+) ([0-9a-f]+)( |$)//) {
            my ($type, $name, $version, $bits, $end, $size, $hash, $mark) = ($1, $2, $3, $4, $5, $6, $7, $8);
            next if $end != ($size - 1);
            die if (length($hash) * 4) != $bits;
            die if $type eq 'v0' && length($mark);

            $given_size //= $size;
            die unless $given_size == $size;
            $digest{join('-', $name, $version, $bits)} = $hash;
        }
    };

    $self->{digest} //= {};

    {
        my $digests = $self->{digest}{$lifecycle} //= {};
        foreach my $algo (keys %digest) {
            $digests->{$algo} //= $digest{$algo};
        }
    }

    return $given_size;
}

sub _load_aggregate {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{$opts{lifecycle}} //= {};
    my $info = $_properties{$key};
    my $current = $self;

    return unless defined($info) && defined($info->{sources});

    foreach my $source (@{$info->{sources}}) {
        if ($source eq ':self') {
            $current = $self;
        } elsif ($source =~ /^::/) {
            $current = undef;

            if ($self->isa('File::Information'.$source)) {
                $current = $self;
            } elsif ($source eq '::Inode') {
                $current = eval{$self->inode};
            } elsif ($source eq '::Filesystem') {
                $current = eval{$self->filesystem};
            } elsif ($source eq '::Deep') {
                $current = eval{$self->deep(no_defaults => 1, default => undef)};
            }
        } elsif (!defined $current) {
            next;
        } elsif ($source =~ /^([a-z]+)\((.+)\)$/) {
            my $func = $1;
            my $re = $_ise_re{$func} // croak 'BUG';
            my $value = $current->get($2, %opts, default => undef, as => 'raw');

            if (defined($value) && eval {$value->isa('Data::TagDB::Tag')}) {
                if (defined(my $c = $value->can($func))) {
                    $value = $value->$c(no_defaults => 1, default => undef);
                }
            }

            if (defined($value) && !ref($value) && $value =~ $re) {
                if (defined($pv->{$key}) && defined($info->{towards})) {
                    next if ($value xor $info->{towards});
                }

                $pv->{$key} = {raw => $value};
            }
        } else {
            my $value_ref;

            #warn sprintf('%s <- %s %s %s', $key, $current, $source, $opts{lifecycle});
            next unless defined $current->get($source, %opts, default => undef, as => 'raw');

            $value_ref = eval {$current->{properties_values}{$opts{lifecycle}}{$source}};

            if (defined($value_ref) && defined($pv->{$key}) && defined($info->{towards})) {
                next if ($value_ref->{raw} xor $info->{towards});
            }

            $pv->{$key} = $value_ref;
        }

        last if !defined($info->{towards}) && defined($pv->{$key}) && scalar(keys %{$pv->{$key}});
    }
}

sub _load_readonly {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{$opts{lifecycle}} //= {};
    my $info = $_properties{$key};
    my $inode = eval {$self->isa('File::Information::Inode') ? $self : $self->inode};
    my $v = $opts{lifecycle} eq 'final';

    return unless defined($info);

    if (defined $inode) {
        $v ||= $inode->get('stat_readonly', %opts, default => undef, as => 'raw');
        $v ||= $inode->get('ntfs_file_attribute_readonly', %opts, default => undef, as => 'raw');
    }

    $v ||= $self->get('writemode', %opts, default => '', as => 'uuid') eq WK_WM_NONE;
    $v ||= $self->get('finalmode', %opts, default => '', as => 'uuid') eq WK_FINAL;

    # Mount options:
    unless ($v) {
        foreach my $option (qw(linux_mount_options linux_superblock_options)) {
            my $value = $self->get($option, %opts, default => undef, as => 'raw') // next;
            $v ||= $value =~ /^ro(?:,.+)?$/ || $value =~ /,ro$/;
        }
    }

    $pv->{$key} = {raw => $v};
}

sub _load_data_tagdb {
    my ($self) = @_;
    my $pv_current  = ($self->{properties_values} //= {})->{current} //= {};
    my $pv_final    = ($self->{properties_values} //= {})->{final} //= {};

    return if $self->{_loaded_data_tagdb};
    $self->{_loaded_data_tagdb} = 1;

    if (defined(my $db = eval {$self->db})) {
        my $wk = $db->wk;
        my %tags;
        my %final_metadata = (
            data_tagdb_size         => $wk->final_file_size,
            data_tagdb_fetch_uri    => $db->tag_by_id(uuid => '96674c6c-cf5e-40cd-af1e-63b86e741f4f'),
        );
        my %final_relation = (
            data_tagdb_encoding     => $wk->final_file_encoding,
            data_tagdb_charset      => $db->tag_by_id(uuid => '99437f71-f1b5-4a50-8ecf-882b61b86b1e'),
        );

        foreach my $key (qw(data_uriid_result contentise inodeise ise)) {
            my $tag = $self->get($key, as => 'Data::TagDB::Tag', default => undef) // next;
            $tags{$tag->dbid} = $tag;
        }

        foreach my $tag (values %tags) {
            my $given_size;

            if (defined(my $displayname = $tag->displayname(default => undef, no_defaults => 1))) {
                my $l = $pv_current->{data_tagdb_displayname} //= [];
                push(@{$l}, {raw => $displayname});
            }

            foreach my $key (keys %final_metadata) {
                my $relation = $final_metadata{$key} // next;
                $db->metadata(tag => $tag, relation => $relation)->foreach(sub {
                        my ($entry) = @_;
                        my $l = $pv_final->{$key} //= [];
                        push(@{$l}, {raw => $entry->data_raw});
                    });
            }

            foreach my $key (keys %final_relation) {
                my $relation = $final_relation{$key} // next;
                $db->relation(tag => $tag, relation => $relation)->foreach(sub {
                        my ($entry) = @_;
                        my $l = $pv_final->{$key} //= [];
                        push(@{$l}, {raw => $entry->related, rawtype => 'Data::TagDB::Tag'});
                    });
            }

            if (defined(my $relation = $wk->final_file_hash)) {
                $db->metadata(tag => $tag, relation => $relation)->foreach(sub {
                        my ($entry) = @_;
                        $given_size = $self->_set_digest_utag(final => $entry->data_raw, $given_size);
                    });
            }

            push(@{$pv_final->{data_tagdb_size} //= []}, {raw => $given_size}) if defined $given_size;

            {
                my @size_values = map {int($_->{raw})} @{$pv_final->{data_tagdb_size}};
                if (scalar @size_values) {
                    $given_size //= $size_values[0];
                    foreach my $size (@size_values) {
                        if ($given_size != $size) {
                            $given_size = undef;
                            last;
                        }
                    }
                    $pv_final->{data_tagdb_size} = defined($given_size) ? {raw => $given_size} : undef;
                }
            }

            foreach my $key (keys(%final_metadata), keys(%final_relation)) {
                if (ref($pv_final->{$key}) eq 'ARRAY' && scalar(@{$pv_final->{$key}}) == 1) {
                    $pv_final->{$key} = $pv_final->{$key}->[0];
                }
            }
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Base - generic module for extracting information from filesystems

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use File::Information;

This is the base package for L<File::Information::Link>, L<File::Information::Inode>, and L<File::Information::Filesystem>.
Common methods are documented in this file. Details (such as supported keys) are documented in the respective modules.

=head1 METHODS

=head2 get

    my $value = $obj->get($key [, %opts]);
    # or:
    my @value = $obj->get($key [, %opts], list => 1);

Get a value for a given key. The keys supported by this function depend on the module.
Below you find a list with keys for aggregated values. Aggregated values are virtual and
may be from different sources.
If a key is not supported and no C<default> option is given, the method will die.

The following optional options are supported:

=over

=item C<as>

The type to get the value in. This is the name of a perl package or special value (in all lower case).
The packages supported depend on the type of data to be returned.
Currently the following special values are supported: C<sid>, C<uuid>, C<oid>, C<uri>, C<ise> (one of UUID, OID, or URI), C<mediatype>, C<raw> (a raw value).
The following packages are supported (they need to be installed):
L<Data::Identifier>,
L<DateTime>,
L<Data::URIID::Result>,
L<Data::TagDB::Tag>,
L<IO::Handle>,
L<File::Information::Link>.

=item C<default>

The value to be returned when no actual value could be read. This can also be C<undef> which switches
from C<die>-ing when no value is available to returning C<undef>.

=item C<lifecycle>

The lifecycle to get the value for. The default is C<current>.
See also L<File::Information/lifecycles>.

=item C<list>

B<Note:>
This is B<experimental>. Exact semantics of this mode may change or it
may be removed completly in later versions.

Enables list support. In list mode this method returns an array of values.
This can be used to access keys that hold multiple values.

To access keys that hold multiple values his mode must be used.
Currently the list mode can also be used on keys that only hole one value.
Then a list of on element is returned.

When this mode is used, C<default> must be an array reference.
Most commonly it will be C<[]>.

=back

The following keys for B<aggregated values> are supported:

=over

=item C<comment>

A comment on the document (if any).

=item C<contentise>

An ISE of the document that refers to it's content (so all bit-perfect copies share this ISE).

=item C<description>

A description of the document (if any).

=item C<displayname>

A string that is suitable for display and likely meaningful to users.

=item C<fetchurl>

An URL the file can be fetched from. This is very often a HTTPS URL. But it may be any valid URL.

=item C<finalmode>

The final mode of the document. Normally this is unset,
auto-final (meaning the document should become final once successfully verifies it's final state),
or final (it reached it's final state).

=item C<hidden>

Hidden files are generally not shown to the user (unless specifically requested).
This is most common for system files or files that hold state information
(like temporary files).

The exact meaning depend on the operating system, the filesystem, and the softwar interacting
with them. On most UNIX like systems files with a filename starting with a dot are considered
hidden (sometimes also called dot-files). On FAT lineage filesystems there is a special hidden attribute.

=item C<inodeise>

An ISE for the inode. All hardlinks share this ISE but (bit-perfect) copies do not.

=item C<ise>

The ISE of the document. That is it's UUID, OID, or URI.

=item C<mediatype>

The media type of the document.

=item C<oid>

The OID of the document.

=item C<pages>

The number of pages in the document.

=item C<readonly>

If the file is ready only. This is different from immutable files in that they still can be deleted (or other file attributes be changed).
B<Note:> In the C<final> lifecycle all files are read only.

=item C<system>

If the file is a system file. The exact meaning system files depend on the operating system.
Generally speaking a user should not write to or delete system files (directly).

Configuration files are generally not considered system files (as they may be edited by the user).
Filesystems may contain special files that are considered system files. For example some filesystems
might expose a list of bad blocks as a special file.

=item C<size>

The file size (in bytes).

=item C<thumbnail>

A file that can be used as a thumbnail for the document.

=item C<title>

Title of the document (if any).

=item C<uri>

The URI of the document.
B<Note:> This is not the URL one can use to fetch the document. This URI is the identifier of the document.

=item C<uuid>

The UUID of the document.

=item C<writemode>

The write mode for the document. Normally one of random access, append only, or none.

=back

=head2 property_info

    my $info = $obj->property_info($property);
    # or:
    my @info = $obj->property_info;
    # or:
    my @info = $obj->property_info($property [, ...] );

Returns information on one or more properties. If no property is given returns infos for all known ones.

B<Note:> This object may not have values for all the listed properties.
Likewise it is not guaranteed that two objects have the same list of properties.

The return value is a hashref or an array of hashrefs which contain the following keys:

=over

=item C<name>

The name of the property in universal tag format (the format used in this module).

=back

=head2 digest

    my $digest = $obj->digest($algorithm [, %opts ]);

Returns a digest (hash). The supported algorithms and lifecycle values depend on object.
If there is a any kind of problem this function dies.

Algorithm names are given in the universal tag form but aliases for names as by L<Digest> are supported.

Common values include: C<md-5-128>, C<sha-1-160>, C<sha-2-256>, and C<sha-3-512>.

The following optional options are supported:

=over

=item C<as>

The type to get the value in. This is the name of a perl package or one of:
C<hex> (the default), C<binary>, C<base64> (or C<b64>), C<base64_padded>, or C<utag>.
To get an object that is compatible with the L<Digest> API use C<Digest>. Do not try to use specific types such as C<Digest::MD5>

=item C<default>

The value to be returned when no actual value could be read. This can also be C<undef> which switches
from C<die>-ing when no value is available to returning C<undef>.

=item C<lifecycle>

The lifecycle to get the value for. The default is C<current>
See also L<File::Information/lifecycles>.

=item C<no_defaults>

Skips calculation of digest in case the digest is not known but could be calculated.

=back

=head2 verify

    my File::Information::VerifyBase $result = $obj->verify;
    # same as:
    my File::Information::VerifyBase $result = $obj->verify(lifecycle_from => 'current', lifecycle_to => 'final');

    my $passed = $result->has_passed;

Performs a verify of the object using the given lifecycles. The verify operation checks if the given object
in the state of C<lifecycle_from> (by default C<'current'>) is the same as in the state of C<lifecycle_to>
(by default C<'final'>).

The resulting object contains information on the result of the verify. The most common operation is to call
L<File::Information::VerifyBase/has_passed> on the result.

B<Note:>
This operation may read the file and calculate digests. This may take significant time.

See also
L</digest>,
L<File::Information/lifecycles>.

The following options (all optional) are supported:

=over

=item C<lifecycle_from>

The lifecycle to verify.

=item C<lifecycle_to>

The lifecycle to verify against/to compare to.

=item C<base_from>

The base object to compare (defaults to C<$obj>).

B<Note:>
This is an experimental option.

=item C<base_to>

The base object to compare (defaults to C<$obj>) against.

B<Note:>
This is an experimental option.

=back

=head2 uuid, oid, uri, ise, displayname, displaycolour, icontext, description

    my $uuid          = $obj->uuid;
    my $oid           = $obj->oid;
    my $uri           = $obj->uri;
    my $ise           = $obj->ise;
    my $displayname   = $obj->displayname;
    my $displaycolour = $obj->displaycolour;
    my $icontext      = $obj->icontext;
    my $description   = $obj->description;

These functions are for compatibility with L<Data::TagDB::Tag> and L<Data::Identifier>.

They perform the same as calling L</get> with their name as key. For example:

    my $displayname   = $obj->displayname;
    # same as:
    my $displayname   = $obj->get('displayname');

There availability depends on the type of object.

=head2 instance

    my File::Information $instance = $obj->instance;

Returns the instance that was used to create this object.

=head2 extractor, db

    my Data::URIID $extractor = $obj->extractor;
    my Data::TagDB $db        = $obj->db;
    my ...                    = $obj->digest_info;

These methods provide access to the same data as the methods of L<File::Information>.
Arguments will be passed to said functions. However the object my cache the result.
Therefore it is only allowed to pass arguments that are compatible with caching (if any exist).

See L<File::Information/extractor>, and L<File::Information/db> for details.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
