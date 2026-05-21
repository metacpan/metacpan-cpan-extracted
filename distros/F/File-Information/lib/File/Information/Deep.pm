# Copyright (c) 2025 Philipp Schafft <lion@cpan.org>

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Deep;

use v5.20;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;
use Scalar::Util qw(weaken);
use Fcntl qw(SEEK_SET SEEK_CUR);

our $VERSION = v0.17;

my %_PNG_colour_types = ( # namespace: 4c11d438-f6f3-417f-85e3-e56e46851dae
    0   => {ise => 'a3934b85-5bec-5cd7-a571-727e4cecfcb1', displayname => 'Greyscale'},
    2   => {ise => '56262598-1d35-566d-b9a3-0e752d58b8ce', displayname => 'Truecolor'},
    3   => {ise => '67f61b65-4978-510b-b318-247da7934837', displayname => 'Indexed-color'},
    4   => {ise => 'cbdafa4e-1cb8-59a9-b6ec-b7a1bef3fcd4', displayname => 'Greyscale with alpha'},
    6   => {ise => 'c6ef9ba0-3b7f-5248-a4f4-18e39c14d7b3', displayname => 'Truecolor with alpha'},
);

my %_PNG_filter_method = ( # namespace: 06f15860-8191-41f5-881c-a465be563089
    0   => {ise => 'b7a197cb-2eee-517f-ae57-8e299d1a92e9', displayname => 'None'},
    1   => {ise => 'c194fcce-c957-5436-861f-09af8526fed8', displayname => 'Sub'},
    2   => {ise => 'fe14ef2d-4098-5a7e-81a0-88beae0e1e65', displayname => 'Up'},
    3   => {ise => 'b0df25b4-b1fb-52cc-a6be-162440bd9628', displayname => 'Average'},
    4   => {ise => '974cf00a-c2e2-5d08-b1da-08169e09b173', displayname => 'Paeth'},
);

my %_PNG_compression_method = ( # namespace: b2b8b4bf-3b0f-4037-9bbc-96e6b53ae73d
    0   => {ise => 'f47c8ff3-5218-555d-bf89-ba30706c29e1', displayname => 'deflate'},
);

my %_vmv0_section_types = (
    1   => {ise => 'bc0dc85a-8c72-5ab6-a60b-377fdf76f678', displayname => 'init'},
    2   => {ise => '18b7bfe0-5e3a-5fe4-ad69-a317e6b2445c', displayname => 'header'},
    3   => {ise => '5460c878-23d6-56b9-8600-9375d76fefc5', displayname => 'rodata'},
    4   => {ise => '0520d8d6-3a85-56d2-ae2b-77c517cff2ce', displayname => 'text'},
    5   => {ise => '95f7f330-a72d-5e0b-ab0f-d46f37edbc9a', displayname => 'trailer'},
    6   => {ise => '9bbc79eb-5a31-5797-8a05-56e58c530289', displayname => 'resources'},
);

my %_flac_metadata_blocks = (
    0   => {ise => '92fd400d-4c47-5db2-b237-f3a0baf5343b', displayname => 'Streaminfo'},
    1   => {ise => 'e54c4b6f-b427-56d1-af10-dccf2aad38d2', displayname => 'Padding'},
    2   => {ise => 'c6e38060-7aa9-5d2c-b657-c9384d45dbe1', displayname => 'Application'},
    3   => {ise => 'f0aa49be-a79a-5fb6-aa78-05a3ee902ce6', displayname => 'Seek table'},
    4   => {ise => 'bdf21d34-8843-5f1e-8a5f-776c151991cd', displayname => 'Vorbis comment'},
    5   => {ise => '4c8656e4-a204-55d0-a5d9-a227200f1fce', displayname => 'Cuesheet'},
    6   => {ise => '97d2ac83-ab79-5715-8115-096a6ab05189', displayname => 'Picture'},
);

# RIFF/WAVE codecs:
my @_riff_wave_codecs = (
    {ise => '00000001-0000-0010-8000-00aa00389b71', displayname => 'PCM'},
    {ise => '00000003-0000-0010-8000-00aa00389b71', displayname => 'IEEE FLOAT'},
    {ise => '00000006-0000-0010-8000-00aa00389b71', displayname => 'ALAW'},
    {ise => '00000007-0000-0010-8000-00aa00389b71', displayname => 'MULAW'},
    {ise => '00000050-0000-0010-8000-00aa00389b71', displayname => 'MPEG-1 Layer I, II'},
    {ise => '00000055-0000-0010-8000-00aa00389b71', displayname => 'MPEG-1 Layer III (MP3)'},
);

# Extra tags that do not belong into one of the other lists.
my %_wk = (
    '.section'              => {ise => 'dad2de0d-9711-5b57-9a31-562122d756ba', displayname => '.section'},
    '.chunk'                => {ise => 'bff479fa-a818-58dc-b5df-539852fa8b80', displayname => '.chunk'},
    'flac-metadata-block'   => {ise => '71edae67-d10e-48d3-ab69-4dfc88e9081c', displayname => 'flac-metadata-block'},
    'riff-master-chunk'     => {ise => '66f903f6-e2de-4871-916e-e82f68d100a3', displayname => 'riff-master-chunk'},
    'riff-slave-chunk'      => {ise => '07ef1e35-b1c1-43c8-bb8b-ffd24c759bcb', displayname => 'riff-slave-chunk'},
    'mono'                  => {ise => 'a7747b62-cbb1-4912-976d-9840ce230d78', displayname => 'mono'},
    #'stereo'                => {ise => 'e9302902-8a56-490f-bcbe-60bdc2ce3ea9', displayname => 'stereo'}, # not yet used.
    'l-r-stereo'            => {ise => '0687c0ed-1138-4265-97bc-78b448292647', displayname => 'L-R-stereo'},
);

my %_properties = (
    chunk_inner_type            => {},
    pdf_version                 => {loader => \&_load_pdf},
    pdf_pages                   => {loader => \&_load_pdf},
    odf_keywords                => {loader => \&_load_odf},
    data_uriid_barcodes         => {loader => \&_load_barcodes, rawtype => 'Data::URIID::Barcode'},
    vmv0_filesize               => {loader => \&_load_vmv0},
    vmv0_section_pointer        => {loader => \&_load_vmv0},
    vmv0_section                => {loader => \&_load_vmv0, rawtype => 'File::Information::Chunk'},
    vmv0_minimum_handles        => {loader => \&_load_vmv0},
    vmv0_minimum_ram            => {loader => \&_load_vmv0},
    vmv0_boundary_text          => {loader => \&_load_vmv0},
    vmv0_boundary_load          => {loader => \&_load_vmv0},
    png_ihdr_width              => {loader => \&_load_png},
    png_ihdr_height             => {loader => \&_load_png},
    png_ihdr_bit_depth          => {loader => \&_load_png},
    png_ihdr_color_type         => {loader => \&_load_png},
    png_ihdr_compression_method => {loader => \&_load_png},
    png_ihdr_filter_method      => {loader => \&_load_png},
    png_ihdr_interlace_method   => {loader => \&_load_png},
    gif_screen_width            => {loader => \&_load_gif},
    gif_screen_height           => {loader => \&_load_gif},
    gpl_palette_name            => {loader => \&_load_gpl},
    gpl_palette_columns         => {loader => \&_load_gpl},
    gpl_palette_colours         => {loader => \&_load_gpl},
    rgbtxt_palette_colours      => {loader => \&_load_rgbtxt},
    libpng_ihdr_width           => {loader => \&_load_libpng},
    libpng_ihdr_height          => {loader => \&_load_libpng},
    libpng_ihdr_color_type      => {loader => \&_load_libpng},
    libpng_plte_colours         => {loader => \&_load_libpng},
    riff_format                 => {loader => \&_load_riff, rawtype => 'binary'},
    riff_root_chunk             => {loader => \&_load_riff, rawtype => 'File::Information::Chunk'},
    riff_wave_fmt_format            => {loader => \&_load_riff_chunks},
    riff_wave_fmt_channels          => {loader => \&_load_riff_chunks},
    riff_wave_fmt_frequency         => {loader => \&_load_riff_chunks},
    riff_wave_fmt_bytes_per_second  => {loader => \&_load_riff_chunks},
    riff_wave_fmt_bytes_per_block   => {loader => \&_load_riff_chunks},
    riff_wave_fmt_bits_per_sample   => {loader => \&_load_riff_chunks},
    riff_wave_fact_frames           => {loader => \&_load_riff_chunks},
    flac_file_metadata              => {loader => \&_load_flac, rawtype => 'File::Information::Chunk'},
    flac_streaminfo_min_block_size  => {loader => \&_load_flac_metadata_blocks},
    flac_streaminfo_max_block_size  => {loader => \&_load_flac_metadata_blocks},
    flac_streaminfo_min_frame_size  => {loader => \&_load_flac_metadata_blocks},
    flac_streaminfo_max_frame_size  => {loader => \&_load_flac_metadata_blocks},
    flac_streaminfo_sample_rate     => {loader => \&_load_flac_metadata_blocks},
    flac_streaminfo_channels        => {loader => \&_load_flac_metadata_blocks},
    flac_streaminfo_bits            => {loader => \&_load_flac_metadata_blocks},
    flac_streaminfo_total_samples   => {loader => \&_load_flac_metadata_blocks},
    flac_streaminfo_md5_checksum    => {loader => \&_load_flac_metadata_blocks},
    flac_vorbiscomment_vendor       => {loader => \&_load_flac_metadata_blocks},
);

my %_vmv0_code_P1_info = (
    0 => 'vmv0_filesize',
    2 => 'vmv0_minimum_handles',
    3 => 'vmv0_minimum_ram',
    4 => 'vmv0_boundary_text',
    5 => 'vmv0_boundary_load',
);

my @_odf_medadata_keys = qw(title description subject creator language initial_creator editing_cycles editing_duration generator creation_date date);
my @_image_info_keys   = qw(height width file_media_type file_ext color_type resolution SamplesPerPixel BitsPerSample Comment Interlace Compression Gamma LastModificationTime);
my @_image_extra_keys  = qw(Thumb::URI Thumb::Image::Width Thumb::Image::Height Thumb::MTime Software);
my @_dynamic_loaders   = (\&_load_odf, \&_load_audio_scan, \&_load_flac_metadata_blocks);

my %_audio_scan_tags = (
    vorbiscomments => {
        title => 'title',
    },
    riffwave => {
        title => 'inam',
    },
    id3 => {
        title => 'tit2',
    },
);

foreach my $keyword (qw(Author CreationDate ModDate Creator Producer Title Subject Keywords)) {
    $_properties{'pdf_info_'.lc($keyword)} = {loader => \&_load_pdf};
}
foreach my $keyword (qw(CreationDate ModDate)) {
    $_properties{'pdf_info_'.lc($keyword)}{parsing} = 'pdf_date';
}

foreach my $key (@_odf_medadata_keys) {
    $_properties{'odf_info_'.$key} = {loader => \&_load_odf};
}
foreach my $key (qw(creation_date date)) {
    $_properties{'odf_info_'.$key}{parsing} = 'iso8601';
}

foreach my $key (@_image_info_keys) {
     $_properties{'image_info_'.lc($key)} = {loader => \&_load_image_info};
}
foreach my $key (@_image_extra_keys) {
     $_properties{'image_info_extra_'.lc($key =~ s/::/_/r)} = {loader => \&_load_image_info};
}
$_properties{image_info_extra_thumb_mtime}{rawtype} = 'unixts';
$_properties{image_info_extra_thumb_uri}{rawtype} = 'uri';


# Register well known:
foreach my $value (
    values(%_PNG_colour_types),
    values(%_PNG_filter_method),
    values(%_PNG_compression_method),
    values(%_vmv0_section_types),
    values(%_flac_metadata_blocks),
    values(%_wk),
    @_riff_wave_codecs,
) {
    Data::Identifier->new(ise => $value->{ise}, displayname => $value->{displayname})->register;
}


#@returns File::Information::Base
sub parent {
    my ($self) = @_;
    return $self->{parent};
}

# ----------------
sub property_info {
    my ($self, @args) = @_;

    unless (defined $self->{_dynamic}) {
        $self->{_dynamic} = 1;
        foreach my $cb (@_dynamic_loaders) {
            $self->$cb('__dummy__');
        }
    }

    return $self->SUPER::property_info(@args);
}

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts, properties => \%_properties);
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my $parent = $self->{parent};

    weaken($self->{parent});

    # copy a few critical values:
    eval { $pv->{contentise}        = {raw => $parent->get('contentise',        lifecycle => 'current', as => 'uuid')} };
    eval { $pv->{mediatype}         = {raw => $parent->get('mediatype',         lifecycle => 'current', as => 'mediatype')} };
    eval { $pv->{chunk_inner_type}  = {ise => $parent->get('chunk_inner_type',  lifecycle => 'current', as => 'ise')} };
    eval { $pv->{size}              = {raw => $parent->get('size',              lifecycle => 'current', as => 'raw')} };

    return $self;
}

sub _dynamic_property {
    my ($self, $prefix, $property) = @_;
    my $key;

    $property = lc($property);
    $property =~ s/::/_/g;
    $property =~ s/[^a-z0-9]/_/g;
    $_properties{$key = $prefix.'_'.$property} //= {};

    return $key;
}

sub _check_mediatype {
    my ($self, @mediasubtypes) = @_;
    my $v;

    return undef unless defined $self->{properties_values}{current}{mediatype}{raw};

    $v = $self->{properties_values}{current}{mediatype}{raw};

    foreach my $mediasubtype (@mediasubtypes) {
        return 1 if $v eq $mediasubtype;
    }

    return undef;
}

sub _pdf_extract_date {
    my ($self, $value) = @_;
    require DateTime::Format::Strptime;

    state $pdf_date_core_pattern = '%Y%m%d%H%M%S';
    state $pdf_date_format_0 = DateTime::Format::Strptime->new('pattern' => $pdf_date_core_pattern, 'time_zone' => 'UTC');
    my $dt;
    my $core;
    my $parser;

    # General format: D:YYYYMMDDHHmmSSOHH'mm'

    if (($core) = $value =~ /^D:([0-9]{14})Z'{0,2}$/) {
        $parser = $pdf_date_format_0;
    } elsif (my ($mycore, $tz_dir, $tz_h, $tz_m) = $value =~ /^D:([0-9]{14})(\+|\-)([0-9]{2})'([0-9]{2})'$/) {
        my $tz = sprintf('%s%s%s', $tz_dir, $tz_h, $tz_m);
        $core = $mycore;
        $parser = DateTime::Format::Strptime->new('pattern' => $pdf_date_core_pattern, 'time_zone' => $tz);
    }

    return undef unless defined($core) && defined($parser);

    return $parser->parse_datetime($core);
}

sub _load_pdf {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_pdf};
    $self->{_loaded_pdf} = 1;

    return unless defined $self->{path};
    return unless $self->_check_mediatype('application/pdf');

    # Check for module;
    if (eval {
            require PDF::API2;
            PDF::API2->VERSION(2.044);
            PDF::API2->import();
            1;
        }) {
        my $pdf = PDF::API2->open($self->{path});
        my %info = $pdf->info_metadata();

        $pv->{pdf_version} = {raw => $pdf->version};
        $pv->{pdf_pages}   = {raw => $pdf->page_count};

        foreach my $key (keys %info) {
            if (defined(my $value = $info{$key})) {
                my $pv_key = 'pdf_info_'.lc($key);

                $value = $self->_pdf_extract_date($value) if ($_properties{$pv_key}{parsing} // '') eq 'pdf_date';
                $pv->{$pv_key} = {raw => $value};
            }
        }

        $pdf->close;
    }
}

sub _load_odf {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_odf};
    $self->{_loaded_odf} = 1;

    return unless defined $self->{path};
    return unless $self->_check_mediatype(qw(application/vnd.oasis.opendocument.text));

    # Check for module;
    if (eval {
            require OpenOffice::OODoc;
            require DateTime::Format::ISO8601;
            OpenOffice::OODoc->import();
            DateTime::Format::ISO8601->import();
            1;
        }) {
        my $document = odfDocument(file => $self->{path});
        my $meta = odfMeta(file => $document);

        foreach my $key (@_odf_medadata_keys) {
            my $func = $meta->can($key);
            my $value = $meta->$func();
            my $pv_key = 'odf_info_'.$key;
            next unless defined($value) && length($value);

            $value = DateTime::Format::ISO8601->parse_datetime($value) if ($_properties{$pv_key}{parsing} // '') eq 'iso8601';

            $pv->{$pv_key} = {raw => $value};
        }

        $pv->{odf_keywords} = [map {{raw => $_}} $meta->keywords];
        delete $pv->{odf_keywords} unless scalar @{$pv->{odf_keywords}};

        {
            my %stats = $meta->statistic;
            foreach my $key (keys %stats) {
                my $pv_key = $self->_dynamic_property(odf_stats => $key);
                my $value = $stats{$key};
                next unless defined($value) && length($value);
                $pv->{$pv_key} = {raw => $value};
            }
        }

        foreach my $el ($meta->getUserPropertyElements) {
            my $pv_key = $self->_dynamic_property(odf_user_properties => $el->att('meta:name'));
            my $value = $el->text;
            $pv->{$pv_key} = {raw => $value};
        }
    }
}

sub _load_vmv0_decode_opcode {
    my ($self, $in) = @_;
    my ($op0, $op1) = unpack('CC', $in);
    my $code  = ($op0 & 0370) >> 3;
    my $P     = ($op0 & 0007) >> 0;
    my $codeX = ($op1 & 0300) >> 6;
    my $S     = ($op1 & 0070) >> 3;
    my $T     = ($op1 & 0007) >> 0;

    return {code => $code, P => $P, codeX => $codeX, S => $S, T => $T, first => $op0, second => $op1};
}

sub _load_vmv0__load_chunks {
    my ($self, %opts) = @_;
    my $fh    = delete $opts{fh};
    my $start = delete $opts{start};
    my @res;

    return undef unless $fh;

    while (1) {
        $fh->seek($start, SEEK_SET) or die $!;
        if (read($fh, my $in, 2) != 2) {
            last;
        } else {
            my $opcode = $self->_load_vmv0_decode_opcode($in);
            my $opcode_length = 2;
            my $outer_length;
            my $inner_offset;
            my $length;
            my %new_opts = %opts;
            my $flags;
            my $type;
            my $identifier;

            last unless $opcode->{first} == 6 && $opcode->{codeX} == 0 && $opcode->{S} && $opcode->{T} < 4;

            # Read length:
            if ($opcode->{T} == 1) {
                last unless read($fh, $in, 2) == 2;
                $length = unpack('n', $in) * 2;
                $opcode_length += 2;
            } elsif ($opcode->{T} == 2) {
                last unless read($fh, $in, 4) == 4;
                $length = unpack('N', $in) * 2;
                $opcode_length += 4;
            }

            next unless defined $length;
            $inner_offset = $opcode_length;

            # Read flags and type:
            last unless read($fh, $in, 4) == 4;
            ($flags, $type) = unpack('nn', $in);
            $inner_offset += 4;

            # Read identifier (if any):
            if ($flags & 0x0002) {
                last unless read($fh, $in, 2) == 2;
                $identifier = unpack('n', $in);
                $inner_offset += 2;
            }

            if (($flags & 0xC000) == 0x0000) { # SNI
                $type = Data::Identifier->new('039e0bb7-5dd3-40ee-a98c-596ff6cce405' => $type);
            } elsif (($flags & 0xC000) == 0x4000) { # SID
                $type = Data::Identifier->new(sid => $type);
            } else {
                $type = undef;
            }

            $outer_length = $length + $opcode_length;
            push(@res, File::Information::Chunk->_new(%opts,
                    start => $start,
                    size => $outer_length,
                    outer_type => {ise => $_wk{'.chunk'}->{ise}},
                    inner_type => {raw => $type, ise => $type->ise},
                    inner_start => $start + $inner_offset,
                    inner_size => $outer_length - $inner_offset - ($flags & 0x1 ? 1 : 0),
                ));

            $start += $outer_length;
        }
    }

    return undef unless scalar @res;
    return \@res;
}

sub _load_vmv0__chunk {
    my ($self, %opts) = @_;

    if (defined(my $fh = delete $opts{fh})) {
        $fh->seek($opts{start}, SEEK_SET) or die $!;
        if (read($fh, my $in, 2) == 2) {
            my $opcode = $self->_load_vmv0_decode_opcode($in);
            if ($opcode->{first} == 0 && $opcode->{codeX} == 0 && ($opcode->{T} & 0x4)) {
                my $n = $opcode->{T} - 4;

                if ($n > 0) {
                    $n *= 2;
                    (read($fh, my $magic, $n) == $n) or croak 'IO error: Cannot read '.$n.' bytes';
                    if (length($magic) == $n) {
                        $opts{outer_magic} = {raw => $magic};
                    }
                }

                my $section_type = $opcode->{S};
                if ($section_type == 5 || $section_type == 6) {
                    $opts{subchunks} = $self->_load_vmv0__load_chunks(%opts, start => $fh->tell, fh => $fh);
                }
                $opts{outer_type} = {ise => $_wk{'.section'}->{ise}};
                $opts{inner_type} = {ise => $_vmv0_section_types{$section_type}->{ise}};
            }
        }
    }

    return File::Information::Chunk->_new(%opts);
}
sub _load_vmv0 {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_vmv0};
    $self->{_loaded_vmv0} = 1;

    return unless $self->_check_mediatype(qw(application/vnd.sirtx.vmv0));

    if (defined(my $inode = eval { $self->inode })) {
        my $data = $self->peek(wanted => 1024);
        my %section_pointer;

        while (length($data)) {
            my $opcode = $self->_load_vmv0_decode_opcode(substr($data, 0, 2, ''));
            my ($op0, $op1, $code, $P, $codeX, $S, $T) = $opcode->@{qw(first second code P codeX S T)};
            my $extra_as_num;
            my $extra_len = 0;
            my $extra;

            last if $code != 0;
            last if $P > 2;
            last if $codeX != 0;

            last if $op0 == 0 && $codeX == 0 && $S > 2; # last on non-opcode sections

            $extra_len = ($T & 0x3) * 2;

            $extra = substr($data, 0, $extra_len, '');

            if ($extra_len == 0) {
                $extra_as_num = 0;
            } elsif ($extra_len == 2) {
                $extra_as_num = unpack('n', $extra);
            } elsif ($extra_len == 4) {
                $extra_as_num = unpack('N', $extra);
            }

            if ($code == 0) {
                if ($P == 1) {
                    if ($codeX == 0) {
                        if (defined $extra_as_num) {
                            if (defined(my $f = $_vmv0_code_P1_info{$S})) {
                                $pv->{$f} = {raw => $extra_as_num*2};
                            } elsif ($S == 1) {
                                $section_pointer{$extra_as_num*2} //= undef;
                            }
                        }
                    }
                }
            }

            #warn sprintf('[code=%u, P=%u; codeX=%u, S=%u, T=%u; extra_len=%u, extra_as_num=%s]', $code, $P, $codeX, $S, $T, $extra_len, $extra_as_num // '<undef>');
        }

        if (scalar keys %section_pointer) {
            my @pointers = sort {$a <=> $b} keys %section_pointer;
            my $fh = $inode->_get_fh;
            my @sections;
            my $last;

            $pv->{vmv0_section_pointer} = [map {{raw => $_}} @pointers];

            require File::Information::Chunk;

            foreach my $c (@pointers) {
                if (defined $last) {
                    push(@sections, $self->_load_vmv0__chunk(instance => $self->instance, path => $self->{path}, parent => $self, inode => $inode, start => $last, end => $c, fh => $fh));
                }
                $last = $c;
            }
            if (defined $last) {
                push(@sections, $self->_load_vmv0__chunk(instance => $self->instance, path => $self->{path}, parent => $self, inode => $inode, start => $last, end => scalar($inode->get('size')), fh => $fh));
            }
            $pv->{vmv0_section} = [map {{raw => $_}} @sections];
        }
    }
}

sub _load_png {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_png};
    $self->{_loaded_png} = 1;

    return unless $self->_check_mediatype(qw(image/png));

    {
        my $inode = $self->inode;
        my $data = $self->peek(wanted => 1024);

        if (substr($data, 0, 8) eq "\x89\x50\x4e\x47\x0d\x0a\x1a\x0a") {
            if (substr($data, 8, 8) eq "\0\0\0\x0dIHDR") {
                my $crc = eval {require Digest::CRC; Digest::CRC->new(type => 'crc32');} // eval { require Digest; Digest->new('CRC-32'); } // croak 'No CRC-32 support';
                $crc->add(substr($data, 8 + 4, 4 + 13));
                if (substr($data, 16 + 13, 4) eq pack('H8', $crc->hexdigest)) {
                    my ($width, $height, $bit_depth, $color_type, $compression_method, $filter_method, $interlace_method) = unpack('NNCCCCC', substr($data, 16, 13));
                    $pv->{png_ihdr_width}               = {raw => $width};
                    $pv->{png_ihdr_height}              = {raw => $height};
                    $pv->{png_ihdr_bit_depth}           = {raw => $bit_depth};
                    $pv->{png_ihdr_interlace_method}    = {raw => $interlace_method};
                    if (defined(my $ct = $_PNG_colour_types{$color_type})) {
                        $pv->{png_ihdr_color_type}          = {raw => $color_type, ise => $ct->{ise}};
                    }
                    if (defined(my $fm = $_PNG_filter_method{$filter_method})) {
                        $pv->{png_ihdr_filter_method}       = {raw => $filter_method, ise => $fm->{ise}};
                    }
                    if (defined(my $cm = $_PNG_compression_method{$compression_method})) {
                        $pv->{png_ihdr_compression_method}  = {raw => $compression_method, ise => $cm->{ise}};
                    }
                }
            }
        }
    }
}

sub _load_gif {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_gif};
    $self->{_loaded_gif} = 1;

    return unless $self->_check_mediatype(qw(image/gif));

    {
        my $inode = $self->inode;
        my $data = $self->peek(wanted => 1024);

        if (substr($data, 0, 6) eq 'GIF89a') { # TODO: check if the following code also holds true for GIF87a
            my ($width, $height) = unpack('vv', substr($data, 6, 4));
            $pv->{gif_screen_width}  = {raw => $width}  if $width  > 0;
            $pv->{gif_screen_height} = {raw => $height} if $height > 0;
        }
    }
}

sub _load_gpl {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_gpl};
    $self->{_loaded_gpl} = 1;

    if (defined(my $inode = eval { $self->inode })) {
        my $data = $self->peek(wanted => 64);

        if ($data =~ /^GIMP Palette\r?\n/) {
            my $fh = $inode->_get_fh;
            my @colours;

            return unless eval { require Data::URIID::Colour; 1; };

            while (defined(my $line = <$fh>)) {
                $line =~ s/\r?\n$//;
                $line =~ s/^\s*#.*$//;
                next unless length($line);
                if ($line eq 'GIMP Palette') {
                    # magic, good, no-op
                } elsif ($line =~ /^Name:\s+(\S.+)$/) {
                    $pv->{gpl_palette_name} = {raw => $1};
                } elsif ($line =~ /^Columns:\s+([1-9][0-9]*)$/) {
                    $pv->{gpl_palette_columns} = {raw => int($1)};
                } elsif ($line =~ /^\s*(0|[1-9][0-9]*)\s+(0|[1-9][0-9]*)\s+(0|[1-9][0-9]*)\s+(\S(?:.*\S)?)$/) {
                    push(@colours, {raw => Data::URIID::Colour->new(
                            rgb => sprintf('#%02x%02x%02x', $1, $2, $3),
                            displayname => $4,
                        )});
                } elsif ($line =~ /^(0|[1-9][0-9]*)\s+(0|[1-9][0-9]*)\s+(0|[1-9][0-9]*)$/) {
                    push(@colours, {raw => Data::URIID::Colour->new(
                            rgb => sprintf('#%02x%02x%02x', $1, $2, $3),
                        )});
                } else {
                    # BAD line!?
                }
            }

            $pv->{gpl_palette_colours} = \@colours if scalar @colours;
        }
    }
}

sub _load_rgbtxt {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_rgbtxt};
    $self->{_loaded_rgbtxt} = 1;

    if (defined(my $inode = eval { $self->inode })) {
        my $data = $self->peek(wanted => 64);

        if ($data =~ /^\! \$Xorg: rgb\.txt,v .+ Exp \$\r?\n/) {
            my $fh = $inode->_get_fh;
            my @colours;

            return unless eval { require Data::URIID::Colour; 1; };

            while (defined(my $line = <$fh>)) {
                $line =~ s/\r?\n$//;
                next unless length($line);
                if ($line =~ /^(0|[1-9][0-9]*)\s+(0|[1-9][0-9]*)\s+(0|[1-9][0-9]*)\s+(\S(?:.*\S)?)$/) {
                    push(@colours, {raw => Data::URIID::Colour->new(
                            rgb => sprintf('#%02x%02x%02x', $1, $2, $3),
                            displayname => $4,
                        )});
                } else {
                    # BAD line!?
                }
            }

            $pv->{rgbtxt_palette_colours} = \@colours if scalar @colours;
        }
    }
}

sub _load_image_info {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_image_info};
    $self->{_loaded_image_info} = 1;

    return unless defined $self->{path};

    foreach my $data (eval {
            require Image::Info;
            Image::Info->import();
            Image::Info::image_info($self->{path});
        }) {
        next if defined($data->{error}) && length($data->{error});

        foreach my $key (@_image_info_keys) {
            my $pv_key = 'image_info_'.lc($key);
            my $value = delete $data->{$key};

            next unless defined($value) && length($value);

            $pv->{$pv_key} = {raw => $value};
        }
        foreach my $key (@_image_extra_keys) {
            my $pv_key = 'image_info_extra_'.lc($key =~ s/::/_/r);
            my $value = delete $data->{$key};

            next unless defined($value) && length($value);

            $pv->{$pv_key} = {raw => $value};
        }
    }
}

sub _load_audio_scan {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_audio_scan};
    $self->{_loaded_audio_scan} = 1;

    return unless defined $self->{path};

    # Check for module;
    if (defined(my $data = eval {
                local $ENV{AUDIO_SCAN_NO_ARTWORK} = 1;
                require Audio::Scan;
                Audio::Scan->import();
                Audio::Scan->scan($self->{path});
            })) {
        my $info = $data->{info};
        my $tags = $data->{tags};

        foreach my $key (keys %{$info}) {
            my $value = $info->{$key};
            my $pv_key;

            next unless defined($value) && length($value);
            next if ref $value;

            $pv_key = $self->_dynamic_property(audio_scan_info => $key);
            $pv->{$pv_key} = {raw => $value};
        }

        foreach my $key (keys %{$tags}) {
            my $value = $tags->{$key};
            my $pv_key;

            next unless defined($value) && length($value);
            next if ref $value;

            $pv_key = $self->_dynamic_property(audio_scan_tags => $key);
            $pv->{$pv_key} = {raw => $value};
        }

        {
            my $style;

            if ($self->_check_mediatype(qw(application/ogg audio/ogg video/ogg audio/flac))) {
                $style = 'vorbiscomments';
            } elsif ($self->_check_mediatype(qw(audio/x-wav))) {
                $style = 'riffwave';
            } else {
                $style = 'id3'; # bad guess
            }

            if (defined($style) && defined(my $map = $_audio_scan_tags{$style})) {
                foreach my $key (keys %{$map}) {
                    my $src_pv_key  = $self->_dynamic_property(audio_scan_tags => $map->{$key});
                    my $pv_key      = $self->_dynamic_property(audio_scan => $key);
                    my $value       = $pv->{$src_pv_key};

                    if (defined($value) && ref($value) eq 'HASH' && defined($value->{raw})) {
                        $pv->{$pv_key} = {raw => $value->{raw}};
                    }
                }
            }
        }
    }
}

sub _load_barcodes {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my @barcodes;

    return if defined $self->{_loaded_barcodes};
    $self->{_loaded_barcodes} = 1;

    return unless defined $self->{path};
    return unless eval { require Data::URIID::Barcode; 1; };

    @barcodes = eval { Data::URIID::Barcode->sheet(filename => $self->{path}) };

    if (scalar @barcodes) {
        $pv->{data_uriid_barcodes} = [map {{raw => $_}} @barcodes];
    }
}

sub _load_libpng {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_libpng};
    $self->{_loaded_libpng} = 1;

    return unless $self->_check_mediatype(qw(image/png));
    return unless defined $self->{path};
    return unless eval { require Image::PNG::Libpng; 1; };

    if (defined(my $png = eval {Image::PNG::Libpng::read_png_file($self->{path})})) {
        my $IHDR = $png->get_IHDR;

        $pv->{libpng_ihdr_width} = {raw => $IHDR->{width}};
        $pv->{libpng_ihdr_height} = {raw => $IHDR->{height}};

        if (defined(my $ct = $_PNG_colour_types{$IHDR->{color_type}})) {
            $pv->{libpng_ihdr_color_type} = {raw => $IHDR->{color_type}, ise => $ct->{ise}};
        }

        if (defined(my $PLTE = eval {$png->get_PLTE})) {
            if (eval { require Data::URIID::Colour; 1; }) {
                my @colours = map {{
                    raw => Data::URIID::Colour->new(rgb => sprintf('#%02x%02x%02x', $_->{red}, $_->{green}, $_->{blue})),
                }} @{$PLTE};
                $pv->{libpng_plte_colours} = \@colours if scalar @colours;
            }
        }
    }
}

sub _load_riff__load_subchunks {
    my ($self, $fh, $offset, $length, $chunk_common) = @_;
    my $end = $offset + $length;
    my @ret;

    require Data::Identifier::Generate;

    while ($offset < ($end - 8)) {
        my $header;
        my $chunk_length;
        my $subtype;
        my $skip = 8;
        my $inner_type;

        $fh->seek($offset, SEEK_SET);

        croak 'IO error' if read($fh, $header, 8) != 8;

        $chunk_length = unpack('V', substr($header, 4, 4, ''));
        croak sprintf('Bad length: %u (max: %u - %u = %u)', $chunk_length, $length, $skip, $length - $skip) if $chunk_length > ($length - $skip);

        $skip += $chunk_length;
        $skip += 1 if $chunk_length & 1; # Additional padding byte

        if ($header eq 'RIFF' || $header eq 'LIST') {
            croak 'IO error' if read($fh, $subtype, 4) != 4;
        }

        {
            my $displayname;

            if (defined $subtype) {
                $displayname = sprintf('%s/%s', $header, $subtype) if $header =~ /^[0-9a-zA-Z_ ]{4}\z/ && $subtype =~ /^[0-9a-zA-Z_ ]{4}\z/;
            } else {
                $displayname = $header if $header =~ /^[0-9a-zA-Z_ ]{4}\z/;
            }

            $displayname =~ s/\s+\z// if defined $displayname;

            $inner_type = Data::Identifier::Generate->generic(
                namespace => 'a416135e-c0b0-4d40-8eb0-24f164c0ad74',
                input => $header.(defined $subtype ? $subtype : ''),
                displayname => $displayname,
            );

            $inner_type->register;
        }

        push(@ret, File::Information::Chunk->_new(
                %{$chunk_common},
                start => $offset,
                size => $chunk_length + 8,
                inner_start => $offset + 8,
                inner_size => $chunk_length,
                outer_type => {ise => $_wk{defined $subtype ? 'riff-master-chunk' : 'riff-slave-chunk'}->{ise}},
                inner_type => {ise => $inner_type->uuid},
                subchunks => (defined $subtype ? $self->_load_riff__load_subchunks($fh, $offset + 12, $chunk_length - 4, $chunk_common) : undef),
            ));

        $offset += $skip,
        $length -= $skip;
    }

    return \@ret;
}

sub _load_riff {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my %chunk_common;

    return if defined $self->{_loaded_riff};
    $self->{_loaded_riff} = 1;

    if (defined(my $inode = eval { $self->inode })) {
        if (defined(my $header = eval {$inode->peek(required => 4*3)})) {
            my $size = $self->get('size');
            my $fh;

            return unless substr($header, 0, 4) eq 'RIFF';
            return unless substr($header, 4, 4) eq pack('V', $size - 8);

            $fh = $inode->_get_fh;

            $pv->{riff_format} = {raw => substr($header, 8, 4)};

            require File::Information::Chunk;

            %chunk_common = (
                instance => $self->instance,
                parent => $self,
                inode => $self->inode,
            );
            $pv->{riff_root_chunk} = {raw => $self->_load_riff__load_subchunks($fh, 0, $size, \%chunk_common)->[0]};
        }
    }
}

sub _load_riff_chunks {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my $chunk_inner_type;

    return if defined $self->{_loaded_riff_chunks};
    $self->{_loaded_riff_chunks} = 1;

    $chunk_inner_type = $self->get('chunk_inner_type', as => 'ise', default => undef);
    return unless defined $chunk_inner_type;

    if ($chunk_inner_type eq 'e3596805-82a2-572a-88af-ab3ce127bb10') { # 'fmt '
        my ($AudioFormat, $NbrChannels, $Frequency, $BytePerSec, $BytePerBloc, $BitsPerSample) = unpack('vvVVvv', $self->peek(required => 16));
        $pv->{riff_wave_fmt_format} = {raw => $AudioFormat, ise => sprintf('%08x-0000-0010-8000-00aa00389b71', $AudioFormat)};
        $pv->{riff_wave_fmt_channels} = {raw => $NbrChannels};
        $pv->{riff_wave_fmt_frequency} = {raw => $Frequency};
        $pv->{riff_wave_fmt_bytes_per_second} = {raw => $BytePerSec};
        $pv->{riff_wave_fmt_bytes_per_block} = {raw => $BytePerBloc};
        $pv->{riff_wave_fmt_bits_per_sample} = {raw => $BitsPerSample};

        if ($NbrChannels == 1) {
            $pv->{riff_wave_fmt_channels}{ise} = $_wk{'mono'}{ise};
        } elsif ($NbrChannels == 2) {
            $pv->{riff_wave_fmt_channels}{ise} = $_wk{'l-r-stereo'}{'ise'};
        }
    } elsif ($chunk_inner_type eq '41ee7c44-704c-50fc-99b7-a2fed7456b4c') { # 'fact'
        my ($frames) = unpack('V', $self->peek(required => 4));
        $pv->{riff_wave_fact_frames} = {raw => $frames};
    }
}

sub _load_flac {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my $fh;
    my $data;
    my @blocks;
    my %chunk_common;

    return if defined $self->{_loaded_flac};
    $self->{_loaded_flac} = 1;

    return unless $self->_check_mediatype(qw(audio/flac));

    $fh = $self->inode->_get_fh;
    return if read($fh, $data, 4) != 4 || $data ne 'fLaC';

    require File::Information::Chunk;

    %chunk_common = (
        instance => $self->instance,
        parent => $self,
        inode => $self->inode,
        outer_type => {ise => '71edae67-d10e-48d3-ab69-4dfc88e9081c'}, # flac-metadata-block
    );

    while (read($fh, $data, 4) == 4) {
        my $start = $fh->tell - 4;
        my ($first, $second, $tail) = unpack('CCn', $data);
        my $length = ($second << 8) + $tail;

        push(@blocks, File::Information::Chunk->_new(
                %chunk_common,
                start => $start,
                size => $length + 4,
                inner_start => $start + 4,
                inner_size => $length,
                inner_type => {ise => $_flac_metadata_blocks{$first & 0x7F}->{ise}},
            ));

        if (($first & 0x7F) == 1) {
            # This is a padding block. It is always boring.
            (($blocks[-1]->{properties_values} //= {})->{current} //= {})->{boring} = {raw => 1};
        }

        last if $first & 0x80;

        $fh->seek($length, SEEK_CUR);
    }

    $pv->{flac_file_metadata} = [map {{raw => $_}} @blocks];
}

sub _load_flac_metadata_blocks__read24 {
    my ($v) = @_;
    my ($x, $y) = unpack('Cn', ${$v});
    substr(${$v}, 0, 3, '');
    return ($x << 16) | $y;
}

sub _load_flac_metadata_blocks__read_string {
    state $UTF8 = do { require Encode; Encode::find_encoding('UTF-8') };
    my ($v) = @_;
    my $len = unpack('V', ${$v});
    my $s = $UTF8->decode(substr(${$v}, 4, $len));
    substr(${$v}, 0, $len + 4, '');
    return $s;
}

sub _load_flac_metadata_blocks {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};
    my $chunk_inner_type;

    return if defined $self->{_loaded_flac_metadata_blocks};
    $self->{_loaded_flac_metadata_blocks} = 1;

    $chunk_inner_type = $self->get('chunk_inner_type', as => 'ise', default => undef);
    return unless defined $chunk_inner_type;

    if ($chunk_inner_type eq '92fd400d-4c47-5db2-b237-f3a0baf5343b') {
        my $data = $self->peek(required => 34);
        return if length($data) != 34;

        $pv->{flac_streaminfo_min_block_size} = {raw => vec($data, 0, 16)};
        $pv->{flac_streaminfo_max_block_size} = {raw => vec($data, 1, 16)};
        substr($data, 0, 2*2, '');

        $pv->{flac_streaminfo_min_frame_size} = {raw => _load_flac_metadata_blocks__read24(\$data)};
        $pv->{flac_streaminfo_max_frame_size} = {raw => _load_flac_metadata_blocks__read24(\$data)};

        {
            my ($x, $y) = unpack('NN', $data);
            substr($data, 0, 8, '');

            $pv->{flac_streaminfo_sample_rate}  = {raw =>   $x >> 12};
            $pv->{flac_streaminfo_channels}     = {raw => (($x >>  9) & 0x07) + 1};
            $pv->{flac_streaminfo_bits}         = {raw => (($x >>  4) & 0x1F) + 1};

            $pv->{flac_streaminfo_total_samples}= {raw => (($x & 0xF) << 32) | $y};
        }

        $pv->{flac_streaminfo_md5_checksum} = {raw => unpack('H32', $data)};

        # Data   Description
        # u(16)  The minimum block size (in samples) used in the stream, excluding the last block.
        # u(16)  The maximum block size (in samples) used in the stream.
        # u(24)  The minimum frame size (in bytes) used in the stream. A value of 0 signifies that the value is not known.
        # u(24)  The maximum frame size (in bytes) used in the stream. A value of 0 signifies that the value is not known.
        # u(20)  Sample rate in Hz.
        # u(3)   (number of channels)-1. FLAC supports from 1 to 8 channels.
        # u(5)   (bits per sample)-1. FLAC supports from 4 to 32 bits per sample.
        # u(36)  Total number of interchannel samples in the stream. A value of 0 here means the number of total samples is unknown.
        # u(128) MD5 checksum of the unencoded audio data. This allows the decoder to determine if an error exists in the audio data even when, despite the error, the bitstream itself is valid. A value
        #        of 0 signifies that the value is not known.
    } elsif ($chunk_inner_type eq 'bdf21d34-8843-5f1e-8a5f-776c151991cd') {
        my $data = $self->peek(required => 8, wanted => 1024);
        my $len;

        $pv->{flac_vorbiscomment_vendor} = {raw => _load_flac_metadata_blocks__read_string(\$data)};

        $len = unpack('V', $data);
        substr($data, 0, 4, '');

        for (my $i = 0; $i < $len; $i++) {
            my ($k, $v) = _load_flac_metadata_blocks__read_string(\$data) =~ /^([\x20-\x3E\x3F-\x7D]+)=(.*)\z/s;
            my $pv_key = $self->_dynamic_property(flac_vorbiscomment_comment => uc($k));
            my $e = $pv->{$pv_key} //= [];
            push(@{$e}, {raw => $v});
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Deep - generic module for extracting information from filesystems

=head1 VERSION

version v0.17

=head1 SYNOPSIS

    use File::Information;

    my File::Information::Deep $deep = $obj->deep;

    # ...

B<Note:> This package inherits from L<File::Information::Base>.

This package allows for deep inspection of files.
This permits to read data directly from files, not just external metadata
(such as filesystem attributes).
This however comes at the price of performance.

B<Note:>
If you want to use data from deep inspection, you need to load this object (by calling C<$obj-E<gt>deep>)
before calling any L<File::Information::Base/get> or similar methods.

=head1 METHODS

=head2 parent

    my File::Information::Base $parent = $deep->parent;

Returns the parent that was used to create this object.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
