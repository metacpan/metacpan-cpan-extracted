
package Docclient;

use IO::Handle;
use RPC::PlClient;
use Docclient::Config;

use strict;
use vars qw( $errstr $DEBUG );

$Docclient::VERSION = '1.0';

$DEBUG = 0;
sub debug ($) {
	return unless $DEBUG;
	my $txt = shift; $txt =~ s/([^\n])$/$1\n/; print STDERR $txt;
}

sub new {
	my $class = shift;
	my %options = ( %Docclient::Config::Config, @_ );

	my %serveroptions;
	$serveroptions{'peeraddr'} = ( $options{'host'} or $options{'server'});
	$serveroptions{'peerport'} = $options{'port'};
	$serveroptions{'version'} = 0.972;	# required server version
	$serveroptions{'logfile'} = undef;
	### $serveroptions{'debug'} = 10;

	my $self;

	eval {
		debug "Connecting to server $serveroptions{'peeraddr'}:$serveroptions{'peerport'}";
		my $client = eval { RPC::PlClient->new(
			%serveroptions,
			### 'ServerClass' => 'Docserver::Srv',
			'application' => 'Docserver::Srv',
			); }
			or die "$@\n";

		debug 'Requesting Docserver';
		my $obj = eval { $client->ClientObject('Docserver', 'new'); };
		if ($@) {
			my ($stderr) = $client->Call('errstr');
			die $stderr;
		}
		debug 'Negotiating chunk size';
		my $ChunkSize = $obj->preferred_chunk_size($options{'ChunkSize'});
		$self = bless {
			%options,
			'obj' => $obj,		
			'ChunkSize' => $ChunkSize,
		}, $class;
	};
	if ($@) {
		$errstr = $@; return;
	}
	$self;
}

sub put_file {
	my ($self, $fh, $file, $size) = @_;
	my $obj = $self->{'obj'};

	if (not defined $size) { $size = -1; }

	eval {
		debug "Processing $file (size $size)";
		$obj->input_file_length($size);

		my $buflen = $self->{'ChunkSize'};
		debug "Setting chunk size to $buflen";
		my $written = 0;
		while ($size < 0 or $written < $size) {
			my $buffer;
			my $out = $fh->read($buffer, $buflen);
			if ($out == 0) {
				debug "Strange: read returned 0 after reading $written bytes\n";
				last;
			}
			$written += $out;

		$obj->put($buffer);
			}
		debug "Written $written bytes";	
		return 1;
	};

	if ($@) {
		$self->{'errstr'} = "Error occured: $@";
	}
	return;
}

sub put_scalar {
	my ($self, $data) = @_;
	my $obj = $self->{'obj'};
	my $size = length $data;

	eval {
		debug "Processing scalar data (size $size)";
		$obj->input_file_length($size);

		my $buflen = $self->{'ChunkSize'};
		debug "Setting chunk size to $buflen";
		my $i = 0;
		while ($i < $size) {
			$obj->put(substr($data, $i, $buflen));
			$i += $buflen;
		}
		return 1;
	};

	if ($@) {
		$self->{'errstr'} = "Error occured: $@";
	}
	return;
}

sub convert {
	my ($self, $in_format, $out_format) = @_;
	my $obj = $self->{'obj'};
	debug "Calling convert($in_format, $out_format)";
	$obj->convert($in_format, $out_format)
		or do { $self->{'errstr'} = $obj->errstr; return; };
	return 1;
}

sub get_to_file {
	my ($self, $fh) = @_;
	debug "Calling get_to_file($fh)";
	my $obj = $self->{'obj'};
	my $buflen = $self->{'ChunkSize'};

	my $result_length = $obj->result_length;
	debug "Result length is $result_length\n";

	my $read = 0;
	while ($read < $result_length) {
		my $buffer = $obj->get($buflen);
		if (length $buffer == 0) {
			debug "Strange: read returned 0 after reading $read bytes\n";
			last;
		}
		$read += length $buffer;
		$fh->print($buffer);
	}
	return 1;
}

sub get_to_scalar {
	my ($self, $fh) = @_;
	my $obj = $self->{'obj'};
	my $buflen = $self->{'ChunkSize'};

	my $result_length = $obj->result_length;
	debug "Result length is $result_length\n";

	my $result = '';
	my $read = 0;
	while ($read < $result_length) {
		my $buffer = $obj->get($buflen);
		if (length $buffer == 0) {
			debug "Strange: read returned 0 after reading $read bytes\n";
			last;
		}
		$read += length $buffer;
		$result .= $buffer;
	}
	$result;
}

sub finished {
	shift->{'obj'}->finished;
}

sub DESTROY {
	shift->finished;
}

sub errstr {
	my $self = shift;
	if (ref $self) { return $self->{'errstr'} }
	return $Docclient::errstr;
}

sub server_version {
	shift->{'obj'}->server_version;
}


1;

=head1 NAME

Docclient.pm - client module for remote MS format conversions

=head1 SYNOPSIS

	my $docclient = new Docclient(
		'host' => 'machine.domain.cz',
		'port' => 6745,
		) or die $Docclient::errstr;
	my $filename = 'word.doc';
	open FILE, $filename or die "Error reading $filename: $!\n";
	binmode FILE;
	$docclient->put_file(*FILE);
	close FILE;
	$docclient->convert('doc', 'txt') or die $docclient->errstr;
	my $text = $docclient->get_to_scalar;
	$docclient->finished;

=head1 DESCRIPTION

Docclient is a client part of a tool that makes it easy to send
a Word or Excel document to a Win* machine, open the module with
a native application and convert it using that proprietary software
to readable form, then deliver the converted document back to the
client machine. On the server machine, a Docserver application
(usually docserver.pl program) has to be running.

From the comment line, you probably want to use the docclient.pl
script, but in case you want to write your own conversion tool or
want to use this inside of a bigger application, here's how:

=head2 METHODS

=over 4

=item new

First you create new Docclient object. You tell it what server machine
and port to use and it tries to connect to the server.
Parameters are passed as hash and are B<host> for the server machine
name and B<port> for TCP port the server is running on. The dafault is
stored in Docclient/Config.pm file, so you can have site-wide defaults
and only specify these parameters when you have to achieve something
special.

If the new method fails (usually becaue it was not able to connect to
the server), it returns undef and the error message is stored in the
$Docclient::errstr string.

After you've got your Docclient object, you can call methods on it.
You need to send your input document to the server, then run
a conversion or series of conversions and then retrieve the result
back from server.

=item put_scalar

If you've got the doc document in a perl scalar (because you've read
it from the CGI upload or so), you can call put_scalar with one
parameter being the document, and this method sends the document to
the server. If there is a error during the tramsmit, it can be
retrieved via $docclient->errstr method.

=item put_file

If you have the file on the disk (not read to perl scalar yet, just a
filehandle), you can use put_file with the filehandle as an argument.
It sends the data to the server just as put_scalar would.

=item convert

When you've got the input data on the server, you want to call convert
which will actually initiate the conversion on the server machine. The
convert method accepts two parameters, input_format and output_format.
You need to tell the convertor what format you think the file is in
and in what format you expect it back.

Possible values for input_format are doc, xls or csv, for
output_format you can use txt, rft, doc6, doc95, html, ps and ps1
for Word documents and txt, csv, prn, xls5, xls95, html, ps and ps1
for Excel documents. Please note that availability of individual
formats depends on the versions of the MS software on the server. For
example, if you have old versions, they may not support the formats,
or if you don't have PostScript printer driver installed, you won't be
able to produce PostScript output.

Upon error, B<convert> returns false and error message can be fetched
using $docclient->errstr method.

=item get_to_scalar

After the conversion was successfully finished, you retrieve the
result to a scalar by calling get_to_scalar method (without any
parameters).

=item get_to_file

You may prefer to directly send the result to output file, use
get_to_file with a filehandle parameter.

=item finished

After you've done with the file, call finished to clean after yourself
on the server side.

After you've sent the file to the server (using put_file or put_scalar
methods), you can call convert (and subsequent get_to_* methods) with
various parameters many times to get different output formats for
single file. Method B<finished> deletes the temporary file on the
server.

=back

=head1 VERSION

This documentation is believed to describe reasonably accurately
version 1.0 of Docclient.

=head1 AUTHOR

(c) 1998--2002 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University in Brno, Czech Republic

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

docclient(1), docserver(1), Docserver(3), Win32::OLE(3),
Win32::API(3)

=cut

