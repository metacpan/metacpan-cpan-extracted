package Geography::States::Borders;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Return the borders of states and provinces

our $VERSION = '0.0106';

use strictures 2;
use Moo;
use namespace::clean;


has country => (
    is      => 'ro',
    isa     => sub { die "$_[0] is not valid" unless $_[0] =~ /^[a-zA-Z]+$/ },
    default => sub { 'usa' },
);

has _australia => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
      {
        ACT => [qw(NSW)],
        NSW => [qw(ACT VIC SA QLD)],
        NT  => [qw(WA QLD SA)],
        QLD => [qw(NSW SA NT)],
        SA  => [qw(WA NT QLD NSW VIC )],
        TAS => [],
        VIC => [qw(SA NSW)],
        WA  => [qw(NT SA)],
      }
    },
);

has _brazil => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
      {
        AC => [qw(AM RO)],
        AL => [qw(BA PE SE)],
        AM => [qw(AC MT RO RR)],
        AP => [qw(PA)],
        BA => [qw(ES MG GO TO PI PE AL SE)],
        CE => [qw(RN PB PE PI )],
        DF => [qw(GO MG)],
        ES => [qw(RJ MG BA)],
        GO => [qw(DF MG MS MT TO BA)],
        MA => [qw(PI TO PA)],
        MG => [qw(SP MS GO DF BA ES RJ)],
        MS => [qw(MT GO MG SP PR)],
        MT => [qw(RO AM PA TO GO MS)],
        PA => [qw(MT AM RR AP MA TO)],
        PB => [qw(PE CE RN)],
        PE => [qw(AL BA PI CE PB)],
        PI => [qw(BA TO MA CE PE)],
        PR => [qw(MS SP SC)],
        RJ => [qw(SP MG ES)],
        RN => [qw(PB CE)],
        RO => [qw(AC AM MT)],
        RR => [qw(AM PA)],
        RS => [qw(SC)],
        SC => [qw(RS PR)],
        SE => [qw(BA AL)],
        SP => [qw(PR MS MG RJ)],
        TO => [qw(GO MT PA MA PI BA)],
      }
    },
);

has _canada => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
      {
        AB => [qw(BC NT SK)],
        BC => [qw(AB NT YT)],
        MB => [qw(NU ON SK)],
        NB => [qw(NS QC)],
        NL => [qw(QC)],
        NS => [qw(NB)],
        NT => [qw(AB BC NU SK YT)],
        NU => [qw(MB NT)],
        ON => [qw(MB QC)],
        PE => [],
        QC => [qw(NB NL ON)],
        SK => [qw(AB MB NT)],
        YT => [qw(BC NT)],
      }
    },
);

has _netherlands => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
      {
        DR  => [qw(OV FR GR)],
        FL  => [qw(OV)],
        FR  => [qw(FL GR DR OV)],
        GE  => [qw(LI NB ZH UT OV)],
        GR  => [qw(DR FR)],
        LI  => [qw(NB GE)],
        NB  => [qw(ZE ZH GE LI)],
        NH  => [qw(ZH UT)],
        OV  => [qw(GE FL FR DR)],
        UT  => [qw(ZH NH GE)],
        ZE  => [qw(NB)],
        ZH  => [qw(NH UT GE NB)],
        AW  => [],
        CW  => [],
        SX  => [],
        BQ1 => [],
        BQ2 => [],
        BQ3 => [],
      }
    },
);

has _usa => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {
      {
        AK => [],
        AL => [qw(FL GA MS TN)],
        AR => [qw(LA MS MO OK TN TX)],
        AS => [],
        AZ => [qw(CA CO NV NM UT)],
        CA => [qw(OR NV AZ)],
        CO => [qw(AZ KS NE NM OK UT)],
        CT => [qw(MA NY RI)],
        DC => [qw(VA MD)],
        DE => [qw(MD NJ PA)],
        FL => [qw(GA AL)],
        FM => [],
        GA => [qw(FL AL TN NC SC)],
        GU => [],
        HI => [],
        IA => [qw(IL MN MO NE SD WI)],
        ID => [qw(MT NV OR UT WA WY)],
        IL => [qw(IN KY MO IA WI)],
        IN => [qw(IL KY MI OH)],
        KS => [qw(CO MO NE OK)],
        KY => [qw(IL IN MO OH TN VA WV)],
        LA => [qw(AR MS TX)],
        MA => [qw(CT NH NY RI VT)],
        MD => [qw(DE PA VA DC WV)],
        ME => [qw(NH)],
        MH => [],
        MI => [qw(WI OH IN MN)],
        MN => [qw(IA MI ND SD WI)],
        MO => [qw(AR IL IA KS KY NE OK TN)],
        MP => [],
        MS => [qw(AL AR LA TN)],
        MT => [qw(ID ND SD WY)],
        NC => [qw(GA SC TN VA)],
        ND => [qw(MN MT SD)],
        NE => [qw(CO IA KS MO SD WY)],
        NH => [qw(MN MA VT)],
        NJ => [qw(NY PA DE)],
        NM => [qw(AZ CO OK TX UT)],
        NV => [qw(AZ CA ID OR UT)],
        NY => [qw(VT MA CT NJ PA)],
        OH => [qw(PA WV KY IN MI)],
        OK => [qw(AR CO KS MO NM TX)],
        OR => [qw(CA ID NV WA)],
        PA => [qw(NY NJ DE MD WV OH)],
        PR => [],
        PW => [],
        RI => [qw(CT MA NY)],
        SC => [qw(GA NC)],
        SD => [qw(IA MN MT NE ND WY)],
        TN => [qw(AL AR GA KY MS MO NC VA)],
        TX => [qw(AR LA NM OK)],
        UT => [qw(AZ CO ID NV NM WY)],
        VA => [qw(KY MD NC TN WV DC)],
        VI => [],
        VT => [qw(MA NH NY)],
        WA => [qw(ID OR)],
        WI => [qw(MN MI IA IL)],
        WV => [qw(KY MD OH PA VA)],
        WY => [qw(CO MT NE SD UT ID)],
      }
    },
);


sub borders {
    my ($self) = @_;
    my $states = '_' . lc $self->country;
    return $self->$states();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geography::States::Borders - Return the borders of states and provinces

=head1 VERSION

version 0.0106

=head1 SYNOPSIS

  use Geography::States::Borders ();
  my $geo = Geography::States::Borders->new(country => 'Netherlands');
  my $states = $geo->borders('AW'); # empty list
  $states = $geo->borders('UT');    # ZH NH GE

=head1 DESCRIPTION

C<Geography::States::Borders> returns the border states (or provinces)
of given states or provinces.

* Currently the recognized countries are Australia, Canada, Brazil,
the Netherlands, and the USA.

=head1 ATTRIBUTES

=head2 country

  $country = $geo->country;

Set the country.

Default: C<usa>

=head1 METHODS

=head2 new

  $geo = Geography::States::Borders->new(country => $country);

Create a new C<Geography::States::Borders> object.

=head2 borders

  $states = $geo->borders($state_code);

Return a hash reference of the bordering states of the given state
code.

=head1 SEE ALSO

The F<t/methods.t> file in this distribution

L<Moo>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
