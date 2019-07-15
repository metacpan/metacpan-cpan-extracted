package Jacode;
######################################################################
#
# Jacode - Perl program for Japanese character code conversion
#
# Copyright (c) 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '2.13.4.21';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;
use vars qw($AUTOLOAD);

sub AUTOLOAD {
    return if $AUTOLOAD =~ /::DESTROY$/;

    require File::Basename;
    require "@{[File::Basename::dirname(__FILE__)]}/\L@{[__PACKAGE__]}\E.pl";
    (my $callee = $AUTOLOAD) =~ s<^@{[__PACKAGE__]}::><\L@{[__PACKAGE__]}\E::>;

    no strict qw(refs);
    *{$AUTOLOAD} = sub {
        require Carp;
        local $@;
        my $return = eval {
            &$callee;
        };
        if ($@) {
            Carp::croak($@);
        }
        return $return;
    };

    goto &$AUTOLOAD;
}

sub DESTROY { }

1;

__END__

=pod

=head1 NAME

Jacode - Perl program for Japanese character code conversion

=head1 SYNOPSIS

    use FindBin;
    use lib "$FindBin::Bin/lib";
    use Jacode;

    Jacode::convert(\$line, $OUTPUT_encoding [, $INPUT_encoding [, $option]])
    Jacode::xxx2yyy(\$line [, $option])
    Jacode::to($OUTPUT_encoding, $line [, $INPUT_encoding [, $option]])
    Jacode::jis($line [, $INPUT_encoding [, $option]])
    Jacode::euc($line [, $INPUT_encoding [, $option]])
    Jacode::sjis($line [, $INPUT_encoding [, $option]])
    Jacode::utf8($line [, $INPUT_encoding [, $option]])
    Jacode::jis_inout($JIS_Kanji_IN, $ASCII_IN)
    Jacode::get_inout($line)
    Jacode::cache()
    Jacode::nocache()
    Jacode::flushcache()
    Jacode::flush()
    Jacode::h2z_xxx(\$line)
    Jacode::z2h_xxx(\$line)
    Jacode::tr(\$line, $from, $to [, $option])
    Jacode::trans($line, $from, $to [, $option])
    Jacode::init()

=head1 SAMPLES

Convert SJIS to JIS and print each line with code name

  use FindBin;
  use lib "$FindBin::Bin/lib";
  #require 'jcode.pl';
  use Jacode;
  while (defined($s = <>)) {
      #$code = &jcode'convert(\$s, 'jis', 'sjis');
      $code = Jacode::convert(\$s, 'jis', 'sjis');
      print $code, "\t", $s;
  }

Convert SJIS to UTF-8 and print each line by perl 5.00503 or later

  use FindBin;
  use lib "$FindBin::Bin/lib";
  #retire 'jcode.pl';
  no Jcode;
  use Jacode;
  while (defined($s = <>)) {
      Jacode::convert(\$s, 'utf8', 'sjis');
      print $s;
  }

Convert SJIS to UTF16-BE and print each line by perl 5.8.1 or later

  use FindBin;
  use lib "$FindBin::Bin/lib";
  use Jacode;
  use 5.8.1;
  while (defined($s = <>)) {
      Jacode::convert(\$s, 'UTF16-BE', 'sjis');
      print $s;
  }

Convert SJIS to MIME-Header-ISO_2022_JP and print each line by perl 5.8.1 or later

  use FindBin;
  use lib "$FindBin::Bin/lib";
  use Jacode;
  use 5.8.1;
  while (defined($s = <>)) {
      Jacode::convert(\$s, 'MIME-Header-ISO_2022_JP', 'sjis');
      print $s;
  }

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt> in a CPAN

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

