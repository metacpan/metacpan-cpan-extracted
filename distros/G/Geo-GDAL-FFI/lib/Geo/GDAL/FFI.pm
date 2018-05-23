package Geo::GDAL::FFI;

use v5.10;
use strict;
use warnings;
use Carp;
use PkgConfig;
use Alien::gdal;
use PDL;
use FFI::Platypus;
use FFI::Platypus::Buffer;
require Exporter;
require B;

use Geo::GDAL::FFI::SpatialReference;
use Geo::GDAL::FFI::Object;
use Geo::GDAL::FFI::Driver;
use Geo::GDAL::FFI::Dataset;
use Geo::GDAL::FFI::Band;
use Geo::GDAL::FFI::Layer;
use Geo::GDAL::FFI::FeatureDefn;
use Geo::GDAL::FFI::FieldDefn;
use Geo::GDAL::FFI::GeomFieldDefn;
use Geo::GDAL::FFI::Feature;
use Geo::GDAL::FFI::Geometry;

our $VERSION = 0.05_01;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(@errors);

our $Warning = 2;
our $Failure = 3;

our %ogr_errors = (
    1 => 'NOT_ENOUGH_DATA',
    2 => 'NOT_ENOUGH_MEMORY',
    3 => 'UNSUPPORTED_GEOMETRY_TYPE',
    4 => 'UNSUPPORTED_OPERATION',
    5 => 'CORRUPT_DATA',
    6 => 'FAILURE',
    7 => 'UNSUPPORTED_SRS',
    8 => 'INVALID_HANDLE',
    9 => 'NON_EXISTING_FEATURE',
    );

our $Read = 0;
our $Write = 1;

our @errors;
our %immutable;
our %parent;

sub error_msg {
    my $args = shift;
    return unless @errors || $args;
    unless (@errors) {
        return $ogr_errors{$args->{OGRError}} if $args->{OGRError};
        return "Unknown error";
    }
    my $msg = join("\n", @errors);
    @errors = ();
    return $msg;
}

our %capabilities = (
    OPEN => 1,
    CREATE => 2,
    CREATECOPY => 3,
    VIRTUALIO => 4,
    RASTER => 5,
    VECTOR => 6,
    GNM => 7,
    NOTNULL_FIELDS => 8,
    DEFAULT_FIELDS => 9,
    NOTNULL_GEOMFIELDS => 10,
    NONSPATIAL => 11,
    FEATURE_STYLES => 12,
    );

sub Capabilities {
    return sort {$capabilities{$a} <=> $capabilities{$b}} keys %capabilities;
}

our %open_flags = (
    READONLY => 0x00,
    UPDATE   => 0x01,
    ALL      => 0x00,
    RASTER   => 0x02,
    VECTOR   => 0x04,
    GNM      => 0x08,
    SHARED   => 0x20,
    VERBOSE_ERROR =>  0x40,
    INTERNAL      =>  0x80,
    ARRAY_BLOCK_ACCESS   =>    0x100,
    HASHSET_BLOCK_ACCESS =>    0x200,
    );

sub OpenFlags {
    return sort {$open_flags{$a} <=> $open_flags{$b}} keys %open_flags;
}

our %data_types = (
    Unknown => 0,
    Byte => 1,
    UInt16 => 2,
    Int16 => 3,
    UInt32 => 4,
    Int32 => 5,
    Float32 => 6,
    Float64 => 7,
    CInt16 => 8,
    CInt32 => 9,
    CFloat32 => 10,
    CFloat64 => 11
    );
our %data_types_reverse = reverse %data_types;

sub DataTypes {
    return sort {$data_types{$a} <=> $data_types{$b}} keys %data_types;
}

our %resampling = (
    NearestNeighbour => 0,
    Bilinear => 1,
    Cubic => 2,
    CubicSpline => 3,
    ORA_Lanczos => 4,
    Average => 5,
    Mode => 6,
    Gauss => 7
    );

sub ResamplingMethods {
    return sort {$resampling{$a} <=> $resampling{$b}} keys %resampling;
}

our %data_type2pdl_data_type = (
    Byte => $PDL::Types::PDL_B,
    Int16 => $PDL::Types::PDL_S,
    UInt16 => $PDL::Types::PDL_US,
    Int32 => $PDL::Types::PDL_L,
    Float32 => $PDL::Types::PDL_F,
    Float64 => $PDL::Types::PDL_D,
    );
our %pdl_data_type2data_type = reverse %data_type2pdl_data_type;

our %field_types = (
    Integer => 0,
    IntegerList => 1,
    Real => 2,
    RealList => 3,
    String => 4,
    StringList => 5,
    #WideString => 6,     # do not use
    #WideStringList => 7, # do not use
    Binary => 8,
    Date => 9,
    Time => 10,
    DateTime => 11,
    Integer64 => 12,
    Integer64List => 13,
    );
our %field_types_reverse = reverse %field_types;

sub FieldTypes {
    return sort {$field_types{$a} <=> $field_types{$b}} keys %field_types;
}

our %field_subtypes = (
    None => 0,
    Boolean => 1,
    Int16 => 2,
    Float32 => 3
    );
our %field_subtypes_reverse = reverse %field_subtypes;

sub FieldSubtypes {
    return sort {$field_subtypes{$a} <=> $field_subtypes{$b}} keys %field_subtypes;
}

our %justification = (
    Undefined => 0,
    Left => 1,
    Right => 2
    );
our %justification_reverse = reverse %justification;

sub Justifications {
    return sort {$justification{$a} <=> $justification{$b}} keys %justification;
}

our %color_interpretations = (
    Undefined => 0,
    GrayIndex => 1,
    PaletteIndex => 2,
    RedBand => 3,
    GreenBand => 4,
    BlueBand => 5,
    AlphaBand => 6,
    HueBand => 7,
    SaturationBand => 8,
    LightnessBand => 9,
    CyanBand => 10,
    MagentaBand => 11,
    YellowBand => 12,
    BlackBand => 13,
    YCbCr_YBand => 14,
    YCbCr_CbBand => 15,
    YCbCr_CrBand => 16,
    );
our %color_interpretations_reverse = reverse %color_interpretations;

sub ColorInterpretations {
    return sort {$color_interpretations{$a} <=> $color_interpretations{$b}} keys %color_interpretations;
}

our %geometry_types = (
    Unknown => 0,
    Point => 1,
    LineString => 2,
    Polygon => 3,
    MultiPoint => 4,
    MultiLineString => 5,
    MultiPolygon => 6,
    GeometryCollection => 7,
    CircularString => 8,
    CompoundCurve => 9,
    CurvePolygon => 10,
    MultiCurve => 11,
    MultiSurface => 12,
    Curve => 13,
    Surface => 14,
    PolyhedralSurface => 15,
    TIN => 16,
    Triangle => 17,
    None => 100,
    LinearRing => 101,
    CircularStringZ => 1008,
    CompoundCurveZ => 1009,
    CurvePolygonZ => 1010,
    MultiCurveZ => 1011,
    MultiSurfaceZ => 1012,
    CurveZ => 1013,
    SurfaceZ => 1014,
    PolyhedralSurfaceZ => 1015,
    TINZ => 1016,
    TriangleZ => 1017,
    PointM => 2001,
    LineStringM => 2002,
    PolygonM => 2003,
    MultiPointM => 2004,
    MultiLineStringM => 2005,
    MultiPolygonM => 2006,
    GeometryCollectionM => 2007,
    CircularStringM => 2008,
    CompoundCurveM => 2009,
    CurvePolygonM => 2010,
    MultiCurveM => 2011,
    MultiSurfaceM => 2012,
    CurveM => 2013,
    SurfaceM => 2014,
    PolyhedralSurfaceM => 2015,
    TINM => 2016,
    TriangleM => 2017,
    PointZM => 3001,
    LineStringZM => 3002,
    PolygonZM => 3003,
    MultiPointZM => 3004,
    MultiLineStringZM => 3005,
    MultiPolygonZM => 3006,
    GeometryCollectionZM => 3007,
    CircularStringZM => 3008,
    CompoundCurveZM => 3009,
    CurvePolygonZM => 3010,
    MultiCurveZM => 3011,
    MultiSurfaceZM => 3012,
    CurveZM => 3013,
    SurfaceZM => 3014,
    PolyhedralSurfaceZM => 3015,
    TINZM => 3016,
    TriangleZM => 3017,
    Point25D => 0x80000001,
    LineString25D => 0x80000002,
    Polygon25D => 0x80000003,
    MultiPoint25D => 0x80000004,
    MultiLineString25D => 0x80000005,
    MultiPolygon25D => 0x80000006,
    GeometryCollection25D => 0x80000007
    );
our %geometry_types_reverse = reverse %geometry_types;

sub GeometryTypes {
    return sort {$geometry_types{$a} <=> $geometry_types{$b}} keys %geometry_types;
}

our %geometry_formats = (
    WKT => 1,
    );

sub GeometryFormats {
    return sort {$geometry_formats{$a} <=> $geometry_formats{$b}} keys %geometry_formats;
}

our %grid_algorithms = (
    InverseDistanceToAPower => 1,
    MovingAverage => 2,
    NearestNeighbor => 3,
    MetricMinimum => 4,
    MetricMaximum => 5,
    MetricRange => 6,
    MetricCount => 7,
    MetricAverageDistance => 8,
    MetricAverageDistancePts => 9,
    Linear => 10,
    InverseDistanceToAPowerNearestNeighbor => 11
    );

sub GridAlgorithms {
    return sort {$grid_algorithms{$a} <=> $grid_algorithms{$b}} keys %grid_algorithms;
}

sub isint {
    my $value = shift;
    my $b_obj = B::svref_2object(\$value);
    my $flags = $b_obj->FLAGS;
    return 1 if $flags & B::SVp_IOK() && !($flags & B::SVp_NOK()) && !($flags & B::SVp_POK());
}

sub fake {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub new {
    my $class = shift;
    my $ffi = FFI::Platypus->new;
    $ffi->load_custom_type('::StringPointer' => 'string_pointer');
    $ffi->lib(Alien::gdal->dynamic_libs);

    $ffi->type('(pointer,size_t,size_t,opaque)->size_t' => 'VSIWriteFunction');
    $ffi->type('(int,int,string)->void' => 'CPLErrorHandler');
    $ffi->type('(double,string,pointer)->int' => 'GDALProgressFunc');
    $ffi->type('(pointer,int, pointer,int,int,unsigned int,unsigned int,int,int)->int' => 'GDALDerivedPixelFunc');
    $ffi->type('(pointer,int,int,pointer,pointer,pointer,pointer)->int' => 'GDALTransformerFunc');
    $ffi->type('(double,int,pointer,pointer,pointer)->int' => 'GDALContourWriter');

    # from port/*.h
    eval{$ffi->attach('VSIFOpenL' => [qw/string string/] => 'opaque');};
    croak "Can't attach to GDAL methods. Does Alien::gdal provide GDAL dynamic libs?" unless $class->can('VSIFOpenL');
    eval{$ffi->attach('VSIFCloseL' => ['opaque'] => 'int');};
    eval{$ffi->attach('VSIFWriteL' => [qw/pointer size_t size_t opaque/] => 'size_t');};
    eval{$ffi->attach('VSIStdoutSetRedirection' => ['VSIWriteFunction', 'opaque'] => 'void');};
    eval{$ffi->attach('CPLPushErrorHandler' => ['CPLErrorHandler'] => 'void');};
    eval{$ffi->attach('CSLDestroy' => ['opaque'] => 'void');};
    eval{$ffi->attach('CSLAddString' => ['opaque', 'string'] => 'opaque');};
    eval{$ffi->attach('CSLCount' => ['opaque'] => 'int');};
    eval{$ffi->attach('CSLGetField' => ['opaque', 'int'] => 'string');};
    eval{$ffi->attach(CPLGetConfigOption => ['string', 'string']  => 'string');};
    eval{$ffi->attach(CPLSetConfigOption => ['string', 'string']  => 'void');};
    eval{$ffi->attach(CPLFindFile => ['string', 'string']  => 'string');};
    eval{$ffi->attach(CPLPushFinderLocation => ['string'] => 'string');};
    eval{$ffi->attach(CPLPopFinderLocation => [] => 'void');};
    eval{$ffi->attach(CPLFinderClean => [] => 'void');};

    # from ogr_core.h
    eval{$ffi->attach( 'OGR_GT_Flatten' => ['unsigned int'] => 'unsigned int');};

# created with parse_h.pl
# from /home/ajolma/github/gdal/gdal/gcore/gdal.h
eval{$ffi->attach('GDALGetDataTypeSize' => ['unsigned int'] => 'int');};
eval{$ffi->attach('GDALGetDataTypeSizeBits' => ['unsigned int'] => 'int');};
eval{$ffi->attach('GDALGetDataTypeSizeBytes' => ['unsigned int'] => 'int');};
eval{$ffi->attach('GDALDataTypeIsComplex' => ['unsigned int'] => 'int');};
eval{$ffi->attach('GDALDataTypeIsInteger' => ['unsigned int'] => 'int');};
eval{$ffi->attach('GDALDataTypeIsFloating' => ['unsigned int'] => 'int');};
eval{$ffi->attach('GDALDataTypeIsSigned' => ['unsigned int'] => 'int');};
eval{$ffi->attach('GDALGetDataTypeName' => ['unsigned int'] => 'string');};
eval{$ffi->attach('GDALGetDataTypeByName' => [qw/string/] => 'unsigned int');};
eval{$ffi->attach('GDALDataTypeUnion' => ['unsigned int','unsigned int'] => 'unsigned int');};
eval{$ffi->attach('GDALDataTypeUnionWithValue' => ['unsigned int','double','int'] => 'unsigned int');};
eval{$ffi->attach('GDALFindDataType' => [qw/int int int int/] => 'unsigned int');};
eval{$ffi->attach('GDALFindDataTypeForValue' => [qw/double int/] => 'unsigned int');};
eval{$ffi->attach('GDALAdjustValueToDataType' => ['unsigned int','double','int*','int*'] => 'double');};
eval{$ffi->attach('GDALGetNonComplexDataType' => ['unsigned int'] => 'unsigned int');};
eval{$ffi->attach('GDALDataTypeIsConversionLossy' => ['unsigned int','unsigned int'] => 'int');};
eval{$ffi->attach('GDALGetAsyncStatusTypeName' => ['unsigned int'] => 'string');};
eval{$ffi->attach('GDALGetAsyncStatusTypeByName' => [qw/string/] => 'unsigned int');};
eval{$ffi->attach('GDALGetColorInterpretationName' => ['unsigned int'] => 'string');};
eval{$ffi->attach('GDALGetColorInterpretationByName' => [qw/string/] => 'unsigned int');};
eval{$ffi->attach('GDALGetPaletteInterpretationName' => ['unsigned int'] => 'string');};
eval{$ffi->attach('GDALAllRegister' => [] => 'void');};
eval{$ffi->attach('GDALCreate' => ['opaque','string','int','int','int','unsigned int','opaque'] => 'opaque');};
eval{$ffi->attach('GDALCreateCopy' => [qw/opaque string opaque int opaque GDALProgressFunc opaque/] => 'opaque');};
eval{$ffi->attach('GDALIdentifyDriver' => [qw/string opaque/] => 'opaque');};
eval{$ffi->attach('GDALIdentifyDriverEx' => ['string','unsigned int','string_pointer','string_pointer'] => 'opaque');};
eval{$ffi->attach('GDALOpen' => ['string','unsigned int'] => 'opaque');};
eval{$ffi->attach('GDALOpenShared' => ['string','unsigned int'] => 'opaque');};
eval{$ffi->attach('GDALOpenEx' => ['string','unsigned int','opaque','opaque','opaque'] => 'opaque');};
eval{$ffi->attach('GDALDumpOpenDatasets' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetDriverByName' => [qw/string/] => 'opaque');};
eval{$ffi->attach('GDALGetDriverCount' => [] => 'int');};
eval{$ffi->attach('GDALGetDriver' => [qw/int/] => 'opaque');};
eval{$ffi->attach('GDALCreateDriver' => [] => 'opaque');};
eval{$ffi->attach('GDALDestroyDriver' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALRegisterDriver' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALDeregisterDriver' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALDestroyDriverManager' => [] => 'void');};
eval{$ffi->attach('GDALDestroy' => [] => 'void');};
eval{$ffi->attach('GDALDeleteDataset' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('GDALRenameDataset' => [qw/opaque string string/] => 'int');};
eval{$ffi->attach('GDALCopyDatasetFiles' => [qw/opaque string string/] => 'int');};
eval{$ffi->attach('GDALValidateCreationOptions' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('GDALGetDriverShortName' => [qw/opaque/] => 'string');};
eval{$ffi->attach('GDALGetDriverLongName' => [qw/opaque/] => 'string');};
eval{$ffi->attach('GDALGetDriverHelpTopic' => [qw/opaque/] => 'string');};
eval{$ffi->attach('GDALGetDriverCreationOptionList' => [qw/opaque/] => 'string');};
eval{$ffi->attach('GDALInitGCPs' => [qw/int opaque/] => 'void');};
eval{$ffi->attach('GDALDeinitGCPs' => [qw/int opaque/] => 'void');};
eval{$ffi->attach('GDALDuplicateGCPs' => [qw/int opaque/] => 'opaque');};
eval{$ffi->attach('GDALGCPsToGeoTransform' => [qw/int opaque double* int/] => 'int');};
eval{$ffi->attach('GDALInvGeoTransform' => [qw/double* double*/] => 'int');};
eval{$ffi->attach('GDALApplyGeoTransform' => [qw/double* double double double* double*/] => 'void');};
eval{$ffi->attach('GDALComposeGeoTransforms' => [qw/double* double* double*/] => 'void');};
eval{$ffi->attach('GDALGetMetadataDomainList' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALGetMetadata' => [qw/opaque string/] => 'opaque');};
eval{$ffi->attach('GDALSetMetadata' => [qw/opaque opaque string/] => 'int');};
eval{$ffi->attach('GDALGetMetadataItem' => [qw/opaque string string/] => 'string');};
eval{$ffi->attach('GDALSetMetadataItem' => [qw/opaque string string string/] => 'int');};
eval{$ffi->attach('GDALGetDescription' => [qw/opaque/] => 'string');};
eval{$ffi->attach('GDALSetDescription' => [qw/opaque string/] => 'void');};
eval{$ffi->attach('GDALGetDatasetDriver' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALGetFileList' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALClose' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALGetRasterXSize' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterYSize' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterBand' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('GDALAddBand' => ['opaque','unsigned int','opaque'] => 'int');};
eval{$ffi->attach('GDALBeginAsyncReader' => ['opaque','int','int','int','int','opaque','int','int','unsigned int','int','int*','int','int','int','string_pointer'] => 'opaque');};
eval{$ffi->attach('GDALEndAsyncReader' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('GDALDatasetRasterIO' => ['opaque','unsigned int','int','int','int','int','opaque','int','int','unsigned int','int','int*','int','int','int'] => 'int');};
eval{$ffi->attach('GDALDatasetRasterIOEx' => ['opaque','unsigned int','int','int','int','int','opaque','int','int','unsigned int','int','int*','sint64','sint64','sint64','opaque'] => 'int');};
eval{$ffi->attach('GDALDatasetAdviseRead' => ['opaque','int','int','int','int','int','int','unsigned int','int','int*','string_pointer'] => 'int');};
eval{$ffi->attach('GDALGetProjectionRef' => [qw/opaque/] => 'string');};
eval{$ffi->attach('GDALSetProjection' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('GDALGetGeoTransform' => [qw/opaque double[6]/] => 'int');};
eval{$ffi->attach('GDALSetGeoTransform' => [qw/opaque double[6]/] => 'int');};
eval{$ffi->attach('GDALGetGCPCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetGCPProjection' => [qw/opaque/] => 'string');};
eval{$ffi->attach('GDALGetGCPs' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALSetGCPs' => [qw/opaque int opaque string/] => 'int');};
eval{$ffi->attach('GDALGetInternalHandle' => [qw/opaque string/] => 'opaque');};
eval{$ffi->attach('GDALReferenceDataset' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALDereferenceDataset' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALReleaseDataset' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALBuildOverviews' => [qw/opaque string int int* int int* GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALGetOpenDatasets' => [qw/uint64* int*/] => 'void');};
eval{$ffi->attach('GDALGetAccess' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALFlushCache' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALCreateDatasetMaskBand' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('GDALDatasetCopyWholeRaster' => [qw/opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALRasterBandCopyWholeRaster' => [qw/opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALRegenerateOverviews' => [qw/opaque int uint64* string GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALDatasetGetLayerCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALDatasetGetLayer' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('GDALDatasetGetLayerByName' => [qw/opaque string/] => 'opaque');};
eval{$ffi->attach('GDALDatasetDeleteLayer' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('GDALDatasetCreateLayer' => ['opaque','string','opaque','unsigned int','opaque'] => 'opaque');};
eval{$ffi->attach('GDALDatasetCopyLayer' => [qw/opaque opaque string opaque/] => 'opaque');};
eval{$ffi->attach('GDALDatasetResetReading' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALDatasetGetNextFeature' => [qw/opaque uint64* double* GDALProgressFunc opaque/] => 'opaque');};
eval{$ffi->attach('GDALDatasetTestCapability' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('GDALDatasetExecuteSQL' => [qw/opaque string opaque string/] => 'opaque');};
eval{$ffi->attach('GDALDatasetReleaseResultSet' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('GDALDatasetGetStyleTable' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALDatasetSetStyleTableDirectly' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('GDALDatasetSetStyleTable' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('GDALDatasetStartTransaction' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('GDALDatasetCommitTransaction' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALDatasetRollbackTransaction' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterDataType' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('GDALGetBlockSize' => [qw/opaque int* int*/] => 'void');};
eval{$ffi->attach('GDALGetActualBlockSize' => [qw/opaque int int int* int*/] => 'int');};
eval{$ffi->attach('GDALRasterAdviseRead' => ['opaque','int','int','int','int','int','int','unsigned int','string_pointer'] => 'int');};
eval{$ffi->attach('GDALRasterIO' => ['opaque','unsigned int','int','int','int','int','opaque','int','int','unsigned int','int','int'] => 'int');};
eval{$ffi->attach('GDALRasterIOEx' => ['opaque','unsigned int','int','int','int','int','opaque','int','int','unsigned int','sint64','sint64','opaque'] => 'int');};
eval{$ffi->attach('GDALReadBlock' => [qw/opaque int int opaque/] => 'int');};
eval{$ffi->attach('GDALWriteBlock' => [qw/opaque int int opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterBandXSize' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterBandYSize' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterAccess' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('GDALGetBandNumber' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetBandDataset' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALGetRasterColorInterpretation' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('GDALSetRasterColorInterpretation' => ['opaque','unsigned int'] => 'int');};
eval{$ffi->attach('GDALGetRasterColorTable' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALSetRasterColorTable' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('GDALHasArbitraryOverviews' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetOverviewCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetOverview' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('GDALGetRasterNoDataValue' => [qw/opaque int*/] => 'double');};
eval{$ffi->attach('GDALSetRasterNoDataValue' => [qw/opaque double/] => 'int');};
eval{$ffi->attach('GDALDeleteRasterNoDataValue' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterCategoryNames' => [qw/opaque/] => 'string_pointer');};
eval{$ffi->attach('GDALSetRasterCategoryNames' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('GDALGetRasterMinimum' => [qw/opaque int*/] => 'double');};
eval{$ffi->attach('GDALGetRasterMaximum' => [qw/opaque int*/] => 'double');};
eval{$ffi->attach('GDALGetRasterStatistics' => [qw/opaque int int double* double* double* double*/] => 'int');};
eval{$ffi->attach('GDALComputeRasterStatistics' => [qw/opaque int double* double* double* double* GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALSetRasterStatistics' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('GDALGetRasterUnitType' => [qw/opaque/] => 'string');};
eval{$ffi->attach('GDALSetRasterUnitType' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('GDALGetRasterOffset' => [qw/opaque int*/] => 'double');};
eval{$ffi->attach('GDALSetRasterOffset' => [qw/opaque double/] => 'int');};
eval{$ffi->attach('GDALGetRasterScale' => [qw/opaque int*/] => 'double');};
eval{$ffi->attach('GDALSetRasterScale' => [qw/opaque double/] => 'int');};
eval{$ffi->attach('GDALComputeRasterMinMax' => [qw/opaque int double/] => 'void');};
eval{$ffi->attach('GDALFlushRasterCache' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterHistogram' => [qw/opaque double double int int* int int GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALGetRasterHistogramEx' => [qw/opaque double double int uint64* int int GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALGetDefaultHistogram' => [qw/opaque double* double* int* int* int GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALGetDefaultHistogramEx' => [qw/opaque double* double* int* uint64* int GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALSetDefaultHistogram' => [qw/opaque double double int int*/] => 'int');};
eval{$ffi->attach('GDALSetDefaultHistogramEx' => [qw/opaque double double int uint64*/] => 'int');};
eval{$ffi->attach('GDALGetRandomRasterSample' => [qw/opaque int float*/] => 'int');};
eval{$ffi->attach('GDALGetRasterSampleOverview' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('GDALGetRasterSampleOverviewEx' => [qw/opaque uint64/] => 'opaque');};
eval{$ffi->attach('GDALFillRaster' => [qw/opaque double double/] => 'int');};
eval{$ffi->attach('GDALComputeBandStats' => [qw/opaque int double* double* GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALOverviewMagnitudeCorrection' => [qw/opaque int uint64* GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('GDALGetDefaultRAT' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALSetDefaultRAT' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('GDALAddDerivedBandPixelFunc' => [qw/string GDALDerivedPixelFunc/] => 'int');};
eval{$ffi->attach('GDALGetMaskBand' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALGetMaskFlags' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALCreateMaskBand' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('GDALGetDataCoverageStatus' => [qw/opaque int int int int int double*/] => 'int');};
eval{$ffi->attach('GDALARGetNextUpdatedRegion' => [qw/opaque double int* int* int* int*/] => 'unsigned int');};
eval{$ffi->attach('GDALARLockBuffer' => [qw/opaque double/] => 'int');};
eval{$ffi->attach('GDALARUnlockBuffer' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALGeneralCmdLineProcessor' => [qw/int string_pointer int/] => 'int');};
eval{$ffi->attach('GDALSwapWords' => [qw/opaque int int int/] => 'void');};
eval{$ffi->attach('GDALSwapWordsEx' => [qw/opaque int size_t int/] => 'void');};
eval{$ffi->attach('GDALCopyWords' => ['opaque','unsigned int','int','opaque','unsigned int','int','int'] => 'void');};
eval{$ffi->attach('GDALCopyBits' => [qw/pointer int int pointer int int int int/] => 'void');};
eval{$ffi->attach('GDALLoadWorldFile' => [qw/string double*/] => 'int');};
eval{$ffi->attach('GDALReadWorldFile' => [qw/string string double*/] => 'int');};
eval{$ffi->attach('GDALWriteWorldFile' => [qw/string string double*/] => 'int');};
eval{$ffi->attach('GDALLoadTabFile' => [qw/string double* string_pointer int* opaque/] => 'int');};
eval{$ffi->attach('GDALReadTabFile' => [qw/string double* string_pointer int* opaque/] => 'int');};
eval{$ffi->attach('GDALLoadOziMapFile' => [qw/string double* string_pointer int* opaque/] => 'int');};
eval{$ffi->attach('GDALReadOziMapFile' => [qw/string double* string_pointer int* opaque/] => 'int');};
eval{$ffi->attach('GDALDecToDMS' => [qw/double string int/] => 'string');};
eval{$ffi->attach('GDALPackedDMSToDec' => [qw/double/] => 'double');};
eval{$ffi->attach('GDALDecToPackedDMS' => [qw/double/] => 'double');};
eval{$ffi->attach('GDALVersionInfo' => [qw/string/] => 'string');};
eval{$ffi->attach('GDALCheckVersion' => [qw/int int string/] => 'int');};
eval{$ffi->attach('GDALExtractRPCInfo' => [qw/string_pointer opaque/] => 'int');};
eval{$ffi->attach('GDALCreateColorTable' => ['unsigned int'] => 'opaque');};
eval{$ffi->attach('GDALDestroyColorTable' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALCloneColorTable' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALGetPaletteInterpretation' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('GDALGetColorEntryCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALGetColorEntry' => [qw/opaque int/] => 'short[4]');};
eval{$ffi->attach('GDALGetColorEntryAsRGB' => [qw/opaque int short[4]/] => 'int');};
eval{$ffi->attach('GDALSetColorEntry' => [qw/opaque int short[4]/] => 'void');};
eval{$ffi->attach('GDALCreateColorRamp' => [qw/opaque int short[4] int short[4]/] => 'void');};
eval{$ffi->attach('GDALCreateRasterAttributeTable' => [] => 'opaque');};
eval{$ffi->attach('GDALDestroyRasterAttributeTable' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALRATGetColumnCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALRATGetNameOfCol' => [qw/opaque int/] => 'string');};
eval{$ffi->attach('GDALRATGetUsageOfCol' => [qw/opaque int/] => 'unsigned int');};
eval{$ffi->attach('GDALRATGetTypeOfCol' => [qw/opaque int/] => 'unsigned int');};
eval{$ffi->attach('GDALRATGetColOfUsage' => ['opaque','unsigned int'] => 'int');};
eval{$ffi->attach('GDALRATGetRowCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALRATGetValueAsString' => [qw/opaque int int/] => 'string');};
eval{$ffi->attach('GDALRATGetValueAsInt' => [qw/opaque int int/] => 'int');};
eval{$ffi->attach('GDALRATGetValueAsDouble' => [qw/opaque int int/] => 'double');};
eval{$ffi->attach('GDALRATSetValueAsString' => [qw/opaque int int string/] => 'void');};
eval{$ffi->attach('GDALRATSetValueAsInt' => [qw/opaque int int int/] => 'void');};
eval{$ffi->attach('GDALRATSetValueAsDouble' => [qw/opaque int int double/] => 'void');};
eval{$ffi->attach('GDALRATChangesAreWrittenToFile' => [qw/opaque/] => 'int');};
eval{$ffi->attach('GDALRATValuesIOAsDouble' => ['opaque','unsigned int','int','int','int','double*'] => 'int');};
eval{$ffi->attach('GDALRATValuesIOAsInteger' => ['opaque','unsigned int','int','int','int','int*'] => 'int');};
eval{$ffi->attach('GDALRATValuesIOAsString' => ['opaque','unsigned int','int','int','int','string_pointer'] => 'int');};
eval{$ffi->attach('GDALRATSetRowCount' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('GDALRATCreateColumn' => ['opaque','string','unsigned int','unsigned int'] => 'int');};
eval{$ffi->attach('GDALRATSetLinearBinning' => [qw/opaque double double/] => 'int');};
eval{$ffi->attach('GDALRATGetLinearBinning' => [qw/opaque double* double*/] => 'int');};
eval{$ffi->attach('GDALRATInitializeFromColorTable' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('GDALRATTranslateToColorTable' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('GDALRATDumpReadable' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('GDALRATClone' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALRATSerializeJSON' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('GDALRATGetRowOfValue' => [qw/opaque double/] => 'int');};
eval{$ffi->attach('GDALSetCacheMax' => [qw/int/] => 'void');};
eval{$ffi->attach('GDALGetCacheMax' => [] => 'int');};
eval{$ffi->attach('GDALGetCacheUsed' => [] => 'int');};
eval{$ffi->attach('GDALSetCacheMax64' => [qw/sint64/] => 'void');};
eval{$ffi->attach('GDALGetCacheMax64' => [] => 'sint64');};
eval{$ffi->attach('GDALGetCacheUsed64' => [] => 'sint64');};
eval{$ffi->attach('GDALFlushCacheBlock' => [] => 'int');};
eval{$ffi->attach('GDALDatasetGetVirtualMem' => ['opaque','unsigned int','int','int','int','int','int','int','unsigned int','int','int*','int','sint64','sint64','size_t','size_t','int','string_pointer'] => 'opaque');};
eval{$ffi->attach('GDALRasterBandGetVirtualMem' => ['opaque','unsigned int','int','int','int','int','int','int','unsigned int','int','sint64','size_t','size_t','int','string_pointer'] => 'opaque');};
eval{$ffi->attach('GDALGetVirtualMemAuto' => ['opaque','unsigned int','int*','sint64*','string_pointer'] => 'opaque');};
eval{$ffi->attach('GDALDatasetGetTiledVirtualMem' => ['opaque','unsigned int','int','int','int','int','int','int','unsigned int','int','int*','unsigned int','size_t','int','string_pointer'] => 'opaque');};
eval{$ffi->attach('GDALRasterBandGetTiledVirtualMem' => ['opaque','unsigned int','int','int','int','int','int','int','unsigned int','size_t','int','string_pointer'] => 'opaque');};
eval{$ffi->attach('GDALCreatePansharpenedVRT' => [qw/string opaque int uint64*/] => 'opaque');};
eval{$ffi->attach('GDALGetJPEG2000Structure' => [qw/string string_pointer/] => 'opaque');};
# from /home/ajolma/github/gdal/gdal/ogr/ogr_api.h
eval{$ffi->attach('OGR_G_CreateFromWkb' => [qw/string opaque uint64* int/] => 'int');};
eval{$ffi->attach('OGR_G_CreateFromWkt' => [qw/string_pointer opaque uint64*/] => 'int');};
eval{$ffi->attach('OGR_G_CreateFromFgf' => [qw/string opaque uint64* int int*/] => 'int');};
eval{$ffi->attach('OGR_G_DestroyGeometry' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_G_CreateGeometry' => ['unsigned int'] => 'opaque');};
eval{$ffi->attach('OGR_G_ApproximateArcAngles' => [qw/double double double double double double double double double/] => 'opaque');};
eval{$ffi->attach('OGR_G_ForceToPolygon' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ForceToLineString' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ForceToMultiPolygon' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ForceToMultiPoint' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ForceToMultiLineString' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ForceTo' => ['opaque','unsigned int','string_pointer'] => 'opaque');};
eval{$ffi->attach('OGR_G_GetDimension' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_GetCoordinateDimension' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_CoordinateDimension' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_SetCoordinateDimension' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_G_Is3D' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_IsMeasured' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Set3D' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_G_SetMeasured' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_G_Clone' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_GetEnvelope' => [qw/opaque double[4]/] => 'void');};
eval{$ffi->attach('OGR_G_GetEnvelope3D' => [qw/opaque double[6]/] => 'void');};
eval{$ffi->attach('OGR_G_ImportFromWkb' => [qw/opaque string int/] => 'int');};
eval{$ffi->attach('OGR_G_ExportToWkb' => ['opaque','unsigned int','string'] => 'int');};
eval{$ffi->attach('OGR_G_ExportToIsoWkb' => ['opaque','unsigned int','string'] => 'int');};
eval{$ffi->attach('OGR_G_WkbSize' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_ImportFromWkt' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OGR_G_ExportToWkt' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OGR_G_ExportToIsoWkt' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OGR_G_GetGeometryType' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_G_GetGeometryName' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_G_DumpReadable' => [qw/opaque opaque string/] => 'void');};
eval{$ffi->attach('OGR_G_FlattenTo2D' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_G_CloseRings' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_G_CreateFromGML' => [qw/string/] => 'opaque');};
eval{$ffi->attach('OGR_G_ExportToGML' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_G_ExportToGMLEx' => [qw/opaque string_pointer/] => 'string');};
eval{$ffi->attach('OGR_G_CreateFromGMLTree' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ExportToGMLTree' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ExportEnvelopeToGMLTree' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ExportToKML' => [qw/opaque string/] => 'string');};
eval{$ffi->attach('OGR_G_ExportToJson' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_G_ExportToJsonEx' => [qw/opaque string_pointer/] => 'string');};
eval{$ffi->attach('OGR_G_CreateGeometryFromJson' => [qw/string/] => 'opaque');};
eval{$ffi->attach('OGR_G_AssignSpatialReference' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_G_GetSpatialReference' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_Transform' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_TransformTo' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Simplify' => [qw/opaque double/] => 'opaque');};
eval{$ffi->attach('OGR_G_SimplifyPreserveTopology' => [qw/opaque double/] => 'opaque');};
eval{$ffi->attach('OGR_G_DelaunayTriangulation' => [qw/opaque double int/] => 'opaque');};
eval{$ffi->attach('OGR_G_Segmentize' => [qw/opaque double/] => 'void');};
eval{$ffi->attach('OGR_G_Intersects' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Equals' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Disjoint' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Touches' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Crosses' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Within' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Contains' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Overlaps' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Boundary' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_ConvexHull' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_Buffer' => [qw/opaque double int/] => 'opaque');};
eval{$ffi->attach('OGR_G_Intersection' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_Union' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_UnionCascaded' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_PointOnSurface' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_Difference' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_SymDifference' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_Distance' => [qw/opaque opaque/] => 'double');};
eval{$ffi->attach('OGR_G_Distance3D' => [qw/opaque opaque/] => 'double');};
eval{$ffi->attach('OGR_G_Length' => [qw/opaque/] => 'double');};
eval{$ffi->attach('OGR_G_Area' => [qw/opaque/] => 'double');};
eval{$ffi->attach('OGR_G_Centroid' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Value' => [qw/opaque double/] => 'opaque');};
eval{$ffi->attach('OGR_G_Empty' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_G_IsEmpty' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_IsValid' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_IsSimple' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_IsRing' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Polygonize' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_Intersect' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_Equal' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_SymmetricDifference' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_GetArea' => [qw/opaque/] => 'double');};
eval{$ffi->attach('OGR_G_GetBoundary' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_G_GetPointCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_GetPoints' => [qw/opaque opaque int opaque int opaque int/] => 'int');};
eval{$ffi->attach('OGR_G_GetPointsZM' => [qw/opaque opaque int opaque int opaque int opaque int/] => 'int');};
eval{$ffi->attach('OGR_G_GetX' => [qw/opaque int/] => 'double');};
eval{$ffi->attach('OGR_G_GetY' => [qw/opaque int/] => 'double');};
eval{$ffi->attach('OGR_G_GetZ' => [qw/opaque int/] => 'double');};
eval{$ffi->attach('OGR_G_GetM' => [qw/opaque int/] => 'double');};
eval{$ffi->attach('OGR_G_GetPoint' => [qw/opaque int double* double* double*/] => 'void');};
eval{$ffi->attach('OGR_G_GetPointZM' => [qw/opaque int double* double* double* double*/] => 'void');};
eval{$ffi->attach('OGR_G_SetPointCount' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_G_SetPoint' => [qw/opaque int double double double/] => 'void');};
eval{$ffi->attach('OGR_G_SetPoint_2D' => [qw/opaque int double double/] => 'void');};
eval{$ffi->attach('OGR_G_SetPointM' => [qw/opaque int double double double/] => 'void');};
eval{$ffi->attach('OGR_G_SetPointZM' => [qw/opaque int double double double double/] => 'void');};
eval{$ffi->attach('OGR_G_AddPoint' => [qw/opaque double double double/] => 'void');};
eval{$ffi->attach('OGR_G_AddPoint_2D' => [qw/opaque double double/] => 'void');};
eval{$ffi->attach('OGR_G_AddPointM' => [qw/opaque double double double/] => 'void');};
eval{$ffi->attach('OGR_G_AddPointZM' => [qw/opaque double double double double/] => 'void');};
eval{$ffi->attach('OGR_G_SetPoints' => [qw/opaque int opaque int opaque int opaque int/] => 'void');};
eval{$ffi->attach('OGR_G_SetPointsZM' => [qw/opaque int opaque int opaque int opaque int opaque int/] => 'void');};
eval{$ffi->attach('OGR_G_SwapXY' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_G_GetGeometryCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_G_GetGeometryRef' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_G_AddGeometry' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_AddGeometryDirectly' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_G_RemoveGeometry' => [qw/opaque int int/] => 'int');};
eval{$ffi->attach('OGR_G_HasCurveGeometry' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_G_GetLinearGeometry' => [qw/opaque double string_pointer/] => 'opaque');};
eval{$ffi->attach('OGR_G_GetCurveGeometry' => [qw/opaque string_pointer/] => 'opaque');};
eval{$ffi->attach('OGRBuildPolygonFromEdges' => [qw/opaque int int double int*/] => 'opaque');};
eval{$ffi->attach('OGRSetGenerate_DB2_V72_BYTE_ORDER' => [qw/int/] => 'int');};
eval{$ffi->attach('OGRGetGenerate_DB2_V72_BYTE_ORDER' => [] => 'int');};
eval{$ffi->attach('OGRSetNonLinearGeometriesEnabledFlag' => [qw/int/] => 'void');};
eval{$ffi->attach('OGRGetNonLinearGeometriesEnabledFlag' => [] => 'int');};
eval{$ffi->attach('OGR_Fld_Create' => ['string','unsigned int'] => 'opaque');};
eval{$ffi->attach('OGR_Fld_Destroy' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_Fld_SetName' => [qw/opaque string/] => 'void');};
eval{$ffi->attach('OGR_Fld_GetNameRef' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_Fld_GetType' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_Fld_SetType' => ['opaque','unsigned int'] => 'void');};
eval{$ffi->attach('OGR_Fld_GetSubType' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_Fld_SetSubType' => ['opaque','unsigned int'] => 'void');};
eval{$ffi->attach('OGR_Fld_GetJustify' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_Fld_SetJustify' => ['opaque','unsigned int'] => 'void');};
eval{$ffi->attach('OGR_Fld_GetWidth' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_Fld_SetWidth' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_Fld_GetPrecision' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_Fld_SetPrecision' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_Fld_Set' => ['opaque','string','unsigned int','int','int','unsigned int'] => 'void');};
eval{$ffi->attach('OGR_Fld_IsIgnored' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_Fld_SetIgnored' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_Fld_IsNullable' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_Fld_SetNullable' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_Fld_GetDefault' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_Fld_SetDefault' => [qw/opaque string/] => 'void');};
eval{$ffi->attach('OGR_Fld_IsDefaultDriverSpecific' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_GetFieldTypeName' => ['unsigned int'] => 'string');};
eval{$ffi->attach('OGR_GetFieldSubTypeName' => ['unsigned int'] => 'string');};
eval{$ffi->attach('OGR_AreTypeSubTypeCompatible' => ['unsigned int','unsigned int'] => 'int');};
eval{$ffi->attach('OGR_GFld_Create' => ['string','unsigned int'] => 'opaque');};
eval{$ffi->attach('OGR_GFld_Destroy' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_GFld_SetName' => [qw/opaque string/] => 'void');};
eval{$ffi->attach('OGR_GFld_GetNameRef' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_GFld_GetType' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_GFld_SetType' => ['opaque','unsigned int'] => 'void');};
eval{$ffi->attach('OGR_GFld_GetSpatialRef' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_GFld_SetSpatialRef' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_GFld_IsNullable' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_GFld_SetNullable' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_GFld_IsIgnored' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_GFld_SetIgnored' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_FD_Create' => [qw/string/] => 'opaque');};
eval{$ffi->attach('OGR_FD_Destroy' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_FD_Release' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_FD_GetName' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_FD_GetFieldCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_FD_GetFieldDefn' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_FD_GetFieldIndex' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_FD_AddFieldDefn' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_FD_DeleteFieldDefn' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_FD_ReorderFieldDefns' => [qw/opaque int*/] => 'int');};
eval{$ffi->attach('OGR_FD_GetGeomType' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_FD_SetGeomType' => ['opaque','unsigned int'] => 'void');};
eval{$ffi->attach('OGR_FD_IsGeometryIgnored' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_FD_SetGeometryIgnored' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_FD_IsStyleIgnored' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_FD_SetStyleIgnored' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_FD_Reference' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_FD_Dereference' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_FD_GetReferenceCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_FD_GetGeomFieldCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_FD_GetGeomFieldDefn' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_FD_GetGeomFieldIndex' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_FD_AddGeomFieldDefn' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_FD_DeleteGeomFieldDefn' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_FD_IsSame' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_F_Create' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_F_Destroy' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_F_GetDefnRef' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_F_SetGeometryDirectly' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_F_SetGeometry' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_F_GetGeometryRef' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_F_StealGeometry' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_F_Clone' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_F_Equal' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_F_GetFieldCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_F_GetFieldDefnRef' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_F_GetFieldIndex' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_F_IsFieldSet' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_F_UnsetField' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_F_IsFieldNull' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_F_IsFieldSetAndNotNull' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_F_SetFieldNull' => [qw/opaque int/] => 'void');};
eval{$ffi->attach('OGR_F_GetRawFieldRef' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_RawField_IsUnset' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_RawField_IsNull' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_RawField_SetUnset' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_RawField_SetNull' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_F_GetFieldAsInteger' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_F_GetFieldAsInteger64' => [qw/opaque int/] => 'sint64');};
eval{$ffi->attach('OGR_F_GetFieldAsDouble' => [qw/opaque int/] => 'double');};
eval{$ffi->attach('OGR_F_GetFieldAsString' => [qw/opaque int/] => 'string');};
eval{$ffi->attach('OGR_F_GetFieldAsIntegerList' => [qw/opaque int int*/] => 'pointer');};
eval{$ffi->attach('OGR_F_GetFieldAsInteger64List' => [qw/opaque int int*/] => 'pointer');};
eval{$ffi->attach('OGR_F_GetFieldAsDoubleList' => [qw/opaque int int*/] => 'pointer');};
eval{$ffi->attach('OGR_F_GetFieldAsStringList' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_F_GetFieldAsBinary' => [qw/opaque int int*/] => 'pointer');};
eval{$ffi->attach('OGR_F_GetFieldAsDateTime' => [qw/opaque int int* int* int* int* int* int* int*/] => 'int');};
eval{$ffi->attach('OGR_F_GetFieldAsDateTimeEx' => [qw/opaque int int* int* int* int* int* float* int*/] => 'int');};
eval{$ffi->attach('OGR_F_SetFieldInteger' => [qw/opaque int int/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldInteger64' => [qw/opaque int sint64/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldDouble' => [qw/opaque int double/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldString' => [qw/opaque int string/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldIntegerList' => [qw/opaque int int int[]/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldInteger64List' => [qw/opaque int int sint64[]/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldDoubleList' => [qw/opaque int int double[]/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldStringList' => [qw/opaque int opaque/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldRaw' => [qw/opaque int opaque/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldBinary' => [qw/opaque int int pointer/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldDateTime' => [qw/opaque int int int int int int int int/] => 'void');};
eval{$ffi->attach('OGR_F_SetFieldDateTimeEx' => [qw/opaque int int int int int int float int/] => 'void');};
eval{$ffi->attach('OGR_F_GetGeomFieldCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_F_GetGeomFieldDefnRef' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_F_GetGeomFieldIndex' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_F_GetGeomFieldRef' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_F_SetGeomFieldDirectly' => [qw/opaque int opaque/] => 'int');};
eval{$ffi->attach('OGR_F_SetGeomField' => [qw/opaque int opaque/] => 'int');};
eval{$ffi->attach('OGR_F_GetFID' => [qw/opaque/] => 'sint64');};
eval{$ffi->attach('OGR_F_SetFID' => [qw/opaque sint64/] => 'int');};
eval{$ffi->attach('OGR_F_DumpReadable' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_F_SetFrom' => [qw/opaque opaque int/] => 'int');};
eval{$ffi->attach('OGR_F_SetFromWithMap' => [qw/opaque opaque int int*/] => 'int');};
eval{$ffi->attach('OGR_F_GetStyleString' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_F_SetStyleString' => [qw/opaque string/] => 'void');};
eval{$ffi->attach('OGR_F_SetStyleStringDirectly' => [qw/opaque string/] => 'void');};
eval{$ffi->attach('OGR_F_GetStyleTable' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_F_SetStyleTableDirectly' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_F_SetStyleTable' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_F_GetNativeData' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_F_SetNativeData' => [qw/opaque string/] => 'void');};
eval{$ffi->attach('OGR_F_GetNativeMediaType' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_F_SetNativeMediaType' => [qw/opaque string/] => 'void');};
eval{$ffi->attach('OGR_F_FillUnsetWithDefault' => [qw/opaque int string_pointer/] => 'void');};
eval{$ffi->attach('OGR_F_Validate' => [qw/opaque int int/] => 'int');};
eval{$ffi->attach('OGR_L_GetName' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_L_GetGeomType' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_L_GetSpatialFilter' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_L_SetSpatialFilter' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_L_SetSpatialFilterRect' => [qw/opaque double double double double/] => 'void');};
eval{$ffi->attach('OGR_L_SetSpatialFilterEx' => [qw/opaque int opaque/] => 'void');};
eval{$ffi->attach('OGR_L_SetSpatialFilterRectEx' => [qw/opaque int double double double double/] => 'void');};
eval{$ffi->attach('OGR_L_SetAttributeFilter' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_L_ResetReading' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_L_GetNextFeature' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_L_SetNextByIndex' => [qw/opaque sint64/] => 'int');};
eval{$ffi->attach('OGR_L_GetFeature' => [qw/opaque sint64/] => 'opaque');};
eval{$ffi->attach('OGR_L_SetFeature' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_L_CreateFeature' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_L_DeleteFeature' => [qw/opaque sint64/] => 'int');};
eval{$ffi->attach('OGR_L_GetLayerDefn' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_L_GetSpatialRef' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_L_FindFieldIndex' => [qw/opaque string int/] => 'int');};
eval{$ffi->attach('OGR_L_GetFeatureCount' => [qw/opaque int/] => 'sint64');};
eval{$ffi->attach('OGR_L_GetExtent' => [qw/opaque double[4] int/] => 'int');};
eval{$ffi->attach('OGR_L_GetExtentEx' => [qw/opaque int double[4] int/] => 'int');};
eval{$ffi->attach('OGR_L_TestCapability' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_L_CreateField' => [qw/opaque opaque int/] => 'int');};
eval{$ffi->attach('OGR_L_CreateGeomField' => [qw/opaque opaque int/] => 'int');};
eval{$ffi->attach('OGR_L_DeleteField' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_L_ReorderFields' => [qw/opaque int*/] => 'int');};
eval{$ffi->attach('OGR_L_ReorderField' => [qw/opaque int int/] => 'int');};
eval{$ffi->attach('OGR_L_AlterFieldDefn' => [qw/opaque int opaque int/] => 'int');};
eval{$ffi->attach('OGR_L_StartTransaction' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_L_CommitTransaction' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_L_RollbackTransaction' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_L_Reference' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_L_Dereference' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_L_GetRefCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_L_SyncToDisk' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_L_GetFeaturesRead' => [qw/opaque/] => 'sint64');};
eval{$ffi->attach('OGR_L_GetFIDColumn' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_L_GetGeometryColumn' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_L_GetStyleTable' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_L_SetStyleTableDirectly' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_L_SetStyleTable' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_L_SetIgnoredFields' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_L_Intersection' => [qw/opaque opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('OGR_L_Union' => [qw/opaque opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('OGR_L_SymDifference' => [qw/opaque opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('OGR_L_Identity' => [qw/opaque opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('OGR_L_Update' => [qw/opaque opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('OGR_L_Clip' => [qw/opaque opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('OGR_L_Erase' => [qw/opaque opaque opaque string_pointer GDALProgressFunc opaque/] => 'int');};
eval{$ffi->attach('OGR_DS_Destroy' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_DS_GetName' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_DS_GetLayerCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_DS_GetLayer' => [qw/opaque int/] => 'opaque');};
eval{$ffi->attach('OGR_DS_GetLayerByName' => [qw/opaque string/] => 'opaque');};
eval{$ffi->attach('OGR_DS_DeleteLayer' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OGR_DS_GetDriver' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_DS_CreateLayer' => ['opaque','string','opaque','unsigned int','opaque'] => 'opaque');};
eval{$ffi->attach('OGR_DS_CopyLayer' => [qw/opaque opaque string opaque/] => 'opaque');};
eval{$ffi->attach('OGR_DS_TestCapability' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_DS_ExecuteSQL' => [qw/opaque string opaque string/] => 'opaque');};
eval{$ffi->attach('OGR_DS_ReleaseResultSet' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_DS_Reference' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_DS_Dereference' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_DS_GetRefCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_DS_GetSummaryRefCount' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_DS_SyncToDisk' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGR_DS_GetStyleTable' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_DS_SetStyleTableDirectly' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_DS_SetStyleTable' => [qw/opaque opaque/] => 'void');};
eval{$ffi->attach('OGR_Dr_GetName' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_Dr_Open' => [qw/opaque string int/] => 'opaque');};
eval{$ffi->attach('OGR_Dr_TestCapability' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_Dr_CreateDataSource' => [qw/opaque string string_pointer/] => 'opaque');};
eval{$ffi->attach('OGR_Dr_CopyDataSource' => [qw/opaque opaque string string_pointer/] => 'opaque');};
eval{$ffi->attach('OGR_Dr_DeleteDataSource' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGROpen' => [qw/string int uint64*/] => 'opaque');};
eval{$ffi->attach('OGROpenShared' => [qw/string int uint64*/] => 'opaque');};
eval{$ffi->attach('OGRReleaseDataSource' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OGRRegisterDriver' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGRDeregisterDriver' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGRGetDriverCount' => [] => 'int');};
eval{$ffi->attach('OGRGetDriver' => [qw/int/] => 'opaque');};
eval{$ffi->attach('OGRGetDriverByName' => [qw/string/] => 'opaque');};
eval{$ffi->attach('OGRGetOpenDSCount' => [] => 'int');};
eval{$ffi->attach('OGRGetOpenDS' => [qw/int/] => 'opaque');};
eval{$ffi->attach('OGRRegisterAll' => [] => 'void');};
eval{$ffi->attach('OGRCleanupAll' => [] => 'void');};
eval{$ffi->attach('OGR_SM_Create' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OGR_SM_Destroy' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_SM_InitFromFeature' => [qw/opaque opaque/] => 'string');};
eval{$ffi->attach('OGR_SM_InitStyleString' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_SM_GetPartCount' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_SM_GetPart' => [qw/opaque int string/] => 'opaque');};
eval{$ffi->attach('OGR_SM_AddPart' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OGR_SM_AddStyle' => [qw/opaque string string/] => 'int');};
eval{$ffi->attach('OGR_ST_Create' => ['unsigned int'] => 'opaque');};
eval{$ffi->attach('OGR_ST_Destroy' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_ST_GetType' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_ST_GetUnit' => [qw/opaque/] => 'unsigned int');};
eval{$ffi->attach('OGR_ST_SetUnit' => ['opaque','unsigned int','double'] => 'void');};
eval{$ffi->attach('OGR_ST_GetParamStr' => [qw/opaque int int*/] => 'string');};
eval{$ffi->attach('OGR_ST_GetParamNum' => [qw/opaque int int*/] => 'int');};
eval{$ffi->attach('OGR_ST_GetParamDbl' => [qw/opaque int int*/] => 'double');};
eval{$ffi->attach('OGR_ST_SetParamStr' => [qw/opaque int string/] => 'void');};
eval{$ffi->attach('OGR_ST_SetParamNum' => [qw/opaque int int/] => 'void');};
eval{$ffi->attach('OGR_ST_SetParamDbl' => [qw/opaque int double/] => 'void');};
eval{$ffi->attach('OGR_ST_GetStyleString' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_ST_GetRGBFromString' => [qw/opaque string int* int* int* int*/] => 'int');};
eval{$ffi->attach('OGR_STBL_Create' => [] => 'opaque');};
eval{$ffi->attach('OGR_STBL_Destroy' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_STBL_AddStyle' => [qw/opaque string string/] => 'int');};
eval{$ffi->attach('OGR_STBL_SaveStyleTable' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_STBL_LoadStyleTable' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OGR_STBL_Find' => [qw/opaque string/] => 'string');};
eval{$ffi->attach('OGR_STBL_ResetStyleStringReading' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OGR_STBL_GetNextStyle' => [qw/opaque/] => 'string');};
eval{$ffi->attach('OGR_STBL_GetLastStyleName' => [qw/opaque/] => 'string');};
# from /home/ajolma/github/gdal/gdal/ogr/ogr_srs_api.h
eval{$ffi->attach('OSRAxisEnumToName' => ['unsigned int'] => 'string');};
eval{$ffi->attach('OSRNewSpatialReference' => [qw/string/] => 'opaque');};
eval{$ffi->attach('OSRCloneGeogCS' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OSRClone' => [qw/opaque/] => 'opaque');};
eval{$ffi->attach('OSRDestroySpatialReference' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OSRReference' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRDereference' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRRelease' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OSRValidate' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRFixupOrdering' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRFixup' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRStripCTParms' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRImportFromEPSG' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OSRImportFromEPSGA' => [qw/opaque int/] => 'int');};
eval{$ffi->attach('OSRImportFromWkt' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OSRImportFromProj4' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRImportFromESRI' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OSRImportFromPCI' => [qw/opaque string string double*/] => 'int');};
eval{$ffi->attach('OSRImportFromUSGS' => [qw/opaque long long double* long/] => 'int');};
eval{$ffi->attach('OSRImportFromXML' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRImportFromDict' => [qw/opaque string string/] => 'int');};
eval{$ffi->attach('OSRImportFromPanorama' => [qw/opaque long long long double*/] => 'int');};
eval{$ffi->attach('OSRImportFromOzi' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OSRImportFromMICoordSys' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRImportFromERM' => [qw/opaque string string string/] => 'int');};
eval{$ffi->attach('OSRImportFromUrl' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRExportToWkt' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OSRExportToPrettyWkt' => [qw/opaque string_pointer int/] => 'int');};
eval{$ffi->attach('OSRExportToProj4' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OSRExportToPCI' => [qw/opaque string_pointer string_pointer double*/] => 'int');};
eval{$ffi->attach('OSRExportToUSGS' => [qw/opaque long* long* double* long*/] => 'int');};
eval{$ffi->attach('OSRExportToXML' => [qw/opaque string_pointer string/] => 'int');};
eval{$ffi->attach('OSRExportToPanorama' => [qw/opaque long* long* long* long* double*/] => 'int');};
eval{$ffi->attach('OSRExportToMICoordSys' => [qw/opaque string_pointer/] => 'int');};
eval{$ffi->attach('OSRExportToERM' => [qw/opaque string string string/] => 'int');};
eval{$ffi->attach('OSRMorphToESRI' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRMorphFromESRI' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRConvertToOtherProjection' => [qw/opaque string string_pointer/] => 'opaque');};
eval{$ffi->attach('OSRSetAttrValue' => [qw/opaque string string/] => 'int');};
eval{$ffi->attach('OSRGetAttrValue' => [qw/opaque string int/] => 'string');};
eval{$ffi->attach('OSRSetAngularUnits' => [qw/opaque string double/] => 'int');};
eval{$ffi->attach('OSRGetAngularUnits' => [qw/opaque string_pointer/] => 'double');};
eval{$ffi->attach('OSRSetLinearUnits' => [qw/opaque string double/] => 'int');};
eval{$ffi->attach('OSRSetTargetLinearUnits' => [qw/opaque string string double/] => 'int');};
eval{$ffi->attach('OSRSetLinearUnitsAndUpdateParameters' => [qw/opaque string double/] => 'int');};
eval{$ffi->attach('OSRGetLinearUnits' => [qw/opaque string_pointer/] => 'double');};
eval{$ffi->attach('OSRGetTargetLinearUnits' => [qw/opaque string string_pointer/] => 'double');};
eval{$ffi->attach('OSRGetPrimeMeridian' => [qw/opaque string_pointer/] => 'double');};
eval{$ffi->attach('OSRIsGeographic' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRIsLocal' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRIsProjected' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRIsCompound' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRIsGeocentric' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRIsVertical' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRIsSameGeogCS' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OSRIsSameVertCS' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OSRIsSame' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OSRSetLocalCS' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRSetProjCS' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRSetGeocCS' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRSetWellKnownGeogCS' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRSetFromUserInput' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRCopyGeogCSFrom' => [qw/opaque opaque/] => 'int');};
eval{$ffi->attach('OSRSetTOWGS84' => [qw/opaque double double double double double double double/] => 'int');};
eval{$ffi->attach('OSRGetTOWGS84' => [qw/opaque double* int/] => 'int');};
eval{$ffi->attach('OSRSetCompoundCS' => [qw/opaque string opaque opaque/] => 'int');};
eval{$ffi->attach('OSRSetGeogCS' => [qw/opaque string string string double double string double string double/] => 'int');};
eval{$ffi->attach('OSRSetVertCS' => [qw/opaque string string int/] => 'int');};
eval{$ffi->attach('OSRGetSemiMajor' => [qw/opaque int*/] => 'double');};
eval{$ffi->attach('OSRGetSemiMinor' => [qw/opaque int*/] => 'double');};
eval{$ffi->attach('OSRGetInvFlattening' => [qw/opaque int*/] => 'double');};
eval{$ffi->attach('OSRSetAuthority' => [qw/opaque string string int/] => 'int');};
eval{$ffi->attach('OSRGetAuthorityCode' => [qw/opaque string/] => 'string');};
eval{$ffi->attach('OSRGetAuthorityName' => [qw/opaque string/] => 'string');};
eval{$ffi->attach('OSRSetProjection' => [qw/opaque string/] => 'int');};
eval{$ffi->attach('OSRSetProjParm' => [qw/opaque string double/] => 'int');};
eval{$ffi->attach('OSRGetProjParm' => [qw/opaque string double int*/] => 'double');};
eval{$ffi->attach('OSRSetNormProjParm' => [qw/opaque string double/] => 'int');};
eval{$ffi->attach('OSRGetNormProjParm' => [qw/opaque string double int*/] => 'double');};
eval{$ffi->attach('OSRSetUTM' => [qw/opaque int int/] => 'int');};
eval{$ffi->attach('OSRGetUTMZone' => [qw/opaque int*/] => 'int');};
eval{$ffi->attach('OSRSetStatePlane' => [qw/opaque int int/] => 'int');};
eval{$ffi->attach('OSRSetStatePlaneWithUnits' => [qw/opaque int int string double/] => 'int');};
eval{$ffi->attach('OSRAutoIdentifyEPSG' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRFindMatches' => [qw/opaque string_pointer int* int*/] => 'uint64*');};
eval{$ffi->attach('OSRFreeSRSArray' => [qw/uint64*/] => 'void');};
eval{$ffi->attach('OSREPSGTreatsAsLatLong' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSREPSGTreatsAsNorthingEasting' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRGetAxis' => ['opaque','string','int','unsigned int'] => 'string');};
eval{$ffi->attach('OSRSetAxes' => ['opaque','string','string','unsigned int','string','unsigned int'] => 'int');};
eval{$ffi->attach('OSRSetACEA' => [qw/opaque double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetAE' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetBonne' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetCEA' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetCS' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetEC' => [qw/opaque double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetEckert' => [qw/opaque int double double double/] => 'int');};
eval{$ffi->attach('OSRSetEckertIV' => [qw/opaque double double double/] => 'int');};
eval{$ffi->attach('OSRSetEckertVI' => [qw/opaque double double double/] => 'int');};
eval{$ffi->attach('OSRSetEquirectangular' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetEquirectangular2' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetGS' => [qw/opaque double double double/] => 'int');};
eval{$ffi->attach('OSRSetGH' => [qw/opaque double double double/] => 'int');};
eval{$ffi->attach('OSRSetIGH' => [qw/opaque/] => 'int');};
eval{$ffi->attach('OSRSetGEOS' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetGaussSchreiberTMercator' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetGnomonic' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetHOM' => [qw/opaque double double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetHOMAC' => [qw/opaque double double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetHOM2PNO' => [qw/opaque double double double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetIWMPolyconic' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetKrovak' => [qw/opaque double double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetLAEA' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetLCC' => [qw/opaque double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetLCC1SP' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetLCCB' => [qw/opaque double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetMC' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetMercator' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetMercator2SP' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetMollweide' => [qw/opaque double double double/] => 'int');};
eval{$ffi->attach('OSRSetNZMG' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetOS' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetOrthographic' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetPolyconic' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetPS' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetRobinson' => [qw/opaque double double double/] => 'int');};
eval{$ffi->attach('OSRSetSinusoidal' => [qw/opaque double double double/] => 'int');};
eval{$ffi->attach('OSRSetStereographic' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetSOC' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetTM' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetTMVariant' => [qw/opaque string double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetTMG' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRSetTMSO' => [qw/opaque double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetTPED' => [qw/opaque double double double double double double/] => 'int');};
eval{$ffi->attach('OSRSetVDG' => [qw/opaque double double double/] => 'int');};
eval{$ffi->attach('OSRSetWagner' => [qw/opaque int double double double/] => 'int');};
eval{$ffi->attach('OSRSetQSC' => [qw/opaque double double/] => 'int');};
eval{$ffi->attach('OSRSetSCH' => [qw/opaque double double double double/] => 'int');};
eval{$ffi->attach('OSRCalcInvFlattening' => [qw/double double/] => 'double');};
eval{$ffi->attach('OSRCalcSemiMinorFromInvFlattening' => [qw/double double/] => 'double');};
eval{$ffi->attach('OSRCleanup' => [] => 'void');};
eval{$ffi->attach('OCTNewCoordinateTransformation' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('OCTDestroyCoordinateTransformation' => [qw/opaque/] => 'void');};
eval{$ffi->attach('OCTTransform' => [qw/opaque int double* double* double*/] => 'int');};
eval{$ffi->attach('OCTTransformEx' => [qw/opaque int double* double* double* int*/] => 'int');};
eval{$ffi->attach('OCTProj4Normalize' => [qw/string/] => 'string');};
eval{$ffi->attach('OCTCleanupProjMutex' => [] => 'void');};
eval{$ffi->attach('OPTGetProjectionMethods' => [] => 'string_pointer');};
eval{$ffi->attach('OPTGetParameterList' => [qw/string string_pointer/] => 'string_pointer');};
eval{$ffi->attach('OPTGetParameterInfo' => [qw/string string string_pointer string_pointer double*/] => 'int');};
# from /home/ajolma/github/gdal/gdal/apps/gdal_utils.h
eval{$ffi->attach('GDALInfoOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALInfoOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALInfo' => [qw/opaque opaque/] => 'string');};
eval{$ffi->attach('GDALTranslateOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALTranslateOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALTranslateOptionsSetProgress' => [qw/opaque GDALProgressFunc opaque/] => 'void');};
eval{$ffi->attach('GDALTranslate' => [qw/string opaque opaque int*/] => 'opaque');};
eval{$ffi->attach('GDALWarpAppOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALWarpAppOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALWarpAppOptionsSetProgress' => [qw/opaque GDALProgressFunc opaque/] => 'void');};
eval{$ffi->attach('GDALWarpAppOptionsSetWarpOption' => [qw/opaque string string/] => 'void');};
eval{$ffi->attach('GDALWarp' => [qw/string opaque int uint64* opaque int*/] => 'opaque');};
eval{$ffi->attach('GDALVectorTranslateOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALVectorTranslateOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALVectorTranslateOptionsSetProgress' => [qw/opaque GDALProgressFunc opaque/] => 'void');};
eval{$ffi->attach('GDALVectorTranslate' => [qw/string opaque int uint64* opaque int*/] => 'opaque');};
eval{$ffi->attach('GDALDEMProcessingOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALDEMProcessingOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALDEMProcessingOptionsSetProgress' => [qw/opaque GDALProgressFunc opaque/] => 'void');};
eval{$ffi->attach('GDALDEMProcessing' => [qw/string opaque string string opaque int*/] => 'opaque');};
eval{$ffi->attach('GDALNearblackOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALNearblackOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALNearblackOptionsSetProgress' => [qw/opaque GDALProgressFunc opaque/] => 'void');};
eval{$ffi->attach('GDALNearblack' => [qw/string opaque opaque opaque int*/] => 'opaque');};
eval{$ffi->attach('GDALGridOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALGridOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALGridOptionsSetProgress' => [qw/opaque GDALProgressFunc opaque/] => 'void');};
eval{$ffi->attach('GDALGrid' => [qw/string opaque opaque int*/] => 'opaque');};
eval{$ffi->attach('GDALRasterizeOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALRasterizeOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALRasterizeOptionsSetProgress' => [qw/opaque GDALProgressFunc opaque/] => 'void');};
eval{$ffi->attach('GDALRasterize' => [qw/string opaque opaque opaque int*/] => 'opaque');};
eval{$ffi->attach('GDALBuildVRTOptionsNew' => [qw/opaque opaque/] => 'opaque');};
eval{$ffi->attach('GDALBuildVRTOptionsFree' => [qw/opaque/] => 'void');};
eval{$ffi->attach('GDALBuildVRTOptionsSetProgress' => [qw/opaque GDALProgressFunc opaque/] => 'void');};
eval{$ffi->attach('GDALBuildVRT' => [qw/string int uint64* opaque opaque int*/] => 'opaque');};

    # we do not use Alien::gdal->data_dir since it issues warnings due to GDAL bug
    my $pc = PkgConfig->find('gdal');
    if ($pc->errmsg) {
        my $dir = Alien::gdal->dist_dir;
        my %options = (search_path_override => [$dir . '/lib/pkgconfig']);
        $pc = PkgConfig->find('gdal', %options);
    }
    if ($pc->errmsg) {
        warn $pc->errmsg;
    } else {
        my $dir = $pc->get_var('datadir');
        # this gdal.pc bug was fixed in GDAL 2.3.1
        # we just hope the one configuring GDAL did not change it to something that ends '/data'
        $dir =~ s/\/data$//;
        CPLSetConfigOption(GDAL_DATA => $dir);
    }

    my $self = {};
    $self->{ffi} = $ffi;
    $self->{CPLErrorHandler} = $ffi->closure(
        sub {
            my ($err, $err_num, $msg) = @_;
            push @errors, $msg;
        });
    CPLPushErrorHandler($self->{CPLErrorHandler});
    GDALAllRegister();
    return bless $self, $class;
}

sub GetVersionInfo {
    shift;
    return GDALVersionInfo(@_);
}

sub GetDriver {
    my ($self, $i) = @_;
    my $d = isint($i) ? GDALGetDriver($i) : GDALGetDriverByName($i);
    return bless \$d, 'Geo::GDAL::FFI::Driver';
}

sub GetDrivers {
    my $self = shift;
    my @drivers;
    for my $i (0..GDALGetDriverCount()-1) {
        push @drivers, $self->GetDriver($i);
    }
    return @drivers;
}

sub Open {
    shift;
    my ($name, $args) = @_;
    $name //= '';
    $args //= {};
    my $flags = 0;
    my $a = $args->{Flags} // [];
    for my $f (@$a) {
        $flags |= $open_flags{$f};
    }
    my $drivers = 0;
    for my $o (@{$args->{AllowedDrivers}}) {
        $drivers = Geo::GDAL::FFI::CSLAddString($drivers, $o);
    }
    my $options = 0;
    for my $o (@{$args->{Options}}) {
        $options = Geo::GDAL::FFI::CSLAddString($options, $o);
    }
    my $files = 0;
    for my $o (@{$args->{SiblingFiles}}) {
        $files = Geo::GDAL::FFI::CSLAddString($files, $o);
    }
    my $ds = GDALOpenEx($name, $flags, $drivers, $options, $files);
    if (@errors) {
        my $msg = join("\n", @errors);
        @errors = ();
        confess $msg;
    }
    unless ($ds) { # no VERBOSE_ERROR in options and fail
        confess "Open failed for '$name'. Hint: add VERBOSE_ERROR to open_flags.";
    }
    return bless \$ds, 'Geo::GDAL::FFI::Dataset';
}

sub write {
    print STDOUT $_[0];
}

sub close {
}

sub SetWriter {
    my ($self, $writer) = @_;
    $writer = $self unless $writer;
    my $w = $writer->can('write');
    my $c = $writer->can('close');
    confess "$writer must be able to write and close." unless $w && $c;
    #$self->{write} = $w;
    $self->{close} = $c;
    $self->{writer} = $self->{ffi}->closure(sub {
        my ($buf, $size, $count, $stream) = @_;
        $w->(buffer_to_scalar($buf, $size*$count));
    });
    VSIStdoutSetRedirection($self->{writer}, 0);
}

sub CloseWriter {
    my $self = shift;
    $self->{close}->() if $self->{close};
    $self->SetWriter;
}

sub get_importer {
    my ($self, $format) = @_;
    my $importer = $self->can('OSRImportFrom' . $format);
    confess "Spatial reference importer for format '$format' not found!" unless $importer;
    return $importer;
}

sub get_exporter {
    my ($self, $format) = @_;
    my $exporter = $self->can('OSRExportTo' . $format);
    confess "Spatial reference exporter for format '$format' not found!" unless $exporter;
    return $exporter;
}

sub get_setter {
    my ($self, $proj) = @_;
    my $setter = $self->can('OSRSet' . $proj);
    confess "Parameter setter for projection '$proj' not found!" unless $setter;
    return $setter;
}

sub HaveGEOS {
    my $t = $geometry_types{Point};
    my $g = OGR_G_CreateGeometry($t);
    OGR_G_SetPoint($g, 0, 0, 0, 0);
    my $c = OGR_G_CreateGeometry($t);
    my $n = @errors;
    OGR_G_Centroid($g, $c);
    if (@errors > $n) {
        pop @errors;
        return undef;
    } else {
        return 1;
    }
}

sub SetConfigOption {
    my ($self, $key, $default) = @_;
    CPLSetConfigOption($key, $default);
}

sub GetConfigOption {
    my ($self, $key, $default) = @_;
    return CPLGetConfigOption($key, $default);
}

sub FindFile {
    my $self = shift;
    my ($class, $basename) = @_ == 2 ? @_ : ('', @_);
    $class //= '';
    $basename //= '';
    return CPLFindFile($class, $basename);
}

sub PushFinderLocation {
    my ($self, $location) = @_;
    $location //= '';
    CPLPushFinderLocation($location);
}

sub PopFinderLocation {
    CPLPopFinderLocation();
}

sub FinderClean {
    CPLFinderClean();
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI - A foreign function interface to GDAL

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

This is an example of creating a vector dataset.

 use Geo::GDAL::FFI;
 my $gdal = Geo::GDAL::FFI->new();

 my $sr = Geo::GDAL::FFI::SpatialReference->new(EPSG => 3067);
 my $layer = $gdal
     ->GetDriver('ESRI Shapefile')
     ->Create('test.shp')
     ->CreateLayer({
         Name => 'test',
         SpatialReference => $sr,
         GeometryType => 'Point',
         Fields => [
         {
             Name => 'name',
             Type => 'String'
         }
         ]
     });
 my $f = Geo::GDAL::FFI::Feature->new($layer->Defn);
 $f->SetField(name => 'a');
 my $g = Geo::GDAL::FFI::Geometry->new('Point');
 $g->SetPoint(1, 2);
 $f->SetGeomField($g);
 $layer->CreateFeature($f);

This is an example of reading a vector dataset.

 use Geo::GDAL::FFI;
 my $gdal = Geo::GDAL::FFI->new();

 my $layer = $gdal->Open('test.shp')->GetLayer;
 $layer->ResetReading;
 while (my $feature = $layer->GetNextFeature) {
     my $value = $feature->GetField('name');
     my $geom = $feature->GetGeomField;
     say $value, ' ', $geom->AsText;
 }

This is an example of creating a raster dataset.

 use Geo::GDAL::FFI;
 my $gdal = Geo::GDAL::FFI->new();

 my $tiff = $gdal->GetDriver('GTiff')->Create('test.tiff', 3, 2);
 my $ogc_wkt = 
        'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS84",6378137,298.257223563,'.
        'AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,'.
        'AUTHORITY["EPSG","8901"]],UNIT["degree",0.01745329251994328,'.
        'AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]]';
 $tiff->SetProjectionString($ogc_wkt);
 my $transform = [10,2,0,20,0,3];
 $tiff->SetGeoTransform($transform);
 my $data = [[0,1,2],[3,4,5]];
 $tiff->GetBand->Write($data);

This is an example of reading a raster dataset. Note that using L<PDL>
and L<MCE::Shared> can greatly reduce the time needed to process large
raster datasets.

 use Geo::GDAL::FFI;
 my $gdal = Geo::GDAL::FFI->new();

 my $band = $gdal->Open($ARGV[0])->GetBand;
 my ($w_band, $h_band) = $band->GetSize;
 my ($w_block, $h_block) = $band->GetBlockSize;
 my $nodata = $band->GetNoDataValue;
 my ($xoff, $yoff) = (0,0);
 my ($min, $max);

 while (1) {
     if ($xoff >= $w_band) {
         $xoff = 0;
         $yoff += $h_block;
         last if $yoff >= $h_band;
     }
     my $w_real = $w_band - $xoff;
     $w_real = $w_block if $w_real > $w_block;
     my $h_real = $h_band - $yoff;
     $h_real = $h_block if $h_real > $h_block;

     my $data = $band->Read($xoff, $yoff, $w_real, $h_real);

     for my $y (0..$#$data) {
         my $row = $data->[$y];
         for my $x (0..$#$row) {
             my $value = $row->[$x];
             next if defined $nodata && $value == $nodata;
             $min = $value if !defined $min || $value < $min;
             $max = $value if !defined $max || $value > $max;
         }
     }
     
     $xoff += $w_block;
 }

 say "min = $min, max = $max";

=head1 DESCRIPTION

This is a foreign function interface to the GDAL geospatial data
access library.

=head1 METHODS

The progress function argument used in many methods should be a
reference to a subroutine. The subroutine is called with three
arguments C<($fraction, $msg, $data)>, where C<$fraction> is a number,
C<$msg> is a string, and C<$data> is a pointer that is given as the
progress data argument.

=head2 new

 my $gdal = Geo::GDAL::FFI->new;

Create a new Geo::GDAL::FFI object. All GDAL functions that are
available (the C API is used) are attached to this class. The other
classes in this distribution are there to provide an easier to use
object oriented Perl API.

=head2 Capabilities

 my @caps = $gdal->Capabilities;

Returns the list of capabilities (strings) a GDAL major object
(Driver, Dataset, Band, or Layer in Geo::GDAL::FFI) can have.

=head2 OpenFlags

 my @flags = $gdal->OpenFlags;

Returns the list of opening flags to be used in the Open method.

=head2 DataTypes

 my @types = $gdal->DataTypes;

Returns the list of raster cell data types to be used in e.g. the
CreateDataset method of the Driver class.

=head2 FieldTypes

 my @types = $gdal->FieldTypes;

Returns the list of field types.

=head2 FieldSubtypes

 my @types = $gdal->FieldSubTypes;

Returns the list of field subtypes.

=head2 Justifications

 my @justifications = $gdal->Justifications;

Returns the list of field justifications.

=head2 ColorInterpretations

 my @interpretations = $gdal->ColorInterpretations;

Returns the list of color interpretations.

=head2 GeometryTypes

 my @types = $gdal->GeometryTypes;

Returns the list of geometry types.

=head2 GetVersionInfo

 my $info = $gdal->GetVersionInfo;

Returns the version information from the underlying GDAL library.

=head2 GetDrivers

 my @drivers = $gdal->GetDrivers;

Returns a list of all available driver objects.

=head2 GetDriver

 my @driver = $gdal->GetDriver($name);

Returns the specific driver object.

=head2 Open

 my $dataset = $gdal->Open($name, {Flags => [qw/READONLY/], ...});

Open a dataset. $name is the name of the dataset. Named arguments are
the following.

=over 4

=item C<Flags>

Optional, default is a reference to an empty array. Note that some
drivers can open both raster and vector datasets.

=item C<AllowedDrivers>

Optional, default is all drivers. Use a reference to an array of
driver names to limit which drivers to test.

=item C<SiblingFiles>

Optional, default is to probe the file system. You may use a reference
to an array of auxiliary file names.

=item C<Options>

Optional, a reference to an array of driver specific open
options. Consult the main GDAL documentation for open options.

=back

=head1 LICENSE

This software is released under the Artistic License. See
L<perlartistic>.

=head1 AUTHOR

Ari Jolma - Ari.Jolma at gmail.com

=head1 SEE ALSO

L<Geo::GDAL::FFI::Object>

L<Geo::GDAL::FFI::Driver>

L<Geo::GDAL::FFI::SpatialReference>

L<Geo::GDAL::FFI::Dataset>

L<Geo::GDAL::FFI::Band>

L<Geo::GDAL::FFI::FeatureDefn>

L<Geo::GDAL::FFI::FieldDefn>

L<Geo::GDAL::FFI::GeomFieldDefn>

L<Geo::GDAL::FFI::Layer>

L<Geo::GDAL::FFI::Feature>

L<Geo::GDAL::FFI::Geometry>

L<Alien::gdal>, L<FFI::Platypus>, L<http://www.gdal.org>

=cut

__END__;
