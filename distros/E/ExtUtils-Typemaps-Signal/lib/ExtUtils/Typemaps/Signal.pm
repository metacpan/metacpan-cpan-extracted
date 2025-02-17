package ExtUtils::Typemaps::Signal;
$ExtUtils::Typemaps::Signal::VERSION = '0.008';
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
	struct timespec T_TIMESPEC

INPUT
T_SIGSET
	if (SvROK($arg)) {
		if (!sv_derived_from($arg, \"POSIX::SigSet\")) {
			Perl_croak(aTHX_ \"$var is not of type POSIX::SigSet\");
		} else {
	\x{23}if PERL_VERSION > 15 || PERL_VERSION == 15 && PERL_SUBVERSION > 2
			$var = (sigset_t *) SvPV_nolen(SvRV($arg));
	\x{23}else
			IV tmp = SvIV((SV*)SvRV($arg));
			$var = INT2PTR(sigset_t*, tmp);
	\x{23}endif
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
	if (SvROK($arg) && sv_derived_from($arg, \"Time::Spec\")) {
		$var = *(struct timespec*)SvPV_nolen(SvRV($arg));
	} else {
		NV input = SvNV($arg);
		$var.tv_sec  = (time_t) floor(input);
		$var.tv_nsec = (long) ((input - $var.tv_sec) * 1000000000);
	}

OUTPUT
T_TIMESPEC
	sv_setnv($arg, $var.tv_sec + $var.tv_nsec / 1000000000.0);
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

version 0.008

=head1 SYNOPSIS

 use ExtUtils::Typemaps::Signal;
 # First, read my own type maps:
 my $private_map = ExtUtils::Typemaps->new(file => 'my.map');

 # Then, get the Signal set and merge it into my maps
 my $map = ExtUtils::Typemaps::Signal->new;
 $private_map->merge(typemap => $map);

 # Now, write the combined map to an output file
 $private_map->write(file => 'typemap');

=head1 DESCRIPTION

ExtUtils::Typemaps::Signal is an ExtUtils::Typemaps subclass that provides several useful typemaps when dealing with signalling code. In particular it converts the following C types:

=over 4

=item * signo_t

Input only. This turns a signal name (e.g. C<TERM>) or number (C<15>) into a signal number. Do note you need to typedef int to this type yourself.

=item * sigset_t*

Input only. This turns a C<POSIX::SigSet> object into a C<sigset_t*>. Alternatively, it will convert a signal name/number into a signal set.

=item * struct timespec

This turns a numeric duration into a struct timespec. This supports input and output.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
