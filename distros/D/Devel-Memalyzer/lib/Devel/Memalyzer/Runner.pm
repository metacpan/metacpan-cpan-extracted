package Devel::Memalyzer::Runner;
use strict;
use warnings;

use base 'Devel::Memalyzer::Base';
use Devel::Memalyzer;

use Time::HiRes qw/sleep/;
use POSIX;

__PACKAGE__->gen_accessors(qw/ command interval /);

sub run {
    my $self = shift;
    $self->collect;
}

sub _run {
    my $self = shift;
    die ( "already ran" ) if $self->{ _run }++;
    exec $self->command unless my $pid = fork();
    return $pid;
}

sub collect {
    my $self = shift;

    my $pid = $self->_run;
    until ( waitpid( $pid, &POSIX::WNOHANG )) {
        Devel::Memalyzer->singleton->record( $pid );
        sleep ($self->interval || 1 );
    }
}

1;

__END__

=head1 NAME

Devel::Memalyzer::Runner - Run a command under the current Memalyzer singleton.

=head1 SYNOPSYS

    use Devel::Memalyzer output => 'output.csv';
    use Devel::Memalyzer::Runner;
    my $runner = Devel::Memalyzer::Runner->new( command => 'echo "hello world"', interval => 1 );
    $runner->run;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

