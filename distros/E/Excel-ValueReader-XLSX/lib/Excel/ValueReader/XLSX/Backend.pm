package Excel::ValueReader::XLSX::Backend;
use utf8;
use 5.10.1;
use Moose;
use Archive::Zip          qw(AZ_OK);

our $VERSION = '1.04';

#======================================================================
# ATTRIBUTES
#======================================================================
has 'frontend'      => (is => 'ro',   isa => 'Excel::ValueReader::XLSX',
                        required => 1, weak_ref => 1,
                        handles => [qw/A1_to_num formatted_date/]);

has 'zip'           => (is => 'ro',   isa => 'Archive::Zip', init_arg => undef,
                        builder => '_zip', lazy => 1);

has 'date_styles'   => (is => 'ro',   isa => 'ArrayRef', init_arg => undef,
                        builder => '_date_styles', lazy => 1);

has 'strings'       => (is => 'ro',   isa => 'ArrayRef', init_arg => undef,
                        builder => '_strings',   lazy => 1);

has 'workbook_data' => (is => 'ro',   isa => 'HashRef', init_arg => undef,
                        builder => '_workbook_data',   lazy => 1);



#======================================================================
# ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _zip {
  my $self = shift;

  my $xlsx_file = $self->frontend->xlsx;
  my $zip       = Archive::Zip->new;
  my $result    = $zip->read($xlsx_file);
  $result == AZ_OK  or die "cannot unzip $xlsx_file";

  return $zip;
}

# attribute constructors for _date_styles, _strings and _workbook_data are supplied in subclasses

#======================================================================
# METHODS
#======================================================================


sub base_year {
  my ($self) = @_;
  return $self->workbook_data->{base_year};
}

sub sheets {
  my ($self) = @_;
  return $self->workbook_data->{sheets};
}



sub Excel_builtin_date_formats {
  my @numFmt;

  # source : section 18.8.30 numFmt (Number Format) in ECMA-376-1:2016
  # Office Open XML File Formats — Fundamentals and Markup Language Reference
  $numFmt[14] = 'mm-dd-yy';
  $numFmt[15] = 'd-mmm-yy';
  $numFmt[16] = 'd-mmm';
  $numFmt[17] = 'mmm-yy';
  $numFmt[18] = 'h:mm AM/PM';
  $numFmt[19] = 'h:mm:ss AM/PM';
  $numFmt[20] = 'h:mm';
  $numFmt[21] = 'h:mm:ss';
  $numFmt[22] = 'm/d/yy h:mm';
  $numFmt[45] = 'mm:ss';
  $numFmt[46] = '[h]:mm:ss';
  $numFmt[47] = 'mmss.0';

  return @numFmt;
}


sub _zip_member_contents {
  my ($self, $member) = @_;

  my $contents = $self->zip->contents($member)
    or die "no contents for member $member";
  utf8::decode($contents);

  return $contents;
}



sub _zip_member_name_for_sheet {
  my ($self, $sheet) = @_;

  # check that sheet name was given
  $sheet or die "->values(): missing sheet name";

  # get sheet id
  my $id = $self->sheets->{$sheet};
  $id //= $sheet if $sheet =~ /^\d+$/;
  $id or die "no such sheet: $sheet";

  # construct member name for that sheet
  return "xl/worksheets/sheet$id.xml";
}


# method "values" is defined in subclasses



1;

__END__

=head1 NAME

Excel::ValueReader::XLSX::Backend -- abstract class, parent for the Regex and LibXML backends

=head1 DESCRIPTION

L<Excel::ValueReader::XLSX> has two possible implementation backends for parsing
C<XLSX> files :
L<Excel::ValueReader::XLSX::Backend::Regex>, based on regular expressions, or
L<Excel::ValueReader::XLSX::Backend::LibXML>, based on the libxml2 library.
Both backends share some common features, so the present class implements those
common features. This is about internal implementation; it should be of no interest
to external users of the module.

=head1 ATTRIBUTES

A backend instance possesses the following attributes :

=over

=item frontend

a weak reference to the frontend instance

=item zip

an L<Archive::Zip> instance for accessing the contents of the C<xlsx> file

=item date_styles

an array of numeric styles for presenting dates and times. Styles are either
Excel's builtin styles, or custom styles defined in the workbook.

=item strings

an array of all shared strings within the workbook

=item workbook_data

some metadata information about the workbook

=back



=head1 ABSTRACT METHODS

=over

=item values

Inspects all cells within the XSLX files and returns a bi-dimensional array of values.
Not defined in this abstract class, but implemented in subclasses.

=back



=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
