use strict;
use warnings;
package Mail::Postfix::Attr;
{
  $Mail::Postfix::Attr::VERSION = '0.06';
}
# ABSTRACT: encode and decode Postfix attributes

use Carp;


# I do not understand the terminal slash in \0/
# -- rjbs, 2013-01-02
my %codecs = (
  '0'     => [ \&encode_0,     \&decode_0,     q(\0/) ],
  '64'    => [ \&encode_64,    \&decode_64,    q(\n) ],
  'plain' => [ \&encode_plain, \&decode_plain, q(\n) ],
);

sub new {
	my ($class, %args) = @_;
	my $self = bless {}, $class;
	my $codec_ref = $codecs{ $args{codec} } || $codecs{plain};

	$self->{sock_path} = $args{path};
	$self->{inet} = $args{inet};
	$self->{fh} = $args{fh};

	@{$self}{qw(encode decode delimiter)} = @{$codec_ref};

	return $self;
}

sub fh {
  my $self = shift;
  my $fh;
  unless ($self->{fh}) {
    if ( $self->{sock_path} ) {
      require IO::Socket::UNIX;
      $fh = IO::Socket::UNIX->new( $self->{sock_path} );
      $fh or croak "Mail::Postfix::Attr can't connect to '$self->{sock_path}' $!\n";
      $self->{fh} = $fh;
    } elsif ( $self->{inet} ) {
      require IO::Socket::INET;
      $fh = IO::Socket::INET->new( $self->{inet} );
      $fh or croak "Mail::Postfix::Attr can't connect to '$self->{inet}' $!\n";
      $self->{fh} = $fh;
    } elsif ($self->{fh}) {
      $fh = $self->{fh}
    } else {
      croak "must have 'path' or 'inet' or 'fh' set to use send";
    }
  }
  croak "can't find filehandle for $self" unless $self->{fh};
  return $self->{fh};
}


sub send {
  my ($self) = shift;
  $self->write(@_);
  return $self->read;
}

sub write {
  my ($self) = shift;
  $self->raw_write($self->encode(@_));
}

sub raw_write {
  my $self = shift;
  my $fh = $self->fh;
  my $count = syswrite($fh, shift);
  croak "syswrite: error: $!" unless $count;
}

sub read {
  my ($self) = shift;
  return map @$_, $self->decode($self->raw_read);
}

sub raw_read {
  my $self = shift;
  my $fh = $self->fh;
  my $buf;
  my $r = sysread($fh, $buf, 64000);
  die "sysread error: $!" unless defined $r;
  return $buf;
}


sub encode {
  my ($self) = @_;
  goto $self->{encode};
}


sub decode {
  my ($self) = @_;
  goto $self->{decode};
}

sub delimiter {
  my ($self) = @_;
  return $self->{delimiter};
}

sub encode_0 {
  my ($self) = shift;
  my $attr_text;
  while (my ($attr, $val) = splice(@_, 0, 2)) {
    $val = "" unless defined $val;
    $attr_text .= "$attr\0$val\0";
  }
  return "$attr_text\0";
}

sub encode_64 {
  my ($self) = shift;
  my $attr_text;
  require MIME::Base64;
  while (my ($attr, $val) = splice(@_, 0, 2)) {
    $val = "" unless defined $val;
    $attr_text .= MIME::Base64::encode_base64( $attr, '' ) . ':' .
      MIME::Base64::encode_base64( $val, '' ) . "\n";
  }
  return "$attr_text\n";
}

sub encode_plain {
  my ($self) = shift;
  my $attr_text;
  while (my ($attr, $val) = splice(@_, 0, 2)) {
    $val = "" unless defined $val;
    $attr_text .= "$attr=$val\n";
  }
  return "$attr_text\n";
}

sub decode_0 {
  my ($self, $text) = @_;
  my @attrs;
  # the lookahead avoids a situation where (x => "") is
  # encoded as "x\0\0\0" but then decoded into [ "x" ], []
  foreach my $section ( split /(?<=\0\0)(?!\0)/, $text ) {
    # count is here to make sure that trailing attributes with empty values are correctly given
    # previously (a => 1, b => 2, c => "") would come out as [ "a", 1, "b", 2, "c" ]
    my $count = ($section =~ tr/\0//) - 1;
    $section = substr($section, 0, length($section) - 2);
    push( @attrs, [ split /\0/, $section, $count ] );
  }
  return @attrs;
}

sub decode_64 {
  my ($self, $text) = @_;
  require MIME::Base64;
  my @attrs;
  foreach my $section (split /(?<=\n\n)/, $text) {
    push (@attrs, [ map MIME::Base64::decode_base64 $_,
		    $section =~ /^([^:]+):(.+)$/mg ]);
  }
  return @attrs;
}

sub decode_plain {
  my ($self, $text) = @_;
  my @attrs;
  foreach my $section (split /(?<=\n\n)/, $text) {
    push (@attrs, [ map { split /=/, $_, 2 } split /\n/, $section ]);
  }
  return @attrs;
}

1;

__END__

=pod

=head1 NAME

Mail::Postfix::Attr - encode and decode Postfix attributes

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use Mail::Postfix::Attr;

  my $pf_attr = Mail::Postfix::Attr->new( 'codec' => '0',
					  'path' => '/tmp/postfix_sock' );


  my $pf_attr = Mail::Postfix::Attr->new( 'codec' => 'plain',
					  'inet' => 'localhost:9999' );

  my @result_attrs = $pf_attr->send( 'foo' => 4, 'bar' => 'blah' );

  my $attr_text = $pf_attr->encode( 'foo' => 4, 'bar' => 'blah' );

  my @attrs = $pf_attr->decode( $attr_text );

=head1 DESCRIPTION

Mail::Postfix::Attr supports encoding and decoding of the three
formats of attributes used in the postfix MTA. Attributes are used by
postfix to communicate with various of its services such as the verify
program. These formats are:

  plain	- key=value\n	(a collection of attributes has an \n appended)
  0	- key\0value\0	(a collection of attributes has a \0 appended)
  64	- base64(key):base64(value)\n
			(a collection of attributes has an \n appended)

These formats are from the specifications in the postfix source files
in the src/util directory:

  attr_scan0.c
  attr_scan64.c
  attr_scan_plain.c
  attr_print0.c
  attr_print64.c
  attr_print_plain.c 	

If you run 'make test' (after building postfix) in this directory it will build
these programs which can be used to test this Perl module:

  attr_scan0
  attr_scan64
  attr_scan_plain
  attr_print0
  attr_print64
  attr_print_plain

=head2 For example...

  # talk to the verify(8) service available in Postfix v2.
  # 
  # perl -MMail::Postfix::Attr -le 'print for Mail::Postfix::Attr
           ->new (codec=>0, path=>"/var/spool/postfix/private/verify")
           ->send(request=>query=>address=>shift)'
          postmaster@localhost

  status
  0
  recipient_status
  0
  reason
  aliased to root

=head1 METHODS

=head2 new

	my $pf_attr = Mail::Postfix::Attr->new( 'codec' => '0',
					  'path' => '/tmp/postfix_sock' );

The new method takes a list of key/value arguments.

	codec	=> <codec_type>
	path	=> <unix_socket_path>
	inet	=> <host:port>

	codec_type is one of '0', '64' or 'plain'. It defaults to
	'plain' if not set or it is not in the allowed codec set.

	The <unix_socket_path> argument is the unix domain socket that
	will be used to send a message to a postfix service. The
	message will be encoded and its response decoded with the
	selected codec.

	The <inet> argument is the internet domain address that will
	be used to send a message to a postfix service. It must be in
	the form of "host:port" where host can be a hostname or IP
	address and port can be a number or a name in
	/etc/services. The message will be encoded and its response
	decoded with the selected codec.

=head2 send

The send method is passed a list of postfix attribute key/value
pairs. It first connects to a postfix service using the UNIX or INET
socket. It then encodes the attributes using the selected codec and
writes that data to the socket. It then reads from the socket to EOF
and decodes that data with the codec and returns that list of
attribute key/value pairs to the caller.

  my @result_attrs = $pf_attr->send( 'foo' => 4, 'bar' => 'blah' );

=head2 encode

The encode method takes a list of key/values and encodes it according
to the selected codec. It returns a single string which has the
encoded text of the attribute/value pairs. Each call will create a
single attribute section which is terminated by an extra separator
char.

  my $attr_text = $pf_attr->encode( 'foo' => 4, 'bar' => 'blah' );

You can also call each encoder directly as a class method:

  my $attr_text = Mail::Postfix::Attr->encode_0( 'foo' => 4, 'bar' => 'blah' );
  my $attr_text = Mail::Postfix::Attr->encode_64( 'foo' => 4, 'bar' => 'blah' );
  my $attr_text = Mail::Postfix::Attr->encode_plain( 'foo' => 4, 'bar' => 'blah' );

=head2 decode

The decode method takes a single string of encoded attributes and
decodes it into a list of attribute sections. Each section is decoded
into a list of attribute/value pairs. It returns a list of array
references, each of which has the attribute/value pairs of one
attribute section.

  my @attrs = $pf_attr->decode( $attr_text );

You can also call each decoder directly as a class method:

  my @attrs = Mail::Postfix::Attr->decode_0( $attr_text );
  my @attrs = Mail::Postfix::Attr->decode_64( $attr_text );
  my @attrs = Mail::Postfix::Attr->decode_plain( $attr_text );

=head1 AUTHOR

Uri Guttman <uri@stemsystems.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002 by Uri Guttman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
