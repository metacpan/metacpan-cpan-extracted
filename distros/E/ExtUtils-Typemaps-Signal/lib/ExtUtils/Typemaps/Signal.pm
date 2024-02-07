package ExtUtils::Typemaps::Signal;
$ExtUtils::Typemaps::Signal::VERSION = '0.005';
use strict;
use warnings;

use parent 'ExtUtils::Typemaps';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->add_string(string => <<'END');
TYPEMAP
	sigset_t*	T_SIGSET
	signo_t		T_SIGNO
	siginfo_t	T_SIGINFO
	struct timespec T_TIMESPEC

INPUT
T_SIGSET
	if (SvROK($arg)) {
		if (!sv_derived_from($arg, \"POSIX::SigSet\")) {
			Perl_croak(aTHX_ \"$var is not of type POSIX::SigSet\");
		} else {
	%:if PERL_VERSION > 15 || PERL_VERSION == 15 && PERL_SUBVERSION > 2
			$var = (sigset_t *) SvPV_nolen(SvRV($arg));
	%:else
			IV tmp = SvIV((SV*)SvRV($arg));
			$var = INT2PTR(sigset_t*, tmp);
	%:endif
		}
	} else if (SvOK($arg)) {
		int signo = (SvIOK($arg) || looks_like_number($arg)) && SvIV($arg) ? SvIV($arg) : whichsig(SvPV_nolen($arg));
		SV* buffer = sv_2mortal(newSVpvn(\"\", 0));
		sv_grow(buffer, sizeof(sigset_t));
		$var = (sigset_t*)SvPV_nolen(buffer);
		sigemptyset($var);
		sigaddset($var, signo);
	} else {
		$var = NULL;
	}

T_SIGNO
	$var = (SvIOK($arg) || looks_like_number($arg)) && SvIV($arg) ? SvIV($arg) : whichsig(SvPV_nolen($arg));

T_TIMESPEC
	{
	NV input = SvNV($arg);
	$var.tv_sec  = (time_t) floor(input);
	$var.tv_nsec = (long) ((input - $var.tv_sec) * 1000000000);
	}

OUTPUT
T_TIMESPEC
	$var.tv_sec + $var.tv_nsec / 1000000000.0;

T_SIGINFO
	{
	HV* ret = newHV();
	hv_stores(ret, \"signo\", newSViv($var.si_signo));
	hv_stores(ret, \"code\", newSViv($var.si_code));
	hv_stores(ret, \"errno\", newSViv($var.si_errno));
	hv_stores(ret, \"pid\", newSViv($var.si_pid));
	hv_stores(ret, \"uid\", newSViv($var.si_uid));
	hv_stores(ret, \"status\", newSViv($var.si_status));
	hv_stores(ret, \"band\", newSViv($var.si_band));
	%:ifdef si_fd
	hv_stores(ret, \"fd\", newSViv($var.si_fd));
	%:endif
	hv_stores(ret, \"value\", newSViv($var.si_value.sival_int));
	hv_stores(ret, \"ptr\", newSVuv(PTR2UV($var.si_value.sival_ptr)));
	hv_stores(ret, \"addr\", newSVuv(PTR2UV($var.si_addr)));

	$arg = newRV_noinc((SV*)ret);
	}
END

	return $self;
}

1;

#ABSTRACT: A typemap for dealing with signal related types

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Typemaps::Signal - A typemap for dealing with signal related types

=head1 VERSION

version 0.005

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
