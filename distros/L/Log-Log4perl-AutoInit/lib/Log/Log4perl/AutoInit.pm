package Log::Log4perl::AutoInit;

use 5.008;
use strict;
use warnings FATAL => 'all';
use Log::Log4perl;

use base qw( Exporter );
our @EXPORT_OK = qw( init_log4perl get_logger );

=head1 NAME

Log::Log4perl::AutoInit - Log4Perl with autoinitialization.

=cut

our $VERSION = '1.0.2';

=head1 SYNOPSIS

 use Log::Log4perl::AutoInit qw(get_logger);
 Log::Log4perl::AutoInit->set_config('path/to/l4p.conf');

 get_logger->warning('l4p initialized and warning logged');

=head1 DESCRIPTION

This module provides a simple wrapper around Log::Log4perl for cases where
initialization may need to be delayed until a statup process is complete, but
where configuration may need to be registered before that point.  In essence
it provides a way to delay logger initialization until the logger is actually
needed or used.

A key use for this is for daemons where configuration may be set on loading a
Perl module, but where file handles may be subsequently closed.  This module
allows you to delay initialization until you are actually logging, with an
ability to initialize the logger at a specific point and reinitialize if
necessary.

=head1 EXPORT

=head2 get_logger


=head1 SUBROUTINES/METHODS

=head2 set_config

This API sets the configuration for subsequent logger initialization.  This
only caches the config and does no initialization itself.  This is safe to call
at any point in the program but if logging is already being done, you must
reinitialize (see initialize_now() below).

=cut

my $l4p_config;

sub set_config {
    $l4p_config = shift;
    $l4p_config = shift if $l4p_config eq __PACKAGE__;
    return;
}

=head2 set_default_category

Sets the default category for all future loggers.  If not found the callers'
module name is used.  To unset pass in undef.

=cut

my $default_category;

sub set_default_category {
    $default_category = shift;
    $default_category = shift if $default_category eq __PACKAGE__;
    return;
}

=head2 get_logger

Initializes, if necessary, and returns a logger with the identical syntax to
Log4perl::get_logger().  If you close the file handles out from under the
logger, you must reinitialize immediately after.  See initialize_now() below.

=cut

sub get_logger {
    my $category = shift;
    _init();
    $category = $default_category unless defined $category;
    $category = (caller)[0]       unless defined $category;
    return Log::Log4perl::get_logger($category);
}

my $initialized = 0;    # move to state when we can drop 5.8 support

=head2 initialize_now(bool $reinitialize);

This initializes Log4perl.  If $reinitialize is set, it allows Log4perl to be
explicitly reinitialized.  This can be used to force a reinitialization, for
example after file handles have been closed or after a configuration change.

=cut

sub initialize_now {
    my $re_init = shift;
    $re_init     = shift if $re_init eq __PACKAGE__;
    $initialized = 0     if $re_init;
    return _init();
}

# private method for for initialization

sub _init {
    return if $initialized;
    ++$initialized;
    return Log::Log4perl->init($l4p_config);
}

=head1 AUTHOR

Binary.com, C<< <perl@binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-log4perl-autoinit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Log4perl-AutoInit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Log4perl::AutoInit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-AutoInit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Log4perl-AutoInit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Log4perl-AutoInit>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Log4perl-AutoInit/>

=back


=head1 ACKNOWLEDGEMENTS

=cut

1;    # End of Log::Log4perl::AutoInit
