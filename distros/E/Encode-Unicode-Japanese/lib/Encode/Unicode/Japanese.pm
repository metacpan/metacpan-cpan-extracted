## ----------------------------------------------------------------------------
#  Encode::Unicode::Japanese
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: Japanese.pm 4 2006-06-15 15:49:18Z hio $
# -----------------------------------------------------------------------------
package Encode::Unicode::Japanese;
use warnings;
use strict;
our $VERSION = '0.02';

use base qw(Encode::Encoding);
use Unicode::Japanese;

&_register_encodings;

1;

# -----------------------------------------------------------------------------
# Methods.
# -----------------------------------------------------------------------------

sub new($ $)
{
  my $pkg = shift;
	my $code = shift;
	bless \$code, $pkg;
}

sub encode($$;$)
{
  my ($obj, $str, $chk) = @_;
	my $code = $$obj;
  $str = Unicode::Japanese->new($str)->conv($code);
  $_[1] = '' if $chk; # this is what in-place edit means
  return $str;
}

sub decode($$;$)
{
  my ($obj, $buf, $chk) = @_;
	my $code = $$obj;
  $buf = Unicode::Japanese->new($buf, $code)->getu;
  $_[1] = '' if $chk; # this is what in-place edit means
  return $buf;
}

sub _register_encodings
{
  # triple Japanese encodings.
	#
  __PACKAGE__->new("sjis")->Define('unijp-sjis');
  __PACKAGE__->new("euc" )->Define('unijp-euc');
  __PACKAGE__->new("jis" )->Define('unijp-jis');
  
  # emoji, and variation.
  #  ex. imode, imode1, imode2
  __PACKAGE__->new("sjis-imode" )->Define("unijp-sjis-imode");
  __PACKAGE__->new("sjis-imode1")->Define("unijp-sjis-imode1");
  __PACKAGE__->new("sjis-imode2")->Define("unijp-sjis-imode2");
  __PACKAGE__->new("sjis-jsky" )->Define("unijp-sjis-jsky");
  __PACKAGE__->new("sjis-jsky1")->Define("unijp-sjis-jsky1");
  __PACKAGE__->new("sjis-jsky2")->Define("unijp-sjis-jsky2");
  
  # unicode variation.
  __PACKAGE__->new('utf8' )->Define("unijp-utf8");
  __PACKAGE__->new('ucs2' )->Define("unijp-ucs2");
  __PACKAGE__->new('utf16')->Define("unijp-utf16");
}

__END__

=head1 NAME

Encode::Unicode::Japanese - use Unicode::Japanese through Encode.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  use Encode::Unicode::Japanese;
  use Encode qw(encode from_to);
	 
  my $sjis = encode("unijp-sjis", $utf8); # utf8 => sjis
  from_to($buf, "unijp-sjis-imode", "unijp-sjis-jsky"); # imode => jsky

=head1 EXPORT

No functions are exported.

=head1 METHODS

=over 4

=item $pkg-E<gt>new($code)

create new instance.

=item $obj-E<gt>encode($string, [$check])

encode $string into utt-8 from $code which is specified at constructor.
an implementation of Encode::Encoding#encode.

=item $obj-E<gt>decode($string, [$check])

decode $string from utf-8 into $code which is specified at constructor.
an implementation of Encode::Encoding#decode.

=back

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at hio.jp> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-encode-unicode-japanese at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-Unicode-Japanese>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Encode::Unicode::Japanese

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Encode-Unicode-Japanese>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Encode-Unicode-Japanese>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Encode-Unicode-Japanese>

=item * Search CPAN

L<http://search.cpan.org/dist/Encode-Unicode-Japanese>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 YAMASHINA Hio, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
