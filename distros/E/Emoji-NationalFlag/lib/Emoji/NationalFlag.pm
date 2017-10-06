package Emoji::NationalFlag;
use strict;
use warnings;
our $VERSION = '0.01';
use Locale::Country 'all_country_codes';

use Exporter 'import';
our @EXPORT_OK = qw(
    code2flag
    flag2code
);

our %A2SYM = map { (chr 0x61 + $_) => (pack U => 0x1f1e6 + $_) } 0 .. 25;

our %FLAG2CODE
    = reverse our %CODE2FLAG
    = map { $_ => join "", map { $A2SYM{$_} } split //, $_ } map { lc($_) } all_country_codes();

sub code2flag {
    my ($code) = @_;
    if (defined(my $flag = $CODE2FLAG{lc($code // '')})) {
        return $flag;
    }
    return;
}

sub flag2code {
    my ($flag) = @_;
    if (defined(my $code = $FLAG2CODE{$flag // ''})) {
        return lc $code;
    }
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Emoji::NationalFlag - convert from country code to national flag emoji

=head1 SYNOPSIS

  use Emoji::NationalFlag qw/ code2flag flag2code /;
  use utf8;

  is code2flag('jp'), "🇯🇵";
  is code2flag('jp'), "\x{1F1EF}\x{1F1f5}";

  is flag2code("🇯🇵"), 'jp';
  is flag2code("\x{1F1EF}\x{1F1f5}"), 'jp';

=head1 DESCRIPTION

Emoji::NationalFlag is a module to convert from country code (ISO 3166-1 alpha-2) to national flag emoji, and vice versa

=head1 METHODS

=head2 code2flag($iso_3166_1_alpha_2_code): Optional[NationalFlagEmoji]

This method returns national flag emoji if the supplied code (case insensitive) is valid, otherwise returns C<undef>

=head2 flag2code($decoded_national_flag_emoji): Optional[lc(CountryCodeAlpha-2)]

This method returns lower case of ISO 3166-1 alpha-2 country code if the supplied emoji is valid, otherwise returns C<undef>

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- punytan

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
