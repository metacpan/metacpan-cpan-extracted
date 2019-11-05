use strict;
package Devel::Timer;
$Devel::Timer::VERSION = '0.13';
use warnings;
use 5.006;

use Time::HiRes();

## no critic (ProhibitAccessOfPrivateData )

##
## instantiate (and initialize) timer object
##

sub new {
    my ($class) = @_;
    my $self = {
                times => [],
                count => 0,
                label => {},        ## index:label
                };

    bless $self, $class;

    $self->initialize();

    $self->mark('INIT');

    return $self;
}

##
## mark time (w/ optional label)
##

sub mark {
    my($self, $label) = @_;

    $label = '' if (!defined($label));

    my $t = [ Time::HiRes::gettimeofday() ];

    my $last_time;
    if ($self->{count} == 0) {       ## first time has no last time
        $last_time = $t;
    }
    else {
        $last_time = $self->{times}->[($self->{count}-1)];
    }

    ## save time for final report

    push(@{$self->{times}}, $t);

    ## save time interval

    my $interval = {
                    value => Time::HiRes::tv_interval($last_time, $t),
                    index => $self->{count},
                   };
    push(@{$self->{intervals}}, $interval);

    ## save label in separate hash for fast lookup

    $self->{label}->{$self->{count}} = $label;

    $self->{count}++;
}


##
## output report to error log
##

sub report {
    my ($self, %args) = @_;

    ## calculate total time (start time vs last time)

    my $total_time = Time::HiRes::tv_interval($self->{times}->[0], $self->{times}->[$self->{count}-1]);

    $self->print("\n");
    $self->print(ref($self) . ' Report -- Total time: ' . sprintf('%.4f', $total_time) . ' secs');
    if ($args{collapse}) {
       $self->_calculate_collapsed;

       $self->print('Count     Time    Percent');
       $self->print('----------------------------------------------');

       my $c = $self->{collapsed};
       my $sort_by = $args{sort_by} || 'time';
       my @labels = sort { $c->{$b}->{$sort_by} <=> $c->{$a}->{$sort_by} } keys %$c;
       foreach my $label (@labels) {
           my $count = $c->{$label}->{count};
           my $time = $c->{$label}->{time};
           my $msg = sprintf('%8s  %.4f  %5.2f%%  %s',
               ($count, $time, (($time/$total_time)*100), $label));
           $self->print($msg);
       }
       return 1;
    }


    $self->print('Interval  Time    Percent');
    $self->print('----------------------------------------------');

    ## sort interval structure based on value

    @{$self->{intervals}} = sort { $b->{value} <=> $a->{value} } @{$self->{intervals}};

    ##
    ## report of each time space between marks
    ##

    for my $i (@{$self->{intervals}})
    {
        ## skip first time (to make an interval,
        ## compare the current time with the previous one)

        next if ($i->{index} == 0);

        my $msg = sprintf('%02d -> %02d  %.4f  %5.2f%%  %s -> %s',
            ($i->{index}-1), $i->{index}, $i->{value}, (($i->{value}/$total_time)*100),
            $self->{label}->{($i->{index}-1)}, $self->{label}->{$i->{index}});

        $self->print($msg);
    }
}

sub _calculate_collapsed {
    my ($self) = @_;

    my %collapsed;
    foreach my $i (0 .. $self->{count} - 2) {
        my $label = $self->{label}->{$i} . ' -> ' . $self->{label}->{$i + 1};
        my $time = Time::HiRes::tv_interval($self->{times}->[$i], $self->{times}->[$i + 1]);
        $collapsed{$label}{time} += $time;
        $collapsed{$label}{count}++;
    }
    $self->{collapsed} = \%collapsed;
}

sub get_stats {
    my ($self, $a, $b) = @_;
    $self->_calculate_collapsed;
    my $collapsed = $self->{collapsed};
    my $total_time = Time::HiRes::tv_interval($self->{times}->[0], $self->{times}->[$self->{count}-1]);
    my $label = "$a -> $b";
    my $time =  $collapsed->{$label}->{time};
    my $count = $collapsed->{$label}->{count};
    return ($time, $time / $total_time * 100, $count);
}



## output methods
## note: if you want to send output to somewhere other than stderr,
##       you can override the print() method below.  The initialize()
##       and shutdown() methods are provided in case you need to open a file
##       or connect to a database before printing the report.
##       See pod for an example.

sub initialize {
}

sub print {
    my($self, $msg) = @_;
    print STDERR $msg . "\n";
}

sub shutdown {
}

sub DESTROY {
    my $self = shift;
    $self->shutdown();
}

1;

__END__

=head1 NAME

Devel::Timer - Track and report execution time for parts of code

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  use Devel::Timer;

  my $t = Devel::Timer->new();

  $t->mark('first db query');

  ## do some work

  $t->mark('second db query');

  ## do some more work

  $t->mark('end of second db query');

  $t->report();

=head1 DESCRIPTION

Devel::Timer allows developers to accurately time how long a specific
piece of code takes to execute.  This can be helpful in locating the
slowest parts of an existing application.

First, the Devel::Timer module is used and instantiated.

  use Devel::Timer;

  my $t = Devel::Timer->new();

Second, markers are placed before and after pieces of code that need to be
timed.  For this example, we are profiling the methods get_user_score() and
get_average_user_score().

  $t->mark('first db query');
  &get_user_score($user);

  $t->mark('second db query');
  &get_average_user_score();

Finally, at the end of the code that you want to profile, and end marker
is place, and a report is generated on stderr.

  $t->mark('END');
  $t->report();

Sample report:

  Devel::Timer Report -- Total time: 0.3464 secs
  Interval  Time    Percent
  ----------------------------------------------
  02 -> 03  0.3001  86.63%  second db query -> END
  01 -> 02  0.0461  13.30%  first db query -> second db query
  00 -> 01  0.0002   0.07%  INIT -> first db query

The report is output using the method Devel::Timer::print() which currently
just prints to stderr.  If you want to send the output to a custom location
you can override the print() method.  The initialize() and shutdown() methods
can also overridden if you want to open and close log files or database
connections.

=head1 METHODS

=head2 new()

Create a new instance. No parameters are processed.

=head2 initialize()

Empty method. Can be implemented in the subclass.

=head2 mark($name)

Set a timestamp with a C<$name>.

=head2 print()

Prints to STDERR. Can be overridden in the subclass.

=head2 report(%args)

Prints the report to STDOUT. The %args can have the following keys:

    +----------+--------------------------+
    | Keys     | Description              |
    +----------+--------------------------+
    | collapse | can be 0 or 1            |
    |          |                          |
    | sort_by  | can be 'time' or 'count' |
    +----------+--------------------------+

By default report() looks like this:

  $t->report;

  Devel::Timer Report -- Total time: 7.0028 secs
  Interval  Time    Percent
  ----------------------------------------------
  05 -> 06  3.0006  42.85%  something begin -> something end
  03 -> 04  2.0007  28.57%  something begin -> something end
  06 -> 07  1.0009  14.29%  something end -> END
  01 -> 02  1.0004  14.29%  something begin -> something end
  00 -> 01  0.0000   0.00%  INIT -> something begin
  04 -> 05  0.0000   0.00%  something end -> something begin
  02 -> 03  0.0000   0.00%  something end -> something begin

Which is great for small or non-iterative programs, but if there's
hundreds of loops of 'something begin -> something end' the report gets
very painful very quickly. :)

In that scenario you might find B<collapse> useful:

  $t->report(collapse => 1);

  Devel::Timer Report -- Total time: 7.0028 secs
  Count     Time    Percent
  ----------------------------------------------
         3  6.0018  85.71%  something begin -> something end
         1  1.0009  14.29%  something end -> END
         2  0.0001   0.00%  something end -> something begin
         1  0.0000   0.00%  INIT -> something begin

The stats for all combinations of labels are added together.

We also accept a B<sort_by> parameter. By default the report is sorted by total
time spent descending (like the default report()), but you can sort by count
descending instead if you want:

  $t->report(collapse => 1, sort_by => 'count');

  Devel::Timer Report -- Total time: 7.0028 secs
  Count     Time    Percent
  ----------------------------------------------
         3  6.0018  85.71%  something begin -> something end
         2  0.0001   0.00%  something end -> something begin
         1  0.0000   0.00%  INIT -> something begin
         1  1.0009  14.29%  something end -> END

=head2 get_stats($start, $end)

Returns the accumulated statistics for a specific a combination of mark()'s that
have occurred while your program ran.
These values are the exact same statistics that report() prints. get_stats()
simply returns them to you so you can do something creative with them.

For example, to get the cumulative stats for every time your program has
specifically moved from mark('X') to mark('Y'), you can run this:

  my ($time, $percent, $count) = $t->get_stats('X', 'Y');

$time is the total number of seconds elapsed between 'X' and 'Y'.

$percent is the percentage of total program run time that you have spent between
'X' and 'Y'.

$count is the number of times your program has moved from 'X' to 'Y'.

=head2 shutdown

Empty method. Can be implemented in subclass.

=head1 SUBCLASSING

    package MyTimer;

    use strict;
    use Devel::Timer;
    use vars qw(@ISA);

    @ISA = ('Devel::Timer');

    sub initialize
    {
        my $log = '/tmp/timer.log';
        open(my $LOG, '>>', $log) or die("Unable to open [$log] for writing.");
    }

    sub print
    {
        my($self, $msg) = @_;
        print $LOG $msg . "\n";
    }

    sub shutdown
    {
        close $LOG;
    }

You would then use the new module MyTimer exactly as you would use C<Devel::Timer>.

  use MyTimer;
  my $t = MyTimer->new();
  $t->mark('about to do x');
  $t->mark('about to do y');
  $t->mark('done y');
  $t->report();

=head1 TO DO

C<Devel::Timer> does not currently do any reporting or statistics of any kind
based on nested trees of mark() calls. So if your program runs these mark() calls:

  A
    B, C
    B, C
  D
  E

C<Devel::Timer> never tells you anything about how much time you spent moving from
A to D. Depth aware reporting might be an interesting project to tackle.

=head1 SEE ALSO

L<Time::HiRes>

=head1 REPOSITORY

L<https://github.com/manwar/Devel-Timer>

=head1 LICENSE AND COPYRIGHT

Jason Moore

This is free software.
It is licensed under the same terms as Perl itself.

=head1 AUTHOR

  Author:      Jason Moore - jmoore@sober.com (no longer valid)
  Maintainer:  Gabor Szabo - gabor@pti.co.il
  Contributor: Jay Hannah  - jay@jays.net

  Currently maintained by Mohammad S Anwar (MANWAR) - mohammad.anwar@yahoo.com

=cut
