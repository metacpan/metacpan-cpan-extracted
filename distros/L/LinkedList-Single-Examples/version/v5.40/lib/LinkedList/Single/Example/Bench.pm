########################################################################
# housekeeping
########################################################################
package LinkedList::Single::Example::Bench v2.0.0;
use v5.40;

use B::Deparse;
use Devel::Size qw( size    );
use Time::HiRes qw( time    );

use Exporter 'import';

our @EXPORT_OK
= qw
(
    array_bytes
    best_of
    complexity
    list_bytes
    report
);

########################################################################
# time
########################################################################

# smallest elapsed time of $reps runs: the least disturbed by
# whatever else the system happens to be doing.

sub best_of( $reps, $code )
{
    my $best;

    for( 1 .. $reps )
    {
        my $start   = time;

        $code->();

        my $took    = time - $start;

        if( ! defined $best || $took < $best )
        {
            $best   = $took;
        }
    }

    $best
}

########################################################################
# code complexity
#
# a heuristic, not a metric to be proud of: deparse the sub so that
# formatting does not matter, then count what makes code harder to
# follow: statements, branches, and the position arithmetic that
# arrays require and linked lists replace with a cursor.
########################################################################

sub complexity( $code )
{
    my $text
    = B::Deparse->new->coderef2text( $code );

    my $statements
    = () = $text =~ m{ ; }gx;

    my $branches
    = () = $text =~ m{ \b (?: if | elsif | unless | while | until | for | foreach | and | or ) \b | \? }gx;

    # element access ($a[0], $$r[0], $r->[0]), $#array, and splice.

    my $index_ops
    = () = $text =~ m{ (?<= [\w\}\]] ) \[ | \$\# | \bsplice\b }gx;

    return
    {
        statements  => $statements
      , branches    => $branches
      , index_ops   => $index_ops
    };
}

########################################################################
# memory
#
# container overhead only: the bytes the structure holds in order to
# hold the payload, not the payload itself. a perl array keeps the
# capacity it grew to after shift/pop; a list holds only live nodes.
########################################################################

sub array_bytes( $aref )
{
    size $aref
}

# Devel::Size cannot see into the list object (it reports the
# few bytes of the handle), so walk the nodes and add them up.

sub list_bytes( $list )
{
    my $bytes   = 0;

    for
    (
        my $node    = $list->node
      ; $node->@*
      ; $node       = $node->[0]
    )
    {
        $bytes  += size $node;
    }

    $bytes
}

########################################################################
# report
########################################################################

sub report( $title, @row )
{
    say "\n$title";

    say sprintf '%-14s %9s %12s %6s %6s %6s'
    => qw( case seconds bytes stmts branch index );

    for my $row ( @row )
    {
        my $cx  = $row->{ cx };

        say sprintf '%-14s %9.4f %12s %6d %6d %6d'
        =>  $row->{ name }
          , $row->{ secs }
          , $row->{ bytes } // '-'
          , $cx->{ statements }
          , $cx->{ branches   }
          , $cx->{ index_ops  };
    }
}

1
__END__

=head1 NAME

LinkedList::Single::Example::Bench - shared timing, memory, and complexity helpers

=head1 SYNOPSIS

    use FindBin::libs;
    use LinkedList::Single::Example::Bench qw( best_of complexity report );

    my $secs    = best_of 3 => sub { ... };
    my $cx      = complexity \&Some::Package::method;

=head1 DESCRIPTION

Every example in L<LinkedList::Single::Examples> compares a LinkedList::Single
solution with the plain-array solution to the same problem. These
helpers keep the comparisons the same from one example to the next.

=over 4

=item best_of( $reps, $code )

Fastest of C<$reps> runs of C<$code>, in seconds.

=item complexity( $code )

Deparses C<$code> and returns a hashref counting C<statements>,
C<branches>, and C<index_ops> (element access, C<$#>, and C<splice>).
The last is the position arithmetic that a cursor makes unnecessary.

=item array_bytes( $aref ), list_bytes( $list )

Container overhead in bytes: the array's allocated capacity, which
stays at its high-water mark after C<shift>, versus the sum of the
live nodes of the list.

=item report( $title, @row )

Prints a table of rows with C<name>, C<secs>, optional C<bytes>,
and C<cx> (as returned by C<complexity>).

=back
