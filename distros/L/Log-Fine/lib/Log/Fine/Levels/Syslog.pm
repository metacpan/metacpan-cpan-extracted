
=head1 NAME

Log::Fine::Levels::Syslog - Provides levels correlating to those provided by Syslog

=head1 SYNOPSIS

Defines log level values and masks correlating to those provided by
Syslog.

    use Log::Fine;
    use Log::Fine::Levels::Syslog;

    # Grab a logging object
    my $log = Log::Fine->getLogger("foo0");

    # Note that INFO and EMER are provided by the
    # Log::Fine::Levels::Syslog object
    $log->log(INFO, "I'm not mad at you, I'm mad at the dirt");
    $log->log(EMER, "No more wire hangers ... EVER!");

Note that this is the default class for L<Log::Fine::Levels>.

=head1 DESCRIPTION

Log::Fine::Levels::Syslog provides logging and mask constants
mimicking those provided by the classic UNIX L<syslog(3)> utility.
This class is also used internally by the L<Log::Fine> utility for
interpreting log levels.

=cut

use strict;
use warnings;

package Log::Fine::Levels::Syslog;

use AutoLoader;
use Carp;
use Exporter;
use POSIX qw( strftime );

use base qw/ Log::Fine::Levels Exporter /;

our $VERSION = $Log::Fine::Levels::VERSION;

# Necessary for AutoLoader
our $AUTOLOAD;

=head2 Log Levels

Log::Fine::Levels::Syslog bases its log levels on those found in
L<Sys::Syslog>.  The following are exported into the caller
namespace:

=over 4

=item * C<EMER>

=item * C<ALRT>

=item * C<CRIT>

=item * C<ERR>

=item * C<WARN>

=item * C<NOTI>

=item * C<INFO>

=item * C<DEBG>

=back

=cut

# Default level-to-value hash
use constant LVLTOVAL_MAP => {
                               EMER => 0,
                               ALRT => 1,
                               CRIT => 2,
                               ERR  => 3,
                               WARN => 4,
                               NOTI => 5,
                               INFO => 6,
                               DEBG => 7
};          # LVLTOVAL_MAP{}

# Default value-to-level hash
use constant VALTOLVL_MAP => {
                               LVLTOVAL_MAP->{EMER} => "EMER",
                               LVLTOVAL_MAP->{ALRT} => "ALRT",
                               LVLTOVAL_MAP->{CRIT} => "CRIT",
                               LVLTOVAL_MAP->{ERR}  => "ERR",
                               LVLTOVAL_MAP->{WARN} => "WARN",
                               LVLTOVAL_MAP->{NOTI} => "NOTI",
                               LVLTOVAL_MAP->{INFO} => "INFO",
                               LVLTOVAL_MAP->{DEBG} => "DEBG"
};          # VALTOLVL_MAP{}

=head2 Log Masks

Log masks can be exported for use in setting up individual handles
(see L<Log::Fine::Handle>).  The following masks are exported into the
caller namespace:

=over 4

=item * C<LOGMASK_EMERG>

=item * C<LOGMASK_ALERT>

=item * C<LOGMASK_CRIT>

=item * C<LOGMASK_ERR>

=item * C<LOGMASK_WARNING>

=item * C<LOGMASK_NOTICE>

=item * C<LOGMASK_INFO>

=item * C<LOGMASK_DEBUG>

=back

See L<Log::Fine::Handle> for more information.

=cut

use constant MASK_MAP => {
                           LOGMASK_EMERG   => 2 << LVLTOVAL_MAP->{EMER},
                           LOGMASK_ALERT   => 2 << LVLTOVAL_MAP->{ALRT},
                           LOGMASK_CRIT    => 2 << LVLTOVAL_MAP->{CRIT},
                           LOGMASK_ERR     => 2 << LVLTOVAL_MAP->{ERR},
                           LOGMASK_WARNING => 2 << LVLTOVAL_MAP->{WARN},
                           LOGMASK_NOTICE  => 2 << LVLTOVAL_MAP->{NOTI},
                           LOGMASK_INFO    => 2 << LVLTOVAL_MAP->{INFO},
                           LOGMASK_DEBUG   => 2 << LVLTOVAL_MAP->{DEBG} };          # MASK_MAP{}

# --------------------------------------------------------------------

# grab appropriate refs
my $levels = LVLTOVAL_MAP;
my $masks  = MASK_MAP;

# Exported tags
our %EXPORT_TAGS = (macros => [ keys %{$levels} ],
                    masks  => [ keys %{$masks} ]);          # EXPORT_TAGS

# Exported macros
our @EXPORT    = (@{ $EXPORT_TAGS{macros} });
our @EXPORT_OK = (@{ $EXPORT_TAGS{masks} });

# functions okay to export
our %ok_fields = (%{$levels}, %{$masks});

# --------------------------------------------------------------------

=head1 CONSTRUCTOR

=head2 new

Returns a newly constructed object

=cut

sub new
{

        my $class = shift;
        return bless { levelclass => $class }, $class;

}          # new()

# Autoloader
# --------------------------------------------------------------------

sub AUTOLOAD
{

        # Get the method name
        my $name = $AUTOLOAD;

        # Strip out package prefix
        $name =~ s/.*://;

        # Return on DESTROY
        return if $name eq 'DESTROY';

        # Make sure we have a valid function
        croak(
               sprintf("[%s] {%s} FATAL : %s\n",
                       strftime("%c", localtime(time)),
                       $AUTOLOAD, "Invalid function name : $name"
               )) unless (exists $ok_fields{$name});

        # Evaluate and return the appropriate level
        eval "sub $name { return $ok_fields{$name} }";
        goto &$name;

}          # AUTOLOAD()

=head1 BUGS

Please report any bugs or feature requests to
C<bug-log-fine at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Fine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Fine::Levels::Syslog

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fine>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Fine>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Fine>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Fine>

=back

=head1 AUTHOR

Christopher M. Fuhrman, C<< <cfuhrman at pobox.com> >>

=head1 SEE ALSO

L<perl>, L<syslog>, L<Log::Fine>, L<Log::Fine::Levels>, L<Sys::Syslog>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009, 2010, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Levels::Syslog

__END__

