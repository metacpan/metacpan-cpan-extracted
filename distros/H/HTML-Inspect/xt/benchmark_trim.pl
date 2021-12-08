use strict;
use warnings;
use utf8;
use Benchmark;

=pod

Is C<$string =~ s/^\s?(.*?)\s?$/$1/s;> faster than C<$string =~ s/^\s//s; $string =~s/\s$//s;> 
The regexes are specific to our special case, where we know that we MAY have only one space already.
Here is the output on my computer

    Benchmark: timing 5000000 iterations of COPY_TRIMMED, STRIPSS...
    COPY_TRIMMED:  1 wallclock secs ( 0.40 usr +  0.00 sys =  0.40 CPU) @ 12500000.00/s (n=5000000)
         STRIPSS:  2 wallclock secs ( 1.15 usr +  0.00 sys =  1.15 CPU) @ 4347826.09/s (n=5000000)


New iteration (The winner is definitely STRIPGRSZ):
    16:24:21|berov@kb-S340:HTML-Inspect$ perl xt/benchmark_trim.pl 
    Benchmark: timing 5000000 iterations of COPY_TRIMMED, STRIPGRSZ, STRIPSS...
    COPY_TRIMMED: 17 wallclock secs (18.33 usr +  0.00 sys = 18.33 CPU) @ 272776.87/s (n=5000000)
     STRIPGRSZ: 10 wallclock secs (10.50 usr +  0.00 sys = 10.50 CPU) @ 476190.48/s (n=5000000)
       STRIPSS: 12 wallclock secs (11.22 usr +  0.00 sys = 11.22 CPU) @ 445632.80/s (n=5000000)Below is the benchmark.

=cut

my $str = " some 
       qqqq
other        multi-spase

string          ";

timethese(
    5000000,
    {
        'COPY_TRIMMED' => sub {
            my $string = $str;
            $string =~ s/\s+/ /gs;
            return $string =~ s/^\s?(.*?)\s?$/$1/r;
        },
        'STRIPSS' => sub {
            my $string = $str;
            $string =~ s/\s+/ /gs;
            $string =~ s/^\s//s;
            $string =~ s/\s$//s;
            return $string;
        },
        'STRIPGRSZ' => sub {
            my $string = $str;
            return $string =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z$//r;
        },
    }
);


