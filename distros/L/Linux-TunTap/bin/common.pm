# encodes a packet into a suitable TXT record
sub encode_txt {
  my($packet)=@_;
  # prepend length to packet.
  $packet=pack('Sa*x', length $packet, $packet);
  # Does a 7-to-8 expansion of bits to ensure that MSB of all bytes are 1.
  my $bits=unpack('b*', $packet);
  my @bytes=grep { length } split /(.{7})/, $bits;
  pop @bytes; # throw away last byte, it's just null padding we added with x
              # in the pack format earlier
  $bits=join '', map { "${_}1" } @bytes;
  my $txt=pack('b*', $bits);
  return $txt;
}

# encodes a packet into a queryable DNS name
sub encode_name {
  my($packet, $seq)=@_;
  # prepend two byte sequence number to packet.
  $packet=pack('SSa*x', $seq, length $packet, $packet);
  # Does a 7-to-8 expansion of bits to ensure that MSB of all bytes are 1.
  my $bits=unpack('b*', $packet);
  my @bytes=grep { length } split /(.{7})/, $bits;
  pop @bytes; # throw away last byte, it's just null padding we added with x
              # in the pack format earlier
  $bits=join '', map { "${_}1" } @bytes;
  my $name=pack('b*', $bits);
  my @parts=grep { length } split /(.{31})/, $name;
  return join '.', @parts;
}

# decodes TXT data into a packet
sub decode_txt {
  my($txt)=@_;
  # Does an 8-to-7 compression, throwing away all MSBs.
  my $bits=unpack('b*', $txt);
  my @bytes=grep { length } split /(.{8})/, $bits;
  @bytes=map { chop; $_ } @bytes; # chop MSB
  $bits=join '',  @bytes;
  my $packet=pack 'b*', $bits;
  my($size, $seq);
  ($size, $packet)=unpack('Sa*', $packet);
  substr($packet, $size)='';
  return $packet;
}

# decodes DNS name into a packet
sub decode_name {
  my($name)=@_;
  $name=~tr[.][]d;		# delete dots
  # Does an 8-to-7 compression, throwing away all MSBs.
  my $bits=unpack('b*', $name);
  my @bytes=grep { length } split /(.{8})/, $bits;
  @bytes=map { chop; $_ } @bytes; # chop MSB
  $bits=join '',  @bytes;
  my $packet=pack 'b*', $bits;
  my($size, $seq);
  ($seq, $size, $packet)=unpack('SSa*', $packet);
  substr($packet, $size)='';
  return $packet;
}

1;
