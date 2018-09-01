package ELF::sign;

use strict;
use Net::SSLeay;
use Fcntl qw(SEEK_END);
use Digest::SHA qw(sha512);

use vars qw($VERSION @ISA);
$VERSION = '0.07';

BEGIN {
   eval {
      require Net::SSLeay;
      Net::SSLeay->import( 1.65 );
   };
   Net::SSLeay::load_error_strings();
   Net::SSLeay::SSLeay_add_ssl_algorithms();
   Net::SSLeay::randomize();
}

require XSLoader;
XSLoader::load('ELF::sign', $VERSION);

sub new {
   my $type = shift;
   my $params = {@_};
   my $self = bless({}, $type);
   $self->{debug}++;
   return $self;
}

sub dataFile {
   my $self = shift;
   my $file = shift;
   $self->{file} = $file;
   $self->{pkcs7} = $self->getFromFile();
   $self->{datapostset} = $self->{pkcs7} ? length($self->{pkcs7}) + 8 : 0;
   return $self->{pkcs7};
}

sub data {
   my $self = shift;
   my $data = shift;
   delete $self->{file};
   $self->{data} = $data;
   $self->{pkcs7} = $self->getFromData();
   $self->{datapostset} = $self->{pkcs7} ? length($self->{pkcs7}) + 8 : 0;
   return $self->{pkcs7};
}

sub crt {
   my $self = shift;
   $self->{"crt"} = shift;
}

sub key {
   my $self = shift;
   $self->{"key"} = shift;
}

sub crtFile {
   return shift->loadFile("crt", @_);
}

sub keyFile {
   return shift->loadFile("key", @_);
}

sub load {
   my $self = shift;
   my $name = shift;
   my $data = shift;
   $self->{$name} = $data;
   return undef;
}

sub loadFile {
   my $self = shift;
   my $name = shift;
   my $file = shift;
   delete $self->{$name};
   open(IN, "<", $file) ||
      return "Error opening ".$name.": ".$!;
   while(<IN>) {
      $self->{$name} .= $_;
   }
   close(IN);
   return undef;
}

sub dataToBio {
   my $data = shift;
   #my $self = {};
   my $bio = Net::SSLeay::BIO_new(Net::SSLeay::BIO_s_mem());
   my $sent = Net::SSLeay::BIO_write($bio, $data);
   #print "Wrote ".$sent." of ".length($data)." bytes.\n"
   #   if $self->{debug};
   die "Cannot write to bio!"
      if (($sent) != length($data));
   return $bio;
}

sub PEMdataToPKCS7 {
   my $data = shift;
   my $pkcs7 = undef;
   my $bio = dataToBio($data);
   die "Error using pkcs7: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      unless ($pkcs7 = PEM_read_bio_PKCS7($bio, 0, 0, 0));
   Net::SSLeay::BIO_free($bio);
   return $pkcs7;
}

sub PEMdataToX509 {
   my $x509 = shift;
   my $bio = dataToBio($x509);
   my $x509result = undef;
   die "Error using x509: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      unless ($x509result = Net::SSLeay::PEM_read_bio_X509($bio));
   Net::SSLeay::BIO_free($bio);
   return $x509result;
}

sub PEMdataToEVP_PKEY {
   my $crt = shift;
   my $bio = dataToBio($crt);
   my $evp_pkey = undef;
   die "Error using cacrt: ".Net::SSLeay::ERR_error_string(Net::SSLeay::ERR_get_error())
      unless ($evp_pkey = Net::SSLeay::PEM_read_bio_PrivateKey($bio));
   Net::SSLeay::BIO_free($bio);
   return $evp_pkey;
}

sub getDigest {
   my $self = shift;
   my $sha512 = Digest::SHA->new("sha512");
   if ($self->{file}) {
      my $filesize = doFile(sub{
         my $buf = shift;
         $sha512->add($buf);
      }, $self->{file}, $self->{datapostset});
      return $filesize
         unless $filesize;
   } elsif(defined($self->{data})) {
      $sha512->add(substr($self->{data}, 0, length($self->{data})-$self->{datapostset}));
   } else {
      return undef;
   }
   return $sha512->digest();
}

sub sign {
   my $self = shift;
   # TODO:XXX:FIXME: Allow to specify which digest should be used!
   # TODO:XXX:FIXME: Allow to specify ca the certificate must match!
   # TODO:XXX:FIXME: Verify the validity of the certificate used!
   delete $self->{pkcs7};
   my $digest = $self->getDigest();
   return "No digest"
      unless $digest;
   return "No Cert"
      unless $self->{crt};
   return "No Key"
      unless $self->{key};
   $self->{pkcs7} = datasign($digest, PEMdataToX509($self->{crt}), PEMdataToEVP_PKEY($self->{key}));
   return $self->{pkcs7} ? undef : "Signing failed";
}

sub doFile {
  my $action = shift;
  my $file = shift;
  my $lenp7 = shift;
  return undef
     unless my $size = (stat($file))[7];
  open(IN, "<", $file) || die($!);
  my $filesize = 0;
  while (1) {
      my $wread = 16*1024;
      if ($lenp7 && ($wread+$filesize > ($size-$lenp7))) {
         last unless
            $wread = $size-($filesize+$lenp7) > 0;
         #print("Reducing wread=16k -> ".$wread." size=".$size." lenp7=".$lenp7." pos=".$filesize." file=".$file."\n");
      }
      if ((my $nread = sysread(IN, my $buf, $wread)) > 0) {
         &$action($buf);
         $filesize += $nread;
      } else {
         last;
      }
  }
  close(IN);
  return $filesize;
}

sub verify {
   my $self = shift;
   # TODO:XXX:FIXME: Allow to specify which digest should be used!
   # TODO:XXX:FIXME: Allow to specify ca the certificate must match!
   # TODO:XXX:FIXME: Verify the validity of the certificate used!
   my $digest = $self->getDigest();
   return "No digest"
      unless $digest;
   return "No PKCS7"
      unless $self->{pkcs7};
   return "No Cert"
      unless $self->{crt};
   my $return = dataverify($digest, PEMdataToX509($self->{crt}), PEMdataToPKCS7($self->{pkcs7}));
   return $return;
}

sub hexdump { join ':', map { sprintf "%02X", $_ } unpack "C*", $_[0]; }

sub save {
   my $self = shift;
   my $newfile = shift;
   my $nopkcs7 = shift || 0;
   return "Unsigned"
      unless $self->{pkcs7} || $nopkcs7;
   open(my $outfile, ">", $newfile) ||
      return "Cannot open file: ".$!;
   if ($self->{file}) {
      my $filesize = doFile(sub{
         my $buf = shift;
         syswrite($outfile, $buf);
      }, $self->{file}, $self->{datapostset});
      return "Error reading file"
         unless defined($filesize);
   } elsif(defined($self->{data})) {
      syswrite($outfile, substr($self->{data}, 0, length($self->{data})-$self->{datapostset}));
   } else {
      return "No data";
   }
   syswrite($outfile, $self->{pkcs7}.pack("Q", length($self->{pkcs7})))
      unless $nopkcs7;
   close($outfile);
   return undef;
}

sub get {
   my $self = shift;
   my $nopkcs7 = shift || 0;
   return undef
      unless $self->{pkcs7} || $nopkcs7;
   my $data = '';
   if ($self->{file}) {
      my $filesize = doFile(sub{
         my $buf = shift;
         $data .= $buf;
      }, $self->{file}, $self->{datapostset});
   } elsif(defined($self->{data})) {
      $data = substr($self->{data}, 0, length($self->{data})-$self->{datapostset});
   } else {
      return undef;
   }
   $data .= $self->{pkcs7}.pack("Q", length($self->{pkcs7}))
      unless $nopkcs7;
   return $data;
}

sub getFromData {
   my $self = shift;
   if (length($self->{data}) < 8) {
      #print "Unable to access 8 bytes! ".length($self->{data})."\n";
      return 0;
   }
   my $offset = unpack("Q", substr($self->{data}, length($self->{data})-8, 8));
   if ($offset+8 > length($self->{data})) {
      #print "Offset bigger than data -> Skipping\n";
      return 0;
   }
   if ($offset > 10*1024) {
      #print "Offset bigger than one MB -> Skipping\n";
      return 0;
   }
   my $wanted = "-----BEGIN PKCS7-----";
   if (substr($self->{data}, length($self->{data})-(8+$offset), length($wanted)) ne $wanted) {
      #print "Not a PKCS7 header!\n";
      return 0;
   }
   return substr($self->{data}, length($self->{data})-(8+$offset), $offset);
}

sub getFromFile {
   my $self = shift;
   unless ($self->{file}) {
      #print "Unable to read 8 bytes!\n";
      return undef;
   }
   my $filesize = (stat($self->{file}))[7];
   my $openfile = undef;
   unless (open($openfile, "<", $self->{file})) {
      #print "Unable to open file="($self->{file}." error=".$!."\n";
      return undef;
   }
   seek($openfile, -8, SEEK_END);
   my $data = undef;
   unless ((sysread($openfile, $data, 8)) == 8) {
      #print "Unable to read 8 bytes!\n";
      return 0;
   }
   my $offset = unpack("Q", $data);
   if ($offset+8 > $filesize) {
      #print "Offset bigger than file -> Skipping\n";
      return 0;
   }
   if ($offset > 1024*1024) {
      #print "Offset bigger than one MB -> Skipping\n";
      return 0;
   }
   #print "Found offset of ".$offset."\n";
   seek($openfile, -(8+$offset), SEEK_END);
   my $wanted = "-----BEGIN PKCS7-----";
   unless ((sysread($openfile, $data, length($wanted))) == length($wanted)) {
      #print "Unable to read ".length($wanted)." bytes!\n";
      return 0;
   }
   if ($data ne $wanted) {
      #print "Not a PKCS7 header!";
      return 0;
   }
   seek($openfile, -(8+$offset), SEEK_END);
   unless ((sysread($openfile, $data, $offset)) == $offset) {
      #print "Unable to read $offset bytes!\n";
      return 0;
   }
   return $data;
}

sub pkcs7 {
   my $self = shift;
   my $pkcs7 = shift;
   $self->{pkcs7} = $pkcs7
      if defined($pkcs7);
   return $self->{pkcs7};
}

1;

__END__

=head1 NAME

ELF::sign - X509 signing of elf execuables

=head1 VERSION

Version 0.07

=over 2

=back

=head1 DESCRIPTION

This module allows one to sign a elf file - or any other file type - based
on a PKCS#7 via a X509-Certifcate and its private key, and include the
signature in the file.

It uses SHA512 Hashing via PKCS#7 to ensure the correctness.

=over 2

=back

=head1 SYNOPSIS

You can mix inmemory and file based commands.

=head2 Signing

   use ELF::sign;
   my $sign = ELF::sign->new();
   $sign->crtFile("test.crt");
   $sign->keyFile("test.key");
   $sign->dataFile($filename);
   my $error = $sign->sign() ||
               $sign->save($outfile);
   die $error
     if $error;

=head2 Verifying

   use ELF::sign;
   my $verify = ELF::sign->new();
   $verify->crtFile("test.crt");
   $verify->dataFile($filename);
   my $error = $verify->verify() ||
               $verify->save($outfile, 1);
   die $error
     if $error;

=head1 FUNCTIONS

=over 2

=item new

Returns a new I<ELF::sign> object. It ignores any options.

=item data{File}($data{/$filename})

Assignes data (as a file with suffix I<File>) on which signing or verifying operations
can be applied.

Detects automatically if there is already a signature on the file or on the data,
and parses it in this case. Verifying via I<verify()> is possible if there is one or
if I<sign()> has been successfully called. Signing via I<sign()> is always possible,
and overwrites a maybe exsting signing - but just inmemory. To update to a file
you have to use I<save()>.

If the I<File> suffix is used, you specify a file. If this file cannot be
read, then I<dataFile> returns undef.

In any other case, also on I<data()>, it returns the attached signing (PKCS#7)
or the scalar defined value 0 if there is none but the file was able to be read.

=item crt{File}($data{/$filename})

Assignes a X509-certificate to be used for verifing or signing. To sign you also
need to set the corresponding I<key{File}()>.

=item key{File}($data{/$filename})

Assignes a key to be used for signing via I<sign()>. To sign you also need to set the
corresponding I<crt{File}()>.

=item verify()

Verifies that a attached or via I<sign()> created signature matches the data passed
via I<data{File}()> and the public key of I<crt{File}()>.

Returns undef on success, or on any error the cause as scalar(string).

B<WARNING:> ELF::sign currently does not verify the validity of the certificate,
            it only uses the public key in the certificate specified by I<crt{File}()>
            and does do not any further certificate, ca processing or checks.
            This will get fixed in one of the next releases.

=item sign()

Creates inmemory a PKCS#7 signature via I<crt{File}()> and I<key{File}()> on the
data that has been passed via I<data{File}()>. Returns undef on success, or on
any error the cause as scalar(string).

To store and attach this signature you have to use I<get()> or I<save()>. The
signature alone, the PKCS#7, can be fetched via I<pkcs7()>.

=item get({1})

Returns the passed data passed via I<data{File}()> as scalar(string), and the
attached signature, if available. If the optional parameter is true, it omits
the signature.

=item save($filename{,1})

Saves the passed data passed via I<data{File}()> to a file, including the attached
signature if available. If the optional parameter is true, it omits the signature.

=item pkcs7({$data})

Returns the currently active PKCS#7 signature, if available, or undef. Via the
optional data the pkcs7 can be manually overwritten.

=item hexdump($string)

Returns string data in hex format.

Example:

  perl -e 'use ELF::sign; print ELF::sign::hexdump("test")."\n";'
  74:65:73:74

=back

=head2 Internal functions

=over 2

=item crt()

=item crtFile()

=item key()

=item keyFile()

=item data()

=item dataFile()

=item datasign()

=item dataverify()

=item load()

=item loadFile()

=item dataToBio()

=item PEMdataToPKCS7()

=item PEMdataToX509()

=item PEMdataToEVP_PKEY()

=item getDigest()

=item doFile()

=item getFromData()

=item getFromFile()

=item PEM_read_bio_PKCS7()

=back

=head1 Commercial support

Commercial support can be gained at <elfsignsupport at cryptomagic.eu>.

Used in our products, you can find on L<https://www.cryptomagic.eu/>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2018 Markus Schraeder, CryptoMagic GmbH, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of ELF::sign
