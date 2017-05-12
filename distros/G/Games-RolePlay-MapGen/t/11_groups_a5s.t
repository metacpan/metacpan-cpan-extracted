
my $file = $0; $file =~ s/11_groups_a5s.t/10_groups.t/;
if( open my $in, $file ) {
    local $/ = undef;
    my $code = <$in>; close $in;

    $code =~ s/^# (.*) # UNCOMMENT/$1/m;

    eval $code; die $@ if $@;

} else {
    die $!;
}
