package Lingua::Strfname;

use strict;
require 5.006;
require Exporter;
use vars qw($VERSION @EXPORT @EXPORT_OK @ISA);

$VERSION = '0.13';
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(strfname);

sub strfname {
    my $format = shift;
    my %t = ( '%' => '%' );

    foreach my $a (0..$#_) {
        my $def = defined $_[$a] && $_[$a] ne '';
        $t{qw(l f m p s g a b c d e)[$a]} = $def && $_[$a];
        $t{qw(L F M _ _ _ A B C D E)[$a]} = $def && substr($_[$a], 0, 1) . '.';
        $t{qw(T S I _ _ _ 1 2 3 4 5)[$a]} = $def && substr($_[$a], 0, 1);
    }

    local $^W;
    $format =~ s/%([^lfmpsgxsabcdeLFMABCDETSI12345%]*)(.)/($_ = $t{$2}) && "$1$_"/ge;
    return $format;
}

1;
__END__

=pod

=head1 NAME

Lingua::Strfname - Formats people's names

=head1 SYNOPSIS

  use Lingua::Strfname;

  my $format = "%f% m% l";
  my @names = qw(Clinton William Jefferson Mr. JD);
  my $name = strfname($format, @names);

=head1 DESCRIPTION

This module exports one function, strfname():

  strfname($format, $last, $first, $middle, $prefix, $suffix, $generation,
           @extra_names)

The strfname function uses the formatting string passed in $format to format a
person's name. The remaining arguments make up the name: last/family name ,
first/given name, middle/second name, prefix ('Mr.', 'Ms.', 'Dr.', etc.),
suffix ('Ph.D., 'MD', etc.), and generation ('III', 'Jr.', etc.). Up to five
additional names may also be passed.

The formats are roughly based on the ideas behind sprintf formatting or strftime
formatting. Each format is denoted by a percent sign (%) and a single
alpha-numeric character. The character represents the data that will be filled
in to the string. Any non-alphanumeric characters placed between the % and the
conversion character will be included in the string B<only if> the data
represented by the conversion character exists.

For example, if I wanted to get a full name, but didn't have a middle name, I
would specify a format string like so:

  my $format = "%f% m% l";

In which case, this call

  strfname($format, 'Clinton', 'William');

would yield 'William Clinton'. But this call

  strfname($format, 'Clinton', 'William', 'Jefferson');

would yield 'William Jefferson Clinton'. Similarly, you can add a comma where
you need one, but only if you need one:

  strfname("%p% f% M% l% g%, s", 'Clinton', 'William', 'Jefferson', 'Mr.',
           'JD', 'III');

would yield 'Mr. William J. Clinton III, JD', but if there is no suffix
(delete 'JD' from the call above), it yeilds 'Mr. William J. Clinton III',
leaving off the comma that would preceed the suffix, if it existed.

Here are the supported formats:

  %l Last Name
  %f First Name
  %m Middle Name
  %p Prefix
  %s Suffix
  %g Generation
  %L Last Name Initial with period
  %F First Name Initial with period
  %M Middle Name Initial with period
  %T Last Name Initial
  %S First Name Initial
  %I Middle Name Initial
  %a Extra Name 1
  %b Extra Name 2
  %c Extra Name 3
  %d Extra Name 4
  %e Extra Name 5
  %A Extra Name 1 Initial with period
  %B Extra Name 2 Initial with period
  %C Extra Name 3 Initial with period
  %D Extra Name 4 Initial with period
  %E Extra Name 5 Initial with period
  %1 Extra Name 1 Initial
  %2 Extra Name 2 Initial
  %3 Extra Name 3 Initial
  %4 Extra Name 4 Initial
  %5 Extra Name 5 Initial

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/lingua-strfname/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/lingua-strfname/issues/> or by sending mail to
L<bug-Lingua-Strfname.cpan.org|mailto:bug-Lingua-Strfname.cpan.org>.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>, with implementation assistance from
David Lowe.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2000-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
