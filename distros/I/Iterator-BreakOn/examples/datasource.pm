package datasource;

use strict;
use warnings;
use Carp;

sub new {
    my  $class  =   shift;
    my  $self   =   {
            'source'    =>  [],
        };
    bless $self, $class;

    return $self->init( @_ );
}

sub init {
    my  $self   =   shift;

    while (<DATA>) {
        chomp;            
        my ($location, $zipcode, $name, $amount ) = split(/\|/, $_);

        my $item = datasource::item->new(
                        location    => $location,
                        zipcode     => $zipcode,
                        name        => $name,
                        amount      => $amount
                     );

        push(@{ $self->{source} }, $item );
    }

    return $self;
}

sub next {
    my  $self   =   shift;

    return shift @{ $self->{source} };
}

sub dump_as_csv {
    my  $self   =   shift;
    my  $file   =   shift;

    open(CSV,"> $file") || die "could not open ${file} for writing - $!";

    print CSV '"location","zipcode","name","amount"',"\n";
    while (my $item = $self->next()) {
        print CSV sprintf('"%s","%u","%s","%.2f"',
                            $item->get('location'),
                            $item->get('zipcode'),
                            $item->get('name'),
                            $item->get('amount') ), "\n";
    }
    close(CSV);

    return;
}

package datasource::item;

sub new {
    my  $class  =   shift;
    my  $self   =   { @_ };

    return bless $self,$class;
}

sub get {
    my  $self   =   shift;
    my  $field  =   shift;

    return $self->{$field};
}

sub getall {
    my  $self   =   shift;
    my  %values =   ( %{ $self} );

    return wantarray ? %values : \%values;
}

package datasource;

1;

__DATA__
AVILA|05000|OVIEDO, ANTONIO|244.52
AVILA|05001|García Calvo, José Luis|249.89
AVILA|05001|García Sanjosé, Rafael|886.34
AVILA|05002|Collado Martin, Francisco José|838.47
AVILA|05003|Herrero, Pedro Luis|703.99
AVILA|05003|Pedro Luis Herrero|411.66
AVILA|05003|Arroyo Dochado, Julio|754.97
BADAJOZ|06100|SANDRES SILVA, EMILIO|175.07
BADAJOZ|06110|GUARINO GONZALEZ, J.|302.77
BADAJOZ|06110|SALA FEIJOO, RAFAEL|83.61
BADAJOZ|06130|MIRANDA QUINTERO, VICENTE|352.88
BADAJOZ|06130|DIEGO REYES, H.DE|298.35
BADAJOZ|06131|DEPORTES QUERQUS, S.L.|379.66
BADAJOZ|06140|DOMINGUEZ RINCON, JULIAN|374.80
BADAJOZ|06150|MONTAÑO RODRIGUEZ, JUAN|37.15
BADAJOZ|06160|CHAVES SAAVEDRA, SATURNINO|351.31
BADAJOZ|06160|DIAZ HERMOSA, FABIAN|265.81
BADAJOZ|06160|SAAVEDRA SERRANO, ANTONIO|23.99
BADAJOZ|06184|FERNANDEZ CACHO, ANDRES|622.67
BADAJOZ|06186|RODRIGUEZ B.. FRANCISCO|653.60
BADAJOZ|06196|ESCOBAR, BENIGNO|952.95
BADAJOZ|28005|Castañon Blazquez, Marcelino|256.86
BADAJOZ|28005|Fernández Fernández, Toribio|949.74
MADRID|28005|Curtidos Arganzuela, S.L.|450.52
MADRID|28005|Peña Fernández, Amalia|857.84
MADRID|28005|Guarnicioneria Roal, S.A.|571.04
MADRID|28005|Isabel Ozores Santos|825.90
MADRID|28005|Cursor Comunicación, S.L.|513.48
MADRID|28005|Cursor Comunicación, S.L.|880.94
MADRID|28005|Sanz Gil, Juana|113.32
MADRID|28005|Guarnicionería Roal, S.A.|530.46
MADRID|28006|ODAE, Representaciones y Distribuciones, S.L.|405.16
MADRID|28006|Fund. Lab. Serv. Asist. I.N.I.|89.96
MADRID|28006|Armería Diana Viaji, S.A.|114.41
