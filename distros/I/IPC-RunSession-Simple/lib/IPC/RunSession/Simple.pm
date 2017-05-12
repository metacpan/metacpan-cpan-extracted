package IPC::RunSession::Simple;

use warnings;
use strict;

=head1 NAME

IPC::RunSession::Simple - Run a simple IPC session in the same vein as IPC::Run & Expect

=head1 VERSION

Version 0.002

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

    use IPC::RunSession::Simple

    $session = IPC::RunSession::Simple->open( "fcsh" )

    # Read until the prompt (which doesn't end in a newline)
    # Timeout after 5 seconds
    $result = $session->read_until( qr/\(fcsh\) /, 5 )

    if ( $result->closed ) {
         # We encountered an (abnormal) EOF... 
    }
    elsif ( $result->expired ) {
        # The timeout got triggered...
    }
    else {
        print $result->content
    }

    # Tell 'fcsh' we want to quit
    $session->write( "quit\n" )

=head1 DESCRIPTION

A simple IPC session with read/write capability using L<IPC::Open3> and L<IO::Select>

=cut

use IPC::Open3 qw/ open3 /;
use Carp;

=head1 USAGE

=head2 $session = IPC::RunSession::Simple->open( $cmd )

Create a new session by calling C<open3> on $cmd

=cut

sub open {
    my $class = shift;
    my $cmd = shift;
    
    my ( $writer, $reader );

    # .., undef, ... means that the output (reader) and error handle will be on the same "stream"
    $cmd = [ $cmd ] unless ref $cmd eq 'ARRAY';
    open3 $writer, $reader, undef, @$cmd or croak "Unable to open3 \"$cmd\": $!";

    return IPC::RunSession::Simple::Session->new( writer => $writer, reader => $reader );
}

sub new {
    return shift->open( @_ );
}

sub run {
    return shift->open( @_ );
}

package IPC::RunSession::Simple::Session;

use Any::Moose;

use IO::Select;

has [qw/ writer reader /] => qw/is ro required 1/;
has _selector => qw/is ro lazy_build 1/;
sub _build__selector {
    my $self = shift;
    my $selector = IO::Select->new;
    $selector->add( $self->reader );
    return $selector;
}
has _read_amount => qw/is rw/, default => 10_000;

=head2 $result = $session->read( [ $timeout ] )

Read (blocking) until some output is gotten

If $timeout is given, then wait until output is gotten OR the timeout expires (setting $result->expired appropiately)

=cut

sub read {
    my $self = shift;
    my $timeout = shift;

    return $self->read_until( undef, $timeout );
}

=head2 $result = $session->read_until( $marker, [ $timeout ] )

Read (blocking) until some output matching $marker is gotten

$marker can either be a regular expression or a code block. If a code block is given, the content accumulated will be available as the first argument and as C<$_>

If $timeout is given, then wait until output is gotten OR the timeout expires (setting $result->expired appropiately). Any content collected up to the timeout will be included in $result->content

=cut

sub read_until {
    my $self = shift;
    my $marker = shift;
    my $timeout = shift;

    my $result = IPC::RunSession::Simple::Session::Result->new;
    my $content = '';

    while ( 1 ) {
        if ( $self->_selector->can_read( $timeout ) ) {

            my $read_size = sysread $self->reader, my $read, $self->_read_amount;
            if ( ! $read_size ) { # Reached EOF...
                $result->closed( 1 );
                last;
            }
            else {
                $content .= $read;
                last unless $marker;
                
                if ( ref $marker eq 'Regexp' ) {
                    last if $content =~ $marker;
                }
                elsif ( ref $marker eq 'CODE' ) {
                    local $_ = $content;
                    last if $marker->( $content );
                }
                else {
                    die "Don't understand marker ($marker)";
                }
            }
        }
        else {
            $result->expired( 1 );
            last;
        }
    }

    $result->content( $content );

    return $result;
}

=head2 $session->write( $content )

Write $content to the input of the opened process

=cut

sub write {
    my $self = shift;
    my $content = shift;

    my $writer = $self->writer;
    print $writer $content;
}

=head2 $reader = $session->reader

Return the reader filehandle (the STDOUT/STDERR of the process)

=head2 $writer = $session->writer

Return the writer filehandle (the STDIN of the process)

=cut

package IPC::RunSession::Simple::Session::Result;

use Any::Moose;

=head2 $result->content

The content read via C<read> or C<read_until>

=head2 $result->expired

True if a read returned as a result of taking longer than the specified timeout value

=head2 $result->closed

True if the process closed during the read

=cut

has [qw/ content closed expired /] => qw/is rw/;

=head1 SEE ALSO

L<IPC::Run>

L<Expect>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-runsession-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-RunSession-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::RunSession::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-RunSession-Simple>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-RunSession-Simple>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-RunSession-Simple>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC-RunSession-Simple/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of IPC::RunSession::Simple
