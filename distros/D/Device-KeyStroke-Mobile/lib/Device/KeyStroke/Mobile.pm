package Device::KeyStroke::Mobile;

use strict;
use vars qw($VERSION @EXPORT $KeyMapping);
$VERSION = 0.01;

require Exporter;
*import = \&Exporter::import;
@EXPORT = qw(calc_keystroke);

$KeyMapping = {
    1 => '',
    2 => 'ABC',
    3 => 'DEF',
    4 => 'GHI',
    5 => 'JKL',
    6 => 'MNO',
    7 => 'PQRS',
    8 => 'TUV',
    9 => 'WXYZ',
    '*' => '.-@/',
    0 => '',
    '#' => '', 
};

sub _croak { require Carp; Carp::croak(@_) }

sub calc_keystroke {
    my $text = uc(shift);
    my $lookup = _build_lookup($KeyMapping); # XXX need cache? but
                                             # mapping can be modified ...

    my $typing_times = 0;
    my $prev = '';
    for my $i (0 .. length($text) - 1) {
	my $char = substr($text, $i, 1);
	my $table = $lookup->{$char}
	    or _croak("don't know how to type $char");
	my($time, $keypad) = @{$lookup->{$char}};
	$typing_times += $time;
	$typing_times++  if $prev eq $keypad; # for ">" key
	$prev = $keypad;
    }

    return $typing_times;
}

sub _build_lookup {
    my $mapping = shift;
    my %lookup;
    while (my($key, $values) = each %$mapping) {
	for my $len (1..length($values)) {
	    my $char = substr($values, $len - 1, 1);
	    if (exists $lookup{$char}) {
		next if $len > $lookup{$char}->[0]; # already has shorter one
	    }
	    $lookup{$char} = [ $len, $key ];
	}
    }
    return \%lookup;
}

1;
__END__

=head1 NAME

Device::KeyStroke::Mobile - Calculate key stroke times with mobile phone keypads

=head1 SYNOPSIS

  use Device::KeyStroke::Mobile;
  my $typing_times = calc_keystroke('example.com');

=head1 DESCRIPTION

Device::KeyStroke::Mobile is a module to calculate how many times you
need to type keypads in mobile phone to build a word. For example,
when you type C<example.com> with a mobile keypad,

  e: 3 3
  x: 9 9
  a: 2
  m: 6
  p: 7
  l: 5 5 5
  e: 3 3
  .: *
  c: 2 2 2
  o: 6 6 6 >
  m: 6

you need to type keys B<21> times.

This module would be useful when you conider taking a new domain name
which is easy to type with mobile phones.

=head1 FUNCTIONS

This module exports following functions by default.

=over 4

=item calc_keystroke

  $typing_times = calc_keystroke($text);

takes any text you wish to type in mobile phone and calculates how
many typings you need to build it. If C<$text> includes non-allowed
characters (see L</"KEY MAPPING">), it would throw an exception. Note
that this function u2c()es C<$text> first, so it ignores cases.

=back

=head1 KEY MAPPING

By default this module uses following key mapping:

        <   >

  [ 1 ] [ 2 ] [ 3 ]
         ABC   DEF

  [ 4 ] [ 5 ] [ 6 ¡×
   GHI   JKL   MNO

  [ 7 ] [ 8 ] [ 9 ]
  PQRS   TUV  WXYZ

  [ * ] [ 0 ] [ # ]
  .-@_/

This mapping is defined in C<$KeyMapping> package variable (hash-ref)
in Device::KeyStroke namespace. You can modify it like:

  $Device::KeyStroke::Mobile::KeyMapping->{1} = q[.@-_/:~];
  $Device::KeyStroke::Mobile::KeyMapping->{*} = q[];
  $Device::KeyStroke::Mobile::KeyMapping->{#} = q[,!?()#];

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Text::T9>

=cut
