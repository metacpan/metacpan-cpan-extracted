use IO::Interactive qw( busy );

print "1..2\n";

*ARGV = *DATA;

my $fh = busy {
    print "ok 1\n";
    sleep 3;
};

print <$fh>;
print <ARGV>;

__DATA__
ok 2
