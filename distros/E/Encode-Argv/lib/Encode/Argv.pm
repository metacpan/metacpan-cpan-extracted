# $Id: /mirror/coderepos/lang/perl/Encode-Argv/trunk/lib/Encode/Argv.pm 50486 2008-04-15T14:50:02.946222Z daisuke  $

package Encode::Argv;
use strict;
use warnings;
use 5.8.0;
use Encode ();
our $VERSION = '0.00002';

sub import
{
    my ($class, $decode_from, $encode_to) = @_;

    if (! $decode_from) {
        eval {
            require Term::Encoding;
            $decode_from = Term::Encoding::get_encoding();
        };
    }

    if ($decode_from) {
        foreach (@ARGV) {
            $_ = Encode::decode($decode_from, $_);
        }
    }

    if ($encode_to) {
        foreach (@ARGV) {
            $_ = Encode::encode($encode_to, $_);
        }
    }
}

1;

__END__

=head1 NAME

Encode::Argv - Automatically Mess With @ARGV's Encoding

=head1 SYNOPSIS

  use Encode::Argv ('cp932');
  # Now @ARGV is decoded unicode characters, decoded from cp932

  use Encode::Argv ('cp932' => 'euc-jp');
  # Now @ARGV is encoded into euc-jp after being decoded from cp932

  use Encode::Argv;
  # Now @ARGV is decoded from whatever Term::Encoding thinks you are
  # using on your terminal.

=head1 DESCRIPTION

I saw L<http://search.cpan.org/dist/Sjis|Sjis.pm> and L<http://www.aritia.org/hizumi/perl/perlwin.html|this>, and thought, "Well, I can't fix /all/ of their
problems, but I can at least start".

So here's a module that silently encodes/decodes your @ARGV from/to encodings
supported by Encode.pm

All you need to do is to simply specify the encodings you want to use:

  use Encode::Argv ('cp932');

There, you got yourself an unicode @ARGV on ShiftJIS Windows.

If in case you don't even want to explicitly specify what encoding to use,
you could rely on Term::Encoding to find out what you are using. In that
case you don't have to specify anything:

  use Encode::Argv;

If Term::Encoding is not found, no decoding will be performad

Of course, this doesn't solve the entire problem, but it's at least a start

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki C<< daisuke@endeworks.jp >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut