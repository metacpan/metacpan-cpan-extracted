package Device::Inverter::KOSTAL::PIKO::File;

use 5.014;
use utf8;
use warnings;

our $VERSION = '0.1';

use Mouse;
use Carp qw(carp confess croak);
use Device::Inverter::KOSTAL::PIKO::LogdataRecord;
use Device::Inverter::KOSTAL::PIKO::Timestamp;
use namespace::clean -except => 'meta';

# not before „use Mouse“, which implicitely turns warnings on:
no warnings 'experimental::smartmatch';

my $RE_zeit = qr/^(?<prefix>akt\. Zeit:\s+)(?<zeit>\d+)(?<suffix>)$/;

has columns => (
    is  => 'rw',
    isa => 'ArrayRef[Str]',
);

has fh => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 1,
);

has filename => (
    is  => 'ro',
    isa => 'Str',
);

has header => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        add_header   => 'push',
        header_lines => 'elements',
    },
);

has inverter => (
    is       => 'ro',
    isa      => 'Device::Inverter::KOSTAL::PIKO',
    required => 1,
);

has logdata => (
    is      => 'rw',
    isa     => 'ArrayRef[Device::Inverter::KOSTAL::PIKO::LogdataRecord]',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        append_logdata  => 'push',
        insert_logdata  => 'insert',
        logdata_records => 'elements',
    },
);

has timestamp => (
    is  => 'rw',
    isa => 'Device::Inverter::KOSTAL::PIKO::Timestamp',
);

sub BUILD {
    my $self = shift;

    # Parse file:
    my @logdata;
    while ( defined( my $line = $self->getline ) ) {
        for ($line) {

            # Wechselricher Logdaten
            when (/^Wechselrich?er Logdaten$/) {    # parse file header
                {                                   # Wechselrichter Nr:	255
                    $self->add_header($line);
                    my ( $line, %c ) =
                      $self->get_header_line(
                        qr/^Wechselrichter Nr:\s+(?<nr>\d+)$/);
                    unless ( $self->inverter->has_number ) {
                        $self->inverter->number( $c{nr} );
                    }
                    elsif ( ( my $nr = $self->inverter->number ) != $c{nr} ) {
                        carp(
                            $self->errmsg(
                                "Conflicting inverter numbers: $nr vs. $c{nr}"
                            )
                        );
                    }
                }
                {    # Name:	piko
                    my ( $line, %c ) =
                      $self->get_header_line(qr/^Name:\s+(?<name>.*?)\s*$/);
                }
                {    # akt. Zeit:	  12345678
                    my ( $line, %c ) = $self->get_header_line($RE_zeit);
                    $self->set_timestamp( $c{zeit} );
                }
                $self->get_header_line(qr/^$/);
            }

   # Logdaten U[V], I[mA], P[W], E[kWh], F[Hz], R[kOhm], Ain T[digit], Zeit[sec]
            when (/^Logdaten (.*)$/) {
                $self->add_header($line);
                for ( split /, /, $1 ) {
                    /^([^\[]+)\[(\w+)\]$/
                      or $self->errmsg(qq(Unknown unit spec "$_"));

                    # further parsing and usage of units not yet implemented
                }
            }

# Zeit	DC1 U	DC1 I	DC1 P	DC1 T	DC1 S	DC2 U	DC2 I	DC2 P	DC2 T	DC2 S	DC3 U	DC3 I	DC3 P	DC3 T	DC3 S	AC1 U	AC1 I	AC1 P	AC1 T	AC2 U	AC2 I	AC2 P	AC2 T	AC3 U	AC3 I	AC3 P	AC3 T	AC F	FC I	Ain1	Ain2	Ain3	Ain4	AC S	Err	ENS S	ENS Err	KB S	total E	Iso R	Ereignis
            when (/^Zeit\t(?:(?:[\w ]+)\t)+$/) {
                $self->add_header($line);
                $self->columns( split /\t/ );
            }

#   40094373	   466	  1070	   483	49402	16393	   543	   520	   287	49421	49162	     0	    20	     0	49412	    3	   224	  1880	   409	49927	   223	  1100	   240	49911	   223	   230	    50	49892	50.0	    1	    0	    0	    0	    0	   28	    0	  3	    0
            when (/^(?=[ 0-9]{10}\t) *([1-9][0-9]*)\t/) {
                if ( !@logdata || $logdata[-1][0] < $1 ) {
                    push @logdata, [ $1 => [$_] ];
                }
                elsif ( $logdata[-1][0] > $1 ) {
                    croak(
                        $self->errmsg(
                            "Records disordered: $logdata[-1][0] > $1")
                    );
                }
                else { push @{ $logdata[-1][1] }, $_ }
            }
        }
    }

    $_ = Device::Inverter::KOSTAL::PIKO::LogdataRecord->new(
        inverter  => $self->inverter,
        logdata   => $_->[1],
        timestamp => Device::Inverter::KOSTAL::PIKO::Timestamp->new(
            inverter => $self->inverter,
            epoch    => $_->[0],
        ),
    ) for @logdata;    # faster than map
    $self->logdata( \@logdata );
}

sub close { shift->fh->close }

sub errmsg {
    my $self     = shift;
    my $message  = shift // 'Unexpected error';
    my $filename = $self->filename;
    "$message at line $." . ( defined $filename && qq( of file "$filename") );
}

sub getline($) {
    my $self = shift;
    my $fh   = $self->fh;
    <$fh>;
}

sub get_header_line($) {
    my ( $self, $expectation ) = @_;
    defined( my $line = $self->getline )
      or confess( $self->errmsg('Unexpected EOF') );
    $line =~ $expectation
      or confess( $self->errmsg(qq(Unexpected content: "$line")) );
    $self->add_header($line);
    if (wantarray) { $line, %+ }
    else           { $line }
}

sub merge {
    my ( $self, $other ) = @_;

    carp('Merging data from different inverters may lead to unexpected results')
      if $self->inverter ne $other->inverter;
    if ( ( my $other_timestamp = $other->timestamp )->epoch >
        $self->timestamp->epoch )
    {
        $self->timestamp($other_timestamp);
        $other_timestamp = $other_timestamp->epoch;
        my $substitutions = 0;
        $substitutions += s/$RE_zeit/$+{prefix}$other_timestamp$+{suffix}/
          for @{ $self->header };    # $self->header_lines provides only a copy
        carp('Could not correct timestamp when merging')
          unless $substitutions;
    }

    my @other_records = $other->logdata_records or return 0;

    my $i = 0;
    {    # perform binary search to locate position for first new element:
        my $i_max            = $#{ $self->logdata } + 1;
        my $target_timestamp = 0 + $other_records[0]->timestamp;
        while ( $i < $i_max ) {
            if ( $self->logdata->[ my $i_mid = ( $i + $i_max ) >> 1 ]
                ->timestamp < $target_timestamp )
            {
                $i = $i_mid + 1;
            }
            else { $i_max = $i }
        }
    }

    my $new_records = 0;
    while ( $i <= $#{ $self->logdata } ) {

        # use ->epoch (not overloading) for better performance:
        for ( $self->logdata->[$i]->timestamp->epoch <=> $other_records[0]
            ->timestamp->epoch )
        {
            when (0) {
                if (
                    (
                        my $my_logdata =
                        $self->logdata->[$i]->logdata_joined('')
                    ) ne (
                        my $other_logdata =
                          $other_records[0]->logdata_joined('')
                    )
                  )
                {
                    croak(  'Different data for '
                          . $self->logdata->[$i]->timestamp->datetime
                          . ":\n$my_logdata----\n$other_logdata" );
                }
                shift @other_records;
                return $new_records unless @other_records;
            }
            when (1) {

                # extremely slow:
                # $self->insert_logdata( $i, shift @other_records );
                splice @{ $self->logdata }, $i, 0, shift @other_records;
                ++$new_records;
                return $new_records unless @other_records;
            }
            when (-1) { ++$i }
            die;
        }
    }
    $self->append_logdata(@other_records);
    $new_records += @other_records;
}

sub print {
    my ( $self, $fh ) = @_;
    $fh //= \*STDOUT;
    print $fh $self->header_lines;
    $_->print($fh) for $self->logdata_records;
}

sub set_timestamp {
    my ( $self, $timestamp ) = @_;
    $self->timestamp(
        Device::Inverter::KOSTAL::PIKO::Timestamp->new(
            inverter => $self->inverter,
            epoch    => $timestamp,
        )
    );
}

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
