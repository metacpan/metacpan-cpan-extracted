my $i = 0;

for (1 .. 5) {
    $i += $_;
}
# non brekeable line
sub_break();
arg_break(5);
arg_break(15);

sub should_break {
    return $i > 9
}

sub sub_break {
    $i = 0;
}

sub arg_break {
    1; # to have a place to break
}
