package File::Fingerprint;
use strict;

use warnings;
no warnings;

use Carp;

our $VERSION = '0.104';

=encoding utf8

=head1 NAME

File::Fingerprint - Identify a file by its checksums and other attributes

=head1 SYNOPSIS

	use File::Fingerprint;

	my $fingerprint = File::Fingerprint->roll( $file );

=head1 DESCRIPTION

=over 4

=cut

=item roll

=cut

sub roll {
	my( $class, $file ) = @_;

	unless( -e $file ) {
		carp "File [$file] does not exist! Can't fingerprint it";
		return;
		}

	my $self = bless { file => $file }, $class;

	$self->init;
	}

=item init

=cut

BEGIN {

my %Prints = (
	md5       => sub { require MD5; my $ctx = MD5->new; $ctx->add( $_[0]->file ); $ctx->hexdigest },

	mmagic    => sub { require File::MMagic; File::MMagic->new->checktype_filename( $_[0]->file ) },
#	mime_info => sub { require File::MimeInfo; File::MimeInfo::mimetype( $_[0]->file ) },

	extension => sub { my @b = split /\./, $_[0]->file; shift @b; [ @b ] },
	size      => sub { -s $_[0]->file },
	stat      => sub { [ stat $_[0]->file ] },
	lines     => sub { open my($fh), "<", $_[0]->file; 1 while( <$fh> ); $. },
	crc16     => sub { require Digest::CRC; my $ctx = Digest::CRC->new( type => 'crc16' ); open my($fh), "<", $_[0]->file; $ctx->addfile( $fh ); $ctx->hexdigest; },
	crc32     => sub { require Digest::CRC; my $ctx = Digest::CRC->new( type => 'crc32' ); open my($fh), "<", $_[0]->file; $ctx->addfile( $fh ); $ctx->hexdigest; },
	basename  => sub { require File::Basename; File::Basename::basename( $_[0]->file ) },
	);

sub init {
	my( $self ) = shift;

	print "File is ", $self->file, "\n";

	foreach my $print ( keys %Prints ) {
		$self->{$print} = eval { $self->$print() };
		carp "Error is $@\n" if $@;
		}

	return $self;
	}

sub AUTOLOAD {
	our $AUTOLOAD;

	( my $method = $AUTOLOAD ) =~ s/.*:://;

	carp "No such method as $AUTOLOAD" unless exists $Prints{$method};

	return $_[0]->{$method} || $Prints{$method}->( $_[0] );
	}

}

sub DESTROY { 1 }

=item file

Returns the filename of the fingerprinted file. This is the same path
passed to C<roll>.

=cut

sub file { $_[0]->{file} }

=item md5

=item mmagic

Return the MIME type of the file, as determined by File::MMagic. For
instance, C<text/plain>.

=item basename

Returns the basename of the file.

=item extension

Returns the file extensions as an array reference.

For instance, F<stable.tar.gz> returns C<[ qw(tar gz) ]>.

=item size

Returns the file size, in bytes.

=item stat

Returns that stat buffer. This is the array reference of all of the values
returned by C<stat>.

=item lines

Returns the line count of the file.

=item crc16

Returns the CRC-16 checksum of the file.

=item crc32

Returns the CRC-32 checksum of the file.

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github

	https://github.com/briandfoy/file-fingerprint.git

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2024, brian d foy <briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
