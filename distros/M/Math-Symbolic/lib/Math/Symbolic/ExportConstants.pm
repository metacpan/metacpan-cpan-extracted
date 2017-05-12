
=encoding utf8

=cut

package Math::Symbolic::ExportConstants;

use 5.006;
use strict;
use warnings;

require Exporter;

use constant EULER => 2.718281828459045235360287;
use constant PI    => 3.141592653589793238462643;

use constant B_SUM            => 0;
use constant B_DIFFERENCE     => 1;
use constant B_PRODUCT        => 2;
use constant B_DIVISION       => 3;
use constant U_MINUS          => 4;
use constant U_P_DERIVATIVE   => 5;
use constant U_T_DERIVATIVE   => 6;
use constant B_EXP            => 7;
use constant B_LOG            => 8;
use constant U_SINE           => 9;
use constant U_COSINE         => 10;
use constant U_TANGENT        => 11;
use constant U_COTANGENT      => 12;
use constant U_ARCSINE        => 13;
use constant U_ARCCOSINE      => 14;
use constant U_ARCTANGENT     => 15;
use constant U_ARCCOTANGENT   => 16;
use constant U_SINE_H         => 17;
use constant U_COSINE_H       => 18;
use constant U_AREASINE_H     => 19;
use constant U_AREACOSINE_H   => 20;
use constant B_ARCTANGENT_TWO => 21;

use constant T_OPERATOR => 0;
use constant T_CONSTANT => 1;
use constant T_VARIABLE => 2;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(
          EULER
          PI

          B_SUM
          B_DIFFERENCE
          B_PRODUCT
          B_DIVISION
          B_EXP
          B_LOG
          U_MINUS
          U_P_DERIVATIVE
          U_T_DERIVATIVE
          U_SINE
          U_COSINE
          U_TANGENT
          U_COTANGENT
          U_ARCSINE
          U_ARCCOSINE
          U_ARCTANGENT
          U_ARCCOTANGENT
          U_SINE_H
          U_COSINE_H
          U_AREASINE_H
          U_AREACOSINE_H
          B_ARCTANGENT_TWO

          T_OPERATOR
          T_CONSTANT
          T_VARIABLE
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);
our $VERSION = '0.612';

1;
__END__

=head1 NAME

Math::Symbolic::ExportConstants - Export constants used for Math::Symbolic

=head1 SYNOPSIS

  use Math::Symbolic::ExportConstants qw/:all/;

=head1 DESCRIPTION

This just exports a number of constants on demand.
Usually, you'd want to rather use Math::Symbolic instead.
Math::Symbolic allows you to optionally export the same constants
as this module, but using the ':constants' tag instead of the
':all' tag that you'd have to use with this module.

Please refer to the documentation of the Math::Symbolic module for
a list of constants.

=head2 EXPORT

None by default. But since exporting symbols is the only functionality
of this module, you'll want to export the :all group of constants.

=head1 AUTHOR

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

List of contributors:

  Steffen Müller, symbolic-module at steffen-mueller dot net
  Stray Toaster, mwk at users dot sourceforge dot net
  Oliver Ebenhöh

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

L<Math::Symbolic>

=cut

