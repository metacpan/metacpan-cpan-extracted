package Lingua::Thesaurus::IO::Jurivoc;
use Moose;
extends 'Lingua::Thesaurus::IO::LivelinkCollectionServer';

has '_rel_types'       => (is => 'ro',
         documentation => "default reltypes for Jurivoc "
                        . "(thesaurus for Swiss Tribunal Federal",
                           default => sub { {
  #  rel    description         reverse   is_external
  #  ===    ===========         =======   ===========
     USE => ['Use'              => UF    => undef],
     UF  => ['Used For'         => USE   => undef],
     USA => ['Use AND'          => UFA   => undef],
     UFA => ['Used For AND'     => USA   => undef],
     BT  => ['Broad Term'       => NT    => undef],
     NT  => ['Narrow Term'      => BT    => undef],
     RT  => ['Related Term'     => RT    => undef],
     SN  => ['Scope Note'       => undef ,  1    ],
     COM => ['Commentaire'      => undef ,  1    ],
     SA  => ['See also'         => undef ,  1    ],
 }});

1;

__END__

=encoding ISO8859-1

=head1 NAME

Lingua::Thesaurus::IO::Jurivoc - Thesaurus IO class for "Jurivoc", the Swiss thesaurus for justice

=head1 DESCRIPTION

The Swiss Supreme Court (a.k.a "Tribunal Fédéral") maintains a multi-lingual
thesaurus called B<Jurivoc>, containing terms related to justice.
This is published at
L<http://www.bger.ch/fr/index/juridiction/jurisdiction-inherit-template/jurisdiction-jurivoc-home.htm>.
Thesaurus files are dumped from a database called "Livelink Collection Server"
(formerly known as "Basis Plus").
The format is quite similar to ISO 2788, but with a few variations.
Hence the present class inherits from
L<Lingua::Thesaurus::IO::LivelinkCollectionServer>.

Relations in Jurivoc are slightly different from default
relations in LivelinkCollectionServer thesauri :

    rel      description         reverse   is_external
    ===      ===========         =======   ===========
   [USE   => 'Use'              => UF    => undef],
   [UF    => 'Used For'         => USE   => undef],
   [USA   => 'Use AND'          => UFA   => undef],
   [UFA   => 'Used For AND'     => USA   => undef],
   [BT    => 'Broad Term'       => NT    => undef],
   [NT    => 'Narrow Term'      => BT    => undef],
   [RT    => 'Related Term'     => RT    => undef],
   [SN    => 'Scope Note'       => undef ,  1    ],
   [COM   => 'Commentaire'      => undef ,  1    ],
   [SA\d* => 'See also'         => undef ,  1    ],


=head1 TODO

  - implement multiligual translations (GER, FRE, IT)
    !! PROBL: inverse relation is not absolute; depends on the input file
