package Math::TamuAnova;

use 5.008006;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::TamuAnova ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	anova_fixed
	anova_mixed
	anova_random
	tamu_anova
	tamu_anova_printtable
	tamu_anova_printtable_twoway
	tamu_anova_twoway
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	anova_fixed
	anova_mixed
	anova_random
);

our $VERSION = '1.0.2';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Math::TamuAnova::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Math::TamuAnova', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Math::TamuAnova - Perl extension for the tamuanova library

=head1 SYNOPSIS

  use Math::TamuAnova;

=head1 DESCRIPTION

This module allows you to use the tamu-anova library from perl programs.

=head2 EXPORT

None by default.

=head2 Exportable constants

  anova_fixed
  anova_mixed
  anova_random

=head2 Exportable functions

  anova
  anova_twoway
  printanova
  printanova_twoway

=head1 USE

  $hash=Math::TamuAnova::anova(DATA[], FACTOR[], J);

DATA is an array of double, FACTOR an array of integer.

Factors must be within 1..J

DATA and FACTOR must have the same size.

  $hash2=Math::TamuAnova::anova_twoway(DATA[], FACTORA[], FACTORB[], JA, JB, mode);

DATA is an array of double, FACTOR(A|B) arrays of integer.

Factors A must be within 1..JA, and Factors B within 1..JB

DATA, FACTORA and FACTORB must have the same size.

=head1 EXAMPLES

  $res=Math::TamuAnova::anova( [88.60,73.20,91.40,68.00,75.20,63.00,53.90,
      69.20,50.10,71.50,44.90,59.50,40.20,56.30,
      38.70,31.00,39.60,45.30,25.20,22.70],
    [1,1,1,1,1,2,2,2,2,2,3,3,3,3,3,4,4,4,4,4],
    4);
  Math::TamuAnova::printtable( $res );

  $res=Math::TamuAnova::anova_twoway(
    [6,10,11,13,15,14,22,12,15,19,18,31,18,9,12],
    [1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2],
    [1, 1, 1, 2, 2, 3, 3, 1, 1, 1, 1, 2, 3, 3, 3],
    2,3,
    &Math::TamuAnova::anova_fixed);
  Math::TamuAnova::printtable_twoway( $res ); 

=head1 SEE ALSO

  info tamu_anova

=head1 AUTHOR

Vincent Danjean, E<lt>Vincent.Danjean@ens-lyon.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Vincent Danjean

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
