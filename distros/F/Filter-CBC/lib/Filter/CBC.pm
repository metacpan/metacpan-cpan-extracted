package Filter::CBC;

use strict;
use vars qw($VERSION $cipher %Ciphers);
use Filter::Util::Call ;
use Crypt::CBC;

my %Ciphers =
("BLOWFISH"=>"Blowfish",
 "DES"=>"DES",
 "DES_EDE3"=>"DES_EDE3",
 "GOST"=>"GOST",
 "IDEA"=>"IDEA",
 "NULL"=>"NULL",
 "RC6"=>"RC6",
 "RIJNDAEL"=>"Rijndael",
 "SERPENT"=>"Serpent",
 "TEA"=>"TEA",
 "TWOFISH"=>"Twofish",);

$VERSION = '0.10';

my $blank = "This space is left blank intentionally";

sub import {
my ($type) = shift @_;
my $algorithm = shift || "Rijndael";
$algorithm = $Ciphers{uc $algorithm} || $algorithm;
my $key = shift || $blank;
my ($ref) = [];
$cipher = Crypt::CBC->new(-key => $key,-cipher => $algorithm);
if (defined $algorithm && defined $key)
{ open(F,"<$0") || die $!;
  flock(F,2); seek(F,0,0);
  my @CODE = ();
  my $past_use;
  while(<F>)
  { if (/^\# $blank/ && !$past_use) { close(F); last; }
    if (/use Filter\:\:CBC/) { push(@CODE,$_); $past_use++; next; }
    if (!$past_use) { push(@CODE,$_); }
    else 
    { my $code = $_; local $/ = undef; $code .= <F>; 
      splice(@CODE,-2,0,"# $blank");
      $code = $cipher->encrypt($code);
      open(OUTFILE,">$0.bak") || die $!;
      binmode(OUTFILE);
      print OUTFILE @CODE,$code;
      close(OUTFILE);
      close(F);
      unlink("$0") || die $!;
      rename ("$0.bak",$0) || die $!;
      exit;
    }
  }
}
filter_add(bless $ref) ;
}

sub filter {
my ($self) = @_ ;
my ($status) ;
local $/ = undef;
if (($status = filter_read()) > 0)
{ $_ = $cipher->decrypt($_);
}
$status ;
}

1;
__END__
=pod

=head1 NAME

Filter::CBC - Source filter for Cipher Block Chaining

=head1 SYNOPSIS

  # Please don't encrypt me!

  use Filter::CBC "Rijndael","my secret key";

  # This file will be encrypted and overwritten.
  # Make backups, damnit!
  # Autofilter example
  print "Don't try this at home, kids !";

  -or-

  # Please don't encrypt me!

  use Filter::CBC "","";

  # This file will be encrypted and overwritten.
  # Make backups, damnit!
  # Autofilter example
  # Defaults will be used
  # Rijndael is default encryption algorithm
  # Default keyphrase is : This space is left blank intentionally
  print "Don't try this at home, kids !";

  -or-

  BEGIN { use LWP::Simple; my $key = get("http://www.somesite.com/key.txt"); }
  
  use Filter::CBC "Rijndael",$key;

  secretstuff();

=head1 DESCRIPTION

Filter::CBC is a Source filter that uses Cipher Block Chaining (CBC) to
encrypt your code. The tricky part is that most CBC Algorithms have binary
output. The textmode bypasses this obstacle, by converting the data to less scary data.

=head1 DOWNSIDES

=over 3

=item *

Source filters are slow. VERY Slow. Filter::CBC is not an exception.
Well uhm kinda. Filter::CBC is even slower. Be warned, be VERY VERY warned.

=back

=over 3

=item *

You're source file is overwrittten when you're using the autoefilter feature.

=back

=head1 PARAMETERS

The two parameters that can be passed along are :

=over 2

=item CBC Handler

This parameter indicates what CBC encryption routine to use. Possible values are described in the next section.

=item Keyphrase

This parameter is the keyphrase for the encryption routine described as previous parameter.

=back

=head1 INTERNAL CBC HANDLERS

The following parameters can be passed as part of the CBC encryption routine

=over 2

=item Rijndael

This is the AES (Advanced Encryption Scheme) routine. You need 
Crypt::Rijndael for this.

=item DES

This is the DES routine. You need Crypt::DES for this.

=item IDEA

This is the IDEA routine. You need Crypt::IDEA for this.

=item Blowfish

This is the Blowfish routine. You need Crypt::Blowfish for this.

=item GOST

This is the GOST routine. You need Crypt::GOST for this.

=item DES_EDE3

This is the Triple DES routine. You need Crypt::DES_EDE3 for this.

=item Twofish

This is the Twofish routine. You need Crypt::Twofish for this.

=item NULL

This is the NULL routine. You need Crypt::NULL for this.

=item TEA

This is the TEA routine. You need Crypt::TEA for this.

=item RC6

This is the RC6 routine. You need Crypt::RC6 for this.

=item Serpent

This is the Serpent routine. You need Crypt::Serpent for this.
(Untested)

=back

But any CBC Compatible routine will work.

=head1 TEXT HANDLERS

As Paul Marquess noted, Filter has no problems with binary data. The text handlers
are totally unnecesary. I therefor removed them. You can still use hex encoding by using
the Filter::Hex module provided in the obsolete directory. If you have code that used the 
older version of Filter::CBC, I recommend stacking the HEX filter. Edit the use statement as follows :

  use Filter::Hex; use Filter::CBC "Rijndael","my secret key";

=head1 AUTOFILTERING

Since Filter::CBC 0.04, using code2cbc isn't required anymore. Filter::CBC can encrypt your code
on the fly if it's not yet encrypted. Be warned that your source file is overwritten. You can use
cbc2code.pl to decrypt your encrypted code. BACKUP!

  use Filter::CBC "Rijndael","my secret key";

  # This file will be encrypted and overwritten.
  # Make backups, damnit!
  # Autofilter example
  print "Don't try this at home, kids !";

This code will be encrypted the first time you run it. Everything before the 'use Filter::CBC' line is kept
intact. Filter::CBC sets a 'marker' so that double encryption doesn't occur.
If you see a comment stating 'This space is left blank intentionally', ignore it.

=head1 DEFAULTS

=over 3

=item Encryption routine

Filter::CBC will use Rijndael when no encryption algorithm is defined.

=back

=over 3

=item Keyphrase

Filter::CBC will use the following line when no keyphrase is defined :

=back

I<This space is left blank intentionally>

=head1 REQUIREMENTS

Filter::CBC requires the following modules (depending on your needs)

=over 3

=item Filter::Util::Call

=item Crypt::CBC

=item Crypt::Rijndael

=item Crypt::DES

=item Crypt::IDEA

=item Crypt::Blowfish

=item Crypt::GOST

=item Crypt::DES_EDE3

=item Crypt::Twofish

=item Crypt::NULL

=item Crypt::TEA

=item Crypt::RC6

=item Crypt::Serpent

=back

=head1 THANKS A MILLION

Alot of thanks to Ray Brinzer (Petruchio on Perlmonks) for giving an example
on how to handle parameters with use.

Paul Marquess for writing Filter and pointing out that Filter does what it should and not what I expect it to.

A bunch of monks at Perlmonks for giving some excellent and well appreciated feedback on 
detecting code. Thank you Blakem, Petral, Chipmunk, Tilly, Jepri and Zaxo.

=head1 TODO

A bit less then first release but still plenty.

=head1 DISCLAIMER

This code is released under GPL (GNU Public License). More information can be 
found on http://www.gnu.org/copyleft/gpl.html

=head1 VERSION

This is Filter::CBC 0.09

=head1 AUTHOR

Hendrik Van Belleghem (beatnik -at- quickndirty -dot- org)

=head1 SEE ALSO

GNU & GPL - http://www.gnu.org/copyleft/gpl.html

Filter::Util::Call - http://search.cpan.org/search?dist=Filter

Crypt::CBC - http://search.cpan.org/search?dist=Crypt-CBC

Crypt::Rijndael - http://search.cpan.org/search?dist=Crypt-Rijndael

Crypt::DES - http://search.cpan.org/search?dist=Crypt-DES

Crypt::IDEA - http://search.cpan.org/search?dist=Crypt-IDEA

Crypt::Blowfish - http://search.cpan.org/search?dist=Crypt-Blowfish

Crypt::GOST - http://search.cpan.org/search?dist=Crypt-GOST

Crypt::DES_EDE3 - http://search.cpan.org/search?dist=Crypt-DES_EDE3

Crypt::Twofish - http://search.cpan.org/search?dist=Crypt-Twofish

Crypt::NULL - http://search.cpan.org/search?dist=Crypt-NULL

Crypt::TEA - http://search.cpan.org/search?dist=Crypt-TEA

Crypt::RC6 - http://search.cpan.org/search?dist=Crypt-RC6

Crypt::Serpent - http://search.cpan.org/search?dist=Crypt-Serpent

Paul Marquess' article
on Source Filters - http://www.samag.com/documents/s=1287/sam03030004/

=cut
