package Medical::Growth::Testme;

our (@ISA) = ('Medical::Growth::Base');

sub new { bless {}, shift }

sub measure_class_for {
    my $self = shift;
    my (%criteria) = @_ == 1 ? %{ $_[0] } : @_;
    return "Found me! (measure = $criteria{measure})";
}

sub check_data {
    shift->read_data;
}

1;

__DATA__

# This is a test
1 2
3 4
5 6

__END__

7 8
9 0

