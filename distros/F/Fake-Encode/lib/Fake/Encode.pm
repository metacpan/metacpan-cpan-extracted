package Fake::Encode;
######################################################################
#
# Fake::Encode - Fake Encode module for compatible scripting
#
# http://search.cpan.org/dist/Fake-Encode/
#
# Copyright (c) 2016, 2017, 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.10';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;

sub Encode::decode {
    my(undef, $human_readable_string) = @_;
    my $jperl_readable_string = $human_readable_string;
    return $jperl_readable_string;
}

sub Encode::encode {
    my(undef, $jperl_readable_string) = @_;
    my $human_readable_string = $jperl_readable_string;
    return $human_readable_string;
}

1;

__END__

=pod

=head1 NAME

Fake::Encode - Fake Encode module for compatible scripting

=head1 SYNOPSIS

  use Fake::Encode;
  use DBI;
  
  ...;
  
  # turn off the utf8 flag as soon as possible to avoid mojibake
  while (my @row = map { Encode::encode('cp932',$_) } $sth->fetchrow_array()) {
      ...;
  }

=head1 DESCRIPTION

Fake::Encode provides a scripting environment with long life by dummy subroutines
Encode::encode() and Encode::decode().

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt> in a CPAN

This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

This software is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

=over 4

=item * L<Encode|http://search.cpan.org/dist/Encode/> - CPAN

=item * L<Encode561.pm - Encode::from_to compatible for Perl 5.6.x and 5.005|http://www.kawa.net/works/perl/i18n-emoji/Encode561.pm.html> - www.kawa.net

=item * L<Encode::compat|http://search.cpan.org/dist/Encode-compat/> - CPAN

=item * L<Porting code from perl-5.6.X|http://perldoc.perl.org/perlunicode.html#Porting-code-from-perl-5.6.X> - perldoc

=item * L<Perl 5.6+: Unicode-processing issues and how to cope with it.|http://ahinea.com/en/tech/perl-5.6-unicode-struggle.html> - ahinea.com

=item * L<Correct processing method of the UTF-8 flag|http://blog.livedoor.jp/dankogai/archives/50116398.html> - blog.livedoor.jp/dankogai/

=item * L<perl - utf8::is_utf8("\x{ff}") == 0|http://blog.livedoor.jp/dankogai/archives/51004472.html> - blog.livedoor.jp/dankogai/

=item * L<To the person who fights against UTF-8 flag|http://blog.livedoor.jp/nipotan/archives/50228106.html> - blog.livedoor.jp/nipotan/

=item * L<utf8::is_utf8 considered harmful|https://subtech.g.hatena.ne.jp/miyagawa/20080218/1203312527> - subtech.g.hatena.ne.jp/miyagawa/

=item * L<Migrating scripts back to Perl 5.005_03|http://www.perlmonks.org/?node_id=289351> - PerlMonks

=item * L<Goodnight, Perl 5.005|http://www.oreillynet.com/onlamp/blog/2007/11/goodnight_perl_5005.html> - ONLamp.com

=item * L<Perl 5.005_03 binaries|http://guest.engelschall.com/~sb/download/win32/> - engelschall.com

=item * L<Welcome to CP5.5.3AN|http://cp5.5.3an.barnyard.co.uk/> - cp5.5.3an.barnyard.co.uk

=item * L<japerl|http://search.cpan.org/dist/japerl/> - CPAN

=item * L<ina|http://search.cpan.org/~ina/> - CPAN

=item * L<A Complete History of CPAN|http://backpan.perl.org/authors/id/I/IN/INA/> - The BackPAN

=back

=cut

