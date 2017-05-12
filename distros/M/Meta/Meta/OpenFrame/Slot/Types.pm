#!/bin/echo This is a perl module and should not be run

package Meta::OpenFrame::Slot::Types;

use strict qw(vars refs subs);
use Cache::MemoryCache qw();
use Meta::File::MMagic qw();
use File::Spec qw();
use OpenFrame::Response qw();
use Pipeline::Segment qw();
use Meta::Utils::File::File qw();
use Meta::Baseline::Aegis qw();

our($VERSION,@ISA,$mm,$cache);
$VERSION="0.01";
@ISA=qw(Pipeline::Segment);

#sub BEGIN();
#sub what();
#sub action($$$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	$mm=Meta::File::MMagic->new();
	$cache=Cache::MemoryCache->new({
		'namespace'=>'mmagic',
		'default_expires_in'=>600,
	});
}

sub what() {
	return(['OpenFrame::Request']);
}

sub action($$$) {
	my($self,$config,$absrq)=@_;
	my($uri)=$absrq->uri();
	warn("[slot:types] checking to make sure we are correct content") if $OpenFrame::DEBUG;
	my($file)=$uri->path();
	if($config->{aegis}) {
		$file=Meta::Baseline::Aegis::which_nodie($file);
	} else {
		if($config->{directory}) {
			$file=File::Spec->catfile($config->{directory},$file);
		}
	}
	if(-e $file && -r $file) {
		my($type)=$cache->get($file);
		if(not defined $type) {
			# cache miss
			$type=$mm->checktype_byfilename($file);
			$cache->set($file,$type);
			warn("image cache miss for [".$file."]=[".$type."]") if $OpenFrame::DEBUG;
		}
		warn("[slot:types] file $file has type $type") if $OpenFrame::DEBUG;

		if($type eq "text/html" || $type eq "text/css") {
			warn("[slot:html] file $file is being handled") if $OpenFrame::DEBUG;
			my($response)=OpenFrame::Response->new();
			#$response->code(OpenFrame::Constants::ofOK);
			$response->mimetype($type);
			my($content);
			Meta::Utils::File::File::load($file,\$content);
			$response->message($content);
			my($time)=(CORE::stat($file))[9];
			$response->last_modified($time);
			return($response);
		}
	}
	warn("[slot:types] file $file was not handled as HTML") if $OpenFrame::DEBUG;
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::OpenFrame::Slot::Types - serve many files types in OpenFrame framework.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Types.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::OpenFrame::Slot::Types qw();
	my($object)=Meta::OpenFrame::Slot::Types->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class is should be able to do all the things that the regular
OpenFrame::Slot::Images and OpenFrame::Slot::HTML. There is no real
difference between the two. In addition, this class does Aegis type
translations for the URLs if needed.

Most of the code here is just an adjustment of the
OpenFrame::Slot::HTML code.

In order to understand what this class works and to a greater
extent what it does you must be familiar with the OpenFrame
framework.

The code here is for OpenFrame 2.x.

=head1 FUNCTIONS

	BEGIN()
	what()
	action($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Setup method to setup a Meta::File::MMagic object we need and it's
cache.

=item B<what()>

This method returns what this slot is supposed to return (a response).

=item B<action($$$)>

This method actually does all the work.

=item B<TEST($)>

This is a testing suite for the Meta::OpenFrame::Slot::Types module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Pipeline::Segment(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV download scripts
	0.01 MV md5 issues

=head1 SEE ALSO

Cache::MemoryCache(3), File::Spec(3), Meta::Baseline::Aegis(3), Meta::File::MMagic(3), Meta::Utils::File::File(3), OpenFrame::Response(3), Pipeline::Segment(3), strict(3)

=head1 TODO

-make a cache for file content as well as for the file type.
