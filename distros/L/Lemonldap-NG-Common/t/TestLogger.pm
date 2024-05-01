package t::TestLogger;
use base 'Test::Builder::Module';

our $VERSION = '2.0.19';

sub new {

    my $obj = { _logs => {} };
    return bless $obj, shift;
}

for my $level (qw/error warn notice info debug/) {
    *$level = sub { push @{ $_[0]->{_logs}->{$level} }, $_[1] };
}

sub contains {
    my ( $self, $level, $line_regex ) = @_;
    if ( ref($line_regex) ) {
        $self->builder->ok(
            scalar grep( $line_regex, @{ $self->{_logs}->{$level} } ),
            "Found $line_regex in $level logs" );
    }
    else {
        $self->builder->ok(
            scalar grep( { $_ eq $line_regex } @{ $self->{_logs}->{$level} } ),
            "Found $line_regex in $level logs"
        );
    }
}

1;
