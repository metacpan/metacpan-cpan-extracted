package Devel::SmallProf; # To help the CPAN indexer to identify us

our $VERSION = '2.02';

package DB;

# do not profile subs
BEGIN { $^P=0x122 }

use strict;

sub Time::HiRes::time ();

our ($profile, $drop_zeros, $grep_format, %packages);

my ($cdone, $done, $cstart, $start, $prevf, $prevl, $nulltime,
    %listings, %profiles, %times, %ctimes);

sub sub; # even if it is not used it has to be declared!

sub DB {
  $profile || return;

  my($pkg,$filename,$line) = caller;
  %packages && !$packages{$pkg} && return;

  $done = Time::HiRes::time;
  my ($u,$s,$cu,$cs) = times;
  $cdone = $u+$s+$cu+$cs;

  # Now save the _< array for later reference.  If we don't do this here, 
  # evals which do not define subroutines will disappear.
  no strict 'refs';
  $listings{$filename} = \@{"main::_<$filename"}
    if defined(@{"main::_<$filename"});
  use strict 'refs';

  my($delta);
  $delta = $done - $start;
  $delta = ($delta > $nulltime) ? $delta - $nulltime : 0;
  $profiles{$filename}->[$line]++;
  $times{$prevf}->[$prevl] += $delta;
  $ctimes{$prevf}->[$prevl] += ($cdone - $cstart);
  ($prevf, $prevl) = ($filename, $line);

  ($u,$s,$cu,$cs) = times;
  $cstart = $u+$s+$cu+$cs;
  $start = Time::HiRes::time;
}


use Time::HiRes;

BEGIN {
  $drop_zeros = 0;
  $profile = 1;
  $grep_format = 0;
  if (-e '.smallprof') {
    do '.smallprof';
  }
  my $env=$ENV{SMALLPROF_CONFIG}||'';
  $drop_zeros = 1 if $env=~/z/;
  $profile = 1 if $env=~/p/;
  $grep_format = 1 if $env=~/g/;

  # print STDERR "drop_zeros=$DB::drop_zeros grep_format=$DB::grep_format\n";

  $prevf = '';
  $prevl = 0;
  my($diff,$cdiff);

  my($testDB) = sub {
    my($pkg,$filename,$line) = caller;
    $profile || return;
    %packages && !$packages{$pkg} && return;
  };

  # "Null time" compensation code
  $nulltime = 0;
  for (1..100) {
    my($u,$s,$cu,$cs) = times;
    $cstart = $u+$s+$cu+$cs;
    $start = Time::HiRes::time;
    &$testDB;
    ($u,$s,$cu,$cs) = times;
    $cdone = $u+$s+$cu+$cs;
    $done = Time::HiRes::time;
    $diff = $done - $start;
    $nulltime += $diff;
  }
  $nulltime /= 100;

  my($u,$s,$cu,$cs) = times;
  $cstart = $u+$s+$cu+$cs;
  $start = Time::HiRes::time;
}

END {
  # Get time on last line executed.
  my($u,$s,$cu,$cs) = times;
  $cdone = $u+$s+$cu+$cs;
  $done = Time::HiRes::time;
  my($delta);
  $delta = $done - $start;
  $delta = ($delta > $nulltime) ? $delta - $nulltime : 0;
  $times{$prevf}->[$prevl] += $delta;
  $ctimes{$prevf}->[$prevl] += ($cdone - $cstart);

  # Now write out the results.
  open(OUT,">smallprof.out");
  select OUT;

  if ($grep_format) {
    my @unsorted=();
    for my $file (keys %profiles) {
      my @line=@{$profiles{$file}};
      for my $i (0..@line) {
	my ($rfile, $ri, $eval)=
	  ($file=~/^\(eval\s*(\d+)\)\[(.*):(\d+)\]$/)
	    ? ($2, $3, "(eval $1:$i) ")
	      : ($file, $i, "");
	$drop_zeros and !$line[$i] and next;
	my $line=sprintf('%s:%s:%d:%d:%d: %s%s',
			 $rfile, $ri, $line[$i],
			 int($times{$file}[$i]*1000),
			 int($ctimes{$file}[$i]*1000),
			 $eval,
			 $listings{$file}[$i]||'?' );
	chomp $line;
	push @unsorted, [ $line, $times{$file}[$i]];
      }
    }
    my @sorted=sort { $b->[1] <=> $a->[1] } @unsorted;
    print "* file name : line number : line count : time (ms) : ctime (ms) : line source\n";
    for (@sorted) {
      print "$_->[0]\n";
    }
  }
  else {
    my($i,$stat,$time,$ctime,$line,$file,$page);
    $page = 1;

    format OUT_TOP=
@||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
'================ SmallProf version '.$Devel::SmallProf::VERSION.' ================'
         @|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| Page @<<
"Profile of $file",$page++
       =================================================================
    count wall tm  cpu time line 
.
    format OUT= 
@######## @##.##### @##.##### @####:^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$stat,$time,$ctime,$i,$line
.

    foreach $file (sort keys %profiles) {
      $- = 0;
      if (defined($listings{$file})) {
	$i = -1;
	foreach $line (@{$listings{$file}}) {
	  ++$i or next;
	  if (defined($line)) {
	    chomp($line);
	  } else {
	    $line = '';
	  }
	  $stat = $profiles{$file}->[$i] || 0 or !$drop_zeros or next;
	  $time = defined($times{$file}->[$i]) ?
	    $times{$file}->[$i] : 0;
	  $ctime = defined($ctimes{$file}->[$i]) ?
	    $ctimes{$file}->[$i] : 0;
	  write OUT;
	}
      } else {
	$line = "The code for $file is not in the symbol table.";
	for ($i=1; $i <= $#{$profiles{$file}}; $i++) {
	  next unless 
	    ($stat = $profiles{$file}->[$i] || 0 or !$drop_zeros);
	  $time = defined($times{$file}->[$i]) ?
	    $times{$file}->[$i] : 0;
	  $ctime = defined($ctimes{$file}->[$i]) ?
	    $ctimes{$file}->[$i] : 0;
	  write OUT;
	}
      }
    }
  }
  close OUT;
}

1;

__END__

=head1 NAME

Devel::SmallProf - per-line Perl profiler

=head1 SYNOPSIS

	perl5 -d:SmallProf test.pl

=head1 DESCRIPTION

The Devel::SmallProf profiler is focused on the time taken for a program run on
a line-by-line basis.  It is intended to be as "small" in terms of impact on
the speed and memory usage of the profiled program as possible and also in
terms of being simple to use.  Those statistics are placed in the file
F<smallprof.out> in the following format:

        <num> <time> <ctime> <line>:<text>

where <num> is the number of times that the line was executed, <time> is the
amount of "wall time" (time according the the clock on the wall vs. cpu time)
spent executing it, <ctime> is the amount of cpu time expended on it and <line>
and <text> are the line number and the actual text of the executed line (read
from the file).

The package uses the debugging hooks in Perl and thus needs the B<-d> switch,
so to profile F<test.pl>, use the command:

	perl5 -d:SmallProf test.pl

Once the script is done, the statistics in F<smallprof.out> can be sorted to 
show which lines took the most time.  The output can be sorted to find which
lines take the longest, either with the sort command:

	sort -k 2nr,2 smallprof.out | less

or a perl script:

	open(PROF,"smallprof.out");
	@sorted = sort {(split(/\s+/,$b))[2] <=> 
                        (split(/\s+/,$a))[2]} <PROF>;
        close PROF;
	print join('',@sorted);

=head1 NOTES

=over 4

=item * 

The "wall time" readings come from Time::HiRes and are reasonably useful, at
least on my system.  The cpu times come from the 'times' built-in and the
granularity is not necessarily as small as with the wall time.  On some systems
this column may be useful.  On others it may not.

=item *

SmallProf does attempt to make up for its shortcomings by subtracting a small
amount from each timing (null time compensation).  This should help somewhat
with the accuracy.

=item * 

SmallProf depends on the Time::HiRes package to do its timings.  It claims to
require version 1.20, but may work with earlier versions, depending on your
platform.

=back

=head1 OPTIONS

SmallProf has 4 variables which can be used during your script to affect what
gets profiled.

=over 4

=item C<$DB::drop_zeros> (z)

If you do not wish to see lines which were never called, set the variable
C<$DB::drop_zeros = 1>.  With C<drop_zeros> set, SmallProf can be used for 
basic coverage analysis.

=item C<$DB::profile> (p)

To turn off profiling for a time, insert a C<$DB::profile = 0> into your code
(profiling may be turned back on with C<$DB::profile = 1>).  All of the time
between profiling being turned off and back on again will be lumped together 
and reported on the C<$DB::profile = 0> line.  This can be used to summarize a
subroutine call or a chunk of code.

=item C<%DB::packages>

To only profile code in a certain package, set the C<%DB::packages> array.  For
example, to see only the code in packages C<main> and C<Test1>, do this:

	%DB::packages = ( 'main' => 1, 'Test1' => 1 );

=item C<$DB::grep_format> (g)

Generates output on a format similar to grep easily parseable from
tools like Emacs (see below).

grep format output appears as:

  file name : line num : count : time : ctime : source

or

  file name : line num : count : time : ctime : (eval n: line num) source

for code inside evals.

Times appear in miliseconds.

=back

These variables can be put in a file called F<.smallprof> in the current 
directory.  For example, a F<.smallprof> containing

	$DB::drop_zeros = 1;
	$DB::profile = 0;

will set SmallProf to not report lines which are never touched for any file
profiled in that directory and will set profiling off initially (presumably to
be turned on only for a small portion of code).

Environment variable C<SMALLPROF_CONFIG> can be also used to set those
flags, i.e:

   SMALLPROF_CONFIG=zg perl -d:SmallProf my_script.plx

activates C<drop_zeros> and C<grep_format> modes.


=head1 INSTALLATION

Just the usual

	perl Makefile.PL
	make
	make test
	make install

and should install fine via the CPAN module.

=head1 BUGS

Subroutine calls are currently not under the control of %DB::packages.  This
should not be a great inconvenience in general.  

The handling of evals is bad news.  This is due to Perl's handling of evals 
under the B<-d> flag.  For certain evals, caller() returns '(eval n)' for the 
filename and for others it doesn't.  For some of those which it does, the array
C<@{'_E<lt>filename'}> contains the code of the eval.  For others it doesn't.
Sometime, when I've an extra tuit or two, I'll figure out why and how I can 
compensate for this.  (Note: 5.6.0 made some debugging changes.  This may now
be fixed, I'm not sure).

SmallProf must be invoked from the command line.  If it is included on the
shebang line, the file in which it is included will not be visible in the
symbol table.  Profiling will continue as expected, but the contents of the
source lines will not be listed.  This is new as of 5.6.0.

Comments, advice and questions are welcome.  If you see
inefficent stuff in this module and have a better way, please let me know.

=head1 EMACS/XEMACS HACK

=over 4

=item 1

Use the C<DB::grep_format> flag to turn on grep like format, i.e.

  SMALLPROF_CONFIG=g perl -d:SmallProf myscript.pl

=item 2

Tell Emacs/XEmacs to read smallprof.out as grep output:

  M-x grep RET C-a C-k cat smallprof.out RET

=item 3

Point and click to go to the script hot spots!

=back

=head1 AUTHOR

Devel::SmallProf was developed by Ted Ashton
E<lt>ashted@cpan.orgE<gt>. It is currently being maintained by
Salvador Fandiño E<lt>sfandino@yahoo.comE<gt>.

SmallProf was developed from code originally posted to usenet by Philippe
Verdret E<lt>philippe.verdret@sonovision-itep.frE<gt>.  Special thanks to
Geoffrey Broadwell E<lt>habusan2@sprynet.comE<gt> for his assistance on the
Win32 platform and to Philippe for his patient assistance in testing and
debugging.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 1997-2000 Ted Ashton

Copyright (c) 2003-2007 Salvador FandiE<ntilde>o

This module is free software and can be redistributed and/or modified under the
same terms as Perl itself.

=head1 SEE ALSO

L<Devel::FastProf> is a simplified and much faster version of this module.

L<Devel::DProf>, L<Time::HiRes>.

=cut

