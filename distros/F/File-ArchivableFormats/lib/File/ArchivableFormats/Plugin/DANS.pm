package File::ArchivableFormats::Plugin::DANS;
our $VERSION = '1.3';
use Moose;

# ABSTRACT: DANS module for archivable formats

with 'File::ArchivableFormats::Plugin';

has '+name' => (default => 'DANS');

sub _build_prefered_formats {
    my $self = shift;

    my %prefered = (
        '.7bdat' => {
            allowed_extensions => ['.7bdat'],
            types              => ['Statistical data (SAS)']
        },
        'audio/x-aac' => {
            allowed_extensions => ['.aac'],
            types              => ['Audio (AAC)']
        },
        'model/vnd.collada+xml' => {
            allowed_extensions => ['.dae'],
            types              => ['3D (COLLADA)']
        },
        '.dta' => {
            allowed_extensions => ['.dta'],
            types              => ['Statistical data (STATA)']
        },
        'image/vnd.dwg' => {
            allowed_extensions => ['.dwg'],
            types => ['Computer Aided Design (CAD) (AutoCAD, other versions)']
        },
        'image/vnd.dxf' => {
            allowed_extensions => ['.dxf'],
            types              => [
                'Computer Aided Design (CAD) (AutoCAD DXF v. R12)',
                'Computer Aided Design (CAD) (AutoCAD, other versions)'
            ]
        },
        '.fbx' => {
            allowed_extensions => ['.fbx'],
            types              => ['3D (Autodesk FBX)']
        },
        'application/x-gml+xml' => {
            allowed_extensions => ['.gml'],
            types              => ['Geographical Information (GIS) (GML)']
        },
        '.grd' => {
            allowed_extensions => ['.grd '],
            types              => ['Raspter GIS (ESRI GRID)']
        },
        'application/x-hdf' => {
            allowed_extensions => ['.h5', '.hdf5', '.he5'],
            types              => ['HDF5']
        },
        'application/x-tgifapplication/x-tgif' => {
            allowed_extensions => ['.obj'],
            types              => ['3D (WaveFront Object)']
        },
        'application/x-spss-por' => {
            allowed_extensions => ['.por'],
            types              => ['Statistical data (SPSS Portable)']
        },
        'application/x-spss' => {
            allowed_extensions => ['.sav'],
            types              => ['Statistical data (SPSS)']
        },
        'text/x-sgml' => {
            allowed_extensions => ['.sgml'],
            types              => ['Markup language (SGML)']
        },
        'application/x-qgis' => {
            allowed_extensions => ['.shp'],
            types => ['Geographical Information (GIS) (ESRI Shapefiles)']
        },
        '.siard' => {
            allowed_extensions => ['.siard'],
            types              => ['Databases (SIARD)']
        },
        '.tab' => {
            allowed_extensions => ['.tab '],
            types              => ['Geographical Information (GIS) (MapInfo)']
        },
        '.tfw' => {
            allowed_extensions => ['.tfw '],
            types              => ['Images (geo reference) (TIFF World File)']
        },
        'application/vnd.trid.tpt' => {
            allowed_extensions => ['.tpt'],
            types              => ['Statistical data (SAS)']
        },
        'application/xslt+xml' => {
            allowed_extensions => ['.xslt'],
            types              => ['Markup language (Related files)']
        },
        'ATLAS.TI copy bundle' => {
            allowed_extensions => [],
            types              => [
                'Computer Assisted Qualitative Data Analysis (CAQDAS) (Application’s export formats)'
            ]
        },
        'NVIVO export project' => {
            allowed_extensions => [],
            types              => [
                'Computer Assisted Qualitative Data Analysis (CAQDAS) (Application’s export formats)'
            ]
        },
        'application/ecmascript' => {
            allowed_extensions => ['.es'],
            types              => ['Markup language (Related files)']
        },
        'application/javascript' => {
            allowed_extensions => ['.js'],
            types              => ['Markup language (Related files)']
        },
        'application/msword' => {
            allowed_extensions => ['.doc'],
            types              => ['Text documents (MS Word)']
        },
        'application/pdf' => {
            allowed_extensions => ['.pdf'],
            types              => [
                'Text documents (PDF/A)',
                'Text documents (PDF)',
                'Spreadsheets (PDF/A)'
            ]
        },
        'application/postscript' => {
            allowed_extensions => ['.ai', '.eps'],
            types =>
                ['Images (vector)  (Illustrator)', 'Images (vector)  (EPS)']
        },
        'application/rtf' => {
            allowed_extensions => ['.rtf'],
            types              => ['Text documents (RTF)']
        },
        'text/rtf' => {
            allowed_extensions => ['.rtf'],
            types              => ['Text documents (RTF)']
        },
        'application/vnd.google-earth.kml+xml' => {
            allowed_extensions => ['.kml'],
            types              => ['Geographical Information (GIS) (KML)']
        },
        'application/vnd.ms-excel' => {
            allowed_extensions => ['.xls'],
            types              => ['Spreadsheets (MS Excel)']
        },
        'application/vnd.ms-word.document.macroEnabled.12' => {
            allowed_extensions => ['.docm'],
            types              => ['Spreadsheets (OOXML)']
        },
        'application/vnd.oasis.opendocument.spreadsheet' => {
            allowed_extensions => ['.ods'],
            types              => ['Spreadsheets (ODS)']
        },
        'application/vnd.oasis.opendocument.text' => {
            allowed_extensions => ['.odt'],
            types              => ['Text documents (ODT)']
        },
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' =>
            {
            allowed_extensions => ['.xlsx'],
            types              => ['Spreadsheets (MS Excel)']
            },
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
            => {
            allowed_extensions => ['.docx'],
            types => ['Text documents (MS Word)', 'Spreadsheets (OOXML)']
            },
        'application/x-mif' => {
            allowed_extensions => ['.mif'],
            types              => ['Geographical Information (GIS) (MIF/MID)']
        },
        'application/vnd.mif' => {
            allowed_extensions => ['.mif'],
            types              => ['Geographical Information (GIS) (MIF/MID)']
        },
        'application/x-sql' => {
            allowed_extensions => ['.sql'],
            types              => ['Databases (SQL)']
        },
        'application/xhtml+xml' => {
            allowed_extensions => ['.xhtml'],
            types              => ['Markup language (HTML)']
        },
        'application/xml' => {
            allowed_extensions => ['.xml'],
            types => ['Markup language (XML)', 'Statistical data (DDI)']
        },
        'audio/flac' => {
            allowed_extensions => ['.flac'],
            types              => ['Audio (FLAC)']
        },
        'audio/midi' => {
            allowed_extensions => ['.mid'],
            types              => ['Geographical Information (GIS) (MIF/MID)']
        },
        'audio/mpeg' => {
            allowed_extensions => ['.mp3', '.m4a'],
            types              => ['Audio (MP3)', 'Audio (AAC)']
        },
        'audio/x-aiff' => {
            allowed_extensions => ['.aiff', '.aif'],
            types              => ['Audio (AIFF)', 'Audio (AIFF)']
        },
        'audio/x-sd2' => {
            allowed_extensions => ['.sd2'],
            types              => ['Statistical data (SAS)']
        },
        'audio/x-wav' => {
            allowed_extensions => ['.wav'],
            types              => ['Audio (WAVE; BWF)']
        },
        'by mutual agreement' => {
            allowed_extensions => ['.jp2', '.dcm'],
            types              => ['(.jp2) (DICOM (.dcm))']
        },
        'image/jpeg' => {
            allowed_extensions => ['.jpeg', '.jpg'],
            types => ['Raster Images (JPEG)', 'Raster Images (JPG)']
        },
        'image/png' => {
            allowed_extensions => ['.png'],
            types              => ['Raster Images (PNG)']
        },
        'image/svg+xml' => {
            allowed_extensions => ['.svg'],
            types              => ['Images (vector)  (SVG)']
        },
        'image/tiff' => {
            allowed_extensions => ['.tif', '.tiff'],
            types              => [
                'Raster Images (TIFF)',
                'Raster Images (TIFF)',
                'Images (geo reference) (GeoTIFF)',
                'Images (geo reference) (GeoTIFF)',
                'Images (geo reference) (TIFF World File)'
            ]
        },
        'model/x3d+xml' => {
            allowed_extensions => ['.x3d'],
            types              => ['3D (X3D)']
        },
        'related files' => {
            allowed_extensions => [],
            types              => [
                'Geographical Information (GIS) (ESRI Shapefiles)',
                'Raspter GIS (ESRI GRID)',
                'Geographical Information (GIS) (MapInfo)'
            ]
        },
        'text/css' => {
            allowed_extensions => ['.css'],
            types              => ['Markup language (Related files)']
        },
        'text/csv' => {
            allowed_extensions => ['.csv'],
            types => ['Spreadsheets (CSV)', 'Databases (DB tables)']
        },
        'text/html' => {
            allowed_extensions => ['.html'],
            types              => ['Markup language (HTML)']
        },
        'text/plain' => {
            allowed_extensions => ['.asc', '.txt'],
            types              => [
                'Plain text (Unicode)',
                'Plain text (Non-Unicode)',
                'Statistical data (data (.csv) + setup)',
                'Raspter GIS (ASCII GRID)',
                'Raspter GIS (ASCII GRID)'
            ]
        },
        'application/x-dbf' => {
            allowed_extensions => ['.dbf'],
            types              => ['dBase']
        },
        'video/mpeg' => {
            allowed_extensions => ['.mpg', '.mpeg'],
            types              => ['Video (MPEG-2)', 'Video (MPEG-2)']
        },
        'video/mp4' => {
            allowed_extensions => ['.mp4'],
            types              => ['MPEG-4'],
        },
        'video/quicktime' => {
            allowed_extensions => ['.mov'],
            types              => ['QuickTime']
        },
        'video/x-matroska' => {
            allowed_extensions => ['.mkv'],
            types              => ['MKV']
        },
        'video/x-msvideo' => {
            allowed_extensions => ['.avi'],
            types              => ['Lossless AVI']
        },
        # Unknown
        '.caqdas' => {
            allowed_extensions => ['.caqdas'],
            types              => [
                'Computer Assisted Qualitative Data Analysis (CAQDAS) (Application’s export formats)'
            ]
        }
    );
    return \%prefered;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ArchivableFormats::Plugin::DANS - DANS module for archivable formats

=head1 VERSION

version 1.3

=head1 SEE ALSO

=over

=item DANS list

The DANS list can be downloaded from L<https://dans.knaw.nl/en/deposit/information-about-depositing-data/DANSpreferredformatsUK.pdf>.

item L<File::LibMagic>

=item RDNL

An alternative to the DANS list is the L<http://researchdata.4tu.nl/fileadmin/editor_upload/File_formats/Preferred_formats.pdf> list.

You can view both lists via: L<http://datasupport.researchdata.nl/en/start-de-cursus/iii-onderzoeksfase/dataformaten/preferred-formats/>.

=back

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mintlab BV.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
