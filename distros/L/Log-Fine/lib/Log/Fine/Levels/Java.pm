
=head1 NAME

Log::Fine::Levels::Java - Provides levels correlating to java.utils.logging

=head1 SYNOPSIS

Defines log level values and masks correlating to those provided by
java.utils.logging

    use Log::Fine;
    use Log::Fine::Levels::Java;

    # Grab a logging object
    my $log = Log::Fine->getLogger("foo1");

    # Note that FINER and SEVERE are provided by the
    # Log::Fine::Levels::Java object
    $log->log(FINER, "I'm not mad at you, I'm mad at the dirt");
    $log->log(SEVERE, "No more wire hangers ... EVER!");

=head1 DESCRIPTION

Log::Fine::Levels::Java provides logging and mask constants mimicking
those provided by the C<java.utils.logging> framework as provided by
Java 1.5.0

=cut

use strict;
use warnings;

package Log::Fine::Levels::Java;

use AutoLoader;
use Carp;
use Exporter;
use POSIX qw( strftime );

use base qw/ Log::Fine::Levels Exporter /;

our $VERSION = $Log::Fine::Levels::VERSION;

# Necessary for AutoLoader
our $AUTOLOAD;

=head2 Log Levels

Log::Fine::Levels::Java bases its log levels on those provided by
C<java.util.logging.Levels>.  See
L<http://java.sun.com/j2se/1.5.0/docs/api/java/util/logging/Level.html>
for further specifics.

=over 4

=item * C<SEVERE>

=item * C<WARNING>

=item * C<INFO>

=item * C<CONFIG>

=item * C<FINE>

=item * C<FINER>

=item * C<FINEST>

=back

=cut

# Default level-to-value hash
use constant LVLTOVAL_MAP => {
                               SEVERE  => 0,
                               WARNING => 1,
                               INFO    => 2,
                               CONFIG  => 3,
                               FINE    => 4,
                               FINER   => 5,
                               FINEST  => 6,
};          # LVLTOVAL_MAP{}

# Default value-to-level hash
use constant VALTOLVL_MAP => {
                               LVLTOVAL_MAP->{SEVERE}  => "SEVERE",
                               LVLTOVAL_MAP->{WARNING} => "WARNING",
                               LVLTOVAL_MAP->{INFO}    => "INFO",
                               LVLTOVAL_MAP->{CONFIG}  => "CONFIG",
                               LVLTOVAL_MAP->{FINE}    => "FINE",
                               LVLTOVAL_MAP->{FINER}   => "FINER",
                               LVLTOVAL_MAP->{FINEST}  => "FINEST",
};          # VALTOLVL_MAP{}

=head2 Log Masks

Log masks can be exported for use in setting up individual handles
(see L<Log::Fine::Handle>).  The following masks are exported into the
caller namespace:

=over 4

=item * C<LOGMASK_SEVERE>

=item * C<LOGMASK_WARNING>

=item * C<LOGMASK_INFO>

=item * C<LOGMASK_CONFIG>

=item * C<LOGMASK_FINE>

=item * C<LOGMASK_FINER>

=item * C<LOGMASK_FINEST>

=back

See L<Log::Fine::Handle> for more information.

=cut

use constant MASK_MAP => {
                           LOGMASK_SEVERE  => 2 << LVLTOVAL_MAP->{SEVERE},
                           LOGMASK_WARNING => 2 << LVLTOVAL_MAP->{WARNING},
                           LOGMASK_INFO    => 2 << LVLTOVAL_MAP->{INFO},
                           LOGMASK_CONFIG  => 2 << LVLTOVAL_MAP->{CONFIG},
                           LOGMASK_FINE    => 2 << LVLTOVAL_MAP->{FINE},
                           LOGMASK_FINER   => 2 << LVLTOVAL_MAP->{FINER},
                           LOGMASK_FINEST  => 2 << LVLTOVAL_MAP->{FINEST},
};          # MASK_MAP{}

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

        # make sure we have a valid function
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

    perldoc Log::Fine::Levels::Java

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

L<perl>, L<syslog>, L<Log::Fine>, L<Log::Fine::Levels>, L<Sys::Java>,
L<http://java.sun.com/j2se/1.5.0/docs/api/java/util/logging/Level.html>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010, 2013 Christopher M. Fuhrman, 
All rights reserved.

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;          # End of Log::Fine::Levels::Java

__END__

