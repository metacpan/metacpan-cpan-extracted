package Finance::StockAccount::Import::OptionsXpress;

our $VERSION = '0.01';

use Time::Moment;
use parent 'Finance::StockAccount::Import';

#### Expected Fields, tab separated:
# Symbol, Description, Action, Quantity, Price, Commission, Reg Fees, Date, TransactionID, Order Number, Transaction Type ID, Total Cost 
# 0       1            2       3         4      5           6         7     8              9             10                   11
my @pattern = qw(symbol 0 action 2 quantity 3 price 4 commission 5 regulatoryFees 6 date 7 totalCost 11);
my $numFields = 12;

sub new {
    my ($class, $file, $tzoffset) = @_;
    my $self = $class->SUPER::new($file, $tzoffset);
    $self->{pattern} = \@pattern;
    $self->{headers} = undef;
    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    my $file = $self->{file};
    open my $fh, '<', $file or die "Failed to open $file: $!.\n";
    $self->{fh} = $fh;

    my $hline = <$fh>;
    chomp($hline);
    my @headers = split(', ', $hline);
    scalar(@headers) == $numFields or die "Unexpected number of headers. Header line:\n$hline\n";
    $self->{headers} = \@headers;
    my $blankLine = <$fh>;
    $blankLine =~ /\w/ and warn "Expected blank line after header line.  May have inadvertantly skipped first transaction...\n";
    return 1;
}

sub getTm {
    my ($self, $dateString) = @_;
    if ($dateString =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})\s+(\d{1,2}):(\d{2}):(\d{2})\s+(\wM)$/i) {
        my ($month, $day, $year, $hour, $minute, $second, $pm) = ($1, $2, $3, $4, $5, $6, $7);
        if ($pm =~ /^PM$/i and $hour < 12) {
            $hour += 12;
        }
        return Time::Moment->new(
            year        => $year,
            month       => $month,
            day         => $day,
            hour        => $hour,
            minute      => $minute,
            second      => $second,
            offset      => $self->{tzoffset},
        );
    }
    else {
        warn "Did not recognize date time format:\n$dateString\n";
        return undef;
    }
}

sub nextAt {
    my $self = shift;
    my $fh = $self->{fh};
    my $pattern = $self->{pattern};
    if (my $line = <$fh>) {
        chomp($line);
        my @row = split(',', $line);

        my $hash = {};
        my $action;
        for (my $x=0; $x<scalar(@$pattern)-1; $x+=2) {
            my $index = $pattern->[$x+1];
            if (exists($row[$index])) {
                my $key = $pattern->[$x];
                if ($key eq 'action') {
                    $action = $row[$index];
                }
                elsif ($key eq 'date') {
                    $hash->{tm} = $self->getTm($row[$index]);
                }
                elsif ($key eq 'totalCost') {
                    next();
                }
                else {
                    my $value = $row[$index];
                    if ($key =~ /^(?:price|quantity|commission|regulatoryFees)$/) {
                        $value += 0;
                    }
                    $hash->{$key} = $row[$index];
                }
            }
        }
        my $at = Finance::StockAccount::AccountTransaction->new($hash);
        if ($action eq 'Sell') {
            $at->sell(1);
        }
        elsif ($action eq 'Buy') {
            $at->buy(1);
        }
        return $at;
    }
    else {
        close($fh) or die "Failed to close file descriptor: $!.\n";
        return 0;
    }
}



1;

