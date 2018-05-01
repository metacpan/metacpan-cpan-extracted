package Geo::GDAL::FFI::Feature;
use v5.10;
use strict;
use warnings;
use Carp;
use Encode qw(decode encode);
use FFI::Platypus::Buffer;

our $VERSION = 0.03;

sub new {
    my ($class, $defn) = @_;
    my $f = Geo::GDAL::FFI::OGR_F_Create($$defn);
    return bless \$f, $class;
}

sub DESTROY {
    my $self = shift;
    Geo::GDAL::FFI::OGR_F_Destroy($$self);
}

sub GetFID {
    my ($self) = @_;
    return Geo::GDAL::FFI::OGR_F_GetFID($$self);
}

sub SetFID {
    my ($self, $fid) = @_;
    $fid //= 0;
    Geo::GDAL::FFI::OGR_F_GetFID($$self, $fid);
}

sub GetDefn {
    my ($self) = @_;
    my $d = Geo::GDAL::FFI::OGR_F_GetDefnRef($$self);
    ++$Geo::GDAL::FFI::immutable{$d};
    #say STDERR "$d immutable";
    return bless \$d, 'Geo::GDAL::FFI::FeatureDefn';
}

sub Clone {
    my ($self) = @_;
    my $f = Geo::GDAL::FFI::OGR_F_Clone($$self);
    return bless \$f, 'Geo::GDAL::FFI::Feature';
}

sub Equals {
    my ($self, $f) = @_;
    return Geo::GDAL::FFI::OGR_F_Equal($$self, $$f);
}

sub SetField {
    my $self = shift;
    my $i = shift;
    $i //= 0;
    $i = Geo::GDAL::FFI::OGR_F_GetFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    unless (@_) {
        Geo::GDAL::FFI::OGR_F_UnsetField($$self, $i) ;
        return;
    }
    my ($value) = @_;
    unless (defined $value) {
        Geo::GDAL::FFI::OGR_F_SetFieldNull($$self, $i);
        return;
    }
    my $d = Geo::GDAL::FFI::OGR_F_GetFieldDefnRef($$self, $i);
    my $t = $Geo::GDAL::FFI::field_types_reverse{Geo::GDAL::FFI::OGR_Fld_GetType($d)};
    Geo::GDAL::FFI::OGR_F_SetFieldInteger($$self, $i, $value) if $t eq 'Integer';
    Geo::GDAL::FFI::OGR_F_SetFieldInteger64($$self, $i, $value) if $t eq 'Integer64';
    Geo::GDAL::FFI::OGR_F_SetFieldDouble($$self, $i, $value) if $t eq 'Real';
    Geo::GDAL::FFI::OGR_F_SetFieldString($$self, $i, $value) if $t eq 'String';

    confess "Can't yet set binary fields." if $t eq 'Binary';

    my @s = @_;
    Geo::GDAL::FFI::OGR_F_SetFieldIntegerList($$self, $i, scalar @s, \@s) if $t eq 'IntegerList';
    Geo::GDAL::FFI::OGR_F_SetFieldInteger64List($$self, $i, scalar @s, \@s) if $t eq 'Integer64List';
    Geo::GDAL::FFI::OGR_F_SetFieldDoubleList($$self, $i, scalar @s, \@s) if $t eq 'RealList';
    if ($t eq 'StringList') {
        my $csl = 0;
        for my $s (@s) {
            $csl = Geo::GDAL::FFI::CSLAddString($csl, $s);
        }
        Geo::GDAL::FFI::OGR_F_SetFieldStringList($$self, $i, $csl);
        Geo::GDAL::FFI::CSLDestroy($csl);
    } elsif ($t eq 'Date') {
        my @dt = @_;
        $dt[0] //= 2000; # year
        $dt[1] //= 1; # month 1-12
        $dt[2] //= 1; # day 1-31
        $dt[3] //= 0; # hour 0-23
        $dt[4] //= 0; # minute 0-59
        $dt[5] //= 0.0; # second with millisecond accuracy
        $dt[6] //= 100; # TZ
        Geo::GDAL::FFI::OGR_F_SetFieldDateTimeEx($$self, $i, @dt);
    } elsif ($t eq 'Time') {
        my @dt = (0, 0, 0, @_);
        $dt[3] //= 0; # hour 0-23
        $dt[4] //= 0; # minute 0-59
        $dt[5] //= 0.0; # second with millisecond accuracy
        $dt[6] //= 100; # TZ
        Geo::GDAL::FFI::OGR_F_SetFieldDateTimeEx($$self, $i, @dt);
    } elsif ($t eq 'DateTime') {
        my @dt = @_;
        $dt[0] //= 2000; # year
        $dt[1] //= 1; # month 1-12
        $dt[2] //= 1; # day 1-31
        $dt[3] //= 0; # hour 0-23
        $dt[4] //= 0; # minute 0-59
        $dt[5] //= 0.0; # second with millisecond accuracy
        $dt[6] //= 100; # TZ
        Geo::GDAL::FFI::OGR_F_SetFieldDateTimeEx($$self, $i, @dt);
    }
}

sub GetField {
    my ($self, $i, $encoding) = @_;
    $i //= 0;
    $i = Geo::GDAL::FFI::OGR_F_GetFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    return unless $self->IsFieldSetAndNotNull($i);
    my $d = Geo::GDAL::FFI::OGR_F_GetFieldDefnRef($$self, $i);
    my $t = $Geo::GDAL::FFI::field_types_reverse{Geo::GDAL::FFI::OGR_Fld_GetType($d)};
    return Geo::GDAL::FFI::OGR_F_GetFieldAsInteger($$self, $i) if $t eq 'Integer';
    return Geo::GDAL::FFI::OGR_F_GetFieldAsInteger64($$self, $i) if $t eq 'Integer64';
    return Geo::GDAL::FFI::OGR_F_GetFieldAsDouble($$self, $i) if $t eq 'Real';
    if ($t eq 'String') {
        my $retval = Geo::GDAL::FFI::OGR_F_GetFieldAsString($$self, $i);
        $retval = decode $encoding => $retval if defined $encoding;
        return $retval;
    }
    return Geo::GDAL::FFI::OGR_F_GetFieldAsBinary($$self, $i) if $t eq 'Binary';
    my @list;
    if ($t eq 'IntegerList') {
        my $len;
        my $p = Geo::GDAL::FFI::OGR_F_GetFieldAsIntegerList($$self, $i, \$len);
        @list = unpack("l[$len]", buffer_to_scalar($p, $len*4));
    } elsif ($t eq 'Integer64List') {
        my $len;
        my $p = Geo::GDAL::FFI::OGR_F_GetFieldAsInteger64List($$self, $i, \$len);
        @list = unpack("q[$len]", buffer_to_scalar($p, $len*8));
    } elsif ($t eq 'RealList') {
        my $len;
        my $p = Geo::GDAL::FFI::OGR_F_GetFieldAsDoubleList($$self, $i, \$len);
        @list = unpack("d[$len]", buffer_to_scalar($p, $len*8));
    } elsif ($t eq 'StringList') {
        my $p = Geo::GDAL::FFI::OGR_F_GetFieldAsStringList($$self, $i);
        for my $i (0..Geo::GDAL::FFI::CSLCount($p)-1) {
            push @list, Geo::GDAL::FFI::CSLGetField($p, $i);
        }
    } elsif ($t eq 'Date') {
        my ($y, $m, $d, $h, $min, $s, $tz) = (0, 0, 0, 0, 0, 0.0, 0);
        Geo::GDAL::FFI::OGR_F_GetFieldAsDateTimeEx($$self, $i, \$y, \$m, \$d, \$h, \$min, \$s, \$tz);
        @list = ($y, $m, $d);
    } elsif ($t eq 'Time') {
        my ($y, $m, $d, $h, $min, $s, $tz) = (0, 0, 0, 0, 0, 0.0, 0);
        Geo::GDAL::FFI::OGR_F_GetFieldAsDateTimeEx($$self, $i, \$y, \$m, \$d, \$h, \$min, \$s, \$tz);
        $s = sprintf("%.3f", $s) + 0;
        @list = ($h, $min, $s, $tz);
    } elsif ($t eq 'DateTime') {
        my ($y, $m, $d, $h, $min, $s, $tz) = (0, 0, 0, 0, 0, 0.0, 0);
        Geo::GDAL::FFI::OGR_F_GetFieldAsDateTimeEx($$self, $i, \$y, \$m, \$d, \$h, \$min, \$s, \$tz);
        $s = sprintf("%.3f", $s) + 0;
        @list = ($y, $m, $d, $h, $min, $s, $tz);
    }
    return @list;
}

sub IsFieldSet {
    my ($self, $i) = @_;
    $i //= 0;
    $i = Geo::GDAL::FFI::OGR_F_GetFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    return Geo::GDAL::FFI::OGR_F_IsFieldSet($$self, $i);
}

sub IsFieldNull {
    my ($self, $i) = @_;
    $i //= 0;
    $i = Geo::GDAL::FFI::OGR_F_GetFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    return Geo::GDAL::FFI::OGR_F_IsFieldNull($$self, $i);
}

sub IsFieldSetAndNotNull {
    my ($self, $i) = @_;
    $i //= 0;
    $i = Geo::GDAL::FFI::OGR_F_GetFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    return Geo::GDAL::FFI::OGR_F_IsFieldSetAndNotNull($$self, $i);
}

sub GetGeomField {
    my ($self, $i) = @_;
    $i //= 0;
    $i = Geo::GDAL::FFI::OGR_F_GetGeomFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    my $g = Geo::GDAL::FFI::OGR_F_GetGeomFieldRef($$self, $i);
    confess "No such field: $i" unless $g;
    ++$Geo::GDAL::FFI::immutable{$g};
    #say STDERR "$g immutable";
    return bless \$g, 'Geo::GDAL::FFI::Geometry';
}

sub SetGeomField {
    my $self = shift;
    my $g = pop;
    my $i = shift;
    $i //= 0;
    $i = Geo::GDAL::FFI::OGR_F_GetGeomFieldIndex($$self, $i) unless Geo::GDAL::FFI::isint($i);
    if (ref $g eq 'ARRAY') {
        $g = Geo::GDAL::FFI::Geometry->new(@$g);
    }
    ++$Geo::GDAL::FFI::immutable{$$g};
    #say STDERR "$$g immutable";
    Geo::GDAL::FFI::OGR_F_SetGeomFieldDirectly($$self, $i, $$g);
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::Feature - A GDAL vector feature

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

 my $feature = Geo::GDAL::FFI::Feature->new($defn);

Create a new Feature object. The argument is a FeatureDefn object,
which you can get from a Layer object (Defn method), another Feature
object (Defn method), or by explicitly creating a new FeatureDefn
object.

=head2 GetDefn

Returns the FeatureDefn object for this Feature.

=head2 GetFID

=head2 SetFID

=head2 Clone

=head2 Equals

 my $equals = $feature1->Equals($feature2);

=head2 SetField

 $feature->SetField($fname, ...);

Set the value of field $fname. If no arguments after the name is
given, the field is unset. If the arguments after the name is
undefined, sets the field to NULL. Otherwise sets the field according
to the field type.

=head2 GetField

 my $value = $feature->GetField($fname);

=head2 SetGeomField

 $feature->SetField($fname, $geom);

$fname is optional and by default the first geometry field.

=head2 GetGeomField

 my $geom = $feature->GetGeomField($fname);

$fname is optional and by default the first geometry field.

=head1 LICENSE

This software is released under the Artistic License. See
L<perlartistic>.

=head1 AUTHOR

Ari Jolma - Ari.Jolma at gmail.com

=head1 SEE ALSO

L<Geo::GDAL::FFI>

L<Alien::gdal>, L<FFI::Platypus>, L<http://www.gdal.org>

=cut

__END__;
