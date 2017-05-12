use HTML::CMTemplate;
use strict;

sub load_file {
    my $name = shift;
    local *FILE;
    local $/;
    undef $/;

    open FILE, "<$name" || die "Failed to open file '$name': $!\n";
    my $str = <FILE>;
    close FILE;
    return $str;
}

sub compare_str_to_file {
    my $str = shift;
    my $name = shift;

    return $str eq load_file($name);
}

sub print_to_file {
    my $name = shift;
    my $str = shift;
    local *FILE;
    open FILE, ">$name" || die "Failed to open file '$name': $!\n";
    print FILE $str;
    close FILE;
}
1;
