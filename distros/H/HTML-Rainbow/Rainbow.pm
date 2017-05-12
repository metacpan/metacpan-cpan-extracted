# HTML::Rainbow.pm
#
# Copyright (c) 2005-2009 David Landgren
# All rights reserved

package HTML::Rainbow;

use strict;
use Exporter;
use Tie::Cycle::Sinewave;

use vars qw/$VERSION @PRIMES @ISA @EXPORT_OK/;

$VERSION = '0.06';
@ISA     = ('Exporter');
@PRIMES  = qw(17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79);

=head1 NAME

HTML::Rainbow - Put colour into your HTML

=head1 VERSION

This document describes version 0.06 of HTML::Rainbow, released
2009-10-04.

=head1 SYNOPSIS

  use HTML::Rainbow 'rainbow';
  print rainbow('hello, world');

=head1 DESCRIPTION

C<HTML::Rainbow> will take plain text string (or array of strings)
and mark it up with C<< <font> >> tags (or C<< <span> >> tags
if you're feeling particularly orthodox), and produce text that
drifts endlessly from one colour to the next.

The intensity of the red, green and blue channels follow mutually
prime sinusoidal periods.

=for html
<p>This comes in handy when you have the burning desire
to say</p>
<blockquote><font color="#737373">P</font><font
color="#7c797c">e</font><font color="#858085">r</font><font
color="#8e878e">l</font> <font color="#978d97">i</font><font
color="#9f949f">s</font> <font color="#a89aa8">a</font> <font
color="#afa0af">l</font><font color="#b7a7b7">a</font><font
color="#beacbe">n</font><font color="#c4b2c4">g</font><font
color="#c9b7c9">u</font><font color="#cebcce">a</font><font
color="#d2c1d2">g</font><font color="#d6c5d6">e</font> <font
color="#d8c9d8">o</font><font color="#dacdda">p</font><font
color="#dbd0db">t</font><font color="#dbd3db">i</font><font
color="#dbd5db">m</font><font color="#dad8d6">i</font><font
color="#d9d9cc">z</font><font color="#d7dabf">e</font><font
color="#d6dbad">d</font> <font color="#d4db99">f</font><font
color="#d1db83">o</font><font color="#cfda6d">r</font> <font
color="#ccd656">s</font><font color="#c8d141">c</font><font
color="#c5ca2e">a</font><font color="#c1c21f">n</font><font
color="#bdb813">n</font><font color="#b9ad0c">i</font><font
color="#b5a00a">n</font><font color="#b0930c">g</font> <font
color="#ab860d">a</font><font color="#a6780e">r</font><font
color="#a16a0f">b</font><font color="#9c5c10">i</font><font
color="#964f12">t</font><font color="#914213">r</font><font
color="#8b3615">a</font><font color="#852b17">r</font><font
color="#802119">y</font> <font color="#7a191b">t</font><font
color="#74131d">e</font><font color="#6e0e1f">x</font><font
color="#680b22">t</font> <font color="#630a24">f</font><font
color="#5d0a27">i</font><font color="#572129">l</font><font
color="#52522c">e</font><font color="#4c8d2f">s</font><font
color="#47c032">,</font> <font color="#41da35">e</font><font
color="#3cd338">x</font><font color="#37d13b">t</font><font
color="#33ce3f">r</font><font color="#2ecb42">a</font><font
color="#2ac845">c</font><font color="#26c449">t</font><font
color="#22c04c">i</font><font color="#1ebc50">n</font><font
color="#1bb854">g</font> <font color="#18b457">i</font><font
color="#15af5b">n</font><font color="#13aa5f">f</font><font
color="#10a562">o</font><font color="#0ea066">r</font><font
color="#0d9b6a">m</font><font color="#0b956e">a</font><font
color="#0b9072">t</font><font color="#0a8a75">i</font><font
color="#0a8479">o</font><font color="#0a7e7d">n</font> <font
color="#0a7981">f</font><font color="#0a7385">r</font><font
color="#0b6d88">o</font><font color="#0c678c">m</font> <font
color="#0d6190">t</font><font color="#0e5c93">h</font><font
color="#0f5697">o</font><font color="#11509b">s</font><font
color="#134b9e">e</font> <font color="#1546a2">t</font><font
color="#1740a5">e</font><font color="#193ba8">x</font><font
color="#1b36ab">t</font> <font color="#1e32af">f</font><font
color="#202db2">i</font><font color="#2329b5">l</font><font
color="#2625b8">e</font><font color="#2921ba">s</font><font
color="#2d1ebd">,</font> <font color="#301ac0">a</font><font
color="#3317c2">n</font><font color="#3714c5">d</font> <font
color="#3b12c7">p</font><font color="#3f10c9">r</font><font
color="#420ecb">i</font><font color="#460ccd">n</font><font
color="#4a0bcf">t</font><font color="#4f0ad1">i</font><font
color="#530ad3">n</font><font color="#570ad4">g</font> <font
color="#5b0ad5">r</font><font color="#600ad7">e</font><font
color="#640cd8">p</font><font color="#680ed9">o</font><font
color="#6d12d9">r</font><font color="#7115da">t</font><font
color="#761adb">s</font> <font color="#7a1fdb">b</font><font
color="#7e25db">a</font><font color="#832cdb">s</font><font
color="#8733db">e</font><font color="#8c3bda">d</font> <font
color="#9043d7">o</font><font color="#944bd2">n</font> <font
color="#9854cc">t</font><font color="#9c5dc4">h</font><font
color="#a066ba">a</font><font color="#a470af">t</font> <font
color="#a879a3">i</font><font color="#ac8296">n</font><font
color="#b08b89">f</font><font color="#b3947b">o</font><font
color="#b79d6d">r</font><font color="#baa55f">m</font><font
color="#bdad51">a</font><font color="#c0b544">t</font><font
color="#c3bc38">i</font><font color="#c6c22d">o</font><font
color="#c8c823">n</font><font color="#cbcd1b">.</font> <font
color="#cdd114">I</font><font color="#cfd50f">t</font><font
color="#d1d80b">'</font><font color="#d3da0a">s</font> <font
color="#d5db0a">a</font><font color="#d6db0c">l</font><font
color="#d8db10">s</font><font color="#d9da16">o</font> <font
color="#dad91d">a</font> <font color="#dad726">g</font><font
color="#dbd530">o</font><font color="#dbd33c">o</font><font
color="#dbd048">d</font> <font color="#dbcd55">l</font><font
color="#dbc963">a</font><font color="#dac571">n</font><font
color="#d6c17f">g</font><font color="#d0bc8d">u</font><font
color="#c9b79a">a</font><font color="#c1b2a7">g</font><font
color="#b7acb2">e</font> <font color="#aba6bd">f</font><font
color="#9fa0c6">o</font><font color="#929ace">r</font> <font
color="#8494d4">m</font><font color="#778dd8">a</font><font
color="#6986db">n</font><font color="#5b80db">y</font> <font
color="#4d79da">s</font><font color="#4172d8">y</font><font
color="#356bd6">s</font><font color="#2a65d2">t</font><font
color="#205ece">e</font><font color="#1857c9">m</font> <font
color="#1251c4">m</font><font color="#0d4abe">a</font><font
color="#0b44b7">n</font><font color="#0a3eb0">a</font><font
color="#0a38a8">g</font><font color="#2233a0">e</font><font
color="#532e97">m</font><font color="#8f298e">e</font><font
color="#c12485">n</font><font color="#da207c">t</font> <font
color="#d31c73">t</font><font color="#ad1869">a</font><font
color="#741560">s</font><font color="#3b1257">k</font><font
color="#140f4e">s</font><font color="#0a0d46">.</font> <font
color="#220c3e">T</font><font color="#330b36">h</font><font
color="#460a2e">e</font> <font color="#5b0a28">l</font><font
color="#720a21">a</font><font color="#890a1c">n</font><font
color="#9e0a17">g</font><font color="#b20b13">u</font><font
color="#c20c0f">a</font><font color="#cf0c0d">g</font><font
color="#d80d0b">e</font> <font color="#db0e0a">i</font><font
color="#da100a">s</font> <font color="#d9110a">i</font><font
color="#d7120f">n</font><font color="#d51419">t</font><font
color="#d21626">e</font><font color="#d01838">n</font><font
color="#cc1a4c">d</font><font color="#c81c62">e</font><font
color="#c41e78">d</font> <font color="#c0208f">t</font><font
color="#bb23a4">o</font> <font color="#b625b6">b</font><font
color="#b128c6">e</font> <font color="#ab2ad2">p</font><font
color="#a52dd9">r</font><font color="#9f30db">a</font><font
color="#9933d9">c</font><font color="#9336d8">t</font><font
color="#8c39d6">i</font><font color="#853dd4">c</font><font
color="#7f40d2">a</font><font color="#7843cf">l</font> <font
color="#7147cc">(</font><font color="#6a4ac9">e</font><font
color="#644ec5">a</font><font color="#5d51c2">s</font><font
color="#5655be">y</font> <font color="#5059b9">t</font><font
color="#4a5cb5">o</font> <font color="#4360b0">u</font><font
color="#3d64ac">s</font><font color="#3868a7">e</font><font
color="#326ca2">,</font> <font color="#2d6f9c">e</font><font
color="#287397">f</font><font color="#237791">f</font><font
color="#1f7b8c">i</font><font color="#1b7f86">c</font><font
color="#178280">i</font><font color="#14867a">e</font><font
color="#118a75">n</font><font color="#0f8e6f">t</font><font
color="#0d9169">,</font> <font color="#0c9563">c</font><font
color="#0a985d">o</font><font color="#0a9c58">m</font><font
color="#0a9f52">p</font><font color="#0aa34d">l</font><font
color="#0ba647">e</font><font color="#0fa942">t</font><font
color="#15ad3d">e</font><font color="#1cb038">)</font> <font
color="#24b333">r</font><font color="#2eb62f">a</font><font
color="#39b92a">t</font><font color="#46bc26">h</font><font
color="#53be22">e</font><font color="#60c11f">r</font> <font
color="#6ec31b">t</font><font color="#7cc618">h</font><font
color="#8ac815">a</font><font color="#98ca13">n</font> <font
color="#a4cc10">b</font><font color="#b0ce0f">e</font><font
color="#bbd00d">a</font><font color="#c5d20c">u</font><font
color="#cdd30b">t</font><font color="#d3d50a">i</font><font
color="#d8d60a">f</font><font color="#dad70a">u</font><font
color="#dbd80a">l</font> <font color="#dbd90b">(</font><font
color="#dada0d">t</font><font color="#d9da10">i</font><font
color="#d7db13">n</font><font color="#d5db17">y</font><font
color="#d3db1c">,</font> <font color="#d1db22">e</font><font
color="#cedb28">l</font><font color="#cbd82f">e</font><font
color="#c7d037">g</font><font color="#c4c43e">a</font><font
color="#c0b447">n</font><font color="#bca14f">t</font><font
color="#b88b58">,</font> <font color="#b37561">m</font><font
color="#af5e6a">i</font><font color="#aa4874">n</font><font
color="#a5357d">i</font><font color="#9f2486">m</font><font
color="#9a178f">a</font><font color="#950e98">l</font><font
color="#8f0aa1">)</font><font color="#890ba9">.</font></blockquote>

Win friends, and influence enemies, on your favourite
HTML bulletin board.

=head1 METHODS

=over 8

=item B<new>

Creates a new C<HTML::Rainbow> object. A set of key/value parameters
can be supplied to control the finer details of the object's
behaviour.

The colour-space of HTML is defined by a tuple of red, green and
blue components. Each component can vary between 0 and 255. Setting
all components to 0 produces black, and setting them all to 255
produces white. The parameters for C<new()> allow you to control
the behaviour of the components, either individually or as a whole.

Each value may be specifed as a number from 0 to 255, or as a
percentage (such as C<50%>). Percentages are rounded to the nearest
integer, and values out of range are clipped to the nearest bound.

=over 4

=item min

Sets the minimum value for all three components. For example, a
value of 0 (zero) may result in white being produced. This may
produce invisible text if the background colour is also white.
Hence, one may wish to use a value between 20 to 40 if this is the
case.

=item max

Sets the maximum value for all three components. Setting it to C<100%> or
255 may result in black being produced. A similar warning concerning a
background colour of black applies here.

=item min_red, min_green, min_blue

Sets the minimum value for the specified colour component.

=item max_red, max_green, max_blue

Sets the maximum value for the specified colour component.

=item red, green, blue

Sets the value of the specified colour component to a fixed value.
For example, the following call to new()...

  my $r = HTML::Rainbow->new(
    red      =>   0,
    green    =>   0,
    min_blue =>  10,
    max_blue => 240,
  );

... will result in a rainbow generator that moves through various
shades of blue.

=item period_list

Set the periods available to choose from. At each peak and trough
of the sine wave followed by each colour component, a new period
length is chosen at random. This is to ensure that the sequence
of colours does not repeat itself too rapidly. Prime numbers
are well suited, and the value of period should be at least 10 (ten) or
more for best results. A list of periods, from 17 to 79, is used by
default. Very long texts will benefit from longer periods. The
parameter is a reference to an array.

  my $r = HTML::Rainbow->new(
    min => 0,
    max => '80%',
    period_list => [qw[ 19 37 53 71 89 107 131 151 173 193 ]],
  );

=item use_span

Use the HTML C<< <span> >> element instead of the C<< <font> >>
element for specifying the colour. The result uses 6 more characters
per marked up character.

=back

The most specific parameter wins. If both, for example, a C<red>
and a C<red_min> parameter are found, the C<red> parameter wins.
If a C<red_min> and a C<min> parameter is found, the C<red_min>
parameter wins.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    # sanity checks for %args
    for my $attr( 
        qw(min max),
        map {( $_, "${_}_min", "${_}_max" )} qw( red green blue )
    ) {
        next unless exists $args{$attr};
        # reduce round-off errors
        # perl -le 'print 1/2+1/32+1/64+1/512+1/1024+1/4096'
        my $scale = 2 + 1/2 + 1/32 + 1/64 + 1/512 + 1/1024 + 1/4096;
        # 2.550048828125 approx 2.55
        # 43% => 43 / 100 * 255 => 43 * 2.55 => 110
        $args{$attr} =~ s{^(\d+(?:\.\d+)?)\s*%$}{sprintf('%d',sprintf('%0.2f',$1) * $scale)}e;
        $args{$attr} =   0 if $args{$attr} <   0;
        $args{$attr} = 255 if $args{$attr} > 255;
    }

    my $self = {
        period   => $args{period_list} ? $args{period_list} : \@PRIMES,
        use_span => $args{use_span } || 0,
    };

    my $change_period = sub {
        my $s = shift;
        $s->period( $self->{period}[rand @{$self->{period}}] );
    };

    tie $self->{$_}, 'Tie::Cycle::Sinewave', {
        min => defined $args{$_}
            ? $args{$_}
            : defined $args{"${_}_min"} 
                ? $args{"${_}_min"} 
                : defined $args{min}
                    ? $args{min}
                    : 16,
        max => defined $args{$_}
            ? $args{$_}
            : defined $args{"${_}_max"} 
                ? $args{"${_}_max"} 
                : defined $args{max}
                    ? $args{max}
                    : 240,
        period => $self->{period}[ rand @{$self->{period}} ],
        at_min => $change_period,
        at_max => $change_period,
    } for qw( red green blue );

    bless $self, $class;
}

=item B<rainbow>

Converts each passed parameter to rainbowed markup, and returns
a single scalar with the resulting marked up text.

  print $r->rainbow( 'somewhere over the rainbow, bluebirds fly' );

You can avoid using an intermediate variable by chaining the
C<rainbow> method on from the C<new> method:

  print HTML::Rainbow->new(
    max => 127,
    min =>   0,
    period_list => [qw[ 11 29 47 71 97 113 149 173 ]],
  )->rainbow( $text );

=cut

push @EXPORT_OK, 'rainbow';
{
    my $ctx;
    sub rainbow {
        my $self = shift;
        my $out  = '';
        if (!($self and UNIVERSAL::isa($self,'HTML::Rainbow'))) {
            # called as a function, not a method
            unshift @_, $self;
            $self = $ctx ? $ctx : $ctx = HTML::Rainbow->new;
        }
        for my $str( grep defined, @_ ) {
            for my $ch( split //, $str ) {
                if( $ch =~ /^\s$/ ) {
                    $out .= $ch;
                }
                else {
                    my $triple = sprintf( "#%02x%02x%02x",
                        $self->{red}, $self->{green}, $self->{blue}
                    );
                    if( $self->{use_span} ) {
                        $out .= qq{<span style="color:$triple">$ch</span>};
                    }
                    else {
                        $out .= qq{<font color="$triple">$ch</font>};
                    }
                }
            }
        }
        $out
    }
}

=back

=head1 DIAGNOSTICS

None.

=head1 SEE ALSO

=over 8

=item L<Tie::Cycle::Sinewave>

The individual red, green and blue colour components follow
sinewaves produced by this module.

=item L<HTML::Parser>

If you want to modify an existing HTML page, you'll probably have
to parse it in order to extract the text. The C<eg> directory
contains some examples to show how this may be done.

=back

=head1 EXAMPLE

The following example produces a valid HTML page.

  use strict;
  use warnings;

  use CGI ':standard';
  use HTML::Rainbow;

  print header(),
    start_html(),
    HTML::Rainbow->new->rainbow('hello, world'),
    end_html();

=head1 BUGS

None known.

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-Rainbow|rt.cpan.org>

Make sure you include the output from the following two commands:

  perl -MHTML::Rainbow -le 'print $HTML::Rainbow::VERSION'
  perl -V

=head1 ACKNOWLEDGEMENTS

This module is dedicated to John Lang, someone I used to work
with back in the early days of the web. I found him one day
painstakingly writing HTML in a text editor and reviewing the
results in Netscape. He was trying to do something like this,
to post to a bulletin board, so I wrote some very ugly Perl
to help him out. Ten years later, I finally got around to
cleaning it up.

=head1 AUTHOR

David Landgren, copyright (C) 2005-2009. All rights reserved.

http://www.landgren.net/perl/

If you (find a) use this module, I'd love to hear about it.
If you want to be informed of updates, send me a note. You
know my first name, you know my domain. Can you guess my
e-mail address?

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

'The Lusty Decadent Delights of Imperial Pompeii';
__END__
