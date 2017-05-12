package File::MMagic::XS;
use strict;
use warnings;
use XSLoader;

our $VERSION;
our $MAGIC_FILE;

BEGIN
{
    $VERSION = '0.09008';
    XSLoader::load(__PACKAGE__, $VERSION);

    require File::Spec;
    foreach my $path (map { File::Spec->catfile($_, qw(File MMagic magic)) } @INC) {
        if (-f $path) {
            $MAGIC_FILE = $path;
            last;
        }
    }
}

sub import
{
    my $class = shift;

    for(my $idx = 0; $idx < @_; $idx++) {
        if ($_[$idx] eq ':compat') {
            *checktype_filename   = \&get_mime;
            *checktype_filehandle = \&fhmagic;
            *checktype_contents   = \&bufmagic;
            *addMagicEntry        = \&add_magic;

            splice(@_, $idx, 1) and last;
        }
    }

    $class->SUPER::import(@_);
}

sub new {
    my ($class, $magic_file) = @_;
    $magic_file ||= $MAGIC_FILE;

    my $self = $class->_create();
    $self->parse_magic_file( $magic_file );
    return $self;
}

1;

__END__

=head1 NAME

File::MMagic::XS - Guess File Type With XS (a la mod_mime_magic)

=head1 SYNOPSIS

  use File::MMagic::XS;

  my $m = File::MMagic::XS->new();
     $m = File::MMagic::XS->new('/etc/magic'); # use external magic file

  my $mime = $m->get_mime($file);

  # use File::MMagic compatible interface
  use File::MMagic::XS qw(:compat);

  my $m = File::MMagic::XS->new();
  $m->checktype_filename($file);

=head1 DESCRIPTION

This is a port of Apache2 mod_mime_magic.c in Perl, written in XS with the
aim of being efficient and fast, especially for applications that need to be 
run for an extended amount of time.

There is a compatibility layer for File::MMagic. you can specify :compat
when importing the module

   use File::MMagic::XS qw(:compat);

And then the following methods are going to be available from File::MMagic::XS:

   checktype_filename
   checktype_filehandle
   checktype_contents
   addMagicEntry

Currently this software is in beta. If you have suggestions/recommendations 
about the interface or anything else, now is your chance to send them!

=head1 METHODS

=head2 new(%args)

Creates a new File::MMagic::XS object.

If you specify the C<file> argument, then File::MMagic::XS will load magic
definitions from the specified file. If unspecified, it will use the magic
file that will be installed under File/MMagic/ directory.

=head2 clone()

Clones an existing File::MMagic::XS object.

=head2 parse_magic_file($file)

Read and parse a magic file, as used by Apache2.

=head2 get_mime($file)

Inspects the file specified by C<$file> and returns a MIME type if possible.
If no matching MIME type is found, then undef is returned.

=head2 fsmagic($file)

Inspects a file and returns a MIME type using inode information only. The
contents of the file is not inspected.

=head2 fhmagic($fh)

Inspects a file handle and returns a mime string by reading the contents
of the file handle.

=head2 ascmagic($file)

Inspects a piece of data (assuming it's not binary data), and attempts to
determine the file type.

=head2 bufmagic($scalar)

Inspects a scalar buffer, and attempts to determine the file type

=head2 add_magic($magic_line)

Adds a new magic entry to the object. The format of $magic_line is the same
as magic(5) file. This allows you to add custom magic entries at run time

=head2 add_file_ext($ext, $mime)

Adds a new file extension to MIME mapping. This is used as a fallback method
to determining MIME types. 

  my $magic = File::MMagic::XS->new;
  $magic->add_file_ext('t', 'text/perl-test');
  my $mime  = $magic->get_mime('t/01-sanity.t');

This will make get_mime() return 'text/perl-test'.

=head2 error()

Returns the last error string.

=head1 PERFORMANCE

This is on my laptop (MacBook, Core 2 Duo/ Mac OS X 10.4.3), tested against
File::MMagic::XS 0.09003

          Rate  perl    xs
  perl   513/s    --  -96%
  xs   12048/s 2249%    --

=head1 SEE ALSO

L<File::MMagic|File::MMagic>

=head1 AUTHOR

Copyright 2005-2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>.

Underlying software: Copyright 1999-2004 The Apache Software Foundation, Copyright (c) 1996-1997 Cisco Systems, Inc., Copyright (c) Ian F. Darwin, 1987. Written by Ian F. Darwin.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
