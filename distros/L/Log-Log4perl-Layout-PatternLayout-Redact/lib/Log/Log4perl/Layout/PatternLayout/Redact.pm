package Log::Log4perl::Layout::PatternLayout::Redact;

use strict;
use warnings;

# Due to circularities in module uses inside Log::Log4perl, loading
# Log::Log4perl seems to pre-load the whole distribution in the correct order
# and makes "use base 'Log::Log4perl::Layout::PatternLayout'" work instead of
# dieing with a "Cannot find new() on Log::Log4perl::Layout::PatternLayout".
# It's unfortunate, but this is why "use Log::Log4perl" is the first thing in
# this file.
use Log::Log4perl;

use base 'Log::Log4perl::Layout::PatternLayout';

use Carp;
use Carp::Parse::Redact;
use Data::Validate::Type;
use Try::Tiny;


=head1 NAME

Log::Log4perl::Layout::PatternLayout::Redact - Add stack traces without sensitive information in Log::Log4perl logs.


=head1 DESCRIPTION

C<Log::Log4perl> offers the ability to add stack traces to layouts using I<%T>
in pattern layouts (see C<Log::Log4perl::Layout::PatternLayout>).

However, stack traces contain a list of arguments, and those arguments can
be sensitive data like passwords or credit card data. This module redacts the
sensitive information, replacing them with '[redacted]' so that the stack traces
can be PCI-compliant.


=head1 VERSION

Version 1.2.2

=cut

our $VERSION = '1.2.2';

our $SENSITIVE_ARGUMENT_NAMES = undef;
our $SENSITIVE_REGEXP_PATTERNS = undef;
our $MESSAGE_REDACTION_CALLBACK = undef;

=head1 SYNOPSIS

	use Log::Log4perl::Layout::PatternLayout::Redact;

=head2 Redacting stack traces

Here's an example of log4perl configuration that outputs a redacted trace
(use I<%E> instead of I<%T>) :

	log4perl.logger = WARN, logfile
	log4perl.appender.logfile                          = Log::Log4perl::Appender::File
	log4perl.appender.logfile.filename                 = $file_name
	log4perl.appender.logfile.layout                   = Log::Log4perl::Layout::PatternLayout::Redact
	log4perl.appender.logfile.layout.ConversionPattern = %d %p: (%X{host}) %P %F:%L %M - %m{chomp}%E
	log4perl.appender.logfile.recreate                 = 1
	log4perl.appender.logfile.mode                     = append

To set your own list of arguments to redact, rather than use the defaults in C<Carp::Parse::Redact>,
you need to set a localized version of $SENSITIVE_ARGUMENT_NAMES:

	$Log::Log4perl::Layout::PatternLayout::Redact::SENSITIVE_ARGUMENT_NAMES = 
	[
		'password',
		'luggage_combination',
		'favorite_pony',
	];

And hash keys in the stack trace that match these names will have their values replaced with '[redacted]'.

To set your own list of regexes to use for redaction, rather than use the
defaults in C<Carp::Parse::Redact>, you need to set a localized version of
$SENSITIVE_REGEXP_PATTERNS:

	$Log::Log4perl::Layout::PatternLayout::Redact::SENSITIVE_REGEXP_PATTERNS =
	[
		qr/^\d{16}$/,
	]

And any argument in the stack trace that matches one of the regexes provided
will be replaced with '[redacted]'.

Be sure to do the localizations of the package variables after you have
initialized your logger.

=head2 Redacting messages

Here's an example of log4perl configuration that outputs a redacted message
(use I<%e> instead of I<%m>) :

	log4perl.logger = WARN, logfile
	log4perl.appender.logfile                          = Log::Log4perl::Appender::File
	log4perl.appender.logfile.filename                 = $file_name
	log4perl.appender.logfile.layout                   = Log::Log4perl::Layout::PatternLayout::Redact
	log4perl.appender.logfile.layout.ConversionPattern = %d %p: (%X{host}) %P %F:%L %M - %e
	log4perl.appender.logfile.recreate                 = 1
	log4perl.appender.logfile.mode                     = append

To redact the message, you will need to write your own redaction subroutine as
follows:

	$Log::Log4perl::Layout::PatternLayout::Redact::MESSAGE_REDACTION_CALLBACK = sub
	{
		my ( $message ) = @_;
		
		# Do replacements on the messages to redact sensitive information.
		$message =~ s/(password=")[^"]+(")/$1\[redacted\]$2/g;
		
		return $message;
	};

Be sure to do the localizations of the package variable after you have
initialized your logger.

=cut

# Add '%E' to the list of options available for the Log4perl layout.
# This offers a redacted stack trace.
Log::Log4perl::Layout::PatternLayout::add_global_cspec(
	'E',
	sub
	{
		my $trace = Carp::longmess();
		chomp( $trace );
		
		my $redacted_stack_trace = Carp::Parse::Redact::parse_stack_trace(
			$trace,
			sensitive_argument_names  => $SENSITIVE_ARGUMENT_NAMES,
			sensitive_regexp_patterns => $SENSITIVE_REGEXP_PATTERNS,
		);
		
		# For each line of the stack trace, replace the original arguments with the
		# newly redacted ones.
		my $lines = [];
		my $bubbled_to_log4perl = 0;
		foreach my $caller_information ( @{ $redacted_stack_trace || [] } )
		{
			# This caller is inside Log::Log4perl, skip it.
			if ( $caller_information->get_line() =~ /^\s*Log::Log4perl/ )
			{
				# But not after indicating that we've bubbled up to Log::Log4perl.
				$bubbled_to_log4perl = 1 if !$bubbled_to_log4perl;
				next;
			}
			# This caller is below Log::Log4perl, skip it.
			next if !$bubbled_to_log4perl;
			
			push( @$lines, $caller_information->get_redacted_line() );
		}
		
		my $redacted_trace = join( "\n", @$lines );
		
		return "\n" . $redacted_trace;
	}
);

# Add '%e' to the list of options available for the Log4perl layout.
# This offers a redacted message.
Log::Log4perl::Layout::PatternLayout::add_global_cspec(
	'e',
	sub
	{
		my ( $self, $message ) = @_;
		
		return $message
			if !defined( $MESSAGE_REDACTION_CALLBACK );
		
		my $redacted_message;
		try
		{
			Carp::croak('the message redaction callback is not a valid code reference')
				if !Data::Validate::Type::is_coderef( $MESSAGE_REDACTION_CALLBACK );
			
			$redacted_message = $MESSAGE_REDACTION_CALLBACK->( $message );
		}
		catch
		{
			my $error = $_;
			Carp::carp("Failed to redact message: $error");
			return $message;
		};
		
		return $redacted_message;
	}
);


=head1 AUTHOR

Kate Kirby, C<< <kate at cpan.org> >>.

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-log-log4perl-layout-patternlayout-redact at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Log4perl-Layout-PatternLayout-Redact>. 
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Log::Log4perl::Layout::PatternLayout::Redact


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Layout-PatternLayout-Redact>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Log4perl-Layout-PatternLayout-Redact>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Log4perl-Layout-PatternLayout-Redact>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Log4perl-Layout-PatternLayout-Redact/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to ThinkGeek (L<http://www.thinkgeek.com/>) and its corporate overlords
at Geeknet (L<http://www.geek.net/>), for footing the bill while we eat pizza
and write code for them!


=head1 COPYRIGHT & LICENSE

Copyright 2012 Kate Kirby & Guillaume Aubert.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License version 3 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/

=cut

1;
