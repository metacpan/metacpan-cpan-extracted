#!/usr/bin/perl
use strict;
use warnings;

$|++;

use Lingua::Stem;
use Lingua::Stem::Snowball;
use Benchmark::Timer;

use constant ITERS => 10;

my $timer = Benchmark::Timer->new;

die "Usage: ./bin/benchmark_stemmers.plx TEXTFILES"
    unless @ARGV;

# Retrieve, pre-process and tokenize text.
sub retrieve_text {
    my $filepath = shift;
    my $text     = do {
        open( my $fh, '<', $filepath )
            or die "Couldn't open file '$filepath' for reading: $!";
        local $/;
        <$fh>;
    };
    $text = lc($text);
    $text =~ s/[^a-z']/ /gs;
    $text =~ s/\B'//g;
    $text =~ s/'\B//g;
    my @tokens = split( ' ', $text );
    return \@tokens;
}

my @token_arrays = map { retrieve_text($_) } @ARGV;
# Prepare vars used in the report.
my %unique;
my $num_tokens = 0;
for my $tokens (@token_arrays) {
    $num_tokens += scalar @$tokens;
    $unique{$_} = 1 for @$tokens;
}
my $num_unique = scalar keys %unique;

for my $iter ( 1 .. ITERS ) {
    print "$iter ";
    my ( @out, $out );
    my $snowball    = Lingua::Stem::Snowball->new( lang => 'en' );
    my $lingua_stem = Lingua::Stem->new( -locale        => 'EN' );

    # LS without cache.
    for my $tokens (@token_arrays) {
        $timer->start('LS');
        $out = $lingua_stem->stem(@$tokens);
        $timer->stop('LS');
        undef $out;
    }

    # Turn stem_caching on for LS.
    $lingua_stem->stem_caching( { -level => 2 } );

    for my $tokens (@token_arrays) {
        # LS, with stem caching.
        $timer->start('LS2');
        $out = $lingua_stem->stem(@$tokens);
        $timer->stop('LS2');
        undef $out;

        # LSS.
        $timer->start('LSS');
        @out = $snowball->stem($tokens);
        $timer->stop('LSS');
        undef @out;

        # stem_in_place, if this version of LSS is recent enough.
        if ( $snowball->can('stem_in_place') ) {
            my @copy = @$tokens;
            $timer->start('LSS2');
            $snowball->stem_in_place( \@copy );
            $timer->stop('LSS2');
        }
    }

    # LS's stem_cache is global per -locale, so clear it each iter.
    $lingua_stem->clear_stem_cache;
}

my $ls_ver  = $Lingua::Stem::VERSION;
my $lss_ver = $Lingua::Stem::Snowball::VERSION;
$lss_ver =~ s/_.*//;
my %results = $timer->results;
# Make each result the average time per iter to stem all docs.
$_ *= scalar @ARGV for values %results;

# Print the report.
printf( '
|--------------------------------------------------------------------|
| total words: %-6d | unique words: %-6d                         |
|--------------------------------------------------------------------|
| module                        | config        | avg secs | rate    |
|--------------------------------------------------------------------|',
    , $num_tokens, $num_unique );
printf( '
| Lingua::Stem %.2f             | no cache      | %.3f    | %-7d |
| Lingua::Stem %.2f             | cache level 2 | %.3f    | %-7d |
| Lingua::Stem::Snowball %.2f   | stem          | %.3f    | %-7d |',
    $ls_ver,  $results{LS},  ( $num_tokens / $results{LS} ),
    $ls_ver,  $results{LS2}, ( $num_tokens / $results{LS2} ),
    $lss_ver, $results{LSS}, ( $num_tokens / $results{LSS} ),
);
printf( '
| Lingua::Stem::Snowball %-4s   | stem_in_place | %.3f    | %-7d |',
    $lss_ver, $results{LSS2}, ( $num_tokens / $results{LSS2} ) )
    if exists $results{LSS2};
print "\n|" . ( '-' x 68 ) . "|\n";

