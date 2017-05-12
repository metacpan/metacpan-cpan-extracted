use strict;
use warnings;
use utf8;
use Test::More;
use Docopt;
use JSON::PP;
use Data::Dumper;
use boolean;

my $src = slurp('t/testcases.docopt');
my @src = grep /\S/, split /r"""/, $src;
my $json = JSON::PP->new()->allow_nonref();
for (@src) {
    note "============================================";
    my ($doc, $cmdlines) = split /"""/, $_;
    $doc =~ s/\n\z//;
    note 'q{' . $doc . '}';
    while ($cmdlines =~ m!^\$ prog(.*)\n((?:[^\n]+\n)+)!mg) {
        note "--------------------------------------------";
        my $argv = $1;
        my $expected = $2;

        $expected =~ s/\n\z//;
        $expected =~ s/\s*#.*//;
        $argv =~ s/\A\s*//;
        $argv =~ s/\s*\z//;
        my @argv = split /\s+/, $argv;
        note("ARGV: $argv");
        note("Expected:: $expected");
        my $result = eval {
            docopt(doc => $doc, argv => \@argv);
        };
        if (my $e = $@) {
            if ((Scalar::Util::blessed($e)||'') =~ /^Docopt::/) {
                note "Error: $e";
                is('"user-error"', $expected) or do { diag Dumper($e); diag Dumper(\@argv); };
            } else {
                die $e;
            }
        } else {
            my $expected_data = eval { $json->decode($expected) } or die "$@\n'''$expected'''";
            for my $k (keys %$expected_data) {
                if (ref $expected_data->{$k}) {
                    if (ref($expected_data->{$k}) eq 'JSON::PP::Boolean') {
                        $expected_data->{$k} = $expected_data->{$k} ? boolean::true() : undef;
                    }
                }
            }
            is_deeply($result, $expected_data) or do { note Dumper($result); note Dumper($expected_data); note Dumper(\@argv)};
        }
    }
}

done_testing;

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname
        or Carp::croak("Can't open '$fname' for reading: '$!'");
    scalar(do { local $/; <$fh> })
}
