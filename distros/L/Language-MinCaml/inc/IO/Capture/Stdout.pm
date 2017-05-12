#line 1
package IO::Capture::Stdout;
use Carp;
use base qw/IO::Capture/;
use IO::Capture::Tie_STDx;

sub _start {
	my $self = shift;
	$self->line_pointer(1);
    tie *STDOUT, "IO::Capture::Tie_STDx";
}

sub _retrieve_captured_text {
    my $self = shift;
    my $messages = \@{$self->{'IO::Capture::messages'}};

    @$messages = <STDOUT>;
	#$self->line_pointer(1);
	return 1;
}

sub _check_pre_conditions {
	my $self = shift;

	return unless $self->SUPER::_check_pre_conditions;

	if (tied *STDOUT) {
		carp "WARNING: STDOUT already tied, unable to capture";
		return;
	}
	return 1;
}

sub _stop {
    untie *STDOUT;
}
1;

#line 291
