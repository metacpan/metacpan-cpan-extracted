package MIME::Lite::Generator;

use strict;
use warnings;
use Carp;
use FileHandle;
use MIME::Lite;

our $VERSION = 0.02;

sub new {
	my ( $class, $msg, $is_smtp ) = @_;
	
	my $encoding = uc( $msg->{Attrs}{'content-transfer-encoding'} );
	my $chunk_getter;
	if (defined( $msg->{Path} ) || defined( $msg->{FH} ) || defined ( $msg->{Data} )) {
		if ($encoding eq 'BINARY') {
			$chunk_getter = defined ( $msg->{Data} )
		                     ? 'get_encoded_chunk_data_other'
		                     : 'get_encoded_chunk_fh_binary';
		}
		elsif ($encoding eq '8BIT') {
			$chunk_getter = defined ( $msg->{Data} )
			                 ? 'get_encoded_chunk_data_other'
			                 : 'get_encoded_chunk_fh_8bit';
		}
		elsif ($encoding eq '7BIT') {
			$chunk_getter = defined ( $msg->{Data} )
			                 ? 'get_encoded_chunk_data_other'
			                 : 'get_encoded_chunk_fh_7bit';
		}
		elsif ($encoding eq 'QUOTED-PRINTABLE') {
			$chunk_getter = defined ( $msg->{Data} )
			                 ? 'get_encoded_chunk_data_qp'
			                 : 'get_encoded_chunk_fh_qp';
		}
		elsif ($encoding eq 'BASE64') {
			$chunk_getter = defined ( $msg->{Data} )
			                 ? 'get_encoded_chunk_data_other'
			                 : 'get_encoded_chunk_fh_base64';
		}
		else {
			$chunk_getter = 'get_encoded_chunk_unknown';
		}
	}
	else {
		$chunk_getter = 'get_encoded_chunk_nodata';
	}
	
	bless {
		msg		  => $msg,
		is_smtp	  => $is_smtp,
		generators   => [],
		has_chunk	=> 0,
		state		=> 'init',
		encoding	 => $encoding,
		chunk_getter => $chunk_getter,
		last		 => '',
	}, ref($class) ? ref($class) : $class;
}

sub get {
	my $self = shift;
	
	### Do we have generators for embedded/main part(s)
	while (@{ $self->{generators} }) {
		my $str_ref = $self->{generators}[0]->get();
		return $str_ref if $str_ref;
		
		shift @{ $self->{generators} };
		
		if ($self->{boundary}) {
			if (@{ $self->{generators} }) {
				return \"\n--$self->{boundary}\n";
			}
			
			### Boundary at the end
			return \"\n--$self->{boundary}--\n\n";
		}
	}
	
	### What we should to generate
	if ($self->{state} eq 'init') {
		my $attrs = $self->{msg}{Attrs};
		my $sub_attrs = $self->{msg}{SubAttrs};
		my $rv;
		$self->{state} = 'first';
		
		### Output either the body or the parts.
		###   Notice that we key off of the content-type!  We expect fewer
		###   accidents that way, since the syntax will always match the MIME type.
		my $type = $attrs->{'content-type'};
		if ( $type =~ m{^multipart/}i ) {
			$self->{boundary} = $sub_attrs->{'content-type'}{'boundary'};

			### Preamble:
			$rv = \($self->{msg}->header_as_string . "\n" . (
					defined( $self->{msg}{Preamble} )
					  ? $self->{msg}{Preamble}
					  : "This is a multi-part message in MIME format.\n"
					) .
					 "\n--$self->{boundary}\n");

			### Parts:
			my $part;
			foreach $part ( @{ $self->{msg}{Parts} } ) {
				push @{ $self->{generators} }, $self->new($part, $self->{out}, $self->{is_smtp});
			}
		}
		elsif ( $type =~ m{^message/} ) {
			my @parts = @{ $self->{msg}{Parts} };

			### It's a toss-up; try both data and parts:
			if ( @parts == 0 ) {
				$self->{has_chunk} = 1;
				$rv = $self->get_encoded_chunk()
			}
			elsif ( @parts == 1 ) { 
				$self->{generators}[0] = $self->new($parts[0], $self->{out}, $self->{is_smtp});
				$rv = $self->{generators}[0]->get();
			}
			else {
				Carp::croak "can't handle message with >1 part\n";
			}
		}
		else {
			$self->{has_chunk} = 1;
			$rv = $self->get_encoded_chunk();
		}
		
		return $rv;
	}
	
	return $self->{has_chunk} ? $self->get_encoded_chunk() : undef;
}

sub get_encoded_chunk {
	my $self = shift;
	
	if ($self->{state} eq 'first') {
		$self->{state} = '';
		### Open file if necessary:
		unless (defined $self->{msg}{Data}) {
			if ( defined( $self->{msg}{Path} ) ) {
				$self->{fh} = new FileHandle || Carp::croak "can't get new filehandle\n";
				$self->{fh}->open($self->{msg}{Path})
					or Carp::croak "open $self->{msg}{Path}: $!\n";
			}
			else {
				$self->{fh} = $self->{msg}{FH};
			}
			CORE::binmode($self->{fh}) if $self->{msg}->binmode;
		}
		
		### Headers first
		return \($self->{msg}->header_as_string . "\n");
	}
	
	my $chunk_getter = $self->{chunk_getter};
	$self->$chunk_getter();
}

sub get_encoded_chunk_data_qp {
	my $self = shift;
	
	### Encode it line by line:
	if ($self->{msg}{Data} =~ m{^(.*[\r\n]*)}smg) {
		my $line = $1; # copy to avoid weird bug; rt 39334
		return \MIME::Lite::encode_qp($line);
	}
	
	$self->{has_chunk} = 0;
	return;
}

sub get_encoded_chunk_data_other {
	my $self = shift;
	$self->{has_chunk} = 0;
	
	if ($self->{encoding} eq 'BINARY') {
		$self->{is_smtp} and $self->{msg}{Data} =~ s/(?!\r)\n\z/\r/;
		return \$self->{msg}{Data};
	}
	
	if ($self->{encoding} eq '8BIT') {
		return \MIME::Lite::encode_8bit( $self->{msg}{Data} );
	}
	
	if ($self->{encoding} eq '7BIT') {
		return \MIME::Lite::encode_7bit( $self->{msg}{Data} );
	}
	
	if ($self->{encoding} eq 'BASE64') {
		return \MIME::Lite::encode_base64( $self->{msg}{Data} );
	}
}

sub get_encoded_chunk_fh_binary {
	my $self = shift;
	my $rv;
	
	if ( read( $self->{fh}, $_, 2048 ) ) {
		$rv = $self->{last};
		$self->{last} = $_;
	}
	else {
		seek $self->{fh}, 0, 0;
		$self->{has_chunk} = 0;
		if ( length $self->{last} ) {
			$self->{is_smtp} and $self->{last} =~ s/(?!\r)\n\z/\r/;
			$rv = $self->{last};
		}
	}
	
	return defined($rv) ? \$rv : undef;
}

sub get_encoded_chunk_fh_8bit {
	my $self = shift;
	
	if ( defined( $_ = readline( $self->{fh} ) ) ) {
		return \MIME::Lite::encode_8bit($_);
	}
	
	$self->{has_chunk} = 0;
	seek $self->{fh}, 0, 0;
	return;
}

sub get_encoded_chunk_fh_7bit {
	my $self = shift;
	
	if ( defined( $_ = readline( $self->{fh} ) ) ) {
		return \MIME::Lite::encode_7bit($_);
	}
	
	$self->{has_chunk} = 0;
	seek $self->{fh}, 0, 0;
	return;
}

sub get_encoded_chunk_fh_qp {
	my $self = shift;
	
	if ( defined( $_ = readline( $self->{fh} ) ) ) {
		return \MIME::Lite::encode_qp($_);
	}
	
	$self->{has_chunk} = 0;
	seek $self->{fh}, 0, 0;
	return;
}

sub get_encoded_chunk_fh_base64 {
	my $self = shift;
	
	if ( read( $self->{fh}, $_, 45 ) ) {
		return \MIME::Lite::encode_base64($_);
	}
	
	$self->{has_chunk} = 0;
	seek $self->{fh}, 0, 0;
	return;
}

sub get_encoded_chunk_unknown {
	croak "unsupported encoding: `$_[0]->{encoding}'\n";
}

sub get_encoded_chunk_nodata {
	croak "no data in this part\n";
}

1;

__END__

=pod

=head1 NAME

MIME::Lite::Generator - generate email created with MIME::Lite chunk by chunk, in memory-efficient way

=head1 SYNOPSIS

	use MIME::Lite;
	use MIME::Lite::Generator;
	
	my $msg = MIME::Lite->new(
		From    => 'root@cpan.org',
		To      => 'root@somewhere.com',
		Subject => 'This is message with big attachment',
		Type    => 'multipart/mixed'
	);
	$msg->attach(Type => 'TEXT', Data => 'See my video in attachment');
	$msg->attach(Path => '/home/kate/hot-video.1gb.mpg', Disposition => 'attachment', Encoding => 'base64');
	# MIME::Lite is efficient enough, file is not readed into memory
	
	# And now generate our email chunk by chunk
	# without reading whole file into memory
	my $msg_generator = MIME::Lite::Generator->new($msg);
	while (my $str_ref = $msg_generator->get()) {
		print $$str_ref;
	}

=head1 DESCRIPTION

C<MIME::Lite> is a good tool to generate emails. It efficiently works with attachments without reading whole
file into memory. But the only way to get generated email in memory-efficient way is to call C<print> method.
C<print> is good enough to write content to the files or other blocking handles. But what if we want to write
content to non-blocking socket? C<print> will fail when socket will become non-writable. Or we may want to write
inside some event loop. C<MIME::Lite::Generator> fixes this problem. Now we can generate email chunk by chunk in
small portions (< 4 kb each) and get result as a string.

=head1 METHODS

=head2 new($msg, $is_smtp=0)

Constructs new C<MIME::Lite::Generator> object. C<$msg> is C<MIME::Lite> object. For C<$is_smtp> description see
L<MIME::Lite>.

=head2 get()

Gets next chunk of the email and returns it as a reference to a string. Each chunk has size less than 4 kb. If there
is no more data available it will return C<undef>.

=head1 SEE ALSO

L<MIME::Lite>

=head1 AUTHOR

Oleg G, E<lt>oleg@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut
