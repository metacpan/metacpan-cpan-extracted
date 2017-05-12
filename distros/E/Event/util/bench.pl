#!./perl -w

use strict;
use Config;
use Event qw(time loop unloop);
use vars qw($VERSION $TestTime);
$VERSION = '0.08';
$TestTime = 11;

#eval q[ use NetServer::ProcessTop; warn '[Top @ '.(7000+$$%1000)."]\n"; ];
#warn if $@;

# $Event::DebugLevel = 2;

Event->timer(cb => \&unloop,
	     after => $TestTime,
	     nice => -1, desc => "End of benchmark");

#------------------------------ Timer
use vars qw($TimerCount $TimerExpect);
$TimerCount = 0;
$TimerExpect = 0;
for (1..20) {
    my $interval = .2 + .1 * int rand 3;
    Event->timer(cb => sub { ++$TimerCount },
		 interval => $interval);
    $TimerExpect += $TestTime/$interval;
}

#------------------------------ Signals
use vars qw($SignalCount);
$SignalCount = 0;
Event->signal(signal => 'USR1',
	      cb => sub { ++$SignalCount; });
Event->timer(cb => sub { kill 'USR1', $$; },
	     interval => .5);

#------------------------------ IO
use vars qw($IOCount @W);
$IOCount = 0;

use Symbol;
for (1..15) {
    my ($r,$w) = (gensym,gensym);
    pipe($r,$w);
    select $w;
    $|=1; 
    Event->io(fd => $r,
	      cb => sub {
		  my $buf;
		  ++$IOCount;
		  sysread $r, $buf, 1;
	      },
	      poll => 'r', desc => "fd ".fileno($r));
    push @W, $w;
}
select STDOUT;

#------------------------------ Idle
use vars qw($IdleCount);
$IdleCount = 0;

my $idle;
$idle = Event->idle(min => undef, cb => sub {
    ++$IdleCount;
    for (0..@W) {
	my $w = $W[int rand @W];
	syswrite $w, '.', 1;
    }
    $idle->again;
}, desc => "idle");

#------------------------------ Loop

sub run {
    my $start = time;
    loop();
    time - $start;
}
warn "Running benchmark...\n";
my $elapse = &run;

sub pct { 
    my ($got, $expect) = @_;
    sprintf "%.2f%%", 100*$got/$expect;
}

warn "Timing a null loop...\n";
my $null = Event::null_loops_per_second(7);

my $e_per_sec = ($IdleCount+$TimerCount+$IOCount+$SignalCount)/$elapse;

chomp(my $uname = `uname -a`);
print "
 benchmark: $VERSION
 Event: $Event::VERSION

 perl $]
 uname=$uname
 cc='$Config{cc}', optimize='$Config{optimize}'
 ccflags='$Config{ccflags}'

Elapse Time:     ".pct($elapse,$TestTime)." of $TestTime seconds
Timer/sec:       ".pct($TimerCount,$TimerExpect)." ($TimerCount total)
Io/sec:          ".sprintf("%.3f", $IOCount/$elapse)." ($IOCount total)
Signals/sec      ".sprintf("%.2f", $SignalCount/$elapse)."
Events/sec       ".sprintf("%.3f", $e_per_sec)."
Null/sec         $null
Event/Null       ".sprintf("%.2f", 100* $e_per_sec / $null)."\%

";

__END__

-------------------------------------

 benchmark: 0.08
 Event: 0.40
 
 perl 5.00556
 uname=SunOS eq1070.wks.na.deuba.com 5.5.1 Generic_103640-24 sun4u sparc SUNW,Ultra-1
 cc='cc', optimize='-xO3 -g'
 ccflags='-DDEBUGGING'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     99.37% of 11 seconds
Timer/sec:       98.18% (801 total)
Io/sec:          4550.053 (49735 total)
Signals/sec      1.92
Events/sec       4909.684
Null/sec         93511
Event/Null       5.25%

-------------------------------------

 benchmark: 0.08
 Event: 0.26
 
 perl 5.00554
 uname=SunOS eq1062.wks.na.deuba.com 5.5.1 Generic_103640-19 sun4u sparc SUNW,Ultra-1
 cc='cc', optimize='-xO3 -g'
 ccflags='-DDEBUGGING'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     99.14% of 11 seconds
Timer/sec:       98.18% (810 total)
Io/sec:          4957.076 (54057 total)
Signals/sec      1.93
Events/sec       5343.137
Null/sec         111410
Event/Null       4.80%

-------------------------------------

 benchmark: 0.07
 Event: 0.24
 
 perl 5.00553
 uname=SunOS eq1062.wks.na.deuba.com 5.5.1 Generic_103640-19 sun4u sparc SUNW,Ultra-1
 cc='cc', optimize='-xO3 -g'
 ccflags='-DDEBUGGING -I/usr/local/include'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     99.14% of 11 seconds
Timer/sec:       98.18% (783 total)
Io/sec:          4911.331 (53562 total)
Signals/sec      1.93
Events/sec       5292.045
Null/sec         114013
Event/Null       4.64%

-------------------------------------

 benchmark: 0.06
 Event: 0.20
 
 perl 5.00552
 uname=Linux furu.g.aas.no 2.0.31 #1 Mon Oct 13 12:20:11 MET DST 1997 i586
 cc='cc', optimize='-g'
 ccflags='-Dbool=char -DHAS_BOOL -DDEBUGGING -I/usr/local/include'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     97.61% of 11 seconds
Timer/sec:       96.80% (772 total)
Io/sec:          1518.486 (16304 total)
Signals/sec      1.96
Events/sec       1687.248
Null/sec         50928

-------------------------------------

 benchmark: 0.06
 Event: 0.18
 
 perl 5.00551
 uname=IRIX64 clobber 6.2 03131016 IP25 mips
 cc='cc -n32', optimize='-O3'
 ccflags='-D_BSD_TYPES -D_BSD_TIME -woff 1009,1110,1184 -OPT:Olimit=0
-I/usr/local/
include -DLANGUAGE_C'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     99.63% of 11 seconds
Timer/sec:       98.18% (720 total)
Io/sec:          6541.408 (71690 total)
Signals/sec      1.92
Events/sec       7017.893
Null/sec         74469

-------------------------------------

 benchmark: 0.05
 Event: 0.13
 
 perl 5.00502
 uname=SunOS eq1062.wks.na.deuba.com 5.5.1 Generic_103640-19 sun4u sparc SUNW,Ultra-1
 cc='cc', optimize='-xO3 -g'
 ccflags='-DDEBUGGING -I/usr/local/include'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     99.48% of 11 seconds
Timer/sec:       98.18% (765 total)
Io/sec:          3742.786 (40955 total)
Signals/sec      1.92
Events/sec       4048.570
Null/sec         176565

-------------------------------------

 benchmark: 0.04
 Time::HiRes: 01.18, Event: 0.10
 
 perl 5.005
 uname=IRIX Pandora 6.3 12161207 IP32
 cc='cc -n32', optimize='-O3'
 ccflags='-D_BSD_TYPES -D_BSD_TIME -woff 1009,1110,1184 -OPT:Olimit=0
-I/usr/local/include -DLANGUAGE_C'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     99.42% of 11 seconds
Timer/sec:       98.18% (846 total)
Io/sec:          4729.905 (51725 total)
Signals/sec      1.92
Events/sec       5104.823
Null/sec         92255

-------------------------------------


 benchmark: 0.04
 Time::HiRes: 01.18, Event: 0.10

 perl 5.00501
 uname=SunOS pluto 5.5.1 Generic_103640-08 sun4m sparc SUNW,SPARCstation-10
 cc='gcc', optimize='-O2 -g'
 ccflags='-DDEBUGGING -I/usr/local/include'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     98.83% of 11 seconds
Timer/sec:       98.18% (765 total)
Io/sec:          2629.475 (28586 total)
Signals/sec      1.93
Events/sec       2866.151
Null/sec         150603

-------------------------------------

 benchmark: 0.03
 IO: 1.20, Time::HiRes: 01.18, Event: 0.07

 perl 5.00404
 uname=IRIX64 clobber 6.2 03131016 IP25
 cc='cc -n32 -mips4 -r10000', optimize='-O3 -TARG:platform=ip25 -OPT:Olimit=0:roundoff=3:div_split=ON:alias=typed'
 ccflags ='-D_BSD_TYPES -D_BSD_TIME -woff 1009,1110,1184 -OPT:Olimit=0 -I/usr/local/include -I/usr/people7/walker/pub/include -DLANGUAGE_C -DPACK_MALLOC -DTWO_POT_OPTIMIZE -DEMERGENCY_SBRK'

 Please mail benchmark results to perl-loop@perl.org.  Thanks!

Elapse Time:     99.66% of 11 seconds
Timer/sec:       98.18% (819 total)
Io/sec:          817.160 (8958 total)
Signals/sec      1.92
Events/sec       944.869

-------------------------------------


 benchmark: 0.03
 IO: 1.20, Time::HiRes: 01.18, Event: 0.07
 
 perl 5.005
 uname=SunOS punch 5.5.1 Generic_103640-08 sun4u sparc SUNW,Ultra-2
 cc='gcc', optimize='-O2 -g'
 ccflags ='-DDEBUGGING -I/usr/local/include'
 
 Please mail benchmark results to perl-loop@perl.org.  Thanks!
 
Elapse Time:     99.76% of 11 seconds
Timer/sec:       98.18% (711 total)
Io/sec:          1020.097 (11194 total)
Signals/sec      1.91
Events/sec       1150.593
