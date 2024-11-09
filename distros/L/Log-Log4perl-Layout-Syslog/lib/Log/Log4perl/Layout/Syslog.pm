package Log::Log4perl::Layout::Syslog;

use 5.006;
use strict;
use warnings;

use Scalar::Util;

=encoding utf8

=head1 NAME

Log::Log4perl::Layout::Syslog - Layout in Syslog format

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This format is useful with the Log::Dispatch::Syslog class.
Add this to your configuration file:

    log4perl.appender.A1=Log::Dispatch::Syslog
    log4perl.appender.A1.Filter=RangeAll
    log4perl.appender.A1.ident=bandsman
    log4perl.appender.A1.layout=Log::Log4perl::Layout::Syslog

Much of the actual formatting is done by the Sys::Syslog code called
from Log::Dispatch::Syslog,
however you can't use Log::Log4perl::Layout::NoopLayout
since that doesn't insert the ident data that's needed by systems such as
flutentd.

=cut

=head2 new

    use Log::Log4perl::Layout::Syslog;
    my $layout = Log::Log4perl::Layout::Syslog->new();

=cut

sub new {
	my $class = shift;

	if(!defined($class)) {
		# Using Log::Log4perl::Layout::Syslog->new(), not Log::Log4perl::Layout::Syslog::new()
		# carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		# return;

		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		# return bless { %{$class}, %args }, ref($class);
		return bless { %{$class} }, ref($class);
	}

	# Return the blessed object
	return bless {
		info_needed => {},
		stack       => [],
	}, $class;
}

=head2 render

Render a message in the correct format.

=cut

sub render {
	# my($self, $message, $category, $priority, $caller_level) = @_;
	my $message = $_[1];

	return "user: $message";
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

I can't work out how to get the ident given to
Log::Dispatch::Syslog's constructor,
so ident (facility in RFC3164 lingo) is always sent to
LOG_USER.

=head1 SEE ALSO

L<Log::Log4perl>
L<Log::Dispatch::Syslog>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log-Log4perl-Layout-Syslog

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Layout-Syslog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Log4perl-Layout-Syslog>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Log4perl-Layout-Syslog/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2014 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
