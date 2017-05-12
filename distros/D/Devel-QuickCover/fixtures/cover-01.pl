
BEGIN { my $b = 0 } # YES SUB,main::BEGIN,BEGIN
INIT  { my $c = 0 } # YES SUB,main::INIT,INIT
CHECK { my $d = 0 } # YES SUB,main::CHECK,CHECK
END   { my $e = 0 } # YES SUB,main::END,END

sub used {
    my $a = 1;  # YES SUB,main::used,RUN
    if (1) {    # YES
        $a = 2;
    }
    return $a;  # YES
}

sub unused {
    return 5;   # NO SUB,main::unused,
}

used();         # YES
