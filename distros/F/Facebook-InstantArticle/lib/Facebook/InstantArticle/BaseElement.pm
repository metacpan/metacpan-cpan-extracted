package Facebook::InstantArticle::BaseElement;
use Moose;
use namespace::autoclean;

sub squeeze {
    my $self = shift;
    my $str  = shift // '';

    $str =~ s/\s+/ /sg;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    return $str;
}

1;
