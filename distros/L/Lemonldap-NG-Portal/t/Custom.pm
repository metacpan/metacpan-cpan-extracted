package My;

sub accessToTrace {
    my $hash    = shift;
    my $custom  = $hash->{custom};
    my $req     = $hash->{req};
    my $vhost   = $hash->{vhost};
    my $params  = $hash->{params};
    my $session = $hash->{session};

    return
"$custom alias $params->[0]_$params->[1]:$session->{groups} by using $session->{ $params->[2] }";
}

sub return0 {
    return 0;
}

sub return1 {
    return 1;
}

1;
