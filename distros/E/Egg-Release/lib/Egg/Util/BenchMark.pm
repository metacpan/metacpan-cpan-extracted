package Egg::Util::BenchMark;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: BenchMark.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Time::HiRes qw/ gettimeofday tv_interval /;

our $VERSION= '3.00';

sub new {
	my($class, $e)= @_;
	my $self= bless { e=> $e, report=> [] }, $class;
	$self->_settime;
	$self;
}
sub stock {
	my($self, $label)= @_;
	my $elapsed= tv_interval ($self->{is_time} || $self->_settime);
	push @{$self->{report}}, [$label, ($elapsed || 0)];
	$self->_settime;
}
sub finish {
	my($self)= @_;
	my($label, $elapsed);
	my $format= "* %-18s : %3.6f sec.\n";
	my $report= "# >> simple bench = -------------------\n";
	my $total= 0;
	for (@{$self->{report}}) {
		$total+= $_->[1];
		$report.= sprintf $format, @$_;
	}
	$report.= sprintf $format, ('======= Total >>', $total);
	$self->{e}->debug_out
	  ("${report}# -------------------------------------\n");
}
sub _settime {
	$_[0]->{is_time}= [gettimeofday];
}

1;

__END__

=head1 NAME

Egg::Util::BenchMark - Easy bench mark class for Egg.

=head1 SYNOPSIS

  my $bench= Egg::Util::BenchMark->new($e);
  
  $bench->stock('start');
  $bench->stock('run');
  $bench->stock('end');
  
  $bench->finish;
  
  # プロジェクトから使うなら
  $e->bench('start');
  $e->bench('run');
  $e->bench('end');

=head1 DESCRIPTION

It is an easy bench mark class used with Debaccmord of Egg.

Egg takes the bench mark at each the following method calls while operating by 
debug mode.

=over 4

=item * _prepare

=item * _dispatch

=item * _action_start

=item * _action_end

=item * _finalize

=item * _output

=item * _finish

=back

And, it totals at the end and the report is output by $e-E<gt>debug_out.

In addition, $e-E<gt>bench(LABEL_STRING) comes to be reported about the application
to take the bench mark in detail including the result when putting it at every step.

When debug mode becomes invalid, arranged $e-E<gt>bench need not be especially
excluded because it is changed to the method of not doing anything.

This module is set up by L<Egg::Util::Debug>. To use other bench mark classes,
it is set to environment variable EGG_BENCH_CLASS.

=head1 METHODS

=head2 new

Constructor.

my $bench= Egg::Util::BenchMark->new;

=head2 stock

The bench mark when called is recorded.

  $bench->stock('start');
  $bench->stock('end');

=head2 finish

The data recorded by stock is totaled and the report is returned.

  print STDERR $bench->finish;

=head2 SEE ALSO

L<Egg::Release>,
L<Egg::Util::Debug>,
L<Time::HiRes>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

