sub foo { bar(@_) }
sub bar { zog(@_) if $_[0] % 7 }
sub zog { }
for (my $i = 0; $i < 1e3; $i++) {
    $i % 5 ? foo($i) : bar($i);
}
