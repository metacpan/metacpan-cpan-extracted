package Egg::Util::Debug;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Debug.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.01';

sub _setup {
	my($class, $e, $p)= @_;
	$e->_setup_log($p);
	my $benchmark=
	   $ENV{EGG_BENCH_CLASS} || 'Egg::Util::BenchMark';
	my $dbgscreen=
	   $ENV{EGG_DEBUG_SCREEN_CLASS} || 'Egg::Util::DebugScreen';
	$benchmark->require or die $@;
	$dbgscreen->require or die $@;
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${p}::_start_engine"}= \&_start_engine_debug;
	*{"${p}::debug_screen"} = $dbgscreen->can('_debug_screen');
	*{"${p}::debug_out"}    = \&_debug_out;
	*{"${p}::debug_end"}    = \&_debug_end;
	*{"${p}::egg_warn"}     = \&_egg_warn;
	*{"${p}::bench"}        = sub { shift->{benchmark}->stock(@_) };
	my $plugins= $e->regists;
	my $r_class= $e->global->{request_class};
	$e->debug_out(<<END_INFO);

# ----------------------------------------------------------
# >> Egg - ${p}: startup !! - load plugins.
#   @{[
  join("\n#   ", map{"= $_->[0] v$_->[1]"}values %$plugins) || "...none."
  ]}
# + Request Class: $r_class v@{[ $r_class->VERSION || 0 ]}
END_INFO
	sub {
		my($egg)= @_;
		$egg->debug_out(<<END_REPORT);
# >>>>> $egg->{namespace} v@{[ $egg->VERSION || 0.00 ]}
END_REPORT
		$egg->{benchmark}= $benchmark->new(@_);
	  };
}
sub _start_engine_debug {
	my($e)= @_;
	local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
	$e->_prepare;      $e->bench('prepare');
	$e->_dispatch;     $e->bench('dispatch');
	$e->_action_start; $e->bench('action_start');
	$e->_action_end;   $e->bench('action_end');
	$e->_finalize;     $e->bench('finalize');
	$e->_output;       $e->bench('output');
	$e->_finish;       $e->bench('finish');
	$e->{benchmark}->finish;
	if (my $header= $e->response->{header}) { $e->debug_out($header) }
	_debug_end($e);
}
sub _debug_out {
	my $e  = shift;
	my $msg= shift || return 0;
	   $msg.= "\n" unless $msg=~m{\n$};
	$e->{debug_buffer}.= $msg;
}
sub _debug_end {
	my $e= shift;
	$e->{debug_buffer}.= shift || "";
	$e->log->debug($e->{debug_buffer});
	$e;
}
sub _report {
	my($e)= @_;
	my $m= $e->model_manager->regists;
	my $v= $e->view_manager->regists;
	my $d= $e->global->{dispatch_class};
	$e->debug_out(<<END_REPORT);
# + Load Model: @{[ join ', ', map{"$_-$m->{$_}[1]"}keys %$m ]}
# + Load View : @{[ join ', ', map{"$_-$v->{$_}[1]"}keys %$v ]}
@{[ $d ? "# + Load Dispatch: $d v@{[ $d->VERSION || '0.01' ]}": "" ]}
END_REPORT
	$e->log->debug($e->{debug_buffer});
}
sub _egg_warn {
	my $e= shift;
	return $e->stash->{egg_warn} unless @_;
	my $msg= $_[0] ? do {
		  ref($_[0]) eq 'HASH'
		  ? join "<br>\n---<br>\n", map{"$_ = $_[0]->{$_}"}keys %{$_[0]}
		: ref($_[0]) eq 'ARRAY'
		  ? join "<br>\n---<br>\n", @{$_[0]}
		: $_[0];
	  }: 'N/A';
	$e->stash->{egg_warn}= $e->stash->{egg_warn}
	    ? $e->stash->{egg_warn}."<hr size=1>$msg": $msg;
	$msg;
}

1;

__END__

=head1 NAME

Egg::Util::Debug - Debug class for Egg.

=head1 DESCRIPTION

It is a class applied when the project operates by Debaccmord.

The following methods are set up by this module for debugging.

=over 4

=item * new

Constructor of project.

=item * bench

Easy bench mark.
When the module used is changed, EGG_BENCH_CLASS of the environment variable is set.
L<Egg::Util::BenchMark> is used in default.

=item * debug_out

Output of debugging message.

=item * debug_screen

Contents output when exception makes an error.
When L<Egg::Util::DebugScreen> loaded by default is changed,
EGG_DEBUG_SCREEN_CLASS of the environment variable is set.

=item * _start_engine

Engine method for debugging.

=back

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Util::BenchMark>,
L<Egg::Util::DebugScreen>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

