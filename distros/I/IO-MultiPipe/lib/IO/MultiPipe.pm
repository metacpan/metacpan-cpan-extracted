package IO::MultiPipe;

use IPC::Open3;
use warnings;
#use strict;

=head1 NAME

IO::MultiPipe - Allows for error checking on a command involving multiple pipes.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

Normally if a part of a pipe fails, depending on the location, it won't be
detected. This breaks down a command involving pipes and runs each command
seperately.

It uses open3 to run each chunk of the pipe.

    use IO::MultiPipe;

    my $pipes = IO::MultiPipe->new();
    
    #This sets the pipe that will be run.
    $pipes->set('sed s/-// | sed s/123/abc/ | sed s/ABC/abc/');
    if ($pipes->{error}){
        print "Error!\n";
    }
    
    #'123-ABCxyz' through the command set above.
    my $returned=$pipes->run('123-ABCxyz');

=head1 FUNCTIONS

=head2 new

Initializes the object.

=cut

sub new{

	my $self={error=>undef, errorString=>'', pipes=>[]};
	bless $self;

	return $self;
}

=head2 run

This runs the data through the pipe.

=cut

sub run{
	my $self=$_[0];
	my $data=$_[1];

	$self->errorBlank;

	if (!defined($self->{pipes}[0])) {
		warn('IO-MultiPipe run:3: No command has been set yet');
		$self->{error}=3;
		$self->{errorString}='No command has been set yet.';
	}

	#holds the returned data
	my $returned;

	#runs each one
	my $int=0;
	while (defined($self->{pipes}[$int])) {
		open3(PIPEWRITE, PIPEREAD, PIPEERROR, $self->{pipes}[$int]);
		if ($?) {
			warn('IO-MultiPipe run:4: Failed to open the command "'.$self->{pipes}[$int].'"');
			$self->{error}=4;
			$self->{errorString}='Failed to open the command "'.$self->{pipes}[$int].'"';
			return undef;
		}

		#If the int equals '0' it means this is the first path.
		if ($int eq '0') {
			print PIPEWRITE $data;
		}else {
			print PIPEWRITE $returned;
		}

		#If we don't close it here stuff like sed will fail.
		close PIPEWRITE;

		#reads the returned
		$returned=join('',<PIPEREAD>);

		#reads the error
		my $error=join('',<PIPEERROR>);

		#makes sure the command did error
		#It will always be equal to '' because of the join
		if ($error ne '') {
			warn('IO-MultiPipe run:5: The command "'.$self->{pipes}[$int].'" failed.'.
				 ' The returned error was "'.$error.'"');
			$self->{error}=5;
			$self->{errorString}='The command "'.$self->{pipes}[$int].'" failed.'.
			                     ' The returned error was "'.$error.'"';
			return undef;
		}

		close PIPEREAD;
		close PIPEERROR;

		$int++;
	}

	return $returned;
}

=head2 set

Sets the command that will be used.

    $pipes->set('sed s/-// | sed s/123/abc/ | sed s/ABC/abc/');
    if ($pipes->{error}){
        print "Error!\n";
    }

=cut

sub set{
	my $self=$_[0];
	my $command=$_[1];

	$self->errorBlank;

	if (!defined($command)) {
		warn('IO-MultiPipe set:1: No command specified');
		$self->{error}=1;
		$self->{errorString}='No command specified.';
		return undef;
	}

	my @commandSplit=split(/\|/, $command);

	#makes sure that all are defined
	my $int=0;
	while (defined($commandSplit[$int])) {
		#this happens when '||' is present in a string
		if (!defined($commandSplit[$int])) {
			warn('IO-MultiPipe set:2: The command "'.$command.'" contains a null section');
			$self->{error}=2;
			$self->{errorString}='The command "'.$command.'" contains a null section.';
			return undef;
		}

		$int++;
	}

	$self->{pipes}=[@commandSplit];

	return 1;
}

=head2 errorBlank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorBlank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 ERROR CODES

This is contained in '$pipe->{error}'. Any time this is true,
there is an error.

=head2 1

No command passed to the set function.

=head2 2

Command contains null section.

=head2 3

No command has been set yet. The 'set' needs called first before calling 'run'.

=head2 4

Opening the command failed.

=head2 5

The command errored.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-io-multipipe at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-MultiPipe>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::MultiPipe


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-MultiPipe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-MultiPipe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-MultiPipe>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-MultiPipe>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of IO::MultiPipe
