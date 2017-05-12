package Fennec::Collector::TB;
use strict;
use warnings;
use Carp qw/confess/;

use base 'Fennec::Collector';

use Fennec::Util qw/accessors/;

accessors qw/skip/;

sub ok   { shift; Test::Builder->new->ok(@_) }
sub diag { shift; Test::Builder->new->diag(@_) }
sub report { confess "Must override report" }

sub finish {
    my $self = shift;

    $self->SUPER::finish();

    my $count = $self->test_count || 0;
    print STDOUT "1..$count";
    print STDOUT " # SKIP " . $self->skip if $self->skip;
    print STDOUT "\n";
}

sub init {
    my $self = shift;
    require Test::Builder;

    my $tbout = tie( *TBOUT, 'Fennec::Collector::TB::_Handle', 'STDOUT', $self );
    my $tberr = tie( *TBERR, 'Fennec::Collector::TB::_Handle', 'STDERR', $self );

    my $tb = Test::Builder->new();
    $tb->use_numbers(0);
    $tb->no_header(1);
    $tb->no_ending(1);

    my $old = select(TBOUT);
    $| = 1;
    select(TBERR);
    $| = 1;
    select($old);

    $tb->output( \*TBOUT );
    $tb->todo_output( \*TBOUT );
    $tb->failure_output( \*TBERR );
}

sub render {
    my $self = shift;
    my ( $handle, $part ) = @_;

    if ( $handle eq 'STDOUT' && $part =~ m/^\s*(?:(not)\s+)?ok(\s|$)/ ) {
        my $fail = $1 && $1 eq 'not' ? 1 : 0;
        my ( $mod, $reason ) = $part =~ m/ # (TODO|skip) (.*)$/;
        $self->inc_test_failed if $fail && !$mod;
        $self->inc_test_count;
    }

    return $self->debug($part) if $part =~ m/# FENNEC_DEBUG/;

    if ( $ENV{HARNESS_IS_VERBOSE} || $handle eq 'STDOUT' ) {
        print STDOUT "$part\n";
    }
    else {
        print STDERR "$part\n";
    }
}

package Fennec::Collector::TB::_Handle;

use Fennec::Util qw/accessors get_test_call/;

accessors qw/name collector/;

sub TIEHANDLE {
    my $class = shift;
    my ( $name, $collector ) = @_;
    return bless( {name => $name, collector => $collector}, $class );
}

sub PRINT {
    my $self = shift;
    my @data = @_;
    my @call = get_test_call();

    $self->collector->report(
        pid    => $$,
        source => join( ", " => @call[0 .. 2] ),
        data   => \@data,
        name   => $self->name,
    );
}

1;

__END__

=head1 NAME

Fennec::Collector::TB - Base class for Test::Builder collectors

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Fennec is free software; Standard perl license (GPL and Artistic).

Fennec is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
