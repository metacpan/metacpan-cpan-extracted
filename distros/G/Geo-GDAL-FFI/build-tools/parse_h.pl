use v5.10;
use strict;
use warnings;

my $gdal_src_root = shift @ARGV;

my @h_files = (
    'gcore/gdal.h',
    'ogr/ogr_api.h',
    'ogr/ogr_srs_api.h',
    'apps/gdal_utils.h'    
    );

my %pre = (
    CPL_C_START => '',
    CPL_DLL => '',
    CPL_STDCALL => '',
    CPL_WARN_UNUSED_RESULT => '',
    CPL_RESTRICT => ''
    );

my %constants = (
    GDALDataType => 1,
    GDALAsyncStatusType => 1,
    GDALColorInterp => 1,
    GDALPaletteInterp => 1,
    GDALAccess => 1,
    GDALRWFlag => 1,
    OGRwkbGeometryType => 1,
    GDALRATFieldUsage => 1,
    GDALRATFieldType => 1,
    GDALRATTableType => 1,
    GDALTileOrganization => 1,
    OGRwkbByteOrder => 1,
    OGRFieldType => 1,
    OGRFieldSubType => 1,
    OGRJustification => 1,
    OGRSTClassId => 1,
    OGRSTUnitId => 1,
    OGRAxisOrientation => 1,
    GDALGridAlgorithm => 1,
    );

my %callbacks = (
    CPLErrorHandler => 1,
    GDALProgressFunc => 1,
    GDALDerivedPixelFunc => 1,
    GDALTransformerFunc => 1,
    GDALContourWriter => 1,
    );

my %char_p_p_ok = (
    OGR_G_CreateFromWkt => 1,
    OGR_G_ImportFromWkt => 1,
    OGR_G_ExportToWkt => 1,
    OGR_G_ExportToIsoWkt => 1,
    OSRExportToWkt => 1,
    OSRExportToPrettyWkt => 1,
    OSRExportToProj4 => 1,
    OSRExportToPCI => 1,
    OSRExportToXML => 1,
    OSRExportToMICoordSys => 1,
    );

my %use_CSL = (
    GDALCreate => 1,
    GDALOpenEx => 1,
    GDALCreateCopy => 1,
    GDALGetMetadataDomainList => 1,
    GDALIdentifyDriver => 1,
    GDALValidateCreationOptions => 1,
    GDALGetMetadata => 1,
    GDALSetMetadata => 1,
    GDALGetFileList => 1,
    GDALAddBand => 1,
    GDALDatasetCreateLayer => 1,
    GDALDatasetCopyLayer => 1,
    OGR_DS_CreateLayer => 1,
    OGR_DS_CopyLayer => 1,
    GDALGetRasterCategoryNames => 1,
    OGR_F_GetFieldAsStringList => 1,
    OGR_F_SetFieldStringList => 1,
    OGR_G_ExportToGMLEx => 1,
    OGR_G_ExportToJsonEx => 1,
    GDALInfoOptionsNew => 1,
    GDALTranslateOptionsNew => 1,
    GDALWarpAppOptionsNew => 1,
    GDALVectorTranslateOptionsNew => 1,
    GDALDEMProcessingOptionsNew => 1,
    GDALNearblackOptionsNew => 1,
    GDALGridOptionsNew => 1,
    GDALRasterizeOptionsNew => 1,
    GDALBuildVRTOptionsNew => 1,
    GDALBuildVRT => 1,
    OGR_L_Intersection => 1,
    OGR_L_Union => 1,
    OGR_L_SymDifference => 1,
    OGR_L_Identity => 1,
    OGR_L_Update => 1,
    OGR_L_Clip => 1,
    OGR_L_Erase => 1,
    );

# these return strings which must be freed
my %use_ret_opaque = (
    OGR_G_ExportToGML => 1,
    OGR_G_ExportToGMLEx => 1,
    OGR_G_ExportToKML => 1,
    OGR_G_ExportToJson => 1,
    OGR_G_ExportToJsonEx => 1,
    );

my %ret_string_ok = (
    GDALGetDataTypeName => 1,
    GDALGetAsyncStatusTypeName => 1,
    GDALGetColorInterpretationName => 1,
    GDALGetPaletteInterpretationName => 1,
    GDALGetDriverShortName => 1,
    GDALGetDriverLongName => 1,
    GDALGetDriverHelpTopic => 1,
    GDALGetDriverCreationOptionList => 1,
    GDALGetMetadataItem => 1,
    GDALGetDescription => 1,
    GDALGetProjectionRef => 1,
    GDALGetGCPProjection => 1,
    GDALGetRasterUnitType => 1,
    GDALDecToDMS => 1,
    OGR_G_GetGeometryName => 1,
    );

my %use_array = (
    OGR_F_SetFieldIntegerList => 1,
    OGR_F_SetFieldInteger64List => 1,
    OGR_F_SetFieldDoubleList => 1,
    );

my %use_opaque_array = (
    GDALWarp => 1,
    GDALVectorTranslate => 1,
    GDALBuildVRT => 1,
    );

my %use_ret_pointer = (
    OGR_F_GetFieldAsIntegerList => 1,
    OGR_F_GetFieldAsInteger64List => 1,
    OGR_F_GetFieldAsDoubleList => 1,
    );

my %use_string = (
    OGR_G_CreateFromWkb => 1,
    OGR_G_CreateFromFgf => 1,
    OGR_G_ImportFromWkb => 1,
    );

my %opaque_pointers = (
    GDAL_GCP => 1,
    GDALRPCInfo => 1,
    CPLXMLNode => 1,
    GDALRasterIOExtraArg => 1,
    GDALGridContext => 1,
    CPLVirtualMem => 1,
    OGRField => 1,
    GDALInfoOptions => 1,
    GDALInfoOptionsForBinary => 1,
    GDALTranslateOptions => 1,
    GDALTranslateOptionsForBinary => 1,
    GDALWarpAppOptions => 1,
    GDALWarpAppOptionsForBinary => 1,
    GDALVectorTranslateOptions => 1,
    GDALVectorTranslateOptionsForBinary => 1,
    GDALDEMProcessingOptions => 1,
    GDALDEMProcessingOptionsForBinary => 1,
    GDALNearblackOptions => 1,
    GDALNearblackOptionsForBinary => 1,
    GDALGridOptions => 1,
    GDALGridOptionsForBinary => 1,
    GDALRasterizeOptions => 1,
    GDALRasterizeOptionsForBinary => 1,
    GDALBuildVRTOptions => 1,
    GDALBuildVRTOptionsForBinary => 1,
    );

my %defines;
my %enums;
my %structs;

say "# generated with parse_h.pl";
for my $f (@h_files) {
    say "# from $f";
    parse_h($gdal_src_root . '/' . $f);
}
say "# end of generated code";

sub parse_h {
    my $f = shift;
    open(my $fh, '<', $f) or die "can't open $f: $!";
    my $s = '';
    while (1) {
        my $n = pre_process($fh);
        #say STDERR "top: ",$n;
        last unless defined $n;
        $s .= ' '.$n;
        next unless $s =~ /;/;
        $s =~ s/^\s+//;
        $s =~ s/\s+$//;
        $s =~ tr/ //s;
        if ($s =~ /^typedef enum/) {
            $enums{$s} = 1;
            $s = '';
            next;
        }
        if ($s =~ /^typedef struct .*?\{/) {
            my $struct = $s;
            while (1) {
                my $n = pre_process($fh);
                die "eof while parsing typedef struct" unless defined $n;
                # look for "} name;"
                $struct .= ' '.$n;
                if ($struct =~ /\} \w+;/) {
                    last;
                }
            }
            $structs{$struct} = 1;
            $s = '';
            next;
        }
        if ($s =~ /^typedef/) {
            $s = '';
            next;
        }
        if ($s =~ /^struct/) {
            $s = '';
            next;
        }
        # now $s should be a function
        #say 'line: ',$s;
        if ($s =~ /(\w+)\s*\((.*?)\)/) {
            my $name = $1;
            my $args = $2;
            my $ret = $s;
            $ret =~ s/$name.*//;
            $ret = parse_type($name, $ret, 'ret');
            my @args = split /\s*,\s*/, $args;
            my $qw = 1;
            for my $arg (@args) {
                $arg = parse_type($name, $arg, 'arg');
                $qw = 0 if $arg =~ /\s/;
            }
            #say "ret: $ret";
            #say "name: $name";
            #say "args: @args";
            if (@args == 1 && $args[0] eq 'void') {
                $args = '';
            } elsif ($qw) {
                $args = "qw/@args/";
            } else {
                $args = "'".join("','", @args)."'";
            }
            say "eval{\$ffi->attach('$name' => [$args] => '$ret');};";
        } else {
            die "can't parse $s as function";
        }
        $s = '';
    }
    close $fh;
}

sub parse_type {
    my ($name, $arg, $mode) = @_;
    $arg =~ s/^\s+//;
    $arg =~ s/\s+$//;
    for my $c (keys %constants) {
        if ($arg =~ /^$c/ or $arg =~ /^const $c/) {
            $arg = 'unsigned int';
        }
    }
    for my $c (keys %callbacks) {
        if ($arg =~ /^$c/) {
            return $c;
        }
    }
    for my $c (keys %opaque_pointers) {
        if ($arg =~ /$c\s*\*/) {
            return 'opaque';
        }
    }
    if ($arg =~ /^\w+?H\s*\*/) {
        if ($use_opaque_array{$name}) {
            $arg = 'opaque[]';
        } else {
            $arg = 'uint64*';
        }
    } elsif ($arg =~ /^\w+?H/) {
        $arg = 'opaque';
    } elsif ($arg =~ /^const \w+?H/) {
        $arg = 'opaque';
    } elsif ($arg =~ /GDALColorEntry\s*\*/) {
        $arg = 'short[4]';
    } elsif ($arg =~ /OGREnvelope\s*\*/) {
        $arg = 'double[4]';
    } elsif ($arg =~ /OGREnvelope3D\s*\*/) {
        $arg = 'double[6]';
    } elsif ($arg =~ /GDALTriangulation/) {
        $arg = 'opaque'; # todo: actually a record
    } elsif ($arg =~ /^FILE\s*\*/) {
        $arg = 'opaque';
    } elsif ($arg =~ /void\s*\*/) {
        for my $c (keys %use_string) {
            if ($c eq $name) {
                say STDERR "$name returns a string" if $mode eq 'ret' && !$ret_string_ok{$name};
                return 'string';
            }
        }
        $arg = 'opaque';
    } elsif ($arg =~ /^char\s*\*\*/ or $arg =~ /^const char\s*\*\s*const\s*\*/) {
        if ($use_CSL{$name}) {
            $arg = 'opaque';
        } else {
            say STDERR "char ** in $name" unless $char_p_p_ok{$name};
            $arg = 'string_pointer';
        }
    } elsif ($arg =~ /char\s*\*/) {
        if ($mode eq 'ret' && $use_ret_opaque{$name}) {
            $arg = 'opaque';
        } else {
            say STDERR "$name returns a string" if $mode eq 'ret' && !$ret_string_ok{$name};
            $arg = 'string';
        }
    } elsif ($arg =~ /^unsigned char\s*\*/) {
        $arg = 'pointer';
    } elsif ($arg =~ /int\s*\*/) {
        if ($use_array{$name}) {
            $arg = 'int[]';
        } elsif ($mode eq 'ret' && $use_ret_pointer{$name}) {
            $arg = 'pointer';
        } else {
            $arg = 'int*';
        }
    } elsif ($arg =~ /^int/) {
        $arg = 'int';
    } elsif ($arg =~ /^unsigned int\s*\*/) {
        $arg = 'unsigned int*';
    } elsif ($arg =~ /^unsigned int/) {
        $arg = 'unsigned int';
    } elsif ($arg =~ /^long\s*\*/) {
        $arg = 'long*';
    } elsif ($arg =~ /^long/) {
        $arg = 'long';
    } elsif ($arg =~ /double\s*\*/) {
        if ($name eq 'GDALGetGeoTransform' or $name eq 'GDALSetGeoTransform') {
            $arg = 'double[6]';
        } elsif ($use_array{$name}) {
            $arg = 'double[]';
        } elsif ($mode eq 'ret' && $use_ret_pointer{$name}) {
            $arg = 'pointer';
        } else {
            $arg = 'double*';
        }
    } elsif ($arg =~ /^double/) {
        $arg = 'double';
    } elsif ($arg =~ /float\s*\*/) {
        $arg = 'float*';
    } elsif ($arg =~ /float/) {
        $arg = 'float';
    } elsif ($arg =~ /^CPLErr/) {
        $arg = 'int';
    } elsif ($arg =~ /^OGRErr\s*\*/) {
        $arg = 'int*';
    } elsif ($arg =~ /^OGRErr/) {
        $arg = 'int';
    } elsif ($arg =~ /^size_t/) {
        $arg = 'size_t';
    } elsif ($arg =~ /GByte\s*\*/) {
        $arg = 'pointer';
    } elsif ($arg =~ /^GUInt32\s*\*/) {
        $arg = 'uint32*';
    } elsif ($arg =~ /^GUInt32/) {
        $arg = 'uint32';
    } elsif ($arg =~ /^GUIntBig\s*\*/) {
        $arg = 'uint64*';
    } elsif ($arg =~ /^GUIntBig/) {
        $arg = 'uint64';
    } elsif ($arg =~ /GIntBig\s*\*/) {
        if ($use_array{$name}) {
            $arg = 'sint64[]';
        } elsif ($mode eq 'ret' && $use_ret_pointer{$name}) {
            $arg = 'pointer';
        } else {
            $arg = 'sint64*';
        }
    } elsif ($arg =~ /^GIntBig/ or $arg =~ /^GSpacing/) {
        $arg = 'sint64';
    } elsif ($arg =~ /^void/) {
        $arg = 'void';
    } elsif ($arg =~ /^CSLConstList/) {
        $arg = 'opaque';
    } else {
        die "can't parse arg '$arg'";
    }
    return $arg;
}

sub pre_process {
    state $skip = 0;
    my $fh = shift;
    while (1) {
        my $s = '';
        while (1) {
            my $n = get_line($fh);
            #say STDERR "got: ",$n;
            return if !defined($n) && $s eq '';
            return $s unless defined $n;
            $s .= ' '.$n;
            last unless $s =~ /\\$/;
        }
        $s =~ s/^\s+//;
        $s =~ s/\s+$//;
        $s =~ tr/ //s;
        $s =~ s/^#\s+/#/;
        if ($s =~ /^#ifndef (\w+)/) {
            next;
        }
        if ($s =~ /^#ifdef (\w+)/ or $s =~ /^#if defined\((\w+)\)/) {
            if ($1 eq 'DEBUG' or $1 eq 'undef' or $1 eq 'GDAL_COMPILATION') {
                $skip = 1;
                next;
            }
        }
        if ($s =~ /^#else/) {
            $skip = 0 if $skip;
            next;
        }
        if ($s =~ /^#define (\w+) (.*)/) {
            $defines{$1} = $2;
            next;
        }
        # skip all other defines
        if ($s =~ /^#define/) {
            next;
        }
        if ($s =~ /^#include/) {
            next;
        }
        if ($s =~ /^#endif/) {
            $skip = 0 if $skip;
            next;
        }
        next if $skip;
        return $s;
    }
}

sub get_line {
    state $state = '';
    my $fh = shift;
    my $s = <$fh>;
    return unless $s;
    chomp $s;
    #say STDERR 'line: ',$s;
    if ($state eq 'comment') {
        if ($s =~ /\*\//) {
            $s =~ s/.*?\*\///;
            $state = '';
        } else {
            return '';
        }
    }
    # replace pre-defined constants
    for my $def (keys %pre) {
        $s =~ s/$def/$pre{$def}/;
    }
    # remove on-line comments
    if ($s =~ /\/\*/ and $s =~ /\*\//) {
        $s =~ s/\/\*.*?\*\///;
    }
    $s =~ s/\/\/.*//;
    # remove starting comment and set state
    if ($s =~ /\/\*/) {
        $s =~ s/\/\*.*//;
        $state = 'comment';
    }
    return $s;
}
