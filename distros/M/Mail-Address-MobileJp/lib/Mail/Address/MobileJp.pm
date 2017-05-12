package Mail::Address::MobileJp;

use strict;
use vars qw($VERSION);
$VERSION = '0.09';

BEGIN {
    require Exporter;
    @Mail::Address::MobileJp::ISA    = qw(Exporter);
    @Mail::Address::MobileJp::EXPORT = qw(is_mobile_jp is_imode is_vodafone is_ezweb is_softbank);
}

# This regex is generated using http://www.mag2.com/faq/mobile.htm

my $regex_mobile = qr@^(?:
dct\.dion\.ne\.jp|
tct\.dion\.ne\.jp|
hct\.dion\.ne\.jp|
kct\.dion\.ne\.jp|
cct\.dion\.ne\.jp|
sct\.dion\.ne\.jp|
qct\.dion\.ne\.jp|
oct\.dion\.ne\.jp|
email\.sky\.tdp\.ne\.jp|
email\.sky\.kdp\.ne\.jp|
email\.sky\.cdp\.ne\.jp|
sky\.tu\-ka\.ne\.jp|
cara\.tu\-ka\.ne\.jp|
sky\.tkk\.ne\.jp|
.*\.sky\.tkk\.ne\.jp|
sky\.tkc\.ne\.jp|
.*\.sky\.tkc\.ne\.jp|
email\.sky\.dtg\.ne\.jp|
em\.nttpnet\.ne\.jp|
.*\.em\.nttpnet\.ne\.jp|
cmchuo\.nttpnet\.ne\.jp|
cmhokkaido\.nttpnet\.ne\.jp|
cmtohoku\.nttpnet\.ne\.jp|
cmtokai\.nttpnet\.ne\.jp|
cmkansai\.nttpnet\.ne\.jp|
cmchugoku\.nttpnet\.ne\.jp|
cmshikoku\.nttpnet\.ne\.jp|
cmkyusyu\.nttpnet\.ne\.jp|
pdx\.ne\.jp|
d.\.pdx\.ne\.jp|
wm\.pdx\.ne\.jp|
phone\.ne\.jp|
.*\.mozio\.ne\.jp|
page\.docomonet\.or\.jp|
page\.ttm\.ne\.jp|
pho\.ne\.jp|
moco\.ne\.jp|
emcm\.ne\.jp|
p1\.foomoon\.com|
mnx\.ne\.jp|
.*\.mnx\.ne\.jp|
ez.\.ido\.ne\.jp|
cmail\.ido\.ne\.jp|
.*\.i\-get\.ne\.jp|
willcom\.com
)$@x; # end of qr@@

my $regex_imode = qr@^(?:
docomo\.ne\.jp
)$@x; # end of qr@@

my $regex_vodafone = qr@^(?:
jp\-[dhtckrnsq]\.ne\.jp|
[dhtckrnsq]\.vodafone\.ne\.jp|
softbank\.ne\.jp|
disney.ne.jp
)$@x; # end of qr@@

my $regex_ezweb = qr@^(?:
ezweb\.ne\.jp|
.*\.ezweb\.ne\.jp
)$@x; # end of qr@@


sub is_imode {
    my $domain = _domain(shift);
    return $domain && $domain =~ /$regex_imode/o;
}

sub is_vodafone {
    my $domain = _domain(shift);
    return $domain && $domain =~ /$regex_vodafone/o;
}

*is_softbank = \&is_vodafone;

sub is_ezweb {
    my $domain = _domain(shift);
    return $domain && $domain =~ /$regex_ezweb/o;
}

sub is_mobile_jp {
    my $domain = _domain(shift);
    return $domain && $domain =~ /(?:$regex_imode|$regex_vodafone|$regex_ezweb|$regex_mobile)/o;
}

sub _domain {
    my $stuff = shift;
    if (ref($stuff) && $stuff->isa('Mail::Address')) {
        return $stuff->host;
    }
    my $i = rindex($stuff, '@');
    return $i >= 0 ? substr($stuff, $i + 1) : undef;
}

1;
__END__

=head1 NAME

Mail::Address::MobileJp - mobile email address in Japan

=head1 SYNOPSIS

  use Mail::Address::MobileJp;

  my $email = '123456789@docomo.ne.jp';
  if (is_mobile_jp($email)) {
      print "$email is mobile email in Japan";
  }

  # extract mobile email address from an array of addresses
  my @mobile = grep { is_mobile_jp($_) } @addr;

=head1 DESCRIPTION

Mail::Address::MobileJp is an utility to detect an email address is
mobile (cellphone) email address or not.

This module should be updated heavily :)

=head1 FUNCTION

This module exports following function(s).

=over 4

=item is_mobile_jp

  $bool = is_mobile_jp($email);

returns whether C<$email> is a mobile email address or not. C<$email>
can be an email string or Mail::Address object.

=item is_imode

  $bool = is_imode($email);

returns whether C<$email> is a i-mode email address or not. C<$email>
can be an email string or Mail::Address object.

=item is_vodafone

  $bool = is_vodafone($email);

returns whether C<$email> is a vodafone(j-sky) email address or not. C<$email>
can be an email string or Mail::Address object.

=item is_ezweb

  $bool = is_ezweb($email);

returns whether C<$email> is a ezweb email address or not. C<$email>
can be an email string or Mail::Address object.

=item is_softbank

  $bool = is_softbank($email);

returns whether C<$email> is a softbank email address or not. C<$email>
can be an email string or Mail::Address object.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mail::Address>, http://www.mag2.com/faq/mobile.htm

=cut
