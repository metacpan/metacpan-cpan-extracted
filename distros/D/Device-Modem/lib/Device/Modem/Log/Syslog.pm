# Device::Modem::Log::Syslog - Syslog logging plugin for Device::Modem class
#
# Copyright (C) 2002-2004 Cosimo Streppone, cosimo@cpan.org
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Additionally, this is ALPHA software, still needs extensive
# testing and support for generic AT commads, so use it at your own risk,
# and without ANY warranty! Have fun.
#
# $Id$

package Device::Modem::Log::Syslog;
$VERSION = sprintf '%d.%02d', q$Revision: 2.1 $ =~ /(\d+)\.(\d+)/;

use strict;
use Sys::Syslog ();

sub new {
	my($class, $package) = @_;
	Sys::Syslog::setlogsock('unix');
	Sys::Syslog::openlog($package, 'cons,pid', 'user');
	my $loglevel = 'info';
	bless \$loglevel, 'Device::Modem::Log::Syslog';
}

{

# Define log levels like syslog service
my %levels = ( debug => 7, info => 6, notice => 5, warning => 4, err => 3, crit => 2, alert => 1, emerg => 0 );

sub loglevel {
	my($self, $newlevel) = @_;

	if( defined $newlevel ) {
		$newlevel = lc $newlevel;
		if( $newlevel eq 'verbose' ) {
			$newlevel = 'info';
		}
		if( ! exists $levels{$newlevel} ) {
			$newlevel = 'notice';
		}
		$$self = $newlevel;

		# Set new logmask
		my $logmask = 0xFF; #(1 << ($levels{$newlevel} + 1)) - 1;
		Sys::Syslog::setlogmask( $logmask );

	} else {

		return $$self;

	}
}

sub write($$) {
	my($self, $level, @msg) = @_;
	Sys::Syslog::syslog( $level, @msg );
	return 1;
}

}

sub close {
	my $self = shift();
	Sys::Syslog::closelog();
}


1;

__END__

=head1 NAME

Device::Modem::Log::Syslog - Syslog logging plugin for Device::Modem class

=head1 SYNOPSIS

  use Device::Modem;

  my $box = new Device::Modem( log => 'syslog', ... );
  ...

=head1 DESCRIPTION

Example log class for B<Device::Modem> that logs all
modem activity, commands, ... to B<syslog>

It is loaded automatically at B<Device::Modem> startup,
only if you specify C<syslog> value to C<log> parameter.

If you don't have B<Sys::Syslog> additional module installed,
you will not be able to use this logging plugin, and you should
better leave the default logging (to text file).

=head2 REQUIRES

C<Sys::Syslog>

=head2 EXPORTS

None

=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 COPYRIGHT

(C) 2002 Cosimo Streppone, cosimo@cpan.org

This library is free software; you can only redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

C<Device::Modem>
C<Device::Modem::Log::File>

=cut
