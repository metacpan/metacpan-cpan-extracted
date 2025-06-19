package JSON::Lines;
use 5.006; use strict; use warnings; our $VERSION = '1.09';
use Cpanel::JSON::XS; use base 'Import::Export';

our ($JSON, $LINES, %EX);
BEGIN {
	$JSON = Cpanel::JSON::XS->new;
	$LINES = qr{ ([\[\{] (?: (?> [^\[\]\{\}]+ ) | (??{ $LINES }) )* [\]\}]) }x;
	%EX = (
		jsonl => [qw/all/]
	);
}

sub jsonl {
	my %args = (scalar @_ == 1 ? %{$_[0]} : @_);
	my $self = __PACKAGE__->new(%args);
	return $args{file} 
		? $self->encode_file($args{file}, $args{data}) 
		: $self->encode($args{data}) 
	if ($args{encode});
	return $args{file}
		? $self->decode_file($args{file})
		: $self->decode($args{data})
	if ($args{decode});
}

sub new {
	my ($pkg, %args) = (shift, scalar @_ == 1 ? %{$_[0]} : @_);
	my $self = bless { headers => [] }, $pkg;
	exists $args{$_} && $JSON->$_($args{$_}) for qw/pretty canonical utf8/;
	$self->{$_} = $args{$_} for qw/parse_headers error_cb success_cb/;
	$self;
}

sub encode {
	my ($self, @data) = (shift, scalar @_ == 1 ? @{$_[0]} : @_);
	@data = $self->_parse_headers(@data) 
		if ($self->{parse_headers});
	my $stream;
	for (@data) {
		my $json = eval { $JSON->encode($_) };
		if ($@) {
			if ($self->{error_cb}) {
				$self->{error_cb}->('encode', $@, $_);
			} else {
				die $@;
			}
		} else {
			$self->{success_cb}->('encode', $json, $_) if $self->{success_cb};
			$stream .= $json . ($json =~ m/\n$/ ? "" : "\n");
		}
	}
	return $self->{stream} = $stream;
}

sub encode_file {
	my ($self, $file) = (shift, shift);
	open my $fh, '>', $file;
	print $fh $self->encode(@_);
	close $fh;
	return $file;
}

sub decode {
	my ($self, $string) = @_;
	my @lines;
	push @lines, $self->_decode_line($_) 
		for ($string =~ m/$LINES/g);
	@lines = $self->_deparse_headers(@lines)
		if ($self->{parse_headers});
	return wantarray ? @lines : \@lines;
}

sub decode_file {
	my ($self, $file) = (shift, shift);
	open my $fh, '<', $file;
	my $content = do { local $/; <$fh> };
	close $fh;
	return $self->decode($content);
}

sub add_line {
	my ($self, $line, $fh) = @_;
	if (defined $fh) {
		print $fh $self->encode([$line]);
	} else {
		my $stream = $self->{stream};
		my $add = $self->encode([$line]);
		$self->{stream} =  $stream .  $add;
		$self->{stream};
	}
}

sub clear_stream {
	$_[0]->{stream} = '';
}

sub get_lines {
	my ($self, $fh, $lines) = @_;
	my @lines;
	for (1 .. $lines) {
		my $line = $self->get_line($fh);
		push @lines, $line;
		last if eof($fh);
	}
	return wantarray ? @lines : \@lines;
}

sub get_line {
	my ($self, $fh) = @_;
	my $line = '';
	$line .= <$fh> while ($line !~ m/^$LINES/ && !eof($fh));
	return undef if $line eq '' && eof($fh);
	return $self->_decode_line($line);
}

sub get_subset {
	my ($self, $fh, $offset, $length, $out_file) = @_;

	my $in_fh = 1;
	if (ref $fh ne 'GLOB') {
		my $file = $fh;
		open my $ffh, '<', $file or die "cannot open file: $!";
		$fh = $ffh;
		$in_fh = 0;
	}

	seek $fh, 0, 0;
	if ($offset) {
		<$fh> for ( 1 .. $offset );
	}
	my @lines;
	my $line = '';
	while ($offset <= $length) {
		do { $offset++; $line .= <$fh> } 
			while ($line !~ m/^$LINES/ && !eof($fh) && $offset <= $length);
		if ($line =~ m/^$LINES/) {
			push @lines, $line;
			$line = "";
		}
	}

	if (!$in_fh) {
		close $fh;
	}

	if ($out_file) {
		open my $cfh, '>', $out_file or die "cannot open file for writing: $!";
		print $cfh join "", @lines;
		close $cfh;
		return 1;
	}

	return [ 
		map { 
			$self->_decode_line($_);
		} @lines
	];
}

sub _decode_line {
	my ($self, $line) = @_;
	my $struct = eval { $JSON->decode($line) };
	if ($@) {
		if ($self->{error_cb}) {
			return $self->{error_cb}->('decode', $@, $line);
		} else {
			die $@;
		}
	}
	return $self->{success_cb}->('decode', $struct, $line) if $self->{success_cb};
	return $struct;
}

sub _parse_headers {
	my ($self, @data) = @_;
	my @headers = @{ $self->{headers} };
	unless (@headers) {
		if (ref $data[0] eq 'ARRAY') {
			@headers = @{ shift @data };
		} else {
			my %key_map;
			for (@data) {
				%key_map = (%key_map, %{$_});
			}
			@headers = sort keys %key_map;
		}
		$self->{headers} = \@headers;
	}
	my @body;
	for my $d (@data) {
		push @body, (ref $d eq 'ARRAY')
			? $d
			: [
				map {
					$d->{$_}
				} @headers
			];
	} 
	return (
		\@headers,
		@body
	);
}

sub _deparse_headers {
	my ($self, @data) = @_;
	return @data unless ref $data[0] eq 'ARRAY';
	my @headers = @{ shift @data };
	my @body;
	for my $d (@data) {
		my $i = 0;
		push @body, (ref $d eq 'HASH')
			? $d
			: {
				map {
					$_ => $d->[$i++]
				} @headers
			};
	}
 	return @body;
}

1;

__END__

=encoding utf8

=head1 NAME

JSON::Lines - Parse JSONLines with perl.

=head1 VERSION

Version 1.09

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use JSON::Lines;

	my $jsonl = JSON::Lines->new();

	my @data = (
		["Name", "Session", "Score", "Completed"],
		["Gilbert", "2013", 24, true],
		["Alexa", "2013", 29, true],
		["May", "2012B", 14, false],
		["Deloise", "2012A", 19, true]
	);

	my $string = $jsonl->encode(@data);

	my $file = $jsonl->encode_file('score.jsonl', @data);
	
	# ["Name", "Session", "Score", "Completed"]
	# ["Gilbert", "2013", 24, true]
	# ["Alexa", "2013", 29, true]
	# ["May", "2012B", 14, false]
	# ["Deloise", "2012A", 19, true]  

	...

	my $all = $jsonl->decode_file($file);

	open my $fh, '<', $file or die $!;
	while (my $line = $jsonl->get_line($fh)) {
		push @lines, $line;
	}
	close $fh;

	open my $fh, '<', $file or die $!;
	my @hundred_lines = $jsonl->get_lines($fh, 100);
	close $fh;

	...

	use JSON::Lines qw/jsonl/;

	my $data = [
		{
			"name" => "Gilbert", 
			"wins" => [
				["straight", "7♣"], 
				["one pair", "10♥"]
			]
		},
		{
			"name" => "Alexa", 
			"wins" => [
				["two pair", "4♠"], 
				["two pair", "9♠"]
			]
		},
		{
			"name" => "May", 
			"wins" => []
		},
		{
			"name" => "Deloise", 
			"wins" => [
				["three of a kind", "5♣"]
			]
		}
	];

	my $string = jsonl( canonical => 1, encode => 1, data => $data );

	# {"name": "Gilbert", "wins": [["straight", "7♣"], ["one pair", "10♥"]]}
	# {"name": "Alexa", "wins": [["two pair", "4♠"], ["two pair", "9♠"]]}
	# {"name": "May", "wins": []}
	# {"name": "Deloise", "wins": [["three of a kind", "5♣"]]}

	
=head1 DESCRIPTION

JSON Lines is a convenient format for storing structured data that may be processed one record at a time. It works well with unix-style text processing tools and shell pipelines. It's a great format for log files. It's also a flexible format for passing messages between cooperating processes.

L<https://jsonlines.org/>

=head1 EXPORT

=head2 jsonl

	my $string = jsonl( success_cb => sub { ... }, error_cb => sub { ... }, encode => 1, data => $aoh );

	my $aoa = jsonl( parse_headers => 1, decode => 1, data => $string )

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new JSON::Lines object.

	my $jsonl = JSON::Lines->new(
		success_cb => sub { if ($_[0] eq 'encode') { ... } },
		error_cb => sub { if ($_[0] eq 'decode') { ... } },
		canonical => 1,
		utf8 => 1,
		pretty => 1,
		parse_headers => 1
	);

=head3 success_cb

Callback called on successfull encode or decode of an item.

=head3 error_cb

Callback called on unsucessfull encode or decode of an item.

=head3 canonical

Print in canonical order.

=head3 utf8

utf8 encode/decode

=head3 pretty

Pretty print.

=head3 parse_headers

Parse the first line of the stream as headers.

=head2 encode

Encode a perl struct into a json lines string.

	$jsonl->encode( $data );

=head2 encode_file

Encode a perl struct into a json lines file.

	$jsonl->encode_file($file, $data);

=head2 decode

Decode a json lines string into a perl struct.

	$jsonl->decode( $string );

=head2 decode_file

Decode a json lines file into a perl struct.

	$jsonl->decode_file( $file );

=head2 add_line

Add a new line to the current JSON::Lines stream.

	$jsonl->add_line($line);

	$jsonl->add_line($line, $fh);

=head2 get_line

Decode a json lines file, one line at a time.

	open my $fh, "<", $file or die "$file: $!";
	my $line = $jsonl->get_line($fh);
	close $fh;

=head2 get_lines

Decode a json lines file, 'n' lines at a time.

	open my $fh, "<", $file or die "$file: $!";
	my @lines = $jsonl->get_lines($fh, 100);
	close $fh;

=head2 clear_stream

Clear the current JSON::Lines stream.

	$jsonl->clear_stream;

=head2 get_subset

Get a subset of JSON lines, optionally pass a file to write to.

	my $lines = $jsonl->get_subset($file, $offset, $length);

	$jsonl->get_subset($file, $offset, $length, $out_file);

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-json-lines at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-Lines>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc JSON::Lines

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-Lines>

=item * Search CPAN

L<https://metacpan.org/release/JSON-Lines>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

