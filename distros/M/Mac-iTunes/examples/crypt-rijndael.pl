use Crypt::Rijndael;

open my( $fh ), "<", "/Users/brian/Music/iTunes/iTunes Library";
binmode $fh;

my $buffer;

sysread $fh, $buffer, 8;

my( $signature, $header_length ) = unpack( "A4l", $buffer );

die "signature [$signature] isn't hdfm!" unless $signature eq 'hdfm';
print "Found signature [$signature]\n";
print "Found header length [$header_length]\n";

seek $fh, 0, 0;

my $cipher = Crypt::Rijndael->new( "BHUILuilfghuila3", Crypt::Rijndael::MODE_ECB );
die "Couldn't make cipher" unless $cipher;

sysread $fh, $buffer, $header_length;

$/ = undef;
my $chunk = <$fh>;
my $chunk_length = length( $chunk );
print "Chunk length is $chunk_length: [", $chunk_length % 16, "]\n";

if( $chunk_length % 16 )
	{
	$length = $chunk_length - $chunk_length % 16;
	print "length is $length: [", $length % 16, "]\n";
	$output = $cipher->decrypt( substr( $chunk, 0, $length ) );
	print "output length is [", length $output, "]\n";
	print substr( $output, 0, 244 ), "\n";
	$output .= substr( $chunk, $length );
	print "output length is [", length $output, "]\n";
	}
else
	{
	$output = $cipher->decrypt( $chunk );
	}
	
open my( $out ), ">", "iTunes.decrypted.txt" or die "Couldn't open output! $!";
print $out $output;

__END__
 # keysize() is 32, but 24 and 16 are also possible
 # blocksize() is 16



 $plaintext = $cipher->decrypt($crypted);
  
 nfile = file(filename, "rb")
 try:
     h = infile.read(8)
     sig, l = struct.unpack(">4sI",h)
     if sig!='hdfm':
         raise ITLError("%s: not an hdfm file"%filename)
     self.headerlen = l
     infile.seek(0)
     self.offset = 0
     m = mcrypt.MCRYPT('rijndael-128', 'ecb')
     m.init("BHUILuilfghuila3")
     buf = infile.read(self.headerlen)
     print "headerlen: %d"%self.headerlen
     chunk = infile.read()
     l = len(chunk)
     if l%16:
         l1 = l-l%16
         out = m.decrypt(chunk[:l1])
         out += chunk[l1:]
     else:
         out = m.decrypt(chunk)
     buf += out
     file("dump.itl","wb").write(buf)
 finally:
     infile.close()
