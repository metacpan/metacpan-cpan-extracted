package File::Ownership::Unix;

use warnings;
use strict;
use base 'Error::Helper';

=head1 NAME

File::Ownership::Unix - A object oriented system for working with file ownership under unix.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 SYNOPSIS

    use File::Ownership::Unix;
    
    my $foo=File::Ownership::Unix->new( 1001, 1001 );

    #gets the ownership info for a file
    $foo->setFromFile('/tmp/foo');

    #chowns a file using the current [GU]ID
    $foo->chown('/tmp/bar');

    #copies the ownership info from one file to another
    $foo->setFromFile('/tmp/foo');
    $foo->chown('/tmp/bar');

=head1 METHODS

=head2 new

This initiates the object.

There are two optional arguments taken. The first
one is the UID and the second is the GID.

Both default to zero.

    my $foo=File::Ownership::Unix->new;
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub new{
	my $uid=$_[1];
	my $gid=$_[2];

	my $self={
		perror=>undef,
		error=>undef,
		errorString=>'',
		uid=>0,
		gid=>0,
	};
	bless $self;

	if(defined($uid)){
		$self->{uid}=$uid;
	}
	if(defined($gid)){
		$self->{gid}=$gid;
	}

	if( $self->{gid} !~ /[0123456789]*/ ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='"'.$self->{gid}.'" is not a valid value for GID';
		return $self;
	}
	
	if( $self->{uid} !~ /[0123456789]*/ ){
		$self->{perror}=1;
		$self->{error}=1;
		$self->{errorString}='"'.$self->{uid}.'" is not a valid value for the UID';
		return $self;
	}

	return $self;
}

=head2 chown

This chowns the specified file.

    $foo->chown('/tmp/foo');
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub chown{
    my $self=$_[0];
	my $file=$_[1];

	$self->errorblank;
	if($self->error){
		return undef;
	}

	if(!defined($file)){
		$self->{error}=2;
		$self->{errorString}='No file specified';
		return undef;
	}

	if (! -e $file){
		$self->{error}=3;
		$self->{errorString}='"'.$file.'" does not exist';
		return undef;
	}

	if(!chown( $self->{uid}, $self->{gid}, $file )){
		$self->{error}=4;
		$self->{errorString}='Failed to chown "'.$file.'" to "'.$self->{uid}.':'.$self->{gid}.'"';
		return undef;
	}

	return 1;
}

=head2 getGID

This returns the currently set GID.

    my $gid=$foo->getGID;

=cut

sub getGID{
	my $self=$_[0];

	$self->errorblank;
	if($self->error){
		return undef;
	}

	return $self->{gid};
}

=head2 getUID

This returns the currently set UID.

    my $gid=$foo->getGID;

=cut

sub getUID{
    my $self=$_[0];

    $self->errorblank;
    if($self->error){
        return undef;
    }

    return $self->{uid};
}

=head2 setGID

This sets the current GID.

    $foo->setGID('1001');
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setGID{
    my $self=$_[0];
	my $gid=$_[1];

    $self->errorblank;
    if($self->error){
        return undef;
    }

	if( $gid !~ /[0123456789]*/ ){
		$self->{error}=1;
		$self->{errorString}='"'.$gid.'" is not a valid value for GID';
		return $self;
	}

	$self->{gid}=$gid;

    return 1;
}

=head2 setUID

This sets the current UID.

    $foo->setUID('1001');
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setUID{
    my $self=$_[0];
    my $uid=$_[1];

    $self->errorblank;
    if($self->error){
        return undef;
    }

    if( $uid !~ /[0123456789]*/ ){
        $self->{error}=1;
        $self->{errorString}='"'.$uid.'" is not a valid value for UID';
        return $self;
    }

    $self->{uid}=$uid;

    return 1;
}

=head2 setFromFile

This sets the current [GU]ID from the specified file.

	$foo->setFromFile('/tmp/foo');
    if( $foo->error ){
        warn('error:'.$foo->error.': '.$foo->errorString);
    }

=cut

sub setFromFile{
	my $self=$_[0];
	my $file=$_[1];

    $self->errorblank;
    if($self->error){
        return undef;
    }
	
	if(!defined($file)){
		$self->{error}=2;
		$self->{errorString}='No file specified';
		return undef;
	}

	if (! -e $file){
		$self->{error}=3;
		$self->{errorString}='"'.$file.'" does not exist';
		return undef;
	}

	$self->{uid}=(stat($file))[4];
	$self->{gid}=(stat($file))[5];

	return 1;
}

=head1 ERROR CODES

=head2 1

Invalid value for a [GU]ID.

=head2 2

No file specified.

=head2 3

The specified file does not exist.

=head2 4

Failed to cown the specified file.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-ownership-unix at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Ownership-Unix>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Ownership::Unix


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Ownership-Unix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Ownership-Unix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Ownership-Unix>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Ownership-Unix/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Zane C. Bowers-Hadley.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of File::Ownership::Unix
