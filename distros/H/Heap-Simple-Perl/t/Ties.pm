package Ties;
# use warnings;	# Remove this for production. Assumes perl 5.6
use strict;

my $ties = 0;

sub count {
    return $ties;
}

END {
    die "You still have ties hanging" if $ties;
}

package Stie;
my $sfetches = 0;

sub TIESCALAR {
    my ($class, $value) = @_;
    $ties++;
    return bless [$value], $class;
}

sub FETCH {
    $sfetches++;
    return shift->[0];
}

sub DESTROY {
    $ties--;
}

sub fetches {
    my $old = $sfetches;
    $sfetches = 0;
    return $old;
}

package Atie;
my $afetches = 0;
sub TIEARRAY {
    my $class = shift;
    $ties++;
    return bless {foo => \@_}, $class;
}

sub FETCH {
    $afetches++;
    # main::diag("Array fetch @_");
    return $_[0]->{foo}[$_[1]];
}

sub FETCHSIZE {
    return scalar @{shift->{foo}};
}

sub DESTROY {
    $ties--;
}

sub fetches {
    my $old = $afetches;
    $afetches = 0;
    return $old;
}

package Htie;
my $hfetches = 0;
sub TIEHASH {
    my ($class, %hash) = @_;
    $ties++;
    return bless [\%hash], $class;
}

sub FETCH {
    $hfetches++;
    return $_[0][0]{$_[1]};
}

sub FIRSTKEY {
    my $array = shift;
    keys %{$array->[0]};	# reset each
    return each %{$array->[0]};
}

sub NEXTKEY {
    my $array = shift;
    return each %{$array->[0]};
}

sub EXISTS {
    return exists $_[0][0]{$_[1]};
}

sub DESTROY {
    $ties--;
}

sub fetches {
    my $old = $hfetches;
    $hfetches = 0;
    return $old;
}

1;
