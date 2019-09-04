# encoding: Latin8
use Latin8;
print "1..1\n";

my $__FILE__ = __FILE__;

# \173
if ("{" =~ m/\173/) {
    print qq<ok - 1 "{" =~ m/\\173/ $^X $__FILE__\n>;
}
else{
    print qq<not ok - 1 "{" =~ m/\\173/ $^X $__FILE__\n>;
}

__END__

