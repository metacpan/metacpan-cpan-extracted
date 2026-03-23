package Medusa;

use 5.008003;
use strict;
use warnings;

use B;
use Data::Dumper;
our %LOG;

our $VERSION = '0.02';

BEGIN {
	%LOG = (
		LOGGER => 'Medusa::Logger',
		LOG_LEVEL => 'debug',
		LOG_FILE  => 'audit.log',
		LOG => sub {
			(my $module = $LOG{LOGGER}) =~ s/::/\//g;
			require $module . '.pm';
			$LOG{LOGGER}->new(
				file => $LOG{LOG_FILE},
			);
		},
		LOG_FUNCTIONS => {
			error => 'error',
			info  => 'info',
			debug => 'debug',
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
	
	if (ref $LOG{LOG} eq 'CODE') {
		$LOG{LOG} = $LOG{LOG}->();
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
			log_message(
				message => sprintf( 
					"subroutine %s called with params:",
					$meth
				),
				params => [@_]
			);
			my @out = $code->(@_);
			log_message(
				message => sprintf(
					"subroutine %s returned:",
					$meth
				),
				params => [@out]
			);
			return wantarray ? @out : shift @out;
		};
		return;
	}

}

sub log_message {
	my (%params) = @_;
	my $log_message = $params{message};
	my $log_meth = $params{level} || $LOG{LOG_FUNCTIONS}{$LOG{LOG_LEVEL}};
	if (@_ > 1) {
		my $len = scalar @{$params{params} || []} - 1;
		for my $i (0 .. $len) {
			my $data = Dumper($params{params}->[$i]);
			$data =~ s/\$VAR1\s=\s//;
			$data =~ s/(\s+)(['"][^"]+['"])*/defined $2 ? $2 : ""/gem;
			$data =~ s/;$/ -/ unless $i == $len;
			$log_message = sprintf("%s %s", $log_message, $data);
		}
	}
	$LOG{LOG}->$log_meth($log_message);
}

1;

__END__

=head1 NAME

Medusa - Subroutine auditing via attributes

=head1 VERSION

Version 0.02

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
