package Log::AutoDump::Dummy;

use 5.006;

use strict;
use warnings;

=head1 NAME

Log::AutoDump::Dummy - Do nothing.

=head1 VERSION

Version 0.17

=cut

our $VERSION = '0.17';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

If a sub is hoping to be passed a log object, but isn't sure, use this as a fallback, so calls to C<debug()> for example don't cause errors.

 use Log::AutoDump::Dummy;

 my $log = $args{ log } || Log::AutoDump::Dummy->new;

=cut

=head1 DESCRIPTION

A dummy log object, that has the same methods, but does nothing;

=cut

=head1 METHODS

=head2 Class Methods

=head3 new

Creates a new dummy logger object.

 my $log = Log::AutoDump::Dummy->new;

=cut

sub new
{
    my ( $class, %args ) = @_;

    my $self = {};

    bless( $self, $class );
    
    return $self;
}

=head2 Instance Methods

=head3 msg

 $log->msg(2, "Hello");

This method expects a log level as the first argument, followed by a list of log messages/references/objects.

This is the core method called by the following (preferred) methods, using the below mapping...

 TRACE => 5
 DEBUG => 4
 INFO  => 3
 WARN  => 2
 ERROR => 1
 FATAL => 0

=cut

sub msg { return shift }

=head4 trace

 $log->trace( "Trace some info" );

A C<trace> statement is generally used for extremely low level logging, calling methods, getting into methods, etc.

=cut

sub trace { return shift }

=head4 debug

 $log->debug( "Debug some info" );

=cut

sub debug { return shift }

=head4 info

 $log->info( "Info about something" );

=cut

sub info { return shift }

=head4 warn

 $log->warn( "Something not quite right here" );

=cut

sub warn { return shift }

=head4 error

 $log->error( "Something went wrong" );

=cut

sub error { return shift }

=head4 fatal

 $log->fatal( "Looks like we died" );

=cut

sub fatal { return shift }


=head1 TODO

simple scripts (the caller stack)

extend to use variations of Data::Dumper




=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-autodump at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-AutoDump>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::AutoDump


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-AutoDump>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-AutoDump>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-AutoDump>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-AutoDump/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Log::AutoDump
