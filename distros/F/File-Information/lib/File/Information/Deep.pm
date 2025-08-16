# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Deep;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;
use Scalar::Util qw(weaken);

our $VERSION = v0.11;

my %_properties = (
    pdf_version             => {loader => \&_load_pdf},
    pdf_pages               => {loader => \&_load_pdf},
    odf_keywords            => {loader => \&_load_odf},
    data_uriid_barcodes     => {loader => \&_load_barcodes, rawtype => 'Data::URIID::Barcode'},
    vmv0_filesize           => {loader => \&_load_vmv0},
    vmv0_section_pointer    => {loader => \&_load_vmv0},
    vmv0_minimum_handles    => {loader => \&_load_vmv0},
    vmv0_minimum_ram        => {loader => \&_load_vmv0},
    vmv0_boundary_text      => {loader => \&_load_vmv0},
    vmv0_boundary_load      => {loader => \&_load_vmv0},
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
my @_dynamic_loaders   = (\&_load_odf, \&_load_audio_scan);

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
    $pv->{contentise} = {raw => $parent->get('contentise', lifecycle => 'current', as => 'uuid')};
    $pv->{mediatype}  = {raw => $parent->get('mediatype',  lifecycle => 'current', as => 'mediatype')};

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
    my $v = $self->{properties_values}{current}{mediatype}{raw};

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

sub _load_vmv0 {
    my ($self, $key, %opts) = @_;
    my $pv = ($self->{properties_values} //= {})->{current} //= {};

    return if defined $self->{_loaded_vmv0};
    $self->{_loaded_vmv0} = 1;

    return unless $self->_check_mediatype(qw(application/vnd.sirtx.vmv0));

    {
        my $inode = $self->parent->inode;
        my $data = $inode->peek(wanted => 1024);
        my %section_pointer;

        while (length($data)) {
            my ($op0, $op1) = unpack('CC', substr($data, 0, 2, ''));
            my $code  = ($op0 & 0370) >> 3;
            my $P     = ($op0 & 0007) >> 0;
            my $codeX = ($op1 & 0300) >> 6;
            my $S     = ($op1 & 0070) >> 3;
            my $T     = ($op1 & 0007) >> 0;
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
            $pv->{vmv0_section_pointer} = [map {{raw => $_}} keys %section_pointer];
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Deep - generic module for extracting information from filesystems

=head1 VERSION

version v0.11

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

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
