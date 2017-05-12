package GD::Barcode::Code93;

use strict;
use warnings;

BEGIN { eval{require 'GD.pm';}; };
use GD::Barcode;

require Exporter;
use vars qw($VERSION @ISA $error_string);
@ISA = qw(GD::Barcode Exporter);
$VERSION='1.4';

my $code93bar = {
    0   =>'100010100',
    1   =>'101001000',
    2   =>'101000100',
    3   =>'101000010',
    4   =>'100101000',
    5   =>'100100100',
    6   =>'100100010',
    7   =>'101010000',
    8   =>'100010010',
    9   =>'100001010',
    A   =>'110101000',
    B   =>'110100100',
    C   =>'110100010',
    D   =>'110010100',
    E   =>'110010010',
    F   =>'110001010',
    G   =>'101101000',
    H   =>'101100100',
    I   =>'101100010',
    J   =>'100110100',
    K   =>'100011010',
    L   =>'101011000',
    M   =>'101001100',
    N   =>'101000110',
    O   =>'100101100',
    P   =>'100010110',
    Q   =>'110110100',
    R   =>'110110010',
    S   =>'110101100',
    T   =>'110100110',
    U   =>'110010110',
    V   =>'110011010',
    W   =>'101101100',
    X   =>'101100110',
    Y   =>'100110110',
    Z   =>'100111010',
   ' '  =>'111010010',
   '$'  =>'111001010',
   '%'  =>'110101110',
   '($)'=>'100100110',
   '(%)'=>'111011010',
   '(+)'=>'100110010',
   '(/)'=>'111010110',
   '+'  =>'101110110',
   '-'  =>'100101110',
   '.'  =>'111010100',
   '/'  =>'101101110',
   '*'  =>'101011110',  ##Start/Stop
};

my %code93values = (
    '0'    =>'0',
    '1'    =>'1',
    '2'    =>'2',
    '3'    =>'3',
    '4'    =>'4',
    '5'    =>'5',
    '6'    =>'6',
    '7'    =>'7',
    '8'    =>'8',
    '9'    =>'9',
    'A'    =>'10',
    'B'    =>'11',
    'C'    =>'12',
    'D'    =>'13',
    'E'    =>'14',
    'F'    =>'15',
    'G'    =>'16',
    'H'    =>'17',
    'I'    =>'18',
    'J'    =>'19',
    'K'    =>'20',
    'L'    =>'21',
    'M'    =>'22',
    'N'    =>'23',
    'O'    =>'24',
    'P'    =>'25',
    'Q'    =>'26',
    'R'    =>'27',
    'S'    =>'28',
    'T'    =>'29',
    'U'    =>'30',
    'V'    =>'31',
    'W'    =>'32',
    'X'    =>'33',
    'Y'    =>'34',
    'Z'    =>'35',
    '-'    =>'36',
    '.'    =>'37',
    ' '    =>'38',
    '$'    =>'39',
    '/'    =>'40',
    '+'    =>'41',
    '%'    =>'42',
    '($)'    =>'43',
    '(%)'    =>'44',
    '(/)'    =>'45',
    '(+)'    =>'46',
    '*'        => '',
);

#------------------------------------------------------------------------------
# new (for GD::Barcode::Code93)
#------------------------------------------------------------------------------
sub new {
  my ( $class, $txt ) = @_;

  my $error_string = '';
  my $self = {};
  bless $self, $class;

  return undef if $error_string = $self->init($txt);
  return $self;
}

#------------------------------------------------------------------------------
# init (for GD::Barcode::Code93)
#------------------------------------------------------------------------------
sub init {
    my ($self, $txt) = @_;

# Validate string:
    return 'Invalid Characters' if $txt =~ /[^0-9A-Za-z\-*+\$%\/. ]/;
    $self->{text} = uc($txt);
    return;
}

#------------------------------------------------------------------------------
# barcode (for GD::Barcode::Code93)
#------------------------------------------------------------------------------
sub barcode {
    my $self = shift;

    my @sum_text = ('*', $self->calculateSums, '*');

    my $return_string = '';
    map { $return_string .= $code93bar->{$_} } @sum_text;
    return $return_string . "1";
}

#------------------------------------------------------------------------------
# plot (for GD::Barcode::Code93)
#------------------------------------------------------------------------------
sub plot(@) {
  my $self   = shift;
  my %params = @_;

  ##  Normalize the hash keys:
  %params = map { lc($_) => $params{$_} } keys %params;

  my $text    = $self->{text};

#Barcode Pattern
  my $pattern = $self->barcode();

#Create Image
  my $height = $params{height} ? $params{height} : 50;

  my $gd;
  if ( $params{notext} ) {
    ( $gd, undef ) = GD::Barcode::plot($pattern, length($pattern), $height, 0, 0);
  }
  else {
    my ( $font_width, $font_height ) = ( GD::Font->Small->width, GD::Font->Small->height );
    my $width = length($pattern);

    my $color;
    #Bar Image
    ( $gd, $color ) = GD::Barcode::plot
        (
              $pattern
            , $width
            , $height
            , $font_height
            , 0
        );

    #String
    my $string_width = ( length($pattern) - $font_width * length($text) ) / 2;
    my $string_height = $height - $font_height;
    $gd->string( GD::Font->Small, $string_width, $string_height, $text, $color );
  }
  return $gd;
}

#-----------------------------------------------------------------------------
# calculateSums (for GD::Barcode::Code93)
#-----------------------------------------------------------------------------
sub calculateSums {
    my $self = shift;
    my @array = split(//, scalar reverse $self->{text});

    my %invCode93Values = reverse %code93values;
    my $weighted_sum;

    foreach my $counter ( qw/4 3/ ) {
        for (my $i = 0, my $x = 1; $i <= $#array; $i++, $x++) {
            my $letter  = $array[$i];

            if ($x > ($counter * 5)) { $x = 1 }
            $weighted_sum += ($code93values{$letter} * $x);
        }

        my $check = $invCode93Values{($weighted_sum % 47)};
        unshift @array, $check;
        $weighted_sum = ();
    }

    return reverse @array;
}
1;
__END__


=head1 NAME

GD::Barcode::Code93 - Create Code93 barcode image with GD

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::Code93;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::Code93->new('text')->plot->png;

I<with Error Check>

  my $barcode = GD::Barcode::Code93->new('text');
  die $GD::Barcode::Code93::error_string unless($barcode);     #Invalid Characters


=head1 DESCRIPTION

GD::Barcode::Code93 is a subclass of GD::Barcode and allows you to
create CODE-39 barcode image with GD.
This module based on "Generate Barcode Ver 1.02 By Shisei Hanai 97/08/22".

=head2 new

I<$barcode> = GD::Barcode::Code93->new(I<$text>);

Constructor. 
Creates a GD::Barcode::Code93 object for I<$text>.

=head2 plot()

I<$gd> = $barcode->plot([Height => I<$height>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$text> specified at L<new> method.
I<$height> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $barcode = GD::Barcode::Code93->new('12345');
  my $gd = $barcode->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$barcode_pattern> = $oGdBar->barcode();

returns a barcode pattern in string with '1' and '0'. 
'1' means black, '0' means white.

 ex.
  my $barcode = GD::Barcode::Code93->new('*12345*');
  my $barcode_pattern = $oGdB->barcode();

=head2 $error_string

$GD::Barcode::Code93::error_string

has error message.

=head2 $text

$oGdBar->{text}

has barcode text based on I<$text> specified in L<new> method.

=head1 AUTHOR

Chris DiMartino chris DOT dimartino AT gmail DOT com

=head1 COPYRIGHT

The GD::Barcode::Code93 module is based on code provided by Kawai Takanori. Japan.
The GD::Barcode::Code93 module was written by Chris DiMartino, 2004.
Thanks to Lobanov Igor, Joel Richard, and Joshua Fortriede for their excellent Bug Reports and patches.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 SEE ALSO

GD::Barcode

=cut

