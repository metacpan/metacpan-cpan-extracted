package Memchmark;

our $VERSION = '0.01';

use 5.008;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(memchmark cmpthese);

use Carp;
use Proc::ProcessTable;
use POSIX qw(:sys_wait_h);
use Time::HiRes qw(usleep);

sub _find_process {
    my $pid = shift || $$;
    my $p=Proc::ProcessTable->new;
    for (@{$p->table}) {
	return $_ if $_->pid == $pid;
    }
}

sub memchmark (&) {
    my $sub = shift;
    ref $sub eq 'CODE'
	or croak "invalid type for memchmark arg ($sub), CODE ref expected";
    my $size0 = _find_process->size;
    my $pid = fork;

    if (defined $pid and $pid==0) {
	eval { &$sub() };
	$@ and print STDERR $@;
	sleep 1;
	exit(0);
    }
    defined $pid or croak "unable to fork";

    my $ecode;
    my $size1 = $size0;
    do {
	usleep(100000);
	my $size = _find_process($pid)->size;
	$size1 = $size if $size > $size1;
	$ecode = waitpid($pid, WNOHANG);
    } until $ecode > 0;
    return $size1-$size0;
}

sub cmpthese {
    my %test = @_;
    my $init = delete $test{-init} || sub {};
    my $size0 = &memchmark($init);
    my %size;
    for my $test (sort keys %test) {
	$test=~/^-/ and croak "invalid test name";
	$size{$test} = &memchmark($test{$test}) - $size0;
	print "test: $test, memory used: $size{$test} bytes\n";
    }
}

1;

__END__


=head1 NAME

Memchmark - Check memory consumption

=head1 SYNOPSIS

  use Memchmark qw(cmpthese);
  my @data = map { rand($_) } 0..10000;
  cmpthese( -init => sub { my @s =  @data },
            nsort => sub { my @s = sort { $a <=> $b } @data },
            rnsort => sub { my @s = sort { -($a <=> $b) } @data } );

=head1 DESCRIPTION

Memchmark is similar to L<Benchmark> but compares memory comsumptions
instead of times.

To measure memory comsumption for some subroutine, Memchmark forks a
new process to run the sub and then monitors its memory usage every
100ms (aprox.) recording the maximum amount used.

The obtained quantities are only approximate, you can expect errors
around 30%.

It is not reliable for small quantities (useles for anything
below 1MB).


=head2 EXPORT_OK

These are the subroutines available from Memchmark:

=over 4

=item cmpthese(foo => sub { ... }, bar => sub { ... }, ...)

prints statistics about the memory comsumption for the different subs.

An entry with the name C<-init> can be used for a do nothing entry
which memory comsumption will be substracted to the results from the
rest of the tests.

=item memchmark { &code() };

returns the memory used by C<&code()>.

=back

=head1 BUGS

This is a very early release, alpha software, expect bugs on it.

The API is not stable. I will change it when required for improvement.

It will not work under Windows (ever).


=head1 SEE ALSO

L<Benchmark>, L<Proc::ProcessTable>, L<Proc::ProcessTable::Process>,
L<fork>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
