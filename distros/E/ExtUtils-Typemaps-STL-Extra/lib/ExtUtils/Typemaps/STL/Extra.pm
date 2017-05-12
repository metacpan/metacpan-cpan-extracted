package ExtUtils::Typemaps::STL::Extra;

use 5.006;
use strict;
use warnings;
use utf8;
use ExtUtils::Typemaps;

=encoding utf-8

=head1 NAME

ExtUtils::Typemaps::STL::Extra - Extra typemaps for STL types

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our @ISA     = qw(ExtUtils::Typemaps);

=head1 SYNOPSIS

    use Module::Build::WithXSpp;
 
    my $build = Module::Build::WithXSpp->new(
		extra_typemap_modules => {
    			'ExtUtils::Typemaps::STL::Extra' => '0'
			},
	);

=head1 DESCRIPTION

This module add extra typemaps for STL types to make it easier wrapping C++ using L<ExtUtils::XSpp>


=head1 METHODS

=cut

=head2 new

Creates a new ExtUtils::Typemaps::STL::Extra object. It acts as any other ExtUtils::Typemaps object, except that it has the extra type maps initialized.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    my $typemap = <<'END_TYPEMAP';
TYPEMAP
std::vector<std::vector<double> >	T_STD_VECTOR_STD_VECTOR_DOUBLE

INPUT

T_STD_VECTOR_STD_VECTOR_DOUBLE
	if (SvROK($arg) && SvTYPE(SvRV($arg))==SVt_PVAV) {
          AV* av = (AV*)SvRV($arg);
          const unsigned int len = av_len(av)+1;
          $var = std::vector<std::vector<double>>(len);
          SV** elem;
          for (unsigned int i = 0; i < len; i++) {
            elem = av_fetch(av, i, 0);
            if (elem != NULL && SvROK(*elem) && SvTYPE(SvRV(*elem))==SVt_PVAV) {
            
               AV* av_inner = (AV*)SvRV(*elem);
               const unsigned int len_j = av_len(av_inner) + 1;
               std::vector<double> inner_vector(len_j);
               SV** inner_elem;
               for (unsigned int j = 0; j < len_j; j++) {
                    inner_elem = av_fetch(av_inner, j, 0);
                    if (inner_elem != NULL) 
                        inner_vector[j] =  SvNV(*inner_elem);
                    else 
                        inner_vector[j] = 0;
               }
               ${var}[i] = inner_vector;
            }
            else
              ${var}[i] = std::vector<double>();
          }
        }
        else
          Perl_croak(aTHX_ \"%s: %s is not an array reference\",
                     ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                     \"$var\");

OUTPUT

T_STD_VECTOR_STD_VECTOR_DOUBLE
	AV* av = newAV();
        $arg = newRV_noinc((SV*)av);
        const unsigned int len = $var.size();
        if (len)
          av_extend(av, len-1);
        for (unsigned int i = 0; i < len; i++) {
            const unsigned int len_j = ${var}[i].size();
            AV *inner_av = newAV();
            if (len_j) av_extend(inner_av, len_j - 1);
            for (unsigned int j = 0; j < len_j; j++) {
                av_store(inner_av, j, newSVnv(${var}[i][j])); 
            }
            av_store(av, i, newRV_noinc((SV*)inner_av));
        }


END_TYPEMAP

    $self->add_string( string => $typemap );

    #die $typemap;
    return $self;
}

1;    # End of ExtUtils::Typemaps::STL::Extra

__END__

=head1 AUTHOR

Pablo Rodríguez González, C<< <pablrod at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests via github: L<https://github.com/pablrod/p5-ExtUtils-Typemaps-STL-Extra/issues>

=head1 SEE ALSO

ExtUtils::XSpp

Module::Build::WithXSpp

ExtUtils::Typemaps::Default

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Pablo Rodríguez González.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

