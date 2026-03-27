package Medusa;

use 5.008003;
use strict;
use warnings;
use Time::HiRes qw/time/;
use B;
use Data::Dumper;
use POSIX qw(strftime);
use Data::GUID;

our %LOG;

our $VERSION = '0.04';

BEGIN {
	%LOG = (
		LOGGER => 'Medusa::Logger',
		LOG_LEVEL => 'debug',
		LOG_FILE  => 'audit.log',
		LOG_INIT => sub {
			(my $module = $LOG{LOGGER}) =~ s/::/\//g;
			require $module . '.pm';
			$LOG{LOGGER}->new(
				file => $LOG{LOG_FILE},
			);
		},
		TIME => 'gmtime',
		TIME_FORMAT => 'default', # example '%Y%m%dT%H:%M:%S.%ms',
		LOG => undef,
		LOG_FUNCTIONS => {
			error => 'error',
			info  => 'info',
			debug => 'debug',
		},
		QUOTE => '†',
		OPTIONS => {
			date => 1,
			guid => 1,
			level => 1,
			elapsed_call => 1,
			caller => 1,
		},
		FORMAT_MESSAGE => sub {
			my %params = @_;
			my $log_message = $params{message};
			my $log_meth = $params{level} || $LOG{LOG_FUNCTIONS}{$LOG{LOG_LEVEL}};
			my $options = $LOG{OPTIONS};
			my $time = ! $options->{date} 
				? 0 
				: $LOG{TIME_FORMAT} eq 'default' 
					? $LOG{TIME} eq 'gmtime'
						? gmtime
						: localtime
					: do {
						my @now = $LOG{TIME} eq 'gmtime'
							? gmtime
							: localtime;
						my ($format, $ms) = $LOG{TIME_FORMAT};
						if ($format =~ s/\.\%ms$//) {
							my $time = Time::HiRes::time;
							$time =~ m/(\.\d+)/;
							$ms = $1;
						}
						strftime($format, @now) . "$ms";
					};
			my $sprintf = "";
			my @sprintf_params;
			if ($time) {
				$sprintf .= "%s ";
				push @sprintf_params, $time;
			}
			if ($options->{guid} && $params{guid}) {
				$sprintf .= "%s ";
				push @sprintf_params, $params{guid};
			}
			if ($options->{level}) {
				$sprintf .= "%s";
				push @sprintf_params, uc $log_meth;
			}
			$sprintf =~ s/\s$//;
			my $message = sprintf($sprintf, @sprintf_params);
			for my $key (sort keys %params) {
				next if $key =~ m/^prefix|level|guid$/;
				if (ref $params{$key}) {
					my $ref = ref $params{$key};
					my $len = $ref eq 'ARRAY' ? scalar @{$params{$key} || []} - 1 : 1;
					for my $i (0 .. $len) {
						my $data = Dumper($ref eq 'HASH' ? $params{$key} : $params{params}->[$i]);
						$data =~ s/\$VAR1\s=\s//;
						$data =~ s/(\s+)(['"][^"]+['"])*/defined $2 ? $2 : ""/gem;
						$data =~ s/;$//;
						$message = sprintf("%s %s%s=%s%s%s",
							$message,
							$params{prefix},
							$i,
							$LOG{QUOTE},
							$data,
							$LOG{QUOTE},
						);
					}
				} else {
					$message = sprintf("%s %s=%s%s%s", $message, $key, $LOG{QUOTE}, $params{$key}, $LOG{QUOTE});
				}
			}
			return $message;
		}
	);
}

sub import {
	my ($pkg, @import) = @_;
	if (scalar @import % 2) {
		die "odd number of params passed in import";
	}
	my $caller = caller();
	{
		no strict 'refs';
		push @{"${caller}::ISA"}, $pkg;
	}
	while (@import) {
		my ($key, $val) = (shift @import, shift @import);
		$LOG{$key} = $val;
	}
}

sub MODIFY_CODE_ATTRIBUTES {
	my ($class,$code,@attrs) = @_;
	
	unless (ref $LOG{LOG}) {
		$LOG{LOG} = $LOG{LOG_INIT}->();
	}
	
	my ($att) = grep { $_ =~ m/Audit/ && $_ } @attrs;
	if ($att) {
		$att =~ m/Audit(?:\((.*)\))/;
		$att = $1;
		my $meta = B::svref_2object($code);
		my $meth = $meta->GV->NAME;
		my $caller = caller(1);
		no strict 'refs';
		no warnings 'redefine';
		*{"${caller}::$meth"} = sub {
			my $options = $LOG{OPTIONS};	
			my ($n, $caller) = (0, "");
			if ($options->{caller}) {
				while (my @l = (caller($n))) {
					$caller .= "->" if $caller;
					$caller = sprintf "%s%s:%s", $caller, $l[0], $l[2];
					$n++;
				}
			}
			my $guid = !$options->{guid} ? 0 : Data::GUID->new->as_string;
			my ($now, $after) = (0, 0);
			log_message(
				($caller ? ( caller => $caller ) : ()),
				guid => $guid,
				message => sprintf(
					"subroutine %s called with args:",
					$meth
				),
				params => [@_],
				prefix => 'arg'
			);
			$now = time if $options->{elapsed_call};
			my @out = $code->(@_);
			$after = time if $options->{elapsed_call};
			log_message(
				($caller ? ( caller => $caller ) : ()),
				guid => $guid,
				message => sprintf(
					"subroutine %s returned:",
					$meth
				),
				params => [@out],
				($options->{elapsed_call} ? (elapsed_call => $after == $now ? 0 : $after - $now) : ()),
				prefix => 'return'
			);
			return wantarray ? @out : shift @out;
		};
		return;
	}

}

sub log_message {
	my (%params) = @_;
	my $log_meth = $params{level} || $LOG{LOG_FUNCTIONS}{$LOG{LOG_LEVEL}};
	$LOG{LOG}->$log_meth(
		$LOG{FORMAT_MESSAGE}->(
			%params,
			level => $log_meth
		)
	);
}

1;

__END__

=head1 NAME

Medusa - Subroutine auditing via attributes

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

    package MyApp;
    use Medusa;

    sub process_data :Audit {
        my ($self, $data) = @_;
        # ... process data ...
        return $result;
    }

    # With custom configuration
    package MyApp;
    use Medusa (
        LOG_LEVEL => 'info',
        LOG_FILE  => 'my_audit.log',
    );

    sub important_action :Audit {
        my ($self, @args) = @_;
        # This subroutine's calls and returns will be logged
        return @results;
    }

    sub error_action :Audit(error) {
        ...
    }

=head1 DESCRIPTION

Medusa provides a simple mechanism to add auditing to subroutines using Perl
attributes. By adding the C<:Audit> attribute to a subroutine, Medusa will
automatically log when the subroutine is called (including its arguments) and
what it returns.

This is useful for debugging, compliance auditing, or tracking the flow of
data through your application.

=head1 USAGE

To use Medusa, simply C<use> the module in your package and add the C<:Audit>
attribute to any subroutines you want to audit:

    package MyModule;
    use Medusa;

    sub my_method :Audit {
        my ($self, $arg1, $arg2) = @_;
        return $arg1 + $arg2;
    }

When C<my_method> is called, Medusa will log:

=over 4

=item * The subroutine name and arguments passed to it

=item * The return value(s) when the subroutine completes

=back

=head1 CONFIGURATION

Medusa accepts the following configuration options during import:

=over 4

=item B<LOGGER>

The logger class to use. Defaults to C<Medusa::Logger>.

    use Medusa ( LOGGER => 'My::Custom::Logger' );

=item B<LOG_LEVEL>

The log level to use. Defaults to C<debug>. Available levels are determined
by your logger class (C<error>, C<info>, C<debug>).

    use Medusa ( LOG_LEVEL => 'info' );

=item B<LOG_FILE>

The file to write audit logs to. Defaults to C<audit.log>.

    use Medusa ( LOG_FILE => '/var/log/myapp/audit.log' );

=back

=head1 CUSTOM LOGGERS

You can provide your own logger class by setting the C<LOGGER> option. Your
logger class must implement:

=over 4

=item * C<new(%args)> - Constructor that accepts a C<file> argument

=item * Log level methods (C<error>, C<info>, C<debug>) that accept a message string

=back

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-medusa at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Medusa>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Medusa

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Medusa>

=item * Search CPAN

L<https://metacpan.org/release/Medusa>

=back

=head1 SEE ALSO

L<Medusa::Logger>, L<attributes>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Medusa
