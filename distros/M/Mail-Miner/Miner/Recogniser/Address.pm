#!/usr/bin/perl -w

package Mail::Miner::Recogniser::Address;

$Mail::Miner::recognisers{"".__PACKAGE__} = 
    {
     title    => "Physical Addresses",
     help     => "Match messages which contain an address",
     keyword  => "address",
    };

my $us_state = qr/(?:A[LKSZREAEEEP]|
   C[AOT]|D[EC]|F[ML]|G[AU]|HI|I[DLNA]|K[SY]|LA|M[EHDAINSOTP]|N[EVHJMYCD]|
   O[HKR]|P[WAR]|RI|S[CD]|T[NX]|UT|V[TIA]|W[AVIY])/x;
my $uk_post_town =
   qr/(?:AL|B[ABDHLNRST]?|C[ABFHMORTVW]|D[ADEGHLNTY]|E[CHNX]?|F[KY]|
   G[LUY]?|H[ADGPRSUX]|I[GMPV]|JE|K[ATWY]|L[ADELNSU]?|M[EKL]?|N[EGNPRW]?|
   O[LX]|P[ORAEHL]|R[GHM]|S[AEGKLMNOPRSTWY]?|T[ADFNQRSW]|UB|W[ACDFNRSV]?|
   YO|ZE)/x;

my $uk_postcode = qr/$uk_post_town\d{1,3}[ \t]+\d{1,2}[A-Z][A-Z]/;
my $us_zipcode = qr/$us_state[ \t]+\d{5}/;

sub process {
    my ($class, %hash) = @_;

    my @lines = split /\n/, $hash{getbody}->();
    my @found;
    my $last =0;

    for (0..$#lines) {
        if ($lines[$_] =~ /(.*\b($uk_postcode|$us_zipcode)\b)/) {
            if ($_ - $last > 10) { $last = $_-10 } # Max of 10 lines
            my $address = join "\n", @lines[$last+1..$_];
            # Trim whitespace and quoters
            $address =~ s/^\s*
                           (?:[A-Z][A-Z]>)? # SUPERCITE
                           [\s>:]+//msgox;
            push @found, $address;
        } elsif ($lines[$_] !~ /\w/) {
            $last = $_;
        }
    }

    return @found;
}

1;
