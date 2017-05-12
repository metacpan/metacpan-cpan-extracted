package File::Permissions::Unix;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

File::Permissions::Unix - A simple object oriented interface to handling file permissions.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use File::Permissions::Unix;
    
    my $foo=File::Permissions::Unix->new('0640');
    
    #chmods a /tmp/foo with 0640
    $foo->chmod('/tmp/foo');

    #do the same thing as above, but check if it worked
    $foo->chmod('/tmp/foo');
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

    #copies the mode from /tmp/foo to /tmp/bar
    $foo->setModeFromFile('/tmp/foo');
    $foo->chmod('/tmp/bar');

    #prints the current mode
    print $foo->getMode."\n";

=head1 METHODS

=head2 new

This initiates the object.

One arguement is accepted. It is the mode
to intialize the object with. If not specified
it defaults to '0644'.

    my $foo=File::Permissions::Unix->new($mode);
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);	
    }

=cut

sub new{
	my $mode=$_[1];
	
	if ( ! defined( $mode ) ){
		$mode='0644';
	}

	my $self={
		mode=>$mode,
		perror=>undef,
		error=>undef,
		errorString=>'',
	};
	bless $self;
	
	# make sure it is a valid mode
	if ( $self->{mode} !~  /^[01246][01234567][01234567][01234567]$/ ){
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}='';
		return $self;
	}
	
	return $self;
}

=head2 chmod

This chmods a file with the current mode.

One argument is required and it the file/directory/etc in question.

    $foo->chmod($file);
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
	}

=cut

sub chmod{
	my $self=$_[0];
	my $file=$_[1];

    $self->errorblank;
    if ( $self->error ){
        return undef;
    }

	#make sure the file is defined
	if( ! defined( $file ) ){
		$self->{error}=2;
		$self->{errorString}='No file specified';
		return undef;
	}

	#try to chmod the file
	if( ! chmod( oct($self->{mode}), $file )){
		$self->{error}=4;
        $self->{errorString}='Unable to chmod "'.$file.'" with "'.$self->{mode}.'"';
        return undef;
	}

	return 1;
}

=head2 getMode

This returns the current mode.

    my $mode=$foo->getMode;

=cut

sub getMode{
	my $self=$_[0];

	$self->errorblank;
	if ( $self->error ){
		return undef;
	}

	return $self->{mode};
}

=head2 setMode

This changes the currently set mode.

One argument is accepted and it is the current mode.

	$foo->setMode('0640')';
    if($foo->error){
	    warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setMode{
	my $self=$_[0];
	my $mode=$_[1];

	$self->errorblank;
    if ( $self->error ){
        return undef;
    }
	
	# make sure it is a valid mode
	if ( $mode !~  /^[01246][01234567][01234567][01234567]$/ ){
		$self->{error}=1;
		$self->{errorString}='"'.$mode.'" is not a valid mode';
		return $self;
	}

	$self->{mode}=$mode;

	return 1;
}

=head2 setModeFromFile

This sets the current mode from a file.

One argument is required and it the file/directory/etc in question.

    $foo->setModeFromFile($file);
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setModeFromFile{
	my $self=$_[0];
	my $file=$_[1];
	
	$self->errorblank;
	if ( $self->error ){
		return undef;
	}

	#make sure the file is defined
	if( ! defined( $file ) ){
		$self->{error}=2;
		$self->{errorString}='No file specified';
		return undef;
	}

	#stat the file and get it
	my $mode = (stat($file))[2] & 07777;
	if ( !defined( $mode ) ){
		$self->{error}=5;
		$self->{errorString}='Failed to stat the file "'.$file.'"';
		return $self;
	}
	$mode=sprintf("%04o", $mode);

	$self->{mode}=$mode;

	return 1;
}

=head1 ERROR CODES

=head2 1

Invalid mode.

This means it did not match the regexp below.

    /^[01246][01234567][01234567][01234567]$/

=head2 2

No file specified.

=head2 3

The file does not exist.

This has been depreciated as it introduces a possible race condition.

=head2 4

Failed to chmod the file.

=head2 5

Failed too stat the file.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-permissions-unix at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Permissions-Unix>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Permissions::Unix


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Permissions-Unix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Permissions-Unix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Permissions-Unix>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Permissions-Unix/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of File::Permissions::Unix
