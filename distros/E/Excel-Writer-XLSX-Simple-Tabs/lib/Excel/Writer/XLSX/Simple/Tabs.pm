package Excel::Writer::XLSX::Simple::Tabs;
use strict;
use warnings;
use base qw{Package::New};
use IO::Scalar qw{};
use Excel::Writer::XLSX qw{};

our $VERSION='0.03';
our $PACKAGE=__PACKAGE__;

=head1 NAME

Excel::Writer::XLSX::Simple::Tabs - Simple Interface to the Excel::Writer::XLSX Package

=head1 SYNOPSIS

  use Excel::Writer::XLSX::Simple::Tabs;
  my $ss=Excel::Writer::XLSX::Simple::Tabs->new;
  my @data=(
            ["Heading1", "Heading2"],
            ["data1",    "data2"   ],
            ["data3",    "data4"   ],
           );
  $ss->add(Tab1=>\@data, Tab2=>\@data);
  print $ss->header(filename=>"filename.xlsx"), $ss->content;

=head1 DESCRIPTION

This is a simple wrapper around Excel::Writer::XLSX that creates tabs for data.  It is meant to be simple not full featured.  I use this package to export data from the L<DBIx::Array> sqlarrayarrayname method which is an array of array references where the first array is the column headings.

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

=head2 book

Returns the workbook object

=cut

sub book {
  my $self=shift;
  #Thanks to Tony Bowden for the IO::Scalar stuff
  unless (defined($self->{"book"})) {
    $self->{"book"}=Excel::Writer::XLSX->new(
                      IO::Scalar->new_tie(\($self->{"content"}))
                    );
  }
  return $self->{"book"};
}

=head2 add

  $ss->add("Tab Name", \@data);
  $ss->add(Tab1=>\@data, Tab2=>\@data);

=cut

sub add {
  my $self=shift;
  die("Error: The $PACKAGE->add method requires an even number of arguments")
    if scalar(@_) % 2;
  while (@_ > 0) {
    my $tab  = shift;
    my $data = shift;
    die(sprintf(qq{Error: Expecting data to be an array reference but got "%s" in $PACKAGE->add}, ref($data)))
      unless ref($data) eq "ARRAY";
    $self->_add1($tab=>$data);
  }
  return $self;
}

sub _add1 {
  my $self            =  shift;
  my $tab             =  shift;
  $tab                =~ s/[\[\]:\*\?\/\\]/ /g; #Invalid character []:*?/\ in worksheet name
  $tab                =  substr($tab,0,31) if length($tab) > 31; #must be <= 31 chars
  my $data            =  shift;
  my $sheet           =  $self->book->add_worksheet($tab);
  my %format          =  $self->default; $format{"num_format"}='mm/dd/yyyy hh:mm:ss';
  my $format_datetime =  $self->book->add_format(%format);
  my $subref          =  sub {
                              my $sheet              = shift;
                              my @args               = @_;
                              my ($m,$d,$y,$h,$n,$s) = split(/[\/ :]/, $args[2]);
                              $args[2]               = sprintf("%4d-%02d-%02dT%02d:%02d:%02d", $y, $m, $d, $h, $n, $s);
                              $args[3]               = $format_datetime;
                              return $sheet->write_date_time(@args);
                            };
  $sheet->add_write_handler(qr/^\d{16,}$/, sub{shift->write_string(@_)});        #Long Integer Support - RT61869
  $sheet->add_write_handler(qr/^0\d+$/, sub{shift->write_string(@_)});           #Leading Zero Support
  $sheet->add_write_handler(qr{^\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}$}, $subref); #DateTime Support
  $self->_add_data($sheet, $data);
  $sheet->freeze_panes(1, 0); 
  return $sheet;
}

sub _add_data {
  my $self      = shift;
  my $worksheet = shift;
  my $data      = shift;
  my $header    = shift(@$data);
  $worksheet->write_col(0,0,[$header], $self->book->add_format($self->default, $self->first));
  $worksheet->write_col(1,0, $data,    $self->book->add_format($self->default));

  unshift @$data, $header; #put the data back together it is a reference!

  #Auto resize columns
  foreach my $col (0 .. scalar(@$header) - 1) {
    my $width = (sort {$a<=>$b} map {length($_->[$col]||'')} @$data)[-1];
    $width    = 8 if $width < 8;
    $worksheet->set_column($col, $col, $width);
  }
  return $self;
}

=head2 header

Returns a header appropriate for a web application

  Content-type: application/vnd.ms-excel
  Content-Disposition: attachment; filename=filename.xls

  $ss->header                                           #embedded in browser
  $ss->header(filename=>"filename.xls")                 #download prompt
  $ss->header(content_type=>"application/vnd.ms-excel") #default content type

=cut

sub header {
  my $self         = shift;
  my %data         = @_;
  my $content_type = $data{"content_type"} || "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
  my $filename     = $data{"filename"};
  my @headers      = ();
  push @headers, qq{Content-type: $content_type\n};
  push @headers, qq{Content-Disposition: attachment; filename="$filename";\n} if defined $filename;
  return join("", @headers). "\n";
}

=head2 content

This returns the binary content of the spreadsheet.

  print $ss->content;

  print $ss->header, $ss->content; #CGI Application

  binmod($fh);
  print $fh, $ss->content;

=cut

sub content {
  my $self=shift;
  $self->book->close;
  return $self->{"content"};
}

=head1 PROPERTIES

=head2 first

Returns a hash of additional settings for the first row

  $ss->first({setting=>"value"}); #settings from L<Excel::Writer::XLSX>

=cut

sub first {
  my $self=shift;
  $self->{"first"}=shift if @_;
  $self->{"first"}={bg_color=>"silver", bold=>1}
    unless ref($self->{"first"}) eq "HASH";
  return wantarray ? %{$self->{"first"}} : $self->{"first"};
}

=head2 default

Returns a hash of default settings for the body

  $ss->default({setting=>"value"}); #settings from L<Excel::Writer::XLSX>

=cut

sub default {
  my $self=shift;
  $self->{"default"}=shift if @_;
  $self->{"default"}={border=>1, border_color=>"gray"}
    unless ref($self->{"default"}) eq "HASH";
  return wantarray ? %{$self->{"default"}} : $self->{"default"};
}

=head1 BUGS

Please report issues on L<GitHub|https://github.com/mrdvt92/perl-Excel-Writer-XLSX-Simple-Tabs/issues>

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT

Copyright (c) 2022 Michael R. Davis

Copyright (c) 2001-2005 Tony Bowden (IO::Scalar portion used here "under the same terms as Perl itself")

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Excel::Writer::XLSX>, L<DBIx::Array> sqlarrayarrayname method, L<IO::Scalar>, L<Spreadsheet::WriteExcel>

=cut

1;
