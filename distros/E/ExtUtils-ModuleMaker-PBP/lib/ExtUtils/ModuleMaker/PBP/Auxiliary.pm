package ExtUtils::ModuleMaker::PBP::Auxiliary;
# Contains test subroutines for distribution with ExtUtils::ModuleMaker::PBP
# As of:  April 5, 2006
use strict;
local $^W = 1;
use vars qw( $VERSION @ISA @EXPORT_OK );
$VERSION = '0.09';
require Exporter;
@ISA         = qw(Exporter);
@EXPORT_OK   = qw(
    check_MakefilePL 
); 
use File::Spec;
*ok = *Test::More::ok;
*is = *Test::More::is;
*like = *Test::More::like;
*copy = *File::Copy::copy;
*move = *File::Copy::move;
use ExtUtils::ModuleMaker::Auxiliary qw(
    read_file_string
);

=head1 NAME

ExtUtils::ModuleMaker::PBP::Auxiliary - Subroutines for testing ExtUtils::ModuleMaker::PBP

=head1 DESCRIPTION

This package contains subroutines used in one or more F<t/*.t> files in
ExtUtils::ModuleMaker::PBP's test suite.

=head1 SUBROUTINES

=head2 C<check_MakefilePL()>

    Function:   Verify that content of Makefile.PL was created correctly.
    Argument:   Two arguments:
                1.  A string holding the directory in which the Makefile.PL
                    should have been created.
                2.  A reference to an array holding strings each of which is a
                    prediction as to content of particular lines in Makefile.PL.
    Returns:    n/a.
    Used:       To see whether Makefile.PL created by complete_build() has
                correct entries.  Runs 1 Test::More test which checks NAME,
                VERSION_FROM, AUTHOR and ABSTRACT.  

=cut

sub check_MakefilePL {
    my ($topdir, $predictref) = @_;
    my @pred = @$predictref;

    my $mkfl = File::Spec->catfile( $topdir, q{Makefile.PL} );
    local *MAK;
    open MAK, $mkfl or die "Unable to open Makefile.PL: $!";
    my $bigstr = read_file_string($mkfl);
    like($bigstr, qr/
            NAME.+($pred[0]).+
            AUTHOR.+($pred[1]).+
            ($pred[2]).+
            VERSION_FROM.+($pred[3]).+
            ABSTRACT_FROM.+($pred[4])
        /sx, "Makefile.PL has predicted values");
}

1;

