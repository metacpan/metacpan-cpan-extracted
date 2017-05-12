package File::Headerinfo;

use strict;
use Carp;

use vars qw( $VERSION $AUTOLOAD );
$VERSION = '0.03';

=head1 NAME

File::Headerinfo - a general purpose extractor of header information from media files. Can handle most image, video and audio file types.

=head1 SYNOPSIS

  use File::Headerinfo;
  my $headerdata = File::Headerinfo->read('/path/to/file.ext');

  or
  
  my $reader = File::Headerinfo->new;
  my %filedata = map { $_ => $reader->read($_) } @files;  
  
=head1 DESCRIPTION

I<File::Headerinfo> is little more than a collection of wrappers around existing modules like MP3::Info and Image::Size. It gathers them all behind a simple, friendly interface and offers an easy way to get header information from almost any kind of media file.

The main Headerinfo modules is a very simple factory class: the real work is done by a set of dedicated subclasses each able to read a different sort of file. A dispatch table in the factory class maps each file suffix onto the subclass that can read that kind of file.

In normal use that minor complexity is hidden from view: all you have to do is pass a file to the read() method and it will do the right thing.

=head1 METHODS

=head2 read( $path, $type)

Examines the file we have been supplied with, creates an object of the appropriate class and tells it to examine the file. 

Loading of the subclasses is deferred until it's necessary, as some of them use quite chunky modules to do the file-reading work for them.

You can force a file to be treated as a particular type by supplying the appropriate three or four letter file suffix as a second parameter:

  my $fileinfo = File::Headerinfo->read('/path/to/file', 'mpeg');

=cut

sub read {
    my $base = shift;
    my $class = $base->subclass(@_);
    return unless $class;
    eval "require $class;";
    Carp::croak($@) if $@;
    my $self = $class->new(@_);
    $self->parse_file;
    return $self->report;
}

=head2 new()

A very simple constructor that is rarely called directly. It is inherited by all the specific-format subclasses, so you could do this:

  my $reader = File::Headerinfo::SWF->new('/path/to/file.swf');
  $reader->parse_file;
  my $report = $reader->report;

but needn't bother, since the same thing is achieved by writing:

  my $report = File::Headerinfo->read('/path/to/file.swf');

=cut

sub new {
    my $class = shift;
    return bless {
        _path => $_[0],
    }, $class;
}

=head2 path()

Gets or sets the full path to the file we're trying to examine.

=cut

sub path {
    my $self = shift;
    return $self->{_path} = $_[0] if @_;
    return $self->{_path};
}

=head2 subclass( $path, $type )

Identifies the subclass (or other class) that is meant to read files of the type supplied.

=cut

sub subclass {
    my ($base, $path, $type) = @_;
    return unless $path;
    my $media_classes = $base->media_classes;
    my $class = $media_classes->{ $type || _suffix($path) } or $base->default_media_class;
    return $class;
}

=head2 _suffix( $path )

Not a method: just a useful helper. Returns the file suffix, with no dot. Useful if we have no other way of identifying the file type.

=cut

sub _suffix {
	my $path = shift;
    $path =~ /\.(\w+)$/;
    return $1;
}

=head2 parse_file()

Each format-specific subclass has its own way of parsing the media file. This is just a placeholder.

=cut

sub parse_file { 
    Carp::croak("File::Headerinfo::parse_file should not be called directly: use the right subclass for your file.");
}

=head2 media_classes()

Returns a hashref that maps media types onto class names. The types can come from stored information or from the suffix of the file.

=cut

sub media_classes {
    return {
        gif => 'File::Headerinfo::Image',
        jpg => 'File::Headerinfo::Image',
        jpeg => 'File::Headerinfo::Image',
        png => 'File::Headerinfo::Image',
        mng => 'File::Headerinfo::Image',
        xbm => 'File::Headerinfo::Image',
        xpm => 'File::Headerinfo::Image',
        tif => 'File::Headerinfo::Image',
        tiff => 'File::Headerinfo::Image',
        psd => 'File::Headerinfo::Image',
        ppm => 'File::Headerinfo::Image',
        mp3 => 'File::Headerinfo::MP3',
        wav => 'File::Headerinfo::WAV',
        swf => 'File::Headerinfo::SWF',
        mov => 'File::Headerinfo::Video',
        moov => 'File::Headerinfo::Video',
        aiff => 'File::Headerinfo::Video',
        mpeg => 'File::Headerinfo::Video',
        mpg => 'File::Headerinfo::Video',
        asf => 'File::Headerinfo::Video',
        avi => 'File::Headerinfo::Video',
        divx => 'File::Headerinfo::Video',
        dvx => 'File::Headerinfo::Video',
    };
}

=head2 default_media_class()

returns the class name we'll try to use if we can't think of anything else.

=cut

sub default_media_class { 'File::Headerinfo::Video' }

=head2 fields()

Defines the list of parameters that will be provided by each subclass, which is currently: height, width, duration, filetype, fps, filesize, freq, datarate, vcodec, metadata.

This list is used by AUTOLOAD to create get and set methods, and by report to build its hash of discovered values. It can be overridden by the format-specific subclass if it needs to be extended, but no harm will come from having unused fields here.

=cut

sub fields {
    return qw(height width duration filetype freq fps filesize datarate vcodec metadata version);
}

=head2 allowed_field( $fieldname )

Returns true if the supplied value is in the list of allowed fields.

=cut

sub allowed_field {
	my ($self, $f) = @_;
    my %fields = map {$_ => 1 } $self->fields;
    return $fields{$f};
}

=head2 report()

Returns a hashref containing all the available file information. This method is usually called by read() to return everything at once.

=cut

sub report {
	my $self = shift;
	my %report = map { $_ => $self->$_() } $self->fields;
	return \%report;
}

sub AUTOLOAD {
	my $self = shift;
	my $field = $AUTOLOAD;
	$field =~ s/.*://;
    return unless $self->allowed_field($field);
    return $self->{$field} = $_[0] if @_;
    return $self->{$field};
}

=head1 COPYRIGHT

Copyright 2004 William Ross (wross@cpan.org)

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;