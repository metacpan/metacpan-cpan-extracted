use Test::More 'no_plan';

BEGIN {
    require 5.006_001 or plan 'skip_all';
    close *STDERR;
    open *STDERR, '>', \my $stderr;
    *CORE::GLOBAL::exit = sub { die $stderr };
}

BEGIN {
    @ARGV = (
        "--foo",
        "--bar",
    );
}

if (eval { require Getopt::Euclid and Getopt::Euclid->import(); 1 }) {
    ok 0 => 'Unexpectedly succeeded';
}
else {
    like $@, qr/Unknown argument: --foo --bar/ => 'Failed as expected'; 
}

__END__

=head1 OPTIONS

=over

=item --foo <foo>

=item --bar <bar>

=back

=cut
