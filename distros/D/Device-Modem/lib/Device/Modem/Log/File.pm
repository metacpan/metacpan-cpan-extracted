# Device::Modem::Log::File - Text files logging plugin for Device::Modem class
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
#
package Device::Modem::Log::File;
$VERSION = sprintf '%d.%02d', q$Revision: 2.1 $ =~ /(\d+)\.(\d+)/;

use strict;
use File::Path     ();
use File::Basename ();
	
# Define log levels like syslog service
use vars '%levels';
%levels = ( debug => 7, info => 6, notice => 5, warning => 4, err => 3, error => 3, crit => 2, alert => 1, emerg => 0 );

sub new {
	my( $class, $package, $filename ) = @_;

	# Get a decent default if no file available
	$filename ||= default_filename();

	my %obj = (
		file => $filename,
		loglevel => 'info'
	);

	my $self = bless \%obj, 'Device::Modem::Log::File';
	
	# Open file at the start and save reference	
	if( open( LOGFILE, '>>'.$self->{'file'} ) ) {

		$self->{'fh'} = \*LOGFILE;

		# Unbuffer writes to logfile
		my $oldfh = select $self->{'fh'};
		$| = 1;
		select $oldfh;

	} else {
		warn('Could not open '.$self->{'file'}.' to start logging');
	}

	return $self;
}

# Provide a suitable filename default
sub default_filename () {
	my $dir = '/tmp';

	# If this is windows, use the temp/tmp dirs
	if (exists $ENV{'TEMP'} || exists $ENV{'TMP'}) {
		$dir = $ENV{'TEMP'} || $ENV{'TMP'};
	}

	return "$dir/modem.log";
}

sub filename {
	my $self = shift();
	$self->{'file'} ||= $self->default_filename();

	if( ! -d File::Basename::dirname($self->{'file'}) ) {
		File::Path::mkpath( File::Basename::dirname($self->{'file'}), 0, 0755 );
	}

	return $self->{'file'};
}


sub loglevel {
	my($self, $newlevel) = @_;

	if( defined $newlevel ) {
		$newlevel = lc $newlevel;
		if( ! exists $levels{$newlevel} ) {
			$newlevel = 'warning';
		}
		$self->{'loglevel'} = $newlevel;
	} else {
		return $self->{'loglevel'};
	}
}

sub write($$) {

	my($self, $level, @msg) = @_;

	# If log level mask allows it, log given message
	#warn('message level='.$level.' ('.$levels{$level}.')    loglevel='.$self->{loglevel}.' ('.$levels{$self->{loglevel}}.')');
	if( $levels{$level} <= $levels{$self->{'loglevel'}} ) {

		if( my $fh = $self->fh() ) {
			map { tr/\r\n/^M/s } @msg;
			print $fh join("\t", scalar localtime, $0, $level, @msg), "\n";
		} else {
			warn('cannot log '.$level.' '.join("\t",@msg).' to file: '.$! );
		}

	}

}

sub fh {
	my $self = shift;
	return $self->{'fh'};
}

# Closes log file opened in new() 
sub close {
	my $self = shift;
	my $fh = $self->{'FH'};
	close $fh;
	undef $self->{'FH'};
}

1;



__END__



=head1 NAME

Device::Modem::Log::File - Text files logging plugin for Device::Modem class

=head1 SYNOPSIS

  use Device::Modem;

  my $box = Device::Modem->new( log => 'file', ... );
  my $box = Device::Modem->new( log => 'file,name=/tmp/mymodem.log', ... );
  ...

=head1 DESCRIPTION

This is meant for an example log class to be hooked to C<Device::Modem>
to provide one's favourite logging mechanism.
You just have to implement your own C<new()>, C<write()> and C<close()> methods.

Default text file is C</tmp/modem.log>. On Windows platforms, this
goes into C<%TEMP%/modem.log> or C<%TMP%/modem.log>, whichever is defined.
By default, if the folder of the log file does not exist, it is created.

This class is loaded automatically by C<Device::Modem> class when an object
is instantiated, and it is the B<default> logging mechanism for
C<Device::Modem> class.

Normally, you should B<not> need to use this class directly, because there
are many other zillions of modules that do logging better than this.

Also, it should be pondered whether to replace C<Device::Modem::Log::File>
and mates with those better classes in a somewhat distant future.

=head2 REQUIRES

Device::Modem

=head2 EXPORTS

None

=head1 AUTHOR

Cosimo Streppone, cosimo@cpan.org

=head1 COPYRIGHT

(C) 2002 Cosimo Streppone, <cosimo@cpan.org>

This library is free software; you can only redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Device::Modem>
L<Device::Modem::Log::Syslog>

=cut
