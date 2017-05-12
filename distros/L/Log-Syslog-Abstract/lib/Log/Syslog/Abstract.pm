package Log::Syslog::Abstract;
use warnings;
use strict;
use Carp;

use vars qw( $VERSION @ISA @EXPORT_OK );
$VERSION = '1.200';

require Exporter;
@ISA = qw( Exporter );  ## no critic(ProhibitExplicitISA)

@EXPORT_OK = qw(
	openlog
	syslog
	closelog
);

my $_DETECTED = 0;
sub import
{
	if( ! $_DETECTED ) {

		my ($openlog, $syslog, $closelog);

		# Try Unix::Syslog first, then Sys::Syslog
		eval qq{use Unix::Syslog qw( :macros ); }; ## no critic (StringyEval)
		if( ! $@ ) {  ## no critic (PunctuationVars)
			($openlog, $syslog, $closelog) = _wrap_for_unix_syslog();
		} else {
			eval qq{use Sys::Syslog ();}; ## no critic (StringyEval)
			if( ! $@ ) {  ## no critic (PunctuationVars)
				($openlog, $syslog, $closelog) = _wrap_for_sys_syslog();
			} else {
				croak q{Unable to detect either Unix::Syslog or Sys::Syslog};
			}
		}

		no warnings 'once';  ## no critic (NoWarnings)
		*openlog = $openlog;
		*syslog = $syslog;
		*closelog = $closelog;

		$_DETECTED = 1;
	}

	return __PACKAGE__->export_to_level(1, @_);
}

sub _wrap_for_unix_syslog
{

	my $openlog = sub {
		my ($id, $flags, $facility) = @_;

		## no critic (ProhibitPostfixControls)
		croak q{first argument must be an identifier string} unless defined $id;
		croak q{second argument must be flag string} unless defined $flags;
		croak q{third argument must be a facility string} unless defined $facility;

		my $numeric_flags    = _convert_flags( $flags );
		my $numeric_facility = _convert_facility( $facility );

		return Unix::Syslog::openlog( $id, $numeric_flags, $numeric_facility);
	};

	my $syslog = sub {
		my $facility = shift;
		my $numeric_facility = _convert_facility( $facility );
		return Unix::Syslog::syslog( $numeric_facility, @_);
	};

	my $closelog = \&Unix::Syslog::closelog;

	return ($openlog, $syslog, $closelog);
}

sub _wrap_for_sys_syslog
{

	my $openlog  = sub {
		if( $Sys::Syslog::VERSION < 0.16 ) {
			# Older Sys::Syslog versions still need
			# setlogsock().  RHEL5 still ships with 0.13 :(
			Sys::Syslog::setlogsock([ 'unix', 'tcp', 'udp' ]);
		}
		return Sys::Syslog::openlog(@_);
	};
	my $syslog   = sub {
		return Sys::Syslog::syslog(@_);
	};
	my $closelog = sub {
		return Sys::Syslog::closelog(@_);
	};

	return ($openlog, $syslog, $closelog);
}

{
	my $flag_map;

	sub _convert_flags
	{
		my($flags) = @_;

		if( ! defined $flag_map ) {
			$flag_map = _make_flag_map();
		}

		my $num = 0;
		foreach my $thing (split(/,/, $flags)) {
			if ( ! exists $flag_map->{$thing} ) {
				next;
			}
			$num |= $flag_map->{$thing};
		}
		return $num;
	}

	sub _make_flag_map
	{
		return {
			pid     => Unix::Syslog::LOG_PID(),
			ndelay  => Unix::Syslog::LOG_NDELAY(),
		};
	}
}

{
	my $fac_map;

	sub _convert_facility
	{
		my($facility) = @_;

		if( ! defined $fac_map ) {
			$fac_map = _make_fac_map();
		}

		my $num = 0;
		foreach my $thing (split(/\|/, $facility)) {
			if ( ! exists $fac_map->{$thing} ) {
				next;
			}
			$num |= $fac_map->{$thing};
		}
		return $num;

	}

	my %special = (
		error => 'err',
		panic => 'emerg',
	);

	# Some of the Unix::Syslog 'macros' tag exports aren't
	# constants, so we need to ignore them if found.
	my %blacklisted = map { $_ => 1 } qw(
		LOG_MASK
		LOG_UPTO
		LOG_PRI
		LOG_MAKEPRI
		LOG_FAC
	);

	sub _make_fac_map
	{
		my %map;

		# Ugh.  Make sure we map only the available constants
		# on this platform.  Some are not defined properly on
		# all platforms.
		foreach my $constant ( grep { /^LOG_/ && !exists $blacklisted{$_} } @{ $Unix::Syslog::EXPORT_TAGS{macros}} ) {
			my $name = lc $constant;
			$name =~ s/^log_//;

			my $value = eval "Unix::Syslog::$constant()";
			if( defined $value ) {
				$map{$name} = $value;
			}
		}

		# Some strings supported by Sys::Syslog don't
		# correspond to a Unix::Syslog LOG_XXXX constant.
		while( my($new_key, $existing_key) = each %special ) {
			$map{$new_key} = $map{$existing_key};
		}

		return \%map;
	}
}

1;
__END__

=head1 NAME

Log::Syslog::Abstract - Use any available syslog API

=head1 VERSION

Version 1.000

=head1 SYNOPSIS

    use Log::Syslog::Abstract qw(openlog syslog closelog);

    openlog( 'myapp', 'pid,ndelay', 'local0' );
    ...
    syslog('info', '%s: %s', 'Something bad happened', $!);
    ...
    closelog();

=head1 DESCRIPTION

This module provides the bare minimum common API to L<Unix::Syslog> and
L<Sys::Syslog>, using whichever one happens to be available.

=head1 FUNCTIONS

=head2 openlog ( $ident, $options, $facility )

Opens a connection to the system logger.

I<$ident> is an identifier string that syslog will include in every
message.  It is normally set to the process name.

I<$options> is a comma-separated list of options.  Valid options are:

=over 4

=item ndelay

Don't delay open until first syslog() call

=item pid

Log the process ID with each message

=back

I<$facility> is a string indicating the syslog facility to be used.  Valid values are:

=over 4

=item auth

=item authpriv

=item cron

=item daemon

=item ftp

=item kern

=item lpr

=item mail

=item mark

=item news

=item security

=item syslog

=item user

=item uucp

=item local0

=item local1

=item local2

=item local3

=item local4

=item local5

=item local6

=item local7

=back

=head2 syslog ( $priority, $format, @args )

Generates a log message and passes it to the appropriate syslog backend.

I<$priority> should be a string containing one of the valid priority names:

=over 4

=item alert

=item crit

=item debug

=item emerg

=item err

=item error

=item info

=item none

=item notice

=item panic

=item warn

=item warning

=back

I<$format> is a format string in the style of printf(3)

I<@args> is a list of values that will replace the placeholders in $format

=head2 closelog ( )

Closes the connection to syslog.

=head1 EXPORT

Nothing is exported by default.  Specify what you need on the use()
line, or call with package-qualified name.

=head1 DEPENDENCIES

At least one of L<Unix::Syslog> or L<Sys::Syslog> must be present, or
Log::Syslog::Abstract will die at use() time.

=head1 AUTHOR

Dave O'Neill, C<< <dmo at roaringpenguin.com> >>

=head1 BUGS

=over 4

=item *

Currently, no validation is performed on the strings provided for
options, facility names, or message priority.  Bogus data may give
bizzare results.

=back

Please report any bugs or feature requests to
C<bug-log-syslog-abstract at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Syslog-Abstract>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Syslog::Abstract

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Syslog-Abstract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Syslog-Abstract>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Syslog-Abstract>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Syslog-Abstract>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dave O'Neill, all rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
