package Form::Validator::UKPostcode;
use base 'Form::Validator';
my $uk_post_town =
   qr/(?:AL|B[ABDHLNRST]?|C[ABFHMORTVW]|D[ADEGHLNTY]|E[CHNX]?|F[KY]|
   G[LUY]?|H[ADGPRSUX]|I[GMPV]|JE|K[ATWY]|L[ADELNSU]?|M[EKL]?|N[EGNPRW]?|
   O[LX]|P[ORAEHL]|R[GHM]|S[AEGKLMNOPRSTWY]?|T[ADFNQRSW]|UB|W[ACDFNRSV]?|
   YO|ZE)/x;

my $uk_postcode = qr/$uk_post_town\d{1,3}[ \t]+\d{1,2}[A-Z][A-Z]/i;
# London?
sub validate {
    my ($self, $field) = @_;
    {
        javascript =>
            '^[a-zA-Z]{1,2}[0-9]{1,3}[ \t]+[0-9]{1,2}[A-Za-z][A-Za-z]',
        perl => qr/^$uk_postcode$/,
    }
}

1;
