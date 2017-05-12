package Devel::SimpleProfiler;

use strict;
use warnings;

use Aspect;
use Time::HiRes;
use Data::Dumper;

use File::Temp qw/ tempfile /;

use vars qw($VERSION);

$VERSION = '1.0';

our( @stack, %calltimes, %callers, %calls, $tmpFile, $re );

=head1 NAME

 Devel::SimpleProfiler - quick and dirty perl code profiler

=head1 SYNPOSIS

 use Devel::SimpleProfiler;

 Devel::SimpleProfiler::init( "/tmp/tmpfile", qr/RegexToMatchSubNames/ );
 Devel::SimpleProfiler::start;

 ....

 if( ! fork ) {
     # must restart for child process
     Devel::SimpleProfiler::start;
 }

 ....

 Devel::SimpleProfiler::analyze('total');
 exit;

 # ---- PRINTS OUT (and sorts by total) -----
 performance stats ( all times are in ms)

             sub  | # calls | total t | mean t | avg t | max t | min t
 -----------------+---------+---------+--------+-------+-------+------
 main::test_suite |       1 |    2922 |   2922 |  2922 |  2922 |  2922
  OtherThing::fun |      27 |     152 |      1 |     5 |    63 |     0
     SomeObj::new |       3 |      26 |      8 |     8 |     8 |     8

 .... 

=head1 DESCRIPTION

 This is meant to be a simple way to get a performance benchmark for 
 perl subs. It uses the fantastic Aspect module written by 
 Adam Kennedy, Marcel Gruenauer and Ran Eilam to monkey patch select
 perl subs and gather statistics about them.

=head1 METHODS

=head2 init

 init takes two arguments : a temp file to use and a regular expression
 to find subs to measure. By default, the file is /tmp/foo and the 
 regex is qr/^main:/;
 
 init should be called once for a run.

=cut
sub init {
    ( $tmpFile, $re ) = @_;
    $tmpFile ||= '/tmp/foo';
    $re      ||= qr/^main:/;
    unlink $tmpFile;
}

=head2 analyze

 analyze simply outputs the data collected from the profiler so far in 
 a table with the columns
   * sub name
   * total number of calls
   * total time in ms
   * mean time in ms
   * average time in ms
   * max time in ms
   * min time in ms

 This can be called as many times as desired. It takes an optional
 argument to sort by, which can be one of :
  'calls', 'total', 'mean', 'avg', 'max', 'min'
 The default sorting is by average.

=cut
sub analyze {
    my $sort = shift;
    my( %funtimes, %funcalls, %funcalled );
    open( IN, "<$tmpFile" );
    while( <IN> ) {
        chomp;
        my( $fun, $time, $stack ) = split /\|/, $_;
        push @{$funtimes{ $fun }}, $time;
        my( @stack ) = split ',', $stack;
        for my $call ( @stack ) {
            $funcalls{$call}{$fun}++;
            $funcalled{$fun}{$call}++
        }
    }
    _analyze( \%funtimes, \%funcalled, \%funcalls, $sort );
} #analyze

sub _analyze {
    my( $calltimes, $callers, $calls, $sort ) = @_;
    $sort ||= 'avg';
    my %stats;
    my $longsub = 0;
    for my $subr ( keys %$calltimes ) {
        if( length( $subr ) > $longsub ) { $longsub = length( $subr ) };
        my @times = sort { $a <=> $b }  @{$calltimes->{$subr}};
        my $calls = scalar( @times );
        my $tottime = 0;
        map { $tottime += $_ } @times;
        $stats{$subr} = {
            calls => $calls,
            total => $tottime,
            mean  => $times[ int( @times/2 ) ],
            avg   => $calls ? int($tottime / $calls) : '?',
            max   => $times[$#times],
            min   => $times[0],
        };
    }
    my( @titles ) = ( 'sub', '# calls', 'total t', 'mean t', 'avg t', 'max t', 'min t' );
    my $minwidth = 7;
    my $buf = "\n performance stats ( all times are in ms)\n\n";
    $buf .= sprintf( "%*s  | ", $longsub, "sub" ). join( " | ", map { sprintf( "%*s", $minwidth, $_ ) } @titles[1..$#titles] ) ."\n";
    $buf .= '-' x $longsub . '--+-' . join( "-+-", map { '-' x $minwidth } @titles[1..$#titles] )."\n";
#    for my $subr (sort { $stats{$b}{total} <=> $stats{$a}{total} } keys %stats) {
    for my $subr (sort { $stats{$b}{$sort} <=> $stats{$a}{$sort} } keys %stats) {
        $buf .= join( " | ", sprintf( "%*s ", $longsub, $subr ),
                    map { sprintf( "%*d", $minwidth, $stats{$subr}{$_} ) }
                    qw( calls total mean avg max min ) )."\n";
    }
    if( 0 ) {
        $buf .= "Who Calls What\n";
        for my $subr (sort { $stats{$a}->{total} <=> $stats{$b}->{total} } keys %stats) {
            my $calls = [sort { $calls->{$subr}{$b} <=> $calls->{$subr}{$a} } keys %{$calls->{$subr}||{}}];
            my $called_by = [sort { $callers->{$subr}{$b} <=> $callers->{$subr}{$a} } keys %{$callers->{$subr}||{}}];
            $buf .= " $subr\n" .
                "   Called by :" . ( @$called_by ? "\n\t" . join( "\n\t", map { "$_ $callers->{$subr}{$_}" } @$called_by ) : '<not called>' ) . "\n" .
                "   Calls :" . ( @$calls ? "\n\t" . join( "\n\t", map { "$_ $calls->{$subr}{$_}" }  @$calls ) : '<does not make calls>' ) . "\n";
        }
        $buf .= "\n\n";
    }
    $buf;
} #_analyze 

=head2 start

 This is called to start or continue the data collection process. It takes
 an option regex parameter in case something different is desired than the
 one given at init. This must be called to continue the profiling in a 
 child thread if one is forked.

=cut
sub start {
    my $re = shift || $re;
    my $count = 0;
    around {
        my $subname = $_->{sub_name};
        my $start = [Time::HiRes::gettimeofday]; # returns [ seconds, microseconds ]

        push @stack, $subname;
        $_->proceed;

        pop @stack;

        map { $callers{$subname}{$_}++; $calls{$_}{$subname}++ } @stack;
        
        # tv_interval returns floating point seconds, convert to ms
        push @{$calltimes{$subname}}, 1_000 * Time::HiRes::tv_interval( $start );

        my $line = "$subname|" . (1_000 * Time::HiRes::tv_interval( $start ) ) . "|" . join(",", @stack );
        ++$count;
        open( OUT, ">>$tmpFile" );
        print OUT "$line\n";
        close OUT;

    } call $re;
} #start

1;

__END__

=head1 CAVEATS

 This does not work so well if the subs are dynamically attached methods.

=head1 AUTHOR

 Eric Wolf        coyocanid@gmail.com

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2015 Eric Wolf. All rights reserved.  This program 
 is free software; you can redistribute it and/or modify it under the
 same terms as Perl itself.

=head1 VERSION

 Version 1.00  (November 18, 2015))

=cut
