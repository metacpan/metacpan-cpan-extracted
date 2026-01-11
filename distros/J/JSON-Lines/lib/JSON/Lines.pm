package JSON::Lines;
use 5.006; use strict; use warnings; our $VERSION = '1.11';
use Cpanel::JSON::XS; use base 'Import::Export';
our ($JSON, $LINES, $STRING, %EX);
BEGIN {
	$JSON = Cpanel::JSON::XS->new;
	$STRING = qr{ " (?> (?: [^"\\]++ | \\. )*+ ) " }x;
	$LINES = qr{ ( [\[\{] (?> (?: (?> [^\[\]\{\}"]++ ) | $STRING | (??{ $LINES }) )*+ ) [\]\}] ) }x;
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
	my $self = bless { headers => [], _buffer => '' }, $pkg;
	exists $args{$_} && $JSON->$_($args{$_}) for qw/pretty canonical utf8/;
	$self->{$_} = $args{$_} for qw/parse_headers error_cb success_cb/;
	$self;
}
sub pretty {
	my ($self, $val) = @_;
	return $JSON->get_indent if @_ == 1;
	$JSON->pretty($val);
	return $self;
}
sub canonical {
	my ($self, $val) = @_;
	return $JSON->get_canonical if @_ == 1;
	$JSON->canonical($val);
	return $self;
}
sub utf8 {
	my ($self, $val) = @_;
	return $JSON->get_utf8 if @_ == 1;
	$JSON->utf8($val);
	return $self;
}
sub parse_headers {
	my ($self, $val) = @_;
	return $self->{parse_headers} if @_ == 1;
	$self->{parse_headers} = $val;
	return $self;
}
sub error_cb {
	my ($self, $val) = @_;
	return $self->{error_cb} if @_ == 1;
	$self->{error_cb} = $val;
	return $self;
}
sub success_cb {
	my ($self, $val) = @_;
	return $self->{success_cb} if @_ == 1;
	$self->{success_cb} = $val;
	return $self;
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
	if (defined $self->{_buffer} && length $self->{_buffer}) {
		$string = $self->{_buffer} . $string;
		$self->{_buffer} = '';
	}
	my @lines;
	my $pos = 0;
	my $len = length($string);
	while ($pos < $len) {
		if ($string =~ m/\G[\s\n]+/gc) {
			$pos = pos($string);
			next;
		}
		my $remaining = substr($string, $pos);
		my ($obj, $chars_consumed, $regex_matched) = $self->_decode_one($remaining);
		if (defined $obj) {
			push @lines, $obj;
			$pos += $chars_consumed;
		} elsif ($regex_matched) {
			$pos += $chars_consumed if $chars_consumed > 0;
			$pos++ if $chars_consumed == 0;
		} else {
			if ($remaining =~ /^[\[\{]/) {
				$self->{_buffer} = $remaining;
				last;
			}
			if ($string =~ m/\G[^\[\{]+/gc) {
				$pos = pos($string);
			} else {
				$pos++;
			}
		}
		pos($string) = $pos;
	}
	@lines = $self->_deparse_headers(@lines)
		if ($self->{parse_headers});
	return wantarray ? @lines : \@lines;
}
sub remaining {
	my ($self) = @_;
	return $self->{_buffer} // '';
}
sub clear_buffer {
	my ($self) = @_;
	$self->{_buffer} = '';
	return $self;
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
	$self->{_line_buffer} //= [];
	if (@{$self->{_line_buffer}}) {
		return shift @{$self->{_line_buffer}};
	}
	my $line = '';
	$line .= <$fh> while ($line !~ m/^$LINES/ && !eof($fh));
	return undef if $line eq '' && eof($fh);
	my @objects = $self->decode($line);
	return undef unless @objects;
	my $first = shift @objects;
	push @{$self->{_line_buffer}}, @objects;
	return $first;
}
sub get_line_at {
	my ($self, $fh, $index, $seek) = @_;
	my $fh_id = fileno($fh);
	my ($target_line, $target_offset) = $index =~ /:/
		? split(/:/, $index)
		: ($index, 0);
	$self->{_line_pos} //= {};
	$self->{_parsed_lines} //= {};
	if ($seek) {
		seek $fh, 0, 0;
		$self->{_line_pos}{$fh_id} = 0;
		$self->{_parsed_lines}{$fh_id} = {};
	}
	$self->{_line_pos}{$fh_id} //= 0;
	$self->{_parsed_lines}{$fh_id} //= {};
	if ($target_line < $self->{_line_pos}{$fh_id}) {
		seek $fh, 0, 0;
		$self->{_line_pos}{$fh_id} = 0;
		$self->{_parsed_lines}{$fh_id} = {};
	}
	while ($self->{_line_pos}{$fh_id} < $target_line && !eof($fh)) {
		<$fh>;
		$self->{_line_pos}{$fh_id}++;
	}
	return undef if eof($fh);
	if (exists $self->{_parsed_lines}{$fh_id}{$target_line}) {
		my $line_objects = $self->{_parsed_lines}{$fh_id}{$target_line};
		return undef unless $line_objects && @$line_objects > $target_offset;
		return $line_objects->[$target_offset];
	}
	my $line = '';
	my $start_line = $self->{_line_pos}{$fh_id};
	while ($line !~ m/^$LINES/ && !eof($fh)) {
		$line .= <$fh>;
		$self->{_line_pos}{$fh_id}++;
	}
	return undef unless $line =~ m/^$LINES/;
	my @objects = $self->decode($line);
	$self->{_parsed_lines}{$fh_id}{$start_line} = \@objects;
	return undef unless @objects > $target_offset;
	return $objects[$target_offset];
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
	my @all_objects;
	my $line = '';
	while (!eof($fh)) {
		do { $line .= <$fh> } while ($line !~ m/^$LINES/ && !eof($fh));
		if ($line =~ m/^$LINES/) {
			push @all_objects, $self->decode($line);
			$line = "";
		}
	}
	if (!$in_fh) {
		close $fh;
	}
	my $end = $length;
	$end = $#all_objects if $end > $#all_objects;
	my @subset = @all_objects[$offset .. $end];
	if ($out_file) {
		open my $cfh, '>', $out_file or die "cannot open file for writing: $!";
		print $cfh $self->encode(\@subset);
		close $cfh;
		return 1;
	}
	return \@subset;
}
sub group_lines {
	my ($self, $fh, $key) = @_;
	die "Key must be provided for grouping" unless defined $key;
	seek $fh, 0, 0;
	my (%groups, $line_num, $line);
	($line_num, $line) = (0, '');
	while (!eof($fh)) {
		my $start_line = $line_num;
		while ($line !~ m/^$LINES/ && !eof($fh)) {
			$line .= <$fh>;
			$line_num++;
		}
		last unless $line =~ m/^$LINES/;
		my @objects = $self->decode($line);
		$line = '';
		my $obj_offset = 0;
		for my $data (@objects) {
			my $value = ref $key eq 'CODE'
				? do { local $_ = $data; $key->($data) }
				: $data->{$key};
			my $index = @objects > 1 ? "$start_line:$obj_offset" : $start_line;
			push @{ $groups{$value} }, $index;
			$obj_offset++;
		}
	}
	return \%groups;
}
sub _decode_one {
	my ($self, $string) = @_;
	return (undef, 0, 0) unless $string =~ /^[\[\{]/;
	if ($string =~ m/^($LINES)/) {
		my $json_str = $1;
		my $chars_consumed = length($json_str);
		my $struct = eval { $JSON->decode($json_str) };
		if ($@) {
			return (undef, $chars_consumed, 1);
		}
		$self->{success_cb}->('decode', $struct, $json_str) if $self->{success_cb};
		return ($struct, $chars_consumed, 1);
	}
	return (undef, 0, 0);
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

Version 1.11

=cut

=head1 SYNOPSIS

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

All of the above options can also be get/set dynamically via accessor methods:

	# Get current value
	my $is_pretty = $jsonl->pretty;

	# Set value (returns $self for chaining)
	$jsonl->pretty(1)->canonical(1);

	# Set callbacks
	$jsonl->error_cb(sub { warn "Error: $_[1]" });
	$jsonl->success_cb(sub { print "Processed: $_[1]" });

=head2 encode

Encode a perl struct into a json lines string.

	$jsonl->encode( $data );

=head2 encode_file

Encode a perl struct into a json lines file.

	$jsonl->encode_file($file, $data);

=head2 decode

Decode a json lines string into a perl struct. Handles multiple JSON objects
per line (e.g., from streaming output that concatenates objects without newlines).
The decoder is string-aware, correctly handling unbalanced braces within JSON
string values (e.g., code snippets containing C<{> or C<}>).

	$jsonl->decode( $string );

	# Handles multiple objects on one line:
	my @data = $jsonl->decode('{"a":1}{"b":2}');
	# Returns: ({ a => 1 }, { b => 2 })

	# Handles code in strings:
	my @data = $jsonl->decode('{"code":"sub foo { }"}');
	# Correctly parses as single object

Supports chunked/streaming input - incomplete JSON is buffered and combined
with subsequent calls. Use C<remaining()> to check buffer state and
C<clear_buffer()> to reset.

=head2 decode_file

Decode a json lines file into a perl struct.

	$jsonl->decode_file( $file );

=head2 remaining

Returns any incomplete JSON data buffered from previous decode() calls.
Useful for debugging chunked input scenarios.

	my $buffered = $jsonl->remaining;
	if (length $buffered) {
		warn "Incomplete JSON in buffer: $buffered";
	}

=head2 clear_buffer

Clears the internal buffer used for chunked input. Call this to reset
state between unrelated decode operations on the same instance.

	$jsonl->clear_buffer;
	# Fresh state for new input
	my @data = $jsonl->decode($new_input);

=head2 add_line

Add a new line to the current JSON::Lines stream.

	$jsonl->add_line($line);

	$jsonl->add_line($line, $fh);

=head2 get_line

Decode a json lines file, one object at a time. If a line contains multiple
JSON objects, they are buffered and returned one at a time on subsequent calls.

	open my $fh, "<", $file or die "$file: $!";
	while (my $obj = $jsonl->get_line($fh)) {
		print $obj->{id}, "\n";
	}
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

=head2 get_line_at

Get a single record at a specific index. Supports both plain line numbers and
"line:offset" format for accessing multiple objects on the same line.

	my $record = $jsonl->get_line_at($fh, 5, 1);      # line 5, seek to beginning first
	my $record = $jsonl->get_line_at($fh, 5);         # line 5, no seek
	my $record = $jsonl->get_line_at($fh, '2:1', 1);  # line 2, second object on that line

Returns undef if the index is beyond the end of the file. Works with indices
returned by group_lines (which may return "line:offset" format for multi-object lines).

=head2 group_lines

Group objects in a JSONL file by a key value, returning a hash of indices.
For lines with multiple objects, indices use "line:offset" format (e.g., "0:1"
for the second object on line 0). Single-object lines use plain integers.

	open my $fh, '<', $file or die $!;
	my $groups = $jsonl->group_lines($fh, 'category');
	# Returns: { 'cat1' => [0, '2:0', '2:1'], 'cat2' => [1, '3:0'] }

	# With a coderef for complex grouping:
	my $groups = $jsonl->group_lines($fh, sub { $_->{nested}{key} });
	close $fh;

	# Use returned indices with get_line_at:
	for my $idx (@{$groups->{cat1}}) {
		my $obj = $jsonl->get_line_at($fh, $idx, !$first++);
	}

The returned indices are compatible with get_line_at.

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
