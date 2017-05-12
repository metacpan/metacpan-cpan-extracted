package Term::ReadLine::Mock;

use strict;
use warnings;

sub ReadLine {'Term::ReadLine::Mock'};
sub readline { $_[0]->{cmd} }
sub new { bless { cmd => $_[1]->{cmd} } }
sub string {
    my ($self) = @_;
    unless ( $self->{string} ) {
        my $string;
        $self->{string} = \$string;
    }
    $self->{string};
}
sub OUT {
    my ($self) = @_;
    unless($self->{OUT}) {
        open($self->{OUT}, '>', \${$self->{string}})
            or die "Could not open string for writing";
    }
    $self->{OUT};
}
1;
