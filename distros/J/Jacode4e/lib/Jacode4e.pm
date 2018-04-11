package Jacode4e;
######################################################################
#
# Jacode4e - jacode.pl-like program for enterprise
#
# Copyright (c) 2018 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################
$VERSION = '2.13.6.5';
$VERSION = $VERSION;

use strict;
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

Jacode4e - jacode.pl-like program for enterprise

=head1 SYNOPSIS

  use FindBin;
  use lib "$FindBin::Bin/lib";
  use Jacode4e;
 
  $return =
  Jacode4e::convert(\$line, $OUTPUT_encoding, $INPUT_encoding [, { %option }]);
 
    $return
      Number of characters in $line
 
    $line
      String variable to convert
      After conversion, this variable is overwritten
 
    $OUTPUT_encoding, and $INPUT_encoding
      To convert, you must specify both $OUTPUT_encoding and $INPUT_encoding.
      The encodings you can specify are as follows:
 
      mnemonic      means
      -----------------------------------------------------------------------
      cp932x        CP932X, Extended CP932 to JIS X 0213 using 0x9C5A as single shift
      cp932         CP932
      sjis2004      Shift_JIS-2004
      cp00930       IBM CP00930(CP00290+CP00300), CCSID 5026 katakana
      keis78        HITACHI KEIS78
      keis83        HITACHI KEIS83
      keis90        HITACHI KEIS90
      jef           FUJITSU JEF
      jipsj         NEC JIPS(J)
      jipse         NEC JIPS(E)
      utf8          UTF-8
      utf8jp        UTF-8-SPUA-JP, JIS X 0213 on SPUA ordered by JIS level, plane, row, cell
      -----------------------------------------------------------------------
 
    %option
      The options you can specify are as follows:
 
      key mnemonic     value means
      -----------------------------------------------------------------------
      INPUT_LAYOUT     input record layout by 'S' and 'D' sequence
                       'S' means one char as SBCS, 'D' means one char as DBCS
      OUTPUT_SHIFTING  true means use output shift code, false means not use
                       default is false
      SPACE            output space code in DBCS
      GETA             output geta code in DBCS
      -----------------------------------------------------------------------

=head1 SAMPLES

  use FindBin;
  use lib "$FindBin::Bin/lib";
  use Jacode4e;
  Jacode4e::VERSION('2.13.6.5');
  while (<>) {
      $return =
      Jacode4e::convert(\$_, 'cp932x', 'cp00930', {
          'INPUT_LAYOUT'    => 'SSSDDDSSDDSDSD',
          'OUTPUT_SHIFTING' => 0,
          'SPACE'           => "\x81\xA2",
          'GETA'            => "\x81\xA1",
      });
      print $_;
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

