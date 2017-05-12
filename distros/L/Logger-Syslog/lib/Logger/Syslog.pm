package Logger::Syslog;

use strict;
use warnings;
use Carp;
use Sys::Syslog qw(:DEFAULT setlogsock); 
use File::Basename;

=head1 NAME

Logger::Syslog -- an intuitive wrapper over Syslog for Perl 

=head1 DESCRIPTION

You want to deal with syslog, but you don't want to bother with Sys::Syslog, 
that module is for you.

Logger::Syslog takes care of everything regarding the Syslog communication, all
you have to do is to use the function you need to send a message to syslog.

Logger::Syslog provides one function per Syslog message level: debug, info, 
warning, error, notice, critic, alert.

=head1 NOTES

Logger::Syslog is compliant with mod_perl, all you have to do when using it 
in such an environement is to call logger_init() at the beginning of your CGI,
that will garantee that everything will run smoothly (otherwise, issues with 
the syslog socket can happen in mod_perl env).

=head1 SYNOPSIS

    use Logger::Syslog;

    info("Starting at ".localtime());
    ...
    if ($error) {
        error("An error occured!");
        exit 1;
    }
    ...
    notice("There something to notify");
     
=cut

BEGIN {
	use Exporter ;
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %SIG);
	$VERSION = "1.1";
	@ISA = ( 'Exporter' ) ;
	@EXPORT = qw (
		&debug
		&info
		&notice
		&warning
		&error
		&critic
		&alert
		&logger_prefix
		&logger_close
		&logger_init
        &logger_set_default_facility
	);
	@EXPORT_OK=@EXPORT;
	%EXPORT_TAGS = (":all"=>[],);
}

sub __get_script_name();
my  $DEFAULT_FACILITY = "user";
our $fullname = __get_script_name();
our $basename = basename($fullname);

=head1 FUNCTIONS

=head2 logger_init

Call this to explicitly open a Syslog socket. You can optionaly specify 
a Syslog facility.

That function is called when you use the module, if you're not in a mod_perl 
environement.

Examples: 

    # open a syslog socket with default facility (user)
    logger_init();

    # open a syslog socket on the 'local' facility
    logger_init('local');

=cut

sub logger_init(;$)
{
    my ($facility) = @_;
    $facility = $DEFAULT_FACILITY unless defined $facility;

    eval {
        setlogsock('unix');
        $fullname = __get_script_name();
        openlog($fullname, 'pid', $facility);
        logger_prefix("");
    };
}

# If we're not under mod_perl, let's open the Syslog socket.
if (! defined $ENV{'MOD_PERL'}) {
    logger_init();
}

=head2 logger_close

Call this to close the Syslog socket.

That function is called automatically when the calling program exits.

=cut

sub logger_close()
{
    eval {
        closelog();
    };
}

END {
    eval {        
	    logger_close();
    };
}

=head2 logger_prefix

That function lets you set a string that will be prefixed to every 
messages sent to syslog.

Example:
  
    logger_prefix("my program");
    info("starting");
    ...
    info("stopping");

=cut

our $g_rh_prefix = {};
sub logger_prefix(;$)
{
        my ($prefix) = @_;
        $prefix = "" unless defined $prefix;
        $fullname = __get_script_name();
        $g_rh_prefix->{$fullname} = $prefix;
}

my %g_rh_label = (
	info    => 'info ',
	notice  => 'note ',
	err     => 'error',
	warning => 'warn ',
	debug   => 'debug',
	crit    => 'crit ',
	alert   => 'alert'
);


=head2 logger_set_default_facility(facility)

You can choose which facility to use, the default one is "user".  Use that
function if you want to switch smoothly from a facility to another.  

That function will close the existing socket and will open a new one with the
appropriate facility.

Example:

    logger_set_default_facility("cron");

=cut

sub logger_set_default_facility($)
{
    my ($facility) = @_;
    if ($facility ne $DEFAULT_FACILITY) {
        logger_close();
        logger_init($facility);
    }
}

=head1 LOGGING

Logger::Syslog provides one function per Syslog level to let you send messages.
If you want to send a debug message, just use debug(), for a warning, use
warning() and so on...

All those function have the same signature : thay take a string as their only
argument, which is the message to send to syslog.

Examples:

    debug("my program starts at ".localtime());
    ...
    warning("some strange stuff occured");
    ...
    error("should not go there !");
    ...
    notice("Here is my notice");

=cut

sub AUTOLOAD 
{
	my ($message) = @_;
	our $AUTOLOAD;
	$AUTOLOAD =~ s/^.*:://;
	return if ($AUTOLOAD eq 'DESTROY');

	return 0 unless defined $message and length $message;
    my @supported = qw(debug info warning err error notice alert crit critic);

	if (grep /^$AUTOLOAD$/, @supported) {
        my $level = $AUTOLOAD;

        $level = 'err' if ($level eq 'error');
        $level = 'crit' if ($level eq 'critic');

        log_with_syslog($level, $message);
    }
    else {
        croak "Unsupported function : $AUTOLOAD";
    }
}
		
sub log_with_syslog ($$)
{
	my ($level, $message) = @_;
	return 0 unless defined $level and defined $message;
	
	my $caller = 2;
	if ($ENV{MOD_PERL}) {
		$caller = 1;
	}
	my ($package, $filename, $line, $fonction) = caller ($caller);

	$package  = "" unless defined $package;
	$filename = "" unless defined $filename;
	$line     = 0 unless defined $line;
	$fonction = $basename unless defined $fonction;
	$level = lc($level);
	$level = 'info' unless defined $level and length $level;
	
	unless (defined $message and length $message) { 
		$message = "[void]";
	}

	my $level_str = $g_rh_label{$level};
	$message  = $level_str . " * $message";
	$message .= " - $fonction ($filename l. $line)" if $line;

	$message =~ s/%/%%/g; # we have to escape % to avoid a bug related to sprintf()
	$message = $g_rh_prefix->{$fullname} . " > " . $message if 
        (defined $g_rh_prefix->{$fullname} and length $g_rh_prefix->{$fullname}); 

    my $sig = $SIG{__WARN__};
    $SIG{__WARN__} = sub {};
	eval {
        syslog($level, $message);
    };
    $SIG{__WARN__} = $sig;
}

# returns the appropriate filename
sub __get_script_name()
{
        # si on est en mod perl, il faut utiliser $ENV{'SCRIPT_FILENAME'}
        return $ENV{'SCRIPT_FILENAME'} if $ENV{'MOD_PERL'} and $ENV{'SCRIPT_FILENAME'};
        return $0;
}

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 COPYRIGHT

This program is copyright © 2004-2006 Alexis Sukrieh

=head1 AUTHOR

Alexis Sukrieh <sukria@sukria.net>

Very first versions were made at Cegetel (2004-2005) ; Thomas Parmelan gave a
hand for the mod_perl support.

=cut

1;
