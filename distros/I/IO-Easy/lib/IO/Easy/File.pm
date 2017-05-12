package IO::Easy::File;

use Class::Easy;

use Encode qw(decode encode perlio_ok is_utf8);

use Fcntl ':seek';

use File::Spec;
our $FS = 'File::Spec';

use IO::Easy;
use base qw(IO::Easy);

use IO::Dir;

our $PART = 1 << 20;
our $ENC  = '';

sub _init {
	my $self = shift;
	
	return $self->_init_layer;
	
}

sub type {
	return 'file';
}

sub enc {
	my $self = shift;
	my $enc  = shift;
	
	return $self->{enc} || $ENC
		unless $enc;
	
	$self->{enc} = $enc;
	return $self->_init_layer;
}

sub _init_layer {
	my $self = shift;
	
	my $enc = $self->enc;
	
	if (!defined $enc or $enc eq '') {
		# binary reading
		$self->{layer} = ':raw';
	} else {
		my $enc_ok = perlio_ok ($enc);
		unless ($enc_ok) {
			warn "selected encoding ($enc) are not perlio savvy";
			return undef;
		}
		$self->{layer} = ":encoding($enc)";
	}
	return $self;
}

sub layer {
	my $self = shift;
	my $layer = shift;
	
	$self->_init_layer;
	
	return $self->{layer}
		unless $layer;
	
	my $old_layer = $self->{layer};
	$self->{layer} = $layer;
	
	return $old_layer;
}

sub part {
	my $self = shift;
	my $part = shift;
	
	return $self->{part} || $PART
		unless $part;
	
	$self->{part} = $part;
}

sub contents {
	my $self = shift;
	
	my $enc = $self->enc;
	
	my $io_layer = $self->layer;
	
	my $fh;
	open ($fh, "<$io_layer", $self->{path})
		|| die "cannot open file $self->{path}: $!";
	
	my $contents;
	
	my $part = $self->part;
	my $buff;
	
	while (read ($fh, $buff, $part)) {
		$contents .= $buff;
	}
	
	close ($fh);
	
	return $contents;
}

sub store {
	my $self = shift;
	
	my $fh;
	open ($fh, ">:raw", $self->{path})
		|| die "cannot open file $self->{path}: $!";
	
	# todo: check for status
	print $fh @_;
	
	close $fh;
	
	return 1;
}

sub store_if_empty {
	my $self = shift;
	return if -e $self;
	
	$self->store (@_);
}

sub move {
	my $self = shift;
	my $to = shift;
	
	# rename function is highly dependent on os, don't rely on it
	my $from_file = $self->path;
	my $to_file = $to;
	$to_file = $to->path
		if ref $to eq 'IO::Easy::File';
	
	$to_file = $FS->join($to->path, $self->file_name)
		if ref $to eq 'IO::Easy::Dir';
	
	$to = IO::Easy::File->new ($to_file);
	
	$to->dir_path->create; # create dir if necessary
	
	print 'move from: ', $from_file, ' to: ', $to_file, "\n";
	
	unless (open (IN, $from_file)) {
		warn "can't open $from_file: $!";
		return;
	}
	unless (open (OUT, '>', $to_file)) {
		warn "can't open $to_file: $!";
		return;
	}

	binmode(IN);
	binmode(OUT);
	
	my $buff;
	
	my $part = $self->part;
	
	# TODO: async
	
	while (read(IN, $buff, $part)) {
		print OUT $buff;
	}
	
	close IN;
	close OUT;
	
	unlink $from_file;
	
	$self->{path} = $to_file;
	
}

sub string_reader {
	my $self = shift;
	my $sub  = shift;
	my %params = @_;
	
	# because we can't seek in characters
	my $fh;
	open ($fh, '<:raw', $self->{path}) or return;

	my $seek_pos = 0;
	if ($params{reverse}) {
		if (seek ($fh, 0, SEEK_END)) {
			$seek_pos = tell ($fh);
		} else {
			return;
		}
	}
	
	my $buffer_size = $self->part;
	
	my $remains = '';
	my $buffer;
	my $read_cnt = 0;
	
	my $c = 10;
	
	if ($params{reverse}) {
		do {
			$seek_pos -= $buffer_size;
			$seek_pos = 0
				if $seek_pos < 0;

			seek ($fh, $seek_pos, SEEK_SET);
			$read_cnt = read ($fh, $buffer, $buffer_size);

			my @lines = split /^/, $buffer . 'aaa';
			
			if ($lines[$#lines] eq 'aaa') {
				$lines[$#lines] = '';
			} else {
				$lines[$#lines] =~ s/aaa$//s;
			}
			
			$lines[$#lines] = $lines[$#lines] . $remains;
			$remains = shift @lines;
			
			for (my $i = $#lines; $i >= 0; $i--) {
				chomp $lines[$i];
				&$sub ($lines[$i]);
			}
			
		} while $seek_pos > 0;
	} else {
		do {
			# seek ($fh, $seek_pos, SEEK_SET);
			$read_cnt = read ($fh, $buffer, $buffer_size);
			
			$seek_pos += $buffer_size;
			
			my @lines = split /^/, $buffer . 'aaa';
			
			if ($lines[$#lines] eq 'aaa') {
				$lines[$#lines] = '';
			} else {
				$lines[$#lines] =~ s/aaa$//s;
			}
			
			$lines[0] = $remains . $lines[0];
			$remains = pop @lines;
			
			foreach my $line (@lines) {
				chomp $line;
				&$sub ($line);
			}
			
		} while $read_cnt == $buffer_size;
		
	}
	
	chomp $remains;
	&$sub ($remains);

	#	@{$lines_ref} = ( $self->{'sep_is_regex'} ) ?
	#		$text =~ /(.*?$self->{'rec_sep'}|.+)/gs :
	#		$text =~ /(.*?\Q$self->{'rec_sep'}\E|.+)/gs ;

}

sub __data__files {
	
	my ($caller) = caller;
	$caller ||= '';
	
	no strict 'refs';
	
	my $fh = *{"${caller}::DATA"}{IO};
	if (@_ and defined *{$_[0]}{IO}) {
		$fh = *{$_[0]}{IO};
	}
	
	local $/;
	my $buf;
	my $data_position;
	eval "\$data_position = tell (\$fh); \$buf = <\$fh>; seek (\$fh, \$data_position, 0);";
	
	my @files = split /\s*#+\s+#*\s*(?=IO::Easy)/s, $buf;
	
	my $response = {};
	
	foreach my $contents (@files) {
		
		my ($key, $value) = split (/\s+#+\s+/, $contents, 2);
		
		next unless defined $key;
		
		$key =~ s/IO::Easy(?:::File)?\s+//;
		
		$response->{$key} = $value;
	}
	
	return $response;
}


sub touch {
	my $self = shift;
	
	if(-e $self->{path})
	{
		if(-f _)
		{
			my $t = time;
			
			die "can't utime $self->{path}: $!"
				unless utime $t, $t, $self->{path};
		}
		else
		{
			warn "not a file: $self->{path}\n";
		}
	}
	else
	{
		$self->store;
	}

	return 1;
}


1;

=head1 NAME

IO::Easy::File - IO::Easy child class for operations with files.

=head1 METHODS

=head2 contents, path, extension, dir_path

	my $io = IO::Easy->new ('.');
	my $file = $io->append('example.txt')->as_file;
	print $file->contents;		# prints file content
	print $file->path;			# prints file path, in this example it's './example.txt'

=cut

=head2 store, store_if_empty

IO::Easy::File has 2 methods for saving file: store and store_if_empty

	my $io = IO::Easy->new ('.');
	my $file = $io->append('example.txt')->as_file;
	my $content = "Some text goes here";

	$file->store($content);   			# saves the variable $content to file

	$file->store_if_empty ($content);	# saves the variable $content to file, only 
										# if there's no such a file existing.		

=cut

=head2 string_reader

read strings from file in normal or reverse order

	$io->string_reader (sub {
		my $s = shift;

		print $s;
	});

read from file end

	$io->string_reader (sub {
		my $s = shift;

		print $s;
	}, reverse => 1);

=cut

=head2 __data__files

parse __DATA__ section and return hash of file contents encoded as:

	__DATA__

	########################
	# IO::Easy file1
	########################

	FILE1 CONTENTS

	########################
	# IO::Easy file2
	########################

	FILE2 CONTENTS

returns

	{
		file1 => 'FILE1 CONTENTS',
		file2 => 'FILE2 CONTENTS',
	}

=cut

=head2 enc

file encoding for reading and writing files. by default '', which is :raw for
PerlIO. you can redefine it by providing supported encoding, as example utf-8 or ascii

=cut

=head2 layer

PerlIO layer name for reading and writing files. you can redefine it by providing argument

=cut

=head2 part

chunk size for file reading, storing and moving

=cut

=head2 move

moving file to another path

=cut

=head2 type

always 'file'

=head2 touch

similar to unix touch command - updates file timestamp

=cut

=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

__DATA__

########################
# IO::Easy file1
########################

FILE1 CONTENTS
