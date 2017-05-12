#=Copyright Infomation
#==========================================================
#Module Name       : MP3::Merge
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics, E.E.
#Home Page           : http://www.mewsoft.com
#Contact Email      : support@mewsoft.com
#Copyrights (c) 2013 Mewsoft. All rights reserved.
#==========================================================
package MP3::Merge;

use Carp;
use strict;
use warnings;
use File::Basename;
use MPEG::Audio::Frame;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

our $VERSION = '1.01';
#==========================================================
sub new {
my ($class) = @_;
	my $self = bless {}, $class;
	$self->clear();
    return $self;
}
#==========================================================
sub clear {
my ($self) = @_; 
	$self->{frames} = 0;
	$self->{length} = 0;
	$self->{size} = 0;
	$self->{files} = undef;
	$self->{counter} = 0;
	return $self;
}
#==========================================================
sub add {
my ($self, @files) = @_; 
	push @{$self->{files}}, @files;
	return $self;
}
#==========================================================
sub files {
my ($self) = @_; 
	return @{$self->{files}};
}
#==========================================================
sub length {
my ($self) = @_; 
	return $self->{length};
}
#==========================================================
sub size {
my ($self) = @_; 
	return $self->{size};
}
#==========================================================
sub frames {
my ($self) = @_; 
	return $self->{frames};
}
#==========================================================
sub stream {
my ($self, $outfh) = @_; 
my ($file, $frame, $fh);
	
	$self->{frames} = 0;
	$self->{length} = 0;
	$self->{size} = 0;

	foreach $file (@{$self->{files}}) {
		open ($fh, $file) || croak("Error reading file $file: $!.");
		binmode ($fh);
		while ($frame = MPEG::Audio::Frame->read($fh)) {
			$self->{length} += $frame->seconds;
			$self->{size} += $frame->length;
			$self->{frames}++;
			print $outfh $frame->asbin();
			$frame = undef;
		}
		close ($fh);
	}

	return $self;
}
#==========================================================
sub save {
my ($self, $out) = @_; 
my ($fh);
	open ($fh, ">$out")  || croak("Error wrtiting file $out: $!.");
	binmode ($fh);
	$self->stream($fh);
	close ($fh);
	return $self;
}
#==========================================================
sub echo {
my ($self, $filename) = @_; 

	$filename ||= @{$self->{files}}[0];
	print "Content-Disposition: attachment; filename=$filename\n";
	print "Content-type: audio/mp3\n\n";
	binmode STDOUT;
	binmode STDERR;
	$self->stream(\*STDOUT);
	return $self;
}
#==========================================================
sub echo_zip {
my ($self, $filename) = @_; 
my ($zip, $file, $name, $dir, $ext, $member);

	$filename ||= @{$self->{files}}[0];

	$zip = Archive::Zip->new();

	foreach $file (@{$self->{files}}) {
		($name, $dir, $ext) = fileparse($file,  qr/\.[^.]*/);
		$member = $zip->addFile($file, "$name.$ext");
		$member->desiredCompressionMethod(COMPRESSION_STORED);
	}
	
	print "Content-Disposition: attachment; filename=$filename\n";
	print "Content-type: application/x-zip-compressed\n\n";
	binmode STDOUT;
	binmode STDERR;
	$zip->writeToFileHandle(\*STDOUT, 0);
	return $self;
}
#==========================================================

1;

=encoding utf-8

=head1 NAME

MP3::Merge - MP3 files merger and streamer to web browser

=head1 SYNOPSIS

	use MP3::Merge;

	#create new object
	my $mp = MP3::Merge->new();
	
	# add mp3 files
	$mp->add("file.mp3");
	$mp->add("file1.mp3", "file2.mp3", "file3.mp3");
	$mp->add(@mp3files);
	
	# save to file
	$mp->save("merged.mp3");
	
	# or stream merged files to the browser as a single mp3 file
	# correct headers will be automatically sent first to the browser
	$mp->echo("output.mp3");
	
	# or stream all files as single zipped file uncompressed to the browser
	# correct headers will be automatically sent first to the browser
	$mp->echo_zip("audio.zip");
	
	# merged file information after save or echo calls
	#print "Total seconds: ", $mp->length(), ", Total frames: ", $mp->frames(), ",  Total size:", $mp->size(),  "\n";

=head1 DESCRIPTION

This module merges MP3 files into a single MP3 file and also can stream directly the merged files to the web browser.

It can also stream the merged MP3 files as a single zipped file with no compression to the web browser.

=head1 PREREQUESTS

L<MPEG::Audio::Frame>

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  <support[ @ ]mewsoft.com>
Website:  L<http://www.mewsoft.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Dr. Ahmed Amin Elsheshtawy د أحمد أمين الششتاوى جودة , Ph.D. EE support[ at ]mewsoft.com
L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
	