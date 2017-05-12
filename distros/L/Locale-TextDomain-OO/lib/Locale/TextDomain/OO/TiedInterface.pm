package Locale::TextDomain::OO::TiedInterface; ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = '1.014';

use Carp qw(confess);
use Tie::Sub;

my %method_name = map { $_ => undef } qw(
    loc_begin_d
    loc_begin_c
    loc_begin_dc
    loc_end_d
    loc_end_c
    loc_end_dc
    loc_
    loc_x
    loc_n
    loc_nx
    loc_p
    loc_px
    loc_np
    loc_npx
    loc_d
    loc_dx
    loc_dn
    loc_dnx
    loc_dp
    loc_dpx
    loc_dnp
    loc_dnpx
    loc_c
    loc_cx
    loc_cn
    loc_cnx
    loc_cp
    loc_cpx
    loc_cnp
    loc_cnpx
    loc_dc
    loc_dcx
    loc_dcn
    loc_dcnx
    loc_dcp
    loc_dcpx
    loc_dcnp
    loc_dcnpx

    Nloc_
    Nloc_x
    Nloc_n
    Nloc_nx
    Nloc_p
    Nloc_px
    Nloc_np
    Nloc_npx
    Nloc_d
    Nloc_dx
    Nloc_dn
    Nloc_dnx
    Nloc_dp
    Nloc_dpx
    Nloc_dnp
    Nloc_dnpx
    Nloc_c
    Nloc_cx
    Nloc_cn
    Nloc_cnx
    Nloc_cp
    Nloc_cpx
    Nloc_cnp
    Nloc_cnpx
    Nloc_dc
    Nloc_dcx
    Nloc_dcn
    Nloc_dcnx
    Nloc_dcp
    Nloc_dcpx
    Nloc_dcnp
    Nloc_dcnpx

    __begin_d
    __begin_c
    __begin_dc
    __end_d
    __end_c
    __end_dc
    __
    __x
    __n
    __nx
    __p
    __px
    __np
    __npx
    __d
    __dx
    __dn
    __dnx
    __dp
    __dpx
    __dnp
    __dnpx
    __c
    __cx
    __cn
    __cnx
    __cp
    __cpx
    __cnp
    __cnpx
    __dc
    __dcx
    __dcn
    __dcnx
    __dcp
    __dcpx
    __dcnp
    __dcnpx

    N__
    N__x
    N__n
    N__nx
    N__p
    N__px
    N__np
    N__npx
    N__d
    N__dx
    N__dn
    N__dnx
    N__dp
    N__dpx
    N__dnp
    N__dnpx
    N__c
    N__cx
    N__cn
    N__cnx
    N__cp
    N__cpx
    N__cnp
    N__cnpx
    N__dc
    N__dcx
    N__dcn
    N__dcnx
    N__dcp
    N__dcpx
    N__dcnp
    N__dcnpx

    locn
    Nlocn

    maketext
    maketext_p
    Nmaketext
    Nmaketext_p

    loc
    loc_m
    loc_mp
    Nloc
    Nloc_m
    Nloc_mp

    localise
    localise_m
    localise_mp
    Nlocalise
    Nlocalise_m
    Nlocalise_mp

    localize
    localize_m
    localize_mp
    Nlocalize
    Nlocalize_m
    Nlocalize_mp
);

our $loc_ref = do { my $loc; \$loc }; ## no critic(PackageVars)

sub import {
    my (undef, @imports) = @_;

    if (! @imports) {
        @imports = (
            qw($loc_ref),
            map { ("\%$_", "\$$_") } keys %method_name,
        );
    }

    my $caller  = caller;
    my $package = __PACKAGE__;

    IMPORT:
    for my $import (@imports) {
        defined $import
            or confess 'An undefined value is not a variable name';
        if ($import eq '$loc_ref') { ## no critic (InterpolationOfMetachars)
            no strict qw(refs);       ## no critic (NoStrict)
            no warnings qw(redefine); ## no critic (NoWarnings)
            *{"$caller\::loc_ref"} = \$loc_ref;
            next IMPORT;
        }
        (my $method = $import) =~ s{\A (?: (\$) | % )}{}xms
            or confess qq{"$import" is not a hash or a hash reference};
        my $is_ref = $1;
        exists $method_name{$method}
            or confess qq{"$import" is not exported};
        {
            no strict qw(refs);       ## no critic (NoStrict)
            no warnings qw(redefine); ## no critic (NoWarnings)
            *{"$caller\::$method"}
                = $is_ref
                ? \${"$package\::$method"}
                : \%{"$package\::$method"};
        }
        my $sub
            = ( index $method, 'N', 0 ) == 0
            ? sub {
                return [ ${$loc_ref}->$method(@_) ];
            }
            : sub {
                return ${$loc_ref}->$method(@_);
            };
        if ($is_ref) {
            no strict qw(refs); ## no critic (NoStrict)
            tie ## no critic (Ties)
                %{ ${$method} },
                'Tie::Sub',
                $sub;
        }
        else {
            no strict qw(refs); ## no critic (NoStrict)
            tie ## no critic (Ties)
                %{$method},
                'Tie::Sub',
                $sub;
        }
    }

    return;
}

1;

__END__

=head1 NAME

Locale::TextDomain::OO::TiedInterface - Call object methods as tied hash

$Id: TiedInterface.pm 546 2014-10-31 09:35:19Z steffenw $

$HeadURL: svn+ssh://steffenw@svn.code.sf.net/p/perl-gettext-oo/code/module/trunk/lib/Locale/TextDomain/OO/TiedInterface.pm $

=head1 VERSION

1.014

=head1 DESCRIPTION

This module wraps the object into a tied hash
and allows to call a method as fetch hash.

=head1 SYNOPSIS

import all

    use Locale::TextDomain::OO;
    use Locale::TextDomain::OO::TiedInterface $loc_ref;
    ${loc_ref} = Locale::TextDomain::OO->new(
        ...
    );

or import only the given variables, as example all

    use Locale::TextDomain::OO;
    use Locale::TextDomain::OO::TiedInterface $loc_ref, qw(
        %loc_begin_d
        %loc_begin_c
        %loc_begin_dc
        %loc_end_d
        %loc_end_c
        %loc_end_dc
        %loc_
        %loc_x
        %loc_n
        %loc_nx
        %loc_p
        %loc_px
        %loc_np
        %loc_npx
        %loc_d
        %loc_dx
        %loc_dn
        %loc_dnx
        %loc_dp
        %loc_dpx
        %loc_dnp
        %loc_dnpx
        %loc_c
        %loc_cx
        %loc_cn
        %loc_cnx
        %loc_cp
        %loc_cpx
        %loc_cnp
        %loc_cnpx
        %loc_dc
        %loc_dcx
        %loc_dcn
        %loc_dcnx
        %loc_dcp
        %loc_dcpx
        %loc_dcnp
        %loc_dcnpx

        %Nloc_
        %Nloc_x
        %Nloc_n
        %Nloc_nx
        %Nloc_p
        %Nloc_px
        %Nloc_np
        %Nloc_npx
        %Nloc_d
        %Nloc_dx
        %Nloc_dn
        %Nloc_dnx
        %Nloc_dp
        %Nloc_dpx
        %Nloc_dnp
        %Nloc_dnpx
        %Nloc_c
        %Nloc_cx
        %Nloc_cn
        %Nloc_cnx
        %Nloc_cp
        %Nloc_cpx
        %Nloc_cnp
        %Nloc_cnpx
        %Nloc_dc
        %Nloc_dcx
        %Nloc_dcn
        %Nloc_dcnx
        %Nloc_dcp
        %Nloc_dcpx
        %Nloc_dcnp
        %Nloc_dcnpx

        %__begin_d
        %__begin_c
        %__begin_dc
        %__end_d
        %__end_c
        %__end_dc
        %__
        %__x
        %__n
        %__nx
        %__p
        %__px
        %__np
        %__npx
        %__d
        %__dx
        %__dn
        %__dnx
        %__dp
        %__dpx
        %__dnp
        %__dnpx
        %__c
        %__cx
        %__cn
        %__cnx
        %__cp
        %__cpx
        %__cnp
        %__cnpx
        %__dc
        %__dcx
        %__dcn
        %__dcnx
        %__dcp
        %__dcpx
        %__dcnp
        %__dcnpx

        %N__
        %N__x
        %N__n
        %N__nx
        %N__p
        %N__px
        %N__np
        %N__npx
        %N__d
        %N__dx
        %N__dn
        %N__dnx
        %N__dp
        %N__dpx
        %N__dnp
        %N__dnpx
        %N__c
        %N__cx
        %N__cn
        %N__cnx
        %N__cp
        %N__cpx
        %N__cnp
        %N__cnpx
        %N__dc
        %N__dcx
        %N__dcn
        %N__dcnx
        %N__dcp
        %N__dcpx
        %N__dcnp
        %N__dcnpx

        %locn
        %Nlocn

        %maketext
        %maketext_p
        %Nmaketext
        %Nmaketext_p

        %loc
        %loc_m
        %loc_mp
        %Nloc
        %Nloc_m
        %Nloc_mp

        %localise
        %localise_m
        %localise_mp
        %Nlocalise
        %Nlocalise_m
        %Nlocalise_mp

        %localize
        %localize_m
        %localize_mp
        %Nlocalize
        %Nlocalize_m
        %Nlocalize_mp

        $loc_begin_d
        $loc_begin_c
        $loc_begin_dc
        $loc_end_d
        $loc_end_c
        $loc_end_dc
        $loc_
        $loc_x
        $loc_n
        $loc_nx
        $loc_p
        $loc_px
        $loc_np
        $loc_npx
        $loc_d
        $loc_dx
        $loc_dn
        $loc_dnx
        $loc_dp
        $loc_dpx
        $loc_dnp
        $loc_dnpx
        $loc_c
        $loc_cx
        $loc_cn
        $loc_cnx
        $loc_cp
        $loc_cpx
        $loc_cnp
        $loc_cnpx
        $loc_dc
        $loc_dcx
        $loc_dcn
        $loc_dcnx
        $loc_dcp
        $loc_dcpx
        $loc_dcnp
        $loc_dcnpx

        $Nloc_
        $Nloc_x
        $Nloc_n
        $Nloc_nx
        $Nloc_p
        $Nloc_px
        $Nloc_np
        $Nloc_npx
        $Nloc_d
        $Nloc_dx
        $Nloc_dn
        $Nloc_dnx
        $Nloc_dp
        $Nloc_dpx
        $Nloc_dnp
        $Nloc_dnpx
        $Nloc_c
        $Nloc_cx
        $Nloc_cn
        $Nloc_cnx
        $Nloc_cp
        $Nloc_cpx
        $Nloc_cnp
        $Nloc_cnpx
        $Nloc_dc
        $Nloc_dcx
        $Nloc_dcn
        $Nloc_dcnx
        $Nloc_dcp
        $Nloc_dcpx
        $Nloc_dcnp
        $Nloc_dcnpx

        $__begin_d
        $__begin_c
        $__begin_dc
        $__end_d
        $__end_c
        $__end_dc
        $__
        $__x
        $__n
        $__nx
        $__p
        $__px
        $__np
        $__npx
        $__d
        $__dx
        $__dn
        $__dnx
        $__dp
        $__dpx
        $__dnp
        $__dnpx
        $__c
        $__cx
        $__cn
        $__cnx
        $__cp
        $__cpx
        $__cnp
        $__cnpx
        $__dc
        $__dcx
        $__dcn
        $__dcnx
        $__dcp
        $__dcpx
        $__dcnp
        $__dcnpx

        $N__
        $N__x
        $N__n
        $N__nx
        $N__p
        $N__px
        $N__np
        $N__npx
        $N__d
        $N__dx
        $N__dn
        $N__dnx
        $N__dp
        $N__dpx
        $N__dnp
        $N__dnpx
        $N__c
        $N__cx
        $N__cn
        $N__cnx
        $N__cp
        $N__cpx
        $N__cnp
        $N__cnpx
        $N__dc
        $N__dcx
        $N__dcn
        $N__dcnx
        $N__dcp
        $N__dcpx
        $N__dcnp
        $N__dcnpx

        $locn
        $Nlocn

        $maketext
        $maketext_p
        $Nmaketext
        $Nmaketext_p

        $loc
        $loc_m
        $loc_mp
        $Nloc
        $Nloc_m
        $Nloc_mp

        $localise
        $localise_m
        $localise_mp
        $Nlocalise
        $Nlocalise_m
        $Nlocalise_mp

        $localize
        $localize_m
        $localize_mp
        $Nlocalize
        $Nlocalize_m
        $Nlocalize_mp
    );
    ${loc_ref} = Locale::TextDomain::OO->new(
        ...
    );

=head1 SUBROUTINES/METHODS

none

=head1 EXAMPLE

Inside of this distribution is a directory named example.
Run this *.pl files.

=head1 DIAGNOSTICS

confess

=head1 CONFIGURATION AND ENVIRONMENT

none

=head1 DEPENDENCIES

L<Carp|Carp>

L<Tie::Sub|Tie::Sub>

=head1 INCOMPATIBILITIES

not known

=head1 BUGS AND LIMITATIONS

none

=head1 SEE ALSO

L<Locale::TextDoamin::OO|Locale::TextDoamin::OO>

=head1 AUTHOR

Steffen Winkler

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 - 2014,
Steffen Winkler
C<< <steffenw at cpan.org> >>.
All rights reserved.

This module is free software;
you can redistribute it and/or modify it
under the same terms as Perl itself.
