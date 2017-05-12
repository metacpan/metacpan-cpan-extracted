package Mail::Miner::Recogniser::Date;
use Date::PeriodParser;

$Mail::Miner::recognisers{"".__PACKAGE__} = 
    {
     help  => "Match messages around the given date",
     keyword => "dated",
     type    => "=s",
     nodisplay => 1,
    };

sub process { return () }

sub search {
    my ($obj, $term) = @_;
    my ($from, $to) = parse_period($term);
    my $when = $obj->date_epoch;
    return ($when >= $from and $when <= $end);
}

1;
