use strict;
use warnings;

BEGIN { $::pkgname = 'Image::MetaData::JPEG';
	$::recname = "${main::pkgname}::Record";
	$::segname = "${main::pkgname}::Segment";
	$::tabname = "${main::pkgname}::data::Tables"; }

sub newimage   { $::pkgname->new(@_) };
sub newrecord  { $::recname->new(@_) };
sub newsegment { $::segname->new(@_) };

return 1;
