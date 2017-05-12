#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Language::Befunge::lib::HRTI;
# ABSTRACT: High-Resolution Timer extension
$Language::Befunge::lib::HRTI::VERSION = '5.000';
use Time::HiRes qw{ gettimeofday };

sub new { return bless {}, shift; }
my %mark;


# -- precision information

#
# $n = G()
#
# 'Granularity' pushes the smallest clock tick the underlying system can
# reliably handle, measured in microseconds.
#
sub G {
    my ($self, $lbi) = @_;
    # 1 microsecond precision - otherwise, Time::HiRes would have failed
    $lbi->get_curip->spush(1);
}


# -- time measurements

#
# M()
#
# 'Mark' designates the timer as having been read by the IP with this ID at
# this instance in time.
#
sub M {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $id = $ip->get_id;
    $mark{$id} = gettimeofday();
}
   

#
# $microseconds = T()
#
# 'Timer' pushes the number of microseconds elapsed since the last time an
# IP with this ID marked the timer. If there is no previous mark, acts like
# r.
#
sub T {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $id = $ip->get_id;
    if ( not exists $mark{$id} ) {
        $ip->dir_reverse;
        return;
    }
    my $secs = gettimeofday() - $mark{$id};
    $ip->spush( int($secs * 1000) );
}
    

#
# E()
#
# 'Erase mark' erases the last timer mark by this IP (such that 'T' above
# will act like r.
#
sub E {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $id = $ip->get_id;
    delete $mark{$id};
}


#
# $microseconds = S()
#
# 'Second' pushes the number of microseconds elapsed since the last whole
# second.
#
sub S {
    my ($self, $lbi) = @_;
    my (undef, $msecs) = gettimeofday();
    $lbi->get_curip->spush( $msecs );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::HRTI - High-Resolution Timer extension

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The HRTI fingerprint (0x48525449) allows a Funge program to measure elapsed
time much more finely than the clock values returned by C<y>. 

The timer and mark-list are considered global and static, shared amongst all
IP's, in order to retain tame behaviour. This timer is not affected by 'time
travel' contrivances. 

=head1 FUNCTIONS

=head2 new

Create a new HRTI instance.

=head2 Precision infos

=over 4

=item $n = G()

C<Granularity> pushes the smallest clock tick the underlying system can
reliably handle, measured in microseconds.

=back

=head2 Time measurements

=over 4

=item M()

C<Mark> designates the timer as having been read by the IP with this ID at
this instance in time.

=item $microseconds = T()

C<Timer> pushes the number of microseconds elapsed since the last time an
IP with this ID marked the timer. If there is no previous mark, acts like
C<r>.

=item E()

C<Erase mark> erases the last timer mark by this IP (such that C<T> above
will act like C<r>).

=item $microseconds = S()

C<Second> pushes the number of microseconds elapsed since the last whole
second.

=back

=head1 SEE ALSO

L<http://catseye.tc/projects/funge98/library/HRTI.html>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
