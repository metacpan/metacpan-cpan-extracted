package Git::Demo;
use strict;
use warnings;
use Git::Repository;
use Git::Demo::Story;

use Log::Log4perl;
use File::Util;
use IO::File;
use File::Temp;

=head1 NAME

Git::Demo - A way for scripting git demonstrations

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Allows playback of a Git story (a sequence of file modifications and git actions
by various characters) to demonstrate the capabilities of Git

Perhaps a little code snippet.

    use Git::Demo;
    ...
    my $demo = Git::Demo->new( $conf );
    $demo->play();

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new{
    my $class = shift;
    my $args = shift;

    foreach( qw/story_file/ ){
        if( ! $args->{$_} ){
            die( "Cannot start without $_ being defined\n" );
        }
    }

    my $self = {};

    # and the optionals
    foreach( qw/verbose/ ){
        $self->{$_} = $args->{$_};
    }

    $self->{conf} = $args;
    my $logger = Log::Log4perl->get_logger( "Git::Demo::Story" );
    $self->{logger} = $logger;

    if( $self->{verbose} ){
        $self->{logger}->info( "Running in verbose mode!" );
    }


    $self->{dir} = File::Temp->newdir( UNLINK => 1 );

    if( ! $self->{dir} ){
        die( "Could not create temporary directory to work in" );
    }
    $logger->info( "Working directory: $self->{dir}" );
    $self->{story} = Git::Demo::Story->new( { story_file => $args->{story_file},
                                              dir        => $self->{dir},
                                              verbose    => $self->{verbose},
                                            } );

    bless $self, $class;

    return $self;
}

sub play{
    my $self = shift;
    if( ! $self->{story} ){
        warn( "No story to play!" );
        return undef;
    }
    $self->{story}->play();
}


sub story{
    my $self = shift;
    return $self->{story};
}

sub save_story{
    my $self = shift;
    if( $self->{story} ){
        $self->{story}->save_story();
    }
}

sub dir{
    my $self = shift;
    return $self->{dir};
}


=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-git-demo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Git-Demo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Git::Demo


You can also look for information at:

=over 4

=item * Repository on Github

L<https://github.com/robin13/Git-Demo>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-Demo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Git-Demo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Git-Demo>

=item * Search CPAN

L<http://search.cpan.org/dist/Git-Demo/>

=back


=head1 ACKNOWLEDGEMENTS

L<http://git-scm.com/>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Git::Demo
