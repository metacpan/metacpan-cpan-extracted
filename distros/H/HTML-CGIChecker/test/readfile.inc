sub readfile {
    my $name = shift;
    my $out = "";
    
    open(F, $name);
    while (<F>) {
        $out .= $_;
    }
    
    return $out;
}

1;
