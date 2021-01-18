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

1;
