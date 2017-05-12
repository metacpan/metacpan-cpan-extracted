#!/usr/bin/perl

use lib qw(../lib);
use strict;
use warnings;

$|++;

use Lingua::Stem;
use Lingua::Stem::En;
use Lingua::Stem::Snowball;
use Benchmark::Timer;

my $timer = Benchmark::Timer->new;

die "Usage: ./benchmark_stemmers.plx TEXTFILE"
    unless @ARGV;

# retrieve, pre-process and tokenize text
my $text = do {
    open( my $fh, '<', $ARGV[0] ) 
        or die "Couldn't open file '$ARGV[0]' for reading: $!";
    local $/;
    <$fh>;
};
$text = lc($text);
$text =~ s/[^a-z']/ /gs;
$text =~ s/\B'//g;
$text =~ s/'\B//g;
my @tokens = split( ' ', $text );

for my $iter ( 1 .. 10 ) {
    print "$iter ";
    my ( @out, $out );
    my $snowball    = Lingua::Stem::Snowball->new( lang => 'en' );
    my $lingua_stem = Lingua::Stem->new( -locale => 'EN' );

    # LSS
    $timer->start('LSS');
    @out = $snowball->stem(\@tokens);
    $timer->stop('LSS');
    undef @out;

    # stem_in_place, if this version of LSS is recent enough
    if ( $snowball->can('stem_in_place') ) {
        my @copy = @tokens;
        $timer->start('LSS2');
        $snowball->stem_in_place(\@copy);
        $timer->stop('LSS2');
    }

    # LS
    $timer->start('LS');
    $out = $lingua_stem->stem(@tokens);
    $timer->stop('LS');
    undef $out;

    # LS, with stem caching
    $lingua_stem->stem_caching({ -level => 2 });
    $timer->start('LS2');
    $out = $lingua_stem->stem(@tokens);
    $timer->stop('LS2');
    undef $out;

    # LS, with stem caching and stem in place
    {
        $lingua_stem->stem_caching({ -level => 2 });
        my @copy = @tokens;
        my $copy_ref = \@copy;
        $timer->start('LS2SIP');
        $out = $lingua_stem->stem_in_place(@copy);
        $timer->stop('LS2SIP');
        undef $out;
    }

}

# prepare vars used in the report
my $num_tokens = scalar @tokens;
my %unique;
$unique{$_} = 1 for @tokens;
my $num_unique = scalar keys %unique;
my $ls_ver = $Lingua::Stem::VERSION;
my $lss_ver = $Lingua::Stem::Snowball::VERSION;
$lss_ver =~ s/_.*//;
my %results = $timer->results;

# print the report
printf('
|--------------------------------------------------------------------|
| source: %-19s | words: %-6d | unique words: %-6d |
|--------------------------------------------------------------------|
| module                        | config        | avg secs | rate    |
|--------------------------------------------------------------------|',
    $ARGV[0], $num_tokens, $num_unique );
printf('
| Lingua::Stem %.2f             | no cache      | %.3f    | %-7d |
| Lingua::Stem %.2f             | cache level 2 | %.3f    | %-7d |
| Lingua::Stem %.2f             | cachelv2, sip | %.3f    | %-7d |
| Lingua::Stem::Snowball %.2f   | stem          | %.3f    | %-7d |',
    $ls_ver, $results{LS}, ($num_tokens/$results{LS}),
    $ls_ver, $results{LS2}, ($num_tokens/$results{LS2}),
    $ls_ver, $results{LS2SIP}, ($num_tokens/$results{LS2SIP}),
    $lss_ver, $results{LSS}, ($num_tokens/$results{LSS}),
    );
printf('
| Lingua::Stem::Snowball %-4s   | stem_in_place | %.3f    | %-7d |',
    $lss_ver, $results{LSS2}, ($num_tokens/$results{LSS2}) )
    if exists $results{LSS2};
print "\n|" . ('-' x 68) . "|\n";

