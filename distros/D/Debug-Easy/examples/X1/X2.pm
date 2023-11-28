package X1::X2;

sub thirdlevel {
    my $d = shift;
    $d->INFO(['Third level']);
    fourthlevel($d);
}

sub fourthlevel {
    my $d = shift;
    $d->WARN(['Fourth level']);
    fifthlevel($d);
}

sub fifthlevel {
    my $d = shift;
    $d->ERR(['Fifth level']);
}

1;
