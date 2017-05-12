package TestChunks;
use strict;
use Test::More 'no_plan';
use Spiffy '-base';
our @EXPORT = qw(test_chunks ok is);
field chunks => {};

sub test_chunks {
    my $start = $_[0];
    my $test_data = join '', <main::DATA>;
    my @test_data = ($test_data =~ /^(\Q$start\E.*?(?=\Q$start\E|\z))/msg);
    my @tests = ();
    my $split = join '|', @_;
    for my $data (@test_data) {
        my $test = TestChunks->new;
        my @hash = split /^($split)\n/m, $data;
        shift @hash;
        %{$test->chunks} = @hash;
        push @tests, $test;
    }
    return @tests;
}

sub chunk {
    my $self = shift;
    $self->chunks->{(shift)};
}
