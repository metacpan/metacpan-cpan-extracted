use Test::More 'no_plan';

BEGIN {
    require 5.006_001 or plan 'skip_all';
    close *STDERR;
    open *STDERR, '>', \my $stderr;
    *CORE::GLOBAL::exit = sub { die $stderr };
}

# Load Getopt::Euclid in compiling (syntax check) mode
eval {
    local $^C = 1;
    require Getopt::Euclid and Getopt::Euclid->import();
    1;
};
is $@, '' => 'Compile test';


__END__

=head1 REQUIRED ARGUMENTS

=over

=item <prefix>

The string used to prefix the output file name(s).

=for Euclid:
    prefix.type: string

=back

