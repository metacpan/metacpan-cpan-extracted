package Jacode;
######################################################################
#
# Jacode - Perl program for Japanese character code conversion
#
# https://metacpan.org/dist/Jacode
#
# Copyright (c) 2018, 2019, 2020, 2022, 2023 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '2.13.4.31';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
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

=encoding utf8

=head1 NAME

Jacode - Perl program for Japanese character code conversion

=head1 SYNOPSIS

  use FindBin;
  use lib "$FindBin::Bin/lib";
  use Jacode;
  
       ($subref, $got_INPUT_encoding) = Jacode::convert(\$line, $OUTPUT_encoding, $INPUT_encoding [, $option])
                  $got_INPUT_encoding = Jacode::convert(\$line, $OUTPUT_encoding, $INPUT_encoding [, $option])
              ($esc_DBCS, $esc_ASCII) = Jacode::get_inout($line)
  ($esc_DBCS_fully, $esc_ASCII_fully) = Jacode::jis_inout([$esc_DBCS [, $esc_ASCII]])
         ($matched_length, $encoding) = Jacode::getcode(\$line)
                            $encoding = Jacode::getcode(\$line)
                                        Jacode::init()

=head1 INSTALL of "Jacode.pm"

=over 2

=item 1. Open URL of "Jacode.pm"

L<https://metacpan.org/pod/Jacode>

=item 2. Click This

  ----------------------------------
  Source (raw) <--- Click this (raw)
  Browse (raw)
  Changes
  How to Contribute
  Repository
  Issues
  Testers (NNN / NNN / NNN)
  Kwalitee
  Bus factor: NN
  NN.NN% Coverage
  License: perl_5
  Perl: v5.5.30
  ----------------------------------

=item 3. Select All Text of Page

=item 4. Save Text as "Jacode.pm"

=back

=head1 DEPENDENCIES

This software requires perl 5.00503 or later.

=head1 SEE MORE

L<https://metacpan.org/dist/Jacode/view/lib/jacode.pl>

=cut

