package METS::Parse::Simple;

use strict;
use warnings;

use Class::Utils qw(set_params);
use XML::Simple;

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	return $self;
}

# Parse XML data.
sub parse {
	my ($self, $mets_data) = @_;
	my $mets_hr = XMLin($mets_data);
	return $mets_hr;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

METS::Parse::Simple - Simple class for METS parsing.

=head1 SYNOPSIS

 use METS::Parse::Simple;

 my $obj = METS::Parse::Simple->new;
 my $mets_hr = $obj->parse($mets_data);

=head1 METHODS

=over 8

=item C<new()>

 Constructor.

=item C<parse($mets_data)>

 Parse METS XML data via XML::Simple::XMLin().
 Returns hash reference to structure.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use METS::Parse::Simple;
 use Perl6::Slurp qw(slurp);

 if (@ARGV < 1) {
         print STDERR "Usage: $0 mets_file\n";
         exit 1;
 }
 my $mets_file = $ARGV[0];

 # Get mets data.
 my $mets_data = slurp($mets_file);

 # Object.
 my $obj = METS::Parse::Simple->new;

 # Parse data.
 my $mets_hr = $obj->parse($mets_data);

 # Dump to output.
 p $mets_hr;

 # Output without argument like:
 # Usage: __SCRIPT__ mets_file

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Data::Printer;
 use METS::Parse::Simple;

 # Example METS data.
 my $mets_data = <<'END';
 <?xml version="1.0" encoding="UTF-8"?>
 <mets xmlns:xlink="http://www.w3.org/TR/xlink">
   <fileSec>
     <fileGrp ID="IMGGRP" USE="Images">
       <file ID="IMG00001" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00001" MIMETYPE="image/tiff" SEQ="1" SIZE="5184000" GROUPID="1">
         <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855r.tif" />
       </file>
       <file ID="IMG00002" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00002" MIMETYPE="image/tiff" SEQ="2" SIZE="5200228" GROUPID="2">
         <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855v.tif" />
       </file>
     </fileGrp>
     <fileGrp ID="PDFGRP" USE="PDF">
       <file ID="PDF00001" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00001" MIMETYPE="text/pdf" SEQ="1" SIZE="251967" GROUPID="1">
         <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855r.pdf" />
       </file>
       <file ID="PDF00002" CREATED="2006-06-20T12:00:00" ADMID="IMGPARAM00002" MIMETYPE="text/pdf" SEQ="2" SIZE="172847" GROUPID="2">
         <FLocat LOCTYPE="URL" xlink:href="file://./003855/003855v.pdf" />
       </file>
     </fileGrp>
   </fileSec>
 </mets>
 END

 # Object.
 my $obj = METS::Parse::Simple->new;

 # Parse.
 my $mets_hr = $obj->parse($mets_data);

 # Dump to output.
 p $mets_hr;

 # Output like:
 \ {
     fileSec       {
         fileGrp   [
             [0] {
                 file   [
                     [0] {
                         ADMID      "IMGPARAM00001",
                         CREATED    "2006-06-20T12:00:00",
                         FLocat     {
                             LOCTYPE      "URL",
                             xlink:href   "file://./003855/003855r.tif"
                         },
                         GROUPID    1,
                         ID         "IMG00001",
                         MIMETYPE   "image/tiff",
                         SEQ        1,
                         SIZE       5184000
                     },
                     [1] {
                         ADMID      "IMGPARAM00002",
                         CREATED    "2006-06-20T12:00:00",
                         FLocat     {
                             LOCTYPE      "URL",
                             xlink:href   "file://./003855/003855v.tif"
                         },
                         GROUPID    2,
                         ID         "IMG00002",
                         MIMETYPE   "image/tiff",
                         SEQ        2,
                         SIZE       5200228
                     }
                 ],
                 ID     "IMGGRP",
                 USE    "Images"
             },
             [1] {
                 file   [
                     [0] {
                         ADMID      "IMGPARAM00001",
                         CREATED    "2006-06-20T12:00:00",
                         FLocat     {
                             LOCTYPE      "URL",
                             xlink:href   "file://./003855/003855r.pdf"
                         },
                         GROUPID    1,
                         ID         "PDF00001",
                         MIMETYPE   "text/pdf",
                         SEQ        1,
                         SIZE       251967
                     },
                     [1] {
                         ADMID      "IMGPARAM00002",
                         CREATED    "2006-06-20T12:00:00",
                         FLocat     {
                             LOCTYPE      "URL",
                             xlink:href   "file://./003855/003855v.pdf"
                         },
                         GROUPID    2,
                         ID         "PDF00002",
                         MIMETYPE   "text/pdf",
                         SEQ        2,
                         SIZE       172847
                     }
                 ],
                 ID     "PDFGRP",
                 USE    "PDF"
             }
         ]
     },
     xmlns:xlink   "http://www.w3.org/TR/xlink"
 }

=head1 DEPENDENCIES

L<Class::Utils>,
L<XML::Simple>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/METS-Parse-Simple>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © Michal Josef Špaček 2015-2020
 BSD 2-Clause License

=head1 VERSION

0.01

=cut
