package Geo::MapInfo::MIF::Writer::Region;
use strict;
use warnings;
use base qw{Package::New};
use DateTime;
use Path::Class qw{file};
use Text::CSV_XS qw{};

our $VERSION='0.05';

=head1 NAME

Geo::MapInfo::MIF::Writer::Region - Perl extension for writing MapInfo Interchange Format (MIF) Region files.

=head1 SYNOPSIS

  use Geo::MapInfo::MIF::Writer::Region;
  my $map=Geo::MapInfo::MIF::Writer::Region->new(basename=>$basename);
  $map->addSimpleRegion(
          data   => {col1=>"val1", col2=>"val2"},
          region => [[$lon1, $lat1], [$lon2, $lat2], [$lon3, $lat3], [$lon4, $lat4]],
        );
  $map->addMultipartRegion(
          data    => {col1=>"val1", col2=>"val2"},
          regions => [                                #note the "s" in regions
                      [[$lon1a, $lat1a], [$lon2a, $lat2a], [$lon3a, $lat3a], [$lon4a, $lat4a]],
                      [[$lon1b, $lat1b], [$lon2b, $lat2b], [$lon3b, $lat3b], [$lon4b, $lat4b]],
                      [[$lon1c, $lat1c], [$lon2c, $lat2c], [$lon3c, $lat3c], [$lon4c, $lat4c]],
                     ],
        );
  $map->save;

=head1 DESCRIPTION

Perl extension for writing MapInfo Interchange Format (MIF) Region files.

Note: This package stores data in memory before writing so it may not be appropriate for every use.

=head1 USAGE

=head2 new

Creates a new object.

  my $map=Geo::MapInfo::MIF::Writer::Region->new;

=head2 basename

Sets and returns the basename of the mid/mif files.

  $map->basename("basename");
  $map->basename("./path/basename"); 
  $map->basename("/path/basename"); 
  $map->basename(undef); #default is "mapinfo-yyyymmddhhmiss"

=cut

sub basename {
  my $self=shift;
  $self->{"basename"}=shift if @_;
  unless (defined($self->{"basename"})) {
    my $dt=DateTime->now;
    $self->{"basename"}=sprintf("mapinfo-%s%s", $dt->ymd(""), $dt->hms(""));
  }
  return $self->{"basename"};
}

=head2 save

Writes mid and mif files to the name indicated by basename.

  $map->save;

Note: This method overwrites files if they exist.

=cut

sub save {
  my $self=shift;
  my @column=$self->_columns; #before we open files
  my @row=$self->_rows; #before we open files
  my $mid=file(join(".", $self->basename, "mid"))->openw;
  my $mif=file(join(".", $self->basename, "mif"))->openw;
  print $mif qq{Version 300\r\n};
  print $mif qq{Charset "WindowsLatin1"\r\n};
  print $mif qq{Delimiter ","\r\n};
  print $mif qq{CoordSys Earth Projection 1, 0\r\n}; #WGS-84 only!
  print $mif sprintf("Columns %s\r\n", scalar(@column));
  foreach my $col (@column) {
    my $name=$col->{"name"};
    my $type=$col->{"type"};
    $type=sprintf("%s(%s)", $col->{"type"}, $col->{"length"})
      if $col->{"type"} eq "Char";
    print $mif sprintf("  %s %s\r\n", $name, $type);
  }
  print $mif "Data\r\n\r\n";
  my $count=1;
  foreach my $row (@row) {
    #Debug
    #use Data::Dumper qw{Dumper};
    #print Dumper($row);
    #add to mid
    my $csv=Text::CSV_XS->new;
    my $data=$row->{"data"} || {id=>$count++};
    my @col=map {$_->{"name"}} @column;
    my $status=$csv->combine(@{$data}{@col});
    warn sprintf("Text::CSV_XS: %s", $csv->error_input) unless $status == 1;
    print $mid $csv->string."\r\n"; #\r\n per RFC 4180
    #add to mif
    my $regions=$row->{"regions"} || [];
    if (scalar(@$regions) == 0) {
      print $mif "none\r\n";
    } else {
      print $mif sprintf("Region  %s\r\n", scalar(@$regions));
      foreach my $region (@$regions) {
        die("Error: Region must be an array reference.")
          unless ref($region) eq "ARRAY";
        print $mif sprintf("  %s\r\n", scalar(@$region));
        foreach my $point (@$region) {
          die("Error: Point must be an array reference.")
            unless ref($point) eq "ARRAY";
          die("Error: Point must have two values.")
            unless @$point == 2 ;
          printf $mif "%s %s\r\n", @$point,
        } 
      }
      #add optional pen, brush, center to mif
    }
  }
  return "1";
}

# _columns Format
# [
#   name   => "",    # m/[a-z_][a-z0-9_}{0,30}/i
#   type   => "",    # Char, Integer
#   length => 1-254, # for string types
# ]

sub _columns {
  my $self=shift;
  my %data=();
  my @column=();
  foreach my $row ($self->_rows) {
    my %column=map {$_->{"name"}=>$_} @column; #updatable reference
    my $data=$row->{"data"};
    $data={} unless ref($row->{"data"}) eq "HASH";
    foreach my $key (sort keys %$data) {
      $data->{$key}="" unless defined $data->{$key};
      unless ($key =~ m/[a-z_]{1}[a-z0-9_]{0,30}/i) {
        warn "MapInfo: A field name can contain only letters, numbers, and '_'. It cannot contain spaces or punctuation marks, and it cannot begin with a number.";
        next;
      }
      if (exists $column{$key}) {
        #update max lenght
        my $length=length($data->{$key});
        $column{$key}->{"length"}=$length if $length>$column{$key}->{"length"};
      } else {
        my $type="Char";
        if ($data->{$key}=~m/^[-]?\d{1,10}$/ and abs($data->{$key}) < 2 ** 31) {
          $type="Integer";
        }
        push @column, {
                        name => $key,
                        type => $type,
                        length => length($data->{$key}),
                      };
      }
    }
  }
  push @column, {name=>"id", type=>"Integer", length=>0} if @column == 0;
  return wantarray ? @column : \@column;
}

=head2 addSimpleRegion

Adds a new object to the in memory array.

  $map->addSimpleRegion(
          data   => {id=>1, col2=>"Foo", col3=>"Bar"}, #default is id=>$index.
          region => [[$x1,$y1], [$x2,$y2], [$x3,$y3]], #default is "none" which means no geocoded data
        );

=cut

sub addSimpleRegion {
  my $self=shift;
  my %data=@_;
  $data{"regions"}=[delete($data{"region"})];
  return $self->addMultipartRegion(%data);
}

=head2 addMultipartRegion

Adds a new object to the in memory array.

  $map->addMultipartRegion(
          data    => {id=>1, col2=>"Foo", col3=>"Bar"},
          regions => [
                       [[$x1,$y1], [$x2,$y2], [$x3,$y3]],
                       \@r2, #can be island or lake but MapInfo figures that out for you.
                       \@r3,
                     ],
        );

=cut

sub addMultipartRegion {
  my $self=shift;
  my %data=@_;
  return push @{$self->_rows}, \%data,
}

sub _rows {
  my $self=shift;
  $self->{"_rows"}=[] unless ref($self->{"_rows"}) eq "ARRAY";
  return wantarray ? @{$self->{"_rows"}} : $self->{"_rows"};
}

=head1 LIMITATIONS

Currently this package only supports Regions since points and circles are trival to support in MapInfo.

Currently we only support string and integer types.

=head1 BUGS

Please log on RT and send an email to the author.

Patches accepted!

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  DavisNetworks.com
  davis@davisnetworks.com
  http://www.davisnetworks.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::MapInfo::MIF> - MapInfo Interchange Format (MIF) File Reader

=cut

1;
