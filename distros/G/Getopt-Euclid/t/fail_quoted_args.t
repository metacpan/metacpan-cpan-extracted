use Test::More 'no_plan';

BEGIN {
    require 5.006_001 or plan 'skip_all';
    close *STDERR;
    open *STDERR, '>', \my $stderr;
    *CORE::GLOBAL::exit = sub { die $stderr };
}

BEGIN {
    @ARGV = (
        '-foo bar',
    );
    # This is equivalent to running:
    #    quoted_args_3.t '-foo bar'
    # or:
    #    quoted_args_2.t -foo\ bar
}


if (eval { require Getopt::Euclid and Getopt::Euclid->import(); 1 }) {
    ok 0 => 'Unexpectedly succeeded';
}
else {
    like $@, qr/Unknown argument/   => 'Failed as expected'; 
}


=head1 REQUIRED ARGUMENTS

=over

=item -foo <foo>

=back

=cut
