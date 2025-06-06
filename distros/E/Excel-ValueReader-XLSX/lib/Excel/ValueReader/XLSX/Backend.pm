package Excel::ValueReader::XLSX::Backend;
use utf8;
use 5.12.1;
use Moose;
use Archive::Zip 1.61     qw(AZ_OK);
use Carp                  qw/croak/;
use Scalar::Util          qw/openhandle/;
use Encode                qw/decode/;


#======================================================================
# ATTRIBUTES
#======================================================================
has 'frontend'      => (is => 'ro', isa => 'Excel::ValueReader::XLSX',
                        required => 1, weak_ref => 1, handles => [qw/formatted_date/]);

my %lazy_attrs = ( zip             => 'Archive::Zip',
                   date_styles     => 'ArrayRef',
                   strings         => 'ArrayRef',
                   workbook_data   => 'HashRef',
                   table_info      => 'HashRef',
                   sheet_for_table => 'ArrayRef',
                  );

while (my ($name, $type) = each %lazy_attrs) {
  has $name => (is => 'ro', isa => $type, builder => "_$name", init_arg => undef, lazy => 1);
}




#======================================================================
# ATTRIBUTE CONSTRUCTORS
#======================================================================

sub _zip {
  my $self = shift;

  my $zip                  = Archive::Zip->new;
  my $xlsx_source          = $self->frontend->xlsx;
  my ($meth, $source_name) = openhandle($xlsx_source) ? (readFromFileHandle => 'filehandle')
                                                      : (read               => $xlsx_source);
  my $result               = $zip->$meth($xlsx_source);
  $result == AZ_OK  or die "cannot unzip from $source_name";

  return $zip;
}


sub _table_info {
  my ($self) = @_;

  my %table_info;
  my @table_members = $self->zip->membersMatching(qr[^xl/tables/table\d+\.xml$]);
  foreach my $table_member (map {$_->fileName} @table_members) {
    my ($table_id)            = $table_member =~ /table(\d+)\.xml/;
    my $table_xml             = $self->_zip_member_contents($table_member);
    my $this_table_info       = $self->_parse_table_xml($table_xml); # defined in subclass
    $this_table_info->{id}    = $table_id;
    $this_table_info->{sheet} = $self->sheet_for_table->[$table_id]
      or croak "could not find sheet id for table $table_id";

    $table_info{$this_table_info->{name}}  = $this_table_info;
  }

  return \%table_info;
}


sub _sheet_for_table {
  my ($self) = @_;

  my @sheet_for_table;
  my @rel_members = $self->zip->membersMatching(qr[^xl/worksheets/_rels/sheet\d+\.xml\.rels$]);
  foreach my $rel_member (map {$_->fileName} @rel_members) {
    my ($sheet_id) = $rel_member =~ /sheet(\d+)\.xml/;
    my $rel_xml    = $self->_zip_member_contents($rel_member);
    my @table_ids  = $self->_table_targets($rel_xml); # defined in subclass
    $sheet_for_table[$_] = $sheet_id foreach @table_ids;
  }

  return \@sheet_for_table;
}

for my $abstract_meth (qw/_date_styles _strings _workbook_data/) {
  no strict 'refs';
  *{$abstract_meth} = sub {die "->$abstract_meth() should be implemented in subclass"}
}


#======================================================================
# METHODS
#======================================================================


# accessors to workbook data
sub base_year    {shift->workbook_data->{base_year}   }
sub sheets       {shift->workbook_data->{sheets}      }
sub active_sheet {shift->workbook_data->{active_sheet}}


sub Excel_builtin_date_formats {
  my @numFmt;

  # source : section 18.8.30 numFmt (Number Format) in ECMA-376-1:2016
  # Office Open XML File Formats - Fundamentals and Markup Language Reference
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

  return decode('UTF-8', $contents);
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

Not defined in this abstract class, but implemented in subclasses.

=over

=item values

Inspects all cells within the XSLX files and returns a bi-dimensional array of values.


=back



=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
