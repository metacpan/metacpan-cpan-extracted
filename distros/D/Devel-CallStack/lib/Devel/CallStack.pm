package Devel::CallStack;

require 5.006001;

use strict;

use vars qw($VERSION
	    $Depth $Full $Reverse $Stdout $Stderr $Out $In $Append
	    $Import
	    %Cumul);

$VERSION = '0.19';
$Depth = 1e9; # If someone has a callstack this deep, we are in trouble.
$Import = 0;

sub import {
    my $class = shift;
    for my $i (@_) {
	if ($i =~ /^(?:depth=)?(\d+)$/) {
	    $Depth = $1;
	} elsif ($i eq 'full') {
	    $Full = 1;
	} elsif ($i eq 'reverse') {
	    $Reverse = 1;
	} elsif ($i eq 'stdout') {
	    $Stdout = 1;
	} elsif ($i eq 'stderr') {
	    $Stderr = 1;
	} elsif ($i =~ /^out=(.+)/) {
	    $Out = $1;
	} elsif ($i =~ /^in(?:=(.+))?/) {
	    $In = $1 ne "" ? $1 : "callstack.out";
	} elsif ($i eq 'append') {
	    $Append = 1;
	} else {
	    die "Devel::CallStack::import: '$i' unknown\n";
	}
    }
    &set(); # Otherwise we get the import() call stack captured, too.
    &read($In) if defined $In;
    $Out = "callstack.out" unless defined $Out || $Stdout;
    $Import++; # Import was a success.
}

sub set {
    %Cumul = @_;
}

sub get {
    %Cumul;
}

sub write {
    if ($Import) {
	my $ofh;
	if ($Stdout) {
	    $ofh = select STDOUT;
	} elsif ($Stderr) {
	    $ofh = select STDERR;
	} elsif (defined $Out) {
	    my $mode = $Append ? ">>" : ">";
	    unless (open(OUT, "$mode$Out")) {
		die qq[Devel::CallStack::END: failed to open "$Out" for writing: $!\n];
	    }
	    $ofh = select OUT;
	}
	for my $s (sort keys %Cumul) {
	    next if $s =~ /Devel::CallStack/o; # We do not exist.
	    my $d = ($s =~ tr/,/,/) + 1;
	    print "$s $d $Cumul{$s}\n";
	}
	select $ofh;
    }
}

sub read {
    my $fn = shift;
    unless (open(IN, $fn)) {
	die qq[Devel::CallStack::read: failed to open "$fn" for reading: $!\n];
    }
    while (<IN>) {
	my ($s, $d, $n) = split;
	$s = join(",", reverse split(/,/, $s)) if $Reverse;
	$Cumul{$s} += $n;
    }
    close(IN);
}

sub END {
    &write();
}

package DB;

use strict;

sub DB { }

use vars qw($Full $Depth $Reverse %Cumul);

*Depth   = \$Devel::CallStack::Depth;
*Full    = \$Devel::CallStack::Full;
*Reverse = \$Devel::CallStack::Reverse;
*Cumul   = \%Devel::CallStack::Cumul;

sub sub {
    if (my ($p, $s) = ($DB::sub =~ /^(.+)::(.+)/)) {
	my @s;
	if ($Full) {
	    if (my ($f, $l) = ($DB::sub{$DB::sub} =~ /^(.+):(\d+)/)) {
		@s = ( "$f:$l:${p}::$s" );
		for (my $i = 0; @s < $Depth; $i++) {
		    my @c = caller($i);
		    last unless @c;
		    push @s, "$c[1]:$c[2]:$c[3]";
		}
	    }
	} else {
	    @s = ( $DB::sub );
	    for (my $i = 0; @s < $Depth; $i++) {
		my @c = caller($i);
		last unless @c;
		push @s, $c[3];
	    }
	}
	$Cumul{
	       join ",", $Reverse ? @s : reverse @s # Ironic, no?
	      }++;
    }
    no strict 'refs';
    &{$DB::sub}(@_);
}

1;
__END__
=pod

=head1 NAME

Devel::CallStack - record the calling stacks

=head1 SYNOPSIS

    perl -d:CallStack ...

=head1 DESCRIPTION

The Devel::CallStack is meant for code developers wondering why their
code is running so slow.  One possible reason is simply too many
subroutine or method calls since they are not cheap in Perl.

The Devel::CallStack records the calling stacks, how many times each
calling stack is being called.  By default the results are written to
a file called F<callstack.out>.

B<NOTE:> recording the callstacks is a very heavy operation which
slows down the execution of your code easily ten-fold or more: do
not attempt any other code timing or profiling at the same time.
The gathered information is useful in conjunction with other profiling
tools such as C<Devel::DProf>.

=head1 MOTIVATION

I got frustrated by C<Devel::DProf> results that looked not unlike this:

  Total Elapsed Time = 1.892063 Seconds
    User+System Time = 1.742063 Seconds
  Exclusive Times
  %Time ExclSec CumulS #Calls sec/call Csec/c  Name
   13.8   0.241  0.426   2170   0.0001 0.0002  Foo::_id
   10.3   0.181  0.181   1747   0.0001 0.0001  Foo::Map::has
   9.18   0.160  0.434      3   0.0532 0.1448  main::BEGIN
   8.21   0.143  0.143   5205   0.0000 0.0000  Foo::Map::_has
   7.46   0.130  0.611      1   0.1299 0.6112  Foo::Map::new
   ...

I obviously needed to try cutting down the number of C<Foo::_id> calls
(not to mention the number of C<Foo::Map::_has> and C<Foo::Map::_has>
calls), but the problem was that C<Foo::_id> was being called from
multiple places, there were more than one possible "hot path" that
I needed to locate and "cool down".

=head1 EXAMPLE

For this file, F<code.pl>:

    sub foo { bar(@_) }
    sub bar { zog(@_) if $_[0] % 7 }
    sub zog { }
    for (my $i = 0; $i < 1e3; $i++) {
	$i % 5 ? foo($i) : bar($i);
    }

running C<perl -d:CallStack code.pl> will result in:

    main::bar 1 200
    main::bar,main::zog 2 171
    main::foo 1 800
    main::foo,main::bar 2 800
    main::foo,main::bar,main::zog 3 686

Meaning that the callstack C<main::bar> was called 200 times, which
makes sense since every fifth call out of 1000 should have been made
to bar().  On the other hand, the callstack C<main::bar,main::zog> was
reached 171 times, which is the number of integers between 0 and 999
(inclusive) that are evenly divisible both by five and seven.
The numbers in the second column are the callstack depths
(the number of commas plus one).

=head1 PARAMETERS

Parameters are given in the command line after the C<-d:Callstack>
and a C<=>:

    perl -d:CallStack=...

The available parameters are as follows:

=head2 Out

The results are written by default to a file called F<callstack.out>.
This can be changed either with

    perl -d:CallStack=out=filename

or

    perl -d:CallStack=out=stdout
    perl -d:CallStack=out=stderr

which will output to a file called F<filename> or the standard output
or the standard error, respectively.

=head2 Depth

By default the calling stacks are walked all the way back to the
beginning.  This may be very expensive if the calling stacks are deep.
To limit the number of frames walked back, supply the C<depth> parameter:

   perl -d:CallStack=depth=N

or just

   perl -d:CallStack=N

Using callstack depth two for for our example:

    main::bar 1 200
    main::bar,main::zog 2 857
    main::foo 1 800
    main::foo,main::bar 2 800

Using the depth of one (or zero) gives the number of times each
subroutine was called:

    main::bar 1 1000
    main::foo 1 800
    main::zog 1 857

=head2 Reverse

By default the callstacks go from left to right, that is, the callers
are on the left and the callees are on the right, the time flows from
left to right.  With the C<reverse> parameter you can flip the order,
which may fit your brain better.  For our example:

    main::bar 1 200
    main::bar,main::foo 2 800
    main::foo 1 800
    main::zog,main::bar 2 171
    main::zog,main::bar,main::foo 3 686

=head2 Full

By default only the names of the called subroutines (methods) are
recorded.  To record also the filename and (calling) linenumber in the
file, use the C<full> parameter:

   perl -d:CallStack=full

The filename and the linenumber are prepended to the subname,
all concatenated with single colons, for our example:

    code.pl:1:main::foo 1 800
    code.pl:2:main::bar 1 200
    code.pl:5:main::bar,code.pl:3:main::zog 2 171
    code.pl:5:main::foo,code.pl:1:main::bar,code.pl:3:main::zog 3 686
    code.pl:5:main::foo,code.pl:2:main::bar 2 800

=head2 Append

Normally the output file is overwritten.  To append instead:

   perl -d:CallStack=append

=head2 In

Normally the statistics are started from scratch for each run.
To read in initial statistics from a file:

   perl -d:CallStack=in=filename

The C<=filename> part is optional, the default filename is
F<callstack.out>.  The input data needs to be in the same format
(C<depth>, C<full>, F<reverse>) as the current settings.

=head2 Combining parameters

To use several parameters at the same time, combine the parameters by
using a comma:

   perl -d:CallStack=3,out=my.out,full

If you combine the C<append> and C<in> parameters, you get cumulative
statistics.

=head1 UTILITY FUNCTIONS

To get a copy of the statistics accumulated so far, call

	my %C = Devel::CallStack::get();

The keys of the hash are the callstacks as comma-concatenated strings,
and the values are the number of calls.

To set the statistics, call

	Devel::CallStack::set(%C).

To clear the statistics, simply call Devel::CallStack::set() with no
argument.

To write out the statistics accumulated so far, call

	Devel::CallStack::write()

This overwrites the existing output file (either F<callstack.out> or
whatever you used for the C<out> parameter or the standard output or
error streams) unless the C<append> parameter is used.  You need to do
any needed file renaming yourself.  write() is used by
Devel::CallStack itself to output the statistics at the end of a run,
by calling it from its END block.

To read in the statistics accumulated from a file, call

	Devel::CallStack::read("filename")

This merges in the data instead of replacing.  If you want to replace
the data, call set() yourself.  read() is used by the C<in> parameter.
The input data needs to be in the same format (C<depth>, C<full>,
F<reverse>) as the current settings.

=head1 POSSIBILITIES

Now you've run your code with Devel::CallStack.  Now what?

If you see that a method or a subroutine is called several thousand times
while the upper layers are called only a few times:

=over 4

=item *

First of all try your code with different input and with different
amount of input: how does the number of calls vary?  Linear,
logarithmic, squared, cubed, random?  Have you picked the right
algorithm?  You are not reimplementing something from the Perl core
that might have either a better algorithm or simply a faster
implementation?  (For example sort().)

=item *

You may manually inline the method or subroutine code to its callers.
The downsides include harder maintenance (remember to document/comment
the inlining both to the callers and to the original code), the upsides
include faster execution.  Maybe you can somehow automate the inlining,
for example via Perl source filters?

=item *

You may manually or (preferably) automatically cache the computation,
whenever reasonable and possible.  Use for example the L<Memoize>
module.  The downsides include more memory usage, upsides include
faster execution.

=back

If you see some deep code paths having only a few callers (or maybe
even just a single one):

=over 4

=item *

Maybe you have several layers of subroutines calling each other always
along the same paths - you could possibly collapse/inline several
levels of these subroutines into fewer ones, or even just a single one.
If you still need to have some of the intermediate functions
separately, you may consider maintaining separate functions for those,
but remember to document/comment the fact profusely.

=back

=head1 KNOWN PROBLEMS

Devel::CallStack unfortunately works only in 5.6.1 or later Perls,
there is something different with the C<-d:Xyz> option of older Perls
that breaks Devel::CallStack, one would get something like this:

   syntax error at code.pl line 0, near "use Devel::CallStack="

=head1 ACKNOWLEDGEMENTS

SE<eacute>bastien Aperghis-Tramoni for bravely testing the code in Jaguar.

=head1 SEE ALSO

L<perlfunc/caller>; L<Devel::CallerItem>, L<Devel::DumpStack>,
L<Devel::StackTrace>, for alternative views of the call stack;
L<Devel::DProf> and L<Devel::SmallProf> for time-based profiling;
L<Devel::Cover> for coverage.

=head1 AUTHOR AND COPYRIGHT

Jarkko Hietaniemi <jhi@iki.fi> 2004-2005

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
