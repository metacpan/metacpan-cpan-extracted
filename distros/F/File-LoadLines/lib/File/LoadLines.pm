#! perl

package File::LoadLines;

use warnings;
use strict;
use Exporter qw(import);
our @EXPORT = qw( loadlines );
our @EXPORT_OK = qw( loadblob );
use Encode;
use Carp;
use utf8;

=head1 NAME

File::LoadLines - Load lines from files and network 

=cut

our $VERSION = '1.045';

=head1 SYNOPSIS

    use File::LoadLines;
    my @lines = loadlines("mydata.txt");

    use File::LoadLines qw(loadblob);
    my $img = loadblob("https://img.shields.io/badge/Language-Perl-blue");

=head1 DESCRIPTION

File::LoadLines provides an easy way to load the contents of a text
file into an array of lines. It is intended for small to moderate size files
like config files that are often produced by weird tools (and users).

It will transparantly fetch data from the network if the provided file
name is a URL.

File::LoadLines automatically handles ASCII, Latin-1 and UTF-8 text.
When the file has a BOM, it handles UTF-8, UTF-16 LE and BE, and
UTF-32 LE and BE.

Recognized line terminators are NL (Unix, Linux), CRLF (DOS, Windows)
and CR (Mac)

Function loadblob(), exported on depand, fetches the content and
returns it without processing, equivalent to File::Slurp and ilk.

=head1 EXPORT

By default the function loadlines() is exported.

=head1 FUNCTIONS

=head2 loadlines

    @lines = loadlines("mydata.txt");
    @lines = loadlines("mydata.txt", $options);

The file is opened, read, decoded and split into lines
that are returned in the result array. Line terminators are removed.

In scalar context, returns an array reference.

The first argument may be the name of a file, an opened file handle,
or a reference to a string that contains the data.
The name of a file on disk may start with C<"file://">, this is ignored.
If the name starts with C<"http:"> or C<"https:"> the data will be
retrieved using LWP.
L<Data URLs|https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs> like C<"data:text/plain;base64,SGVsbG8sIFdvcmxkIQ=="> are
also supported.

The second argument can be used to influence the behaviour.
It is a hash reference of option settings.

Note that loadlines() is a I<slurper>, it reads the whole file into
memory and, for splitting, requires temporarily memory for twice the
size of the file.

=over

=item split

Enabled by default.

The data is split into lines and returned as an array (in list
context) or as an array reference (in scalar context).

If set to zero, the data is not split into lines but returned as a
single string.

=item chomp

Enabled by default.

Line terminators are removed from the resultant lines.

If set to zero, the line terminators are not removed.

=item encoding

If specified, loadlines() will use this encoding to decode the file
data if it cannot automatically detect the encoding.

If you pass an options hash, File::LoadLines will set C<encoding> to
the encoding it detected and used for this file data.

=item blob

If specified, the data read is not touched but returned exactly as read.

C<blob> overrules C<split> and C<chomp>.

=item fail

If specified, it should be either C<"hard"> or C<"soft">.

If C<"hard">, read errors are signalled using croak exceptions.
This is the default.

If set to C<"soft">, loadlines() will return an empty result and set
the error message in the options hash with key C<"error">.

=back

=cut

sub loadlines {
    my ( $filename, $options ) = @_;
    croak("Missing filename.\n") unless defined $filename;
    croak("Invalid options.\n")  if (defined $options && (ref($options) ne "HASH"));

    $options->{blob}  //= 0;
    $options->{split} //= !$options->{blob};
    $options->{chomp} //= !$options->{blob};

    my $data;			# slurped file data
    my $encoded;		# already encoded

    # Gather data from the input.
    if ( ref($filename) ) {
	if ( ref($filename) eq 'GLOB' ) {
	    binmode( $filename, ':raw' );
	    $data = do { local $/; <$filename> };
	    $filename = "__GLOB__";
	}
	else {
	    $data = $$filename;
	    $filename = "__STRING__";
	    $encoded++;
	}
    }
    elsif ( $filename eq '-' ) {
	$filename = "__STDIN__";
	binmode( STDIN, ':raw' );
	$data = do { local $/; <STDIN> };
    }
    elsif ( $filename =~ /^https?:/ ) {
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new( timeout => 20 );
	my $res = $ua->get($filename);
	if ( $res->is_success ) {
	    $data = $res->decoded_content;
	}
	elsif ( $options->{fail} eq "soft" ) {
	    $options->{error} = $res->status_line;
	    return;
	}
	else {
	    croak("$filename: ", $res->status_line);
	}
    }
    elsif ( $filename =~ /^data:/ ) {
	unless ( $filename =~ m! ^ data:
				 (?<mediatype> .*? )
				 ,
				 (?<data>      .*  ) $
			  !sx ) {
	    if ( $options->{fail} eq "soft" ) {
		$options->{error} = "Malformed inline data";
		return;
	    }
	    else {
		croak("Malformed inline data");
	    }
	}
	$data = $+{data};
	$filename = "__DATA__";
	my $mediatype = $+{mediatype};
	my $enc = "";
	if ( $mediatype && $mediatype =~ /^(.*);base64$/ ) {
	    $mediatype = $1;
	    $enc = "base64";
	}
	$options->{mediatype} = $mediatype if $mediatype;
	if ( ! $enc ) {
	    # URL encoded.
	    $data = $+{data};
	    $data =~ s/\%([0-9a-f][0-9a-f])/chr(hex($1))/ige;
	}
	else {
	    # Base64.
	    require MIME::Base64;
	    $data = MIME::Base64::decode($data);
	}
	if ( $mediatype && $mediatype =~ /;charset=([^;]*)/ ) {
	    $data = decode( $1, $data );
	    $options->{encoding} = $1;
	    $encoded++;
	}
    }
    else {
	my $name = $filename;
	$name =~ s;^file://;;;
	$filename = decode_utf8($name);
	# On MS Windows, non-latin (wide) filenames need special treatment.
	if ( $filename ne $name && $^O =~ /mswin/i ) {
	    require Win32API::File;
	    my $fn = encode('UTF-16LE', "$filename").chr(0).chr(0);
	    my $fh = Win32API::File::CreateFileW
	      ( $fn, Win32API::File::FILE_READ_DATA(), 0, [],
		Win32API::File::OPEN_EXISTING(), 0, []);
	    croak("$filename: $^E (Win32)\n") if $^E;
	    unless ( Win32API::File::OsFHandleOpen( 'FILE', $fh, "r") ) {
		$options->{error} = "$!", return if $options->{fail} eq "soft";
		croak("$filename: $!\n");
	    }
	    binmode FILE => ':raw';
	    $data = do { local $/; readline(\*FILE) };
	    # warn("$filename³: len=", length($data), "\n");
	    close(FILE);
	}
	else {
	    my $f;
	    unless ( open( $f, '<:raw', $filename ) ) {
		$options->{error} = "$!", return if $options->{fail} eq "soft";
		croak("$filename: $!\n");
	    }
	    $data = do { local $/; <$f> };
	}
    }
    $options->{_filesource} = $filename if $options;

    my $name = encode_utf8($filename);
    if ( $options->{blob} ) {
	# Do not touch.
	$options->{encoding} = 'Blob';
    }
    elsif ( $encoded ) {
	# Nothing to do, already dealt with.
	$options->{encoding} //= 'Perl';
    }

    # Detect Byte Order Mark.
    elsif ( $data =~ /^\xEF\xBB\xBF/ ) {
	warn("$name is UTF-8 (BOM)\n") if $options->{debug};
	$options->{encoding} = 'UTF-8';
	$data = decode( "UTF-8", substr($data, 3) );
    }
    elsif ( $data =~ /^\xFE\xFF/ ) {
	warn("$name is UTF-16BE (BOM)\n") if $options->{debug};
	$options->{encoding} = 'UTF-16BE';
	$data = decode( "UTF-16BE", substr($data, 2) );
    }
    elsif ( $data =~ /^\xFF\xFE\x00\x00/ ) {
	warn("$name is UTF-32LE (BOM)\n") if $options->{debug};
	$options->{encoding} = 'UTF-32LE';
	$data = decode( "UTF-32LE", substr($data, 4) );
    }
    elsif ( $data =~ /^\xFF\xFE/ ) {
	warn("$name is UTF-16LE (BOM)\n") if $options->{debug};
	$options->{encoding} = 'UTF-16LE';
	$data = decode( "UTF-16LE", substr($data, 2) );
    }
    elsif ( $data =~ /^\x00\x00\xFE\xFF/ ) {
	warn("$name is UTF-32BE (BOM)\n") if $options->{debug};
	$options->{encoding} = 'UTF-32BE';
	$data = decode( "UTF-32BE", substr($data, 4) );
    }

    # No BOM, did user specify an encoding?
    elsif ( $options->{encoding} ) {
	warn("$name is ", $options->{encoding}, " (fallback)\n")
	  if $options->{debug};
	$data = decode( $options->{encoding}, $data, 1 );
    }

    # Try UTF8, fallback to ISO-8895.1.
    else {
	my $d = eval { decode( "UTF-8", $data, 1 ) };
	if ( $@ ) {
	    warn("$name is ISO-8859.1 (assumed)\n") if $options->{debug};
	    $options->{encoding} = 'ISO-8859-1';
	    $data = decode( "iso-8859-1", $data );
	}
	elsif ( $d !~ /[^[:ascii:]]/ ) {
	    warn("$name is ASCII (detected)\n") if $options->{debug};
	    $options->{encoding} = 'ASCII';
	    $data = $d;
	}
	else {
	    warn("$name is UTF-8 (detected)\n") if $options->{debug};
	    $options->{encoding} = 'UTF-8';
	    $data = $d;
	}
    }

    # This can be used to add line continuation or comment stripping.
    if ( $options->{strip} ) {
	$data =~ s/$options->{strip}//g;
    }

    return $data unless $options->{split};

    # Split in lines;
    my @lines;
    if ( $options->{chomp} ) {
	# Unless empty, make sure there is a final newline.
	$data .= "\n" if $data =~ /.(?!\r\n|\n|\r)\z/;
	# We need to maintain trailing newlines.
	push( @lines, $1 ) while $data =~ /(.*?)(?:\r\n|\n|\r)/g;
    }
    else {
	push( @lines, $1 ) while $data =~ /(.*?(?:\r\n|\n|\r))/g;
	# In case the last line has no terminator.
	push( @lines, $1 ) if $data =~ /(?:\r\n|\n|\r)([^\r\n]+)\z/;
    }
    undef $data;
    return wantarray ? @lines : \@lines;
}

=head2 loadblob

    use File::LoadLines qw(loadblob);
    $rawdata = loadblob("raw.dat");
    $rawdata = loadblob("raw.dat", $options);

This is equivalent to calling loadlines() with C<< blob=>1 >> in the options.

=cut

sub loadblob {
    my ( $filename, $options ) = @_;
    croak("Missing filename.\n") unless defined $filename;
    croak("Invalid options.\n")
      if defined($options) && ref($options) ne "HASH";
    $options //= {};
    $options->{blob} = 1;
    loadlines( $filename, $options );
}

=head1 SEE ALSO

There are currently no other modules that handle BOM detection and
line splitting.

I have a faint hope that future versions of Perl and Raku will deal
with this transparently, but I fear the worst.

=head1 HINTS

When you have raw file data (e.g. from a zip), you can use loadlines()
to decode and unpack:

    open( my $data, '<', \$contents );
    $lines = loadlines( $data, $options );

There is no hard requirement on LWP. If you want to use transparent
fetching of data over the network please make sure LWP::UserAgent is
available.

=head1 AUTHOR

Johan Vromans, C<< <JV at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-File-LoadLines.

You can find documentation for this module with the perldoc command.

    perldoc File::LoadLines

Please report any bugs or feature requests using the issue tracker on
GitHub.

=head1 COPYRIGHT & LICENSE

Copyright 2018,2020,2024 Johan Vromans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of File::LoadLines
