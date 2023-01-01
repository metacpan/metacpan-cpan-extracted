package MultiPackage;

sub go {
    my $x = 1;
    return $x;
}

1;

package MultiPackage::Sub;

sub go {
    my $x = 1;
    return $x;
}

1;
