# $Id: /mirror/coderepos/lang/perl/Encode-StdIO/trunk/lib/Encode/StdIO.pm 50483 2008-04-15T14:45:42.926236Z daisuke  $

package Encode::StdIO;
use strict;
use warnings;
use 5.008;
our $VERSION = '0.00001';

sub import
{
    my $class = shift;
    my %args  = @_;

    my $encoding = $class->find_encoding(%args);
    binmode(STDOUT, ":encoding($encoding)");
    binmode(STDERR, ":encoding($encoding)");
    binmode(STDIN,  ":encoding($encoding)");
}

sub find_encoding
{
    my $class = shift;
    my %args  = @_;

    my $encoding = $args{encoding};
    if (! $encoding) {
        eval {
            require Term::Encoding;
            $encoding = Term::Encoding::get_encoding();
        };
    }
    $encoding ||= "utf-8";
    return $encoding;
}

1;

__END__

=head1 NAME

Encode::StdIO - Setup STDIN/STDOUT/STDERR With Proper Encodings

=head1 SYNOPSIS

  use Encode::StdIO;
  # Use Term::Encoding to figure out the encoding

  use Encode::StdIO encoding => 'sjis';
  # Now perl octets sent to STDOUT/STDERR automatically gets encoded to sjis

=head1 DESCRIPTION

Encode::StdIO automatically sets up your STDIN/STDOUT/STDERR with whatever
encoding you're using.

You can specify explicitly what encoding you want to setup:

  use Encode::StdIO encoding => 'sjis';

or you can let Term::Encoding figure out what you are using:

  use Encode::StdIO;

If Term::Encoding fails to find the encoding, then utf-8 is assumed.

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki C<< daisuke@endeworks.jp >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut