package Image::Signature::Grayscale;

our @coef = qw(0.3 0.59 0.11);
sub to_gray { $_[0]*$coef[0] + $_[1]*$coef[1] + $_[2]*$coef[2] }

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(to_gray);


1;
