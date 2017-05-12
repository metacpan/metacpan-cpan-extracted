package Fennec::Collector;
use strict;
use warnings;

use Carp qw/confess/;
use Fennec::Util qw/accessors require_module/;
use File::Temp qw/tempfile/;

accessors qw/test_count test_failed debug_data/;

sub ok      { confess "Must override ok" }
sub diag    { confess "Must override diag" }
sub end_pid { confess "Must override end_pid" }
sub collect { confess "Must override collect" }

sub init   { }

sub new {
    my $class  = shift;
    my %params = @_;
    my $self   = bless \%params, $class;

    $self->debug_data([]);
    $self->init;

    return $self;
}

sub inc_test_count {
    my $self = shift;
    my $count = $self->test_count || 0;
    $self->test_count( $count + 1 );
}

sub inc_test_failed {
    my $self = shift;
    my $count = $self->test_failed || 0;
    $self->test_failed( $count + 1 );
}

sub debug {
    my $self = shift;
    my ($msg) = @_;
    my ($action, $data) = $msg =~ m/^ ?# ?FENNEC_DEBUG_(MOCK|BLOCK|CUSTOM):(.*)$/;

    my $set = { ACTION => $action };

    for my $field (split "\0", $data) {
        my ($key, $val) = $field =~ m/([^:]+):(.*)/;
        $set->{lc($key)} = $val;
    }

    push @{$self->debug_data} => $set;
}

sub finish {
    my $self = shift;
    return unless @{$self->debug_data};
    my @data = sort { return $a->{sec} <=> $b->{sec} || $a->{msec} <=> $b->{msec} }
        @{ $self->debug_data };

    my $index = 0;
    my $map = { $$ => $index++ };

    my @out;

    for my $item (@data) {
        $map->{$item->{pid}} = $index++ unless defined $map->{$item->{pid}};
        my $idx = $map->{$item->{pid}};
        if ($item->{ACTION} eq 'MOCK') {
            push @out => [ $idx, "MOCK $item->{class} => ($item->{overrides})" ];
        }
        elsif ($item->{ACTION} eq 'BLOCK') {
            push @out => [ $idx, "BLOCK $item->{start_line}\->$item->{end_line} $item->{type}: $item->{name} ($item->{state})" ];
        }
        else {
            push @out => [ $idx, "CUSTOM: $item->{message}" ];
        }
    }

    my @pids = sort { $map->{$a} <=> $map->{$b} } keys %$map;
    my ($fh, $filename) = tempfile( CLEANUP => 0 );

    print $fh join "," => @pids;
    print $fh "\n";
    for my $row (@out) {
        print $fh " ," x $row->[0];
        print $fh $row->[1];
        print $fh ", " x ($index - $row->[0]);
        print $fh "\n";
    }

    close($fh);

    print "# See $filename for process debugging\n";
    print "# Try column -s, -t < '$filename' | less -#2 -S\n";
}

1;

__END__

=head1 NAME

Fennec::Collector - Funnel results from child to parent

=head1 DESCRIPTION

The collector is responsible for 2 jobs:
1) In the parent process it is responsible for gathering all test results from
the child processes.
2) In the child processes it is responsible for sending results to the parent
process.

=head1 METHODS SUBCLASSES MUST OVERRIDE

=over 4

=item $bool = ok( $bool, $description )

Fennec sometimes needs to report the result of an internal check. These checks
will pass a boolean true/false value and a description.

=item diag( $msg )

Fennec uses this to report internal diagnostics messages

=item end_pid

Called just before a child process exits.

=item collect

Used by the parent process at an interval to get results from children and
display them.

=back

=head1 METHODS SUBCLASSES MAY OVERRIDE

=over 4

=item new

Builds the object from params, then calls init.

=item init

Called by new

=item finish

Called at the very end of C<done_testing()> no tests should be reported after
this.

=back

=head1 METHODS SUBCLASSES MUST BE AWARE OF

=over 4

=item test_count

Holds the test count so far.

=item test_failed

Holds the number of tests failed so far.

=item inc_test_count

Used to add 1 to the number of tests.

=item inc_test_failed

Used to add 1 to the number of failed tests.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license (GPL and Artistic).

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
