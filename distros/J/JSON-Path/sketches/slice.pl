use 5.016;

use Data::Dumper;

my @slices = ( 
    ':b',
    '::c',
    
    'a:',
    'a::',
    'a:b',
    'a:b:c',
);
my $TOKEN_ARRAY_SLICE = ':';

my %h = map { $_ => join ':', @{slice($_)} } @slices;
print Dumper \%h;

sub slice {
    my $spec = shift;
    my @substream = split //, $spec;

    if ($substream[0] eq $TOKEN_ARRAY_SLICE) { 
        unshift @substream, undef;
    }

    if ($substream[2] eq $TOKEN_ARRAY_SLICE) {
        @substream = (@substream[(0,1)], undef, @substream[(2..$#substream)]);
    }

    my ($start, $end, $step);
    $start = $substream[0] // 0;
    $end = $substream[2] // -1;
    $step = $substream[4] // 1;
    
    return [ $start, $end, $step ];
}
