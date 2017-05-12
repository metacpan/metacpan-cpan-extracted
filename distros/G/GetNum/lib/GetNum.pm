package GetNum;

use strict;
use warnings;
use Inline 'C' => <<'EOC';
#include <stdlib.h>

SV* coerce_num_string(SV* sv, int iType) {
    if(SvOK(sv) == 0 || SvPOK(sv) == 0) {
        return( NULL );
    }

    STRLEN len;
    errno = 0;
    char *endptr;
    char *str = SvPV(sv,len);

    double iSV = strtod( str, &endptr );
    if(errno != 0 || endptr == str) {
        return( NULL );
    }
    
    if(iType == 1) {
        return( newSViv( iSV ) );
    }
    else {
        return( newSVnv( iSV ) );
    }
}

SV* get_int(SV* sv) {
    if(SvIOK(sv) != 0 || SvNOK(sv) != 0) {
        return( newSViv( SvIV(sv) ) );
    }
    else if(SvPOK(sv) != 0) {
        return( coerce_num_string(sv,1) );
    }
    else {
        return( NULL );
    }
}

SV* get_float(SV* sv) {
    if(SvNOK(sv) != 0 || SvIOK(sv) != 0) {
        return( newSVnv( SvNV(sv) ) );
    }
    else if(SvPOK(sv) != 0) {
        return( coerce_num_string(sv,2) );
    }
    else {
        return( NULL );
    }
}

int is_int(SV* sv) {
    return SvIOK(sv);
}

int is_float(SV* sv) {
    return SvNOK(sv);
}
EOC

use parent qw(Exporter);
our @EXPORT = qw(get_int is_int is_float get_float);

use version; our $VERSION = qv(1.0.2);

1;

=pod

=head1 NAME

GetNum - coerce scalars into numbers or return undef

=head1 SYNOPSIS

 use GetNum;

 my $i = get_int('foo'); # returns undef
 my $i = get_int('123'); # returns 123

=head1 DESCRIPTION

This module can be used to force scalar to be coerced into numeric types
in a situation when the effect of C<int()> to turn non-numerics into
0 (zero) is not desirable.

This module is handy when programming a serialization strategy for
a Perl object into JSON where datatypes affect the output.

=head1 EXPORTED SUBROUTINES

All subroutines are exported by default.

=over

=item * B<iget_int> - coerce a scalar into an integer or return undef

=item * B<is_int> - returns true if a scalar is an integer

=item * B<get_float> - coerce a scalar into a float or return undef

=item * B<is_float> - returns true if a scalar is a float

=back

=head1 SEE ALSO

The discussion on SV (Perl scalar variables) manipulation functions
in the documentation for the perlapi: L<http://perldoc.perl.org/perlapi.html#SV-Manipulation-Functions>

=head1 DEPENDENCIES

=over

=item * Inline::C

=back

=head1 Revision History

=over

=item v1.0.0 - Original package submitted September 2014

=item v1.0.1 - Added POD

=item v1.0.2 - Added README file

=back

=head1 Author

=over

=item Aaron Dallas

=item adallas@cpan.org

=back

=cut
