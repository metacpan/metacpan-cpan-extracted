package File::Syslogger;

use 5.006;
use strict;
use warnings;
use POE qw(Wheel::FollowTail);
use Log::Syslog::Fast ':all';
use Sys::Hostname;

=head1 NAME

File::Syslogger - Use POE to tail a file and read new lines into syslog.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

=head1 SYNOPSIS

    use File::Syslogger;

    File::Syslogger->run(
                         pri=>'alert',
                         facility=>'daemon',
                         files=>{
                                 {'sagan_eve'}=>{file=>'/var/log/sagan/eve', program=>'saganEve'},
                                 {'suricata_eve'}=>{file=>'/var/log/suricata/eve', program=>'suricataEve'},
                                 },
                         );

=head1 METHODS

=head2 run

Initiates POE sessions and run them.

This will die if there are any config issues.

The following options are optionaal.

    priority - The priority of the logged item.
          Default is 'notice'.
    
    facility - The facility for logging.
               Default is 'daemon'.
    
    program - Name of the program logging.
              Default is 'fileSyslogger'.
    
    socket - The syslogd socket.
             Default is "/var/run/log"

The option files is a hash of hashes. It has one mandatory
key, 'file', which is the file to follow. All the above
options may be used in the sub hashes.

For priority, below are the various valid values.

    emerg
    emergency
    alert
    crit
    critical
    err
    error
    warning
    notice
    info

For facility, below are the various valid values.

    kern
    user
    mail
    daemon
    auth
    syslog
    lpr
    news
    uucp
    cron
    authpriv
    ftp
    local0
    local1
    local2
    local3
    local4
    local5
    local6
    local7

File rotation should be picked up POE::Wheel::FollowTail.

=cut

sub run {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{files} ) ) {
		die('"files" is not defined');
	}

	if ( ref( $opts{files} ) ne 'HASH' ) {
		die("$opts{files} is not a hash");
	}

	if ( !defined( $opts{program} ) ) {
		$opts{program} = 'fileSyslogger';
	}

	if (!defined( $opts{socket} )) {
		$opts{socket}="/var/run/log";
	}

	#mapping for severity for constant handling
	my %sev_mapping = (
		'emerg'     => LOG_EMERG,
		'emergency' => LOG_EMERG,
		'alert'     => LOG_ALERT,
		'crit'      => LOG_CRIT,
		'critical'  => LOG_CRIT,
		'err'       => LOG_ERR,
		'error'     => LOG_ERR,
		'warning'   => LOG_WARNING,
		'notice'    => LOG_NOTICE,
		'info'      => LOG_INFO,
	);

	# default to info if none is specified
	if ( !defined( $opts{priority} ) ) {
		$opts{priority} = "notice";
	}
	else {
		# one was specified, convert to lower case and make sure it valid
		$opts{priority} = lc( $opts{priority} );
		if ( !defined( $sev_mapping{ $opts{priority} } ) ) {
			die( '"' . $opts{priority} . '" is not a known priority' );
		}
	}

	#mapping for facility for constant handling
	my %fac_mapping = (
		'kern'     => LOG_KERN,
		'user'     => LOG_USER,
		'mail'     => LOG_MAIL,
		'daemon'   => LOG_DAEMON,
		'auth'     => LOG_AUTH,
		'syslog'   => LOG_SYSLOG,
		'lpr'      => LOG_LPR,
		'news'     => LOG_NEWS,
		'uucp'     => LOG_UUCP,
		'cron'     => LOG_CRON,
		'authpriv' => LOG_AUTHPRIV,
		'ftp'      => LOG_FTP,
		'local0'   => LOG_LOCAL0,
		'local1'   => LOG_LOCAL1,
		'local2'   => LOG_LOCAL2,
		'local3'   => LOG_LOCAL3,
		'local4'   => LOG_LOCAL4,
		'local5'   => LOG_LOCAL5,
		'local6'   => LOG_LOCAL6,
		'local7'   => LOG_LOCAL7,
	);

	# default to system if none is specified
	if ( !defined( $opts{facility} ) ) {
		$opts{facility} = 'daemon';
	}
	else {
		# one was specified, convert to lower case and make sure it valid
		$opts{facility} = lc( $opts{facility} );
		if ( !defined( $fac_mapping{ $opts{facility} } ) ) {
			die( '"' . $opts{facility} . '" is not a known facility' );
		}
	}

	# process each file and setup the syslogger
	my $file_count = 0;
	foreach my $item ( keys( %{ $opts{files} } ) ) {

		# make sure we have a file specified
		if ( !defined( $opts{files}{$item}{file} ) ) {
			die( 'No file specified for "' . $item . '"' );
		}

		# figure out what facility to use for this item
		my $item_fac;
		if ( defined( $opts{files}{$item}{facility} ) ) {

			# make sure it is valid
			$item_fac = lc( $opts{files}{$item}{facility} );
			if ( !defined( $fac_mapping{ $opts{facility} } ) ) {
				die( '"' . $item_fac . '" in "' . $item . '" is not a known facility' );
			}
		}
		else {
			# none specified, so using default
			$item_fac = $opts{facility};
		}
		$item_fac=$fac_mapping{$item_fac};

		# figure out what facility to use for this item
		my $item_pri;
		if ( defined( $opts{files}{$item}{priority} ) ) {

			# make sure it is valid
			$item_pri = lc( $opts{files}{$item}{priority} );
			if ( !defined( $fac_mapping{$item_pri} ) ) {
				die( '"' . $item_pri . '" in "' . $item . '" is not a known facility' );
			}
		}
		else {
			# none specified, so using default
			$item_pri = $opts{priority};
		}
		$item_pri=$sev_mapping{$item_pri};

		# figure out what program name to use
		my $item_program;
		if ( defined( $opts{files}{$item}{program} ) ) {
			$item_program = $opts{files}{$item}{program};
		}
		else {
			# none specified, so using default
			$item_program = $opts{program};
		}

		# create the logger that will be used by the POE session
		my $logger = Log::Syslog::Fast->new( LOG_UNIX, $opts{socket}, 1, $item_fac, $item_pri, hostname, $item_program );

		# create the POE session
		POE::Session->create(
			inline_states => {
				_start => sub {
					$_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
						Filename   => $_[HEAP]{file},
						InputEvent => "got_log_line",
					);
				},
				got_log_line => sub {
					$_[HEAP]{logger}->send( $_[ARG0] );
				},
			},
			heap => { file => $opts{files}{$item}{file}, logger => $logger },
		);

		$file_count++;
	}

	if ( $file_count == 0 ) {
		die("No files specified");
	}

	POE::Kernel->run;
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-syslogger at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Syslogger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Syslogger


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Syslogger>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/File-Syslogger>

=item * Search CPAN

L<https://metacpan.org/release/File-Syslogger>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of File::Syslogger
