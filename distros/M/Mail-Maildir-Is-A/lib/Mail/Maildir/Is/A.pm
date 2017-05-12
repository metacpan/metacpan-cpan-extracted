package Mail::Maildir::Is::A;

use warnings;
use strict;

=head1 NAME

Mail::Maildir::Is::A - Checks if a directory is a mail directory or not.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';

=head1 METHODS

=head2 new

Initiates the object.

    my $foo=Mail::Maildir::Is::A->new;

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};
	my $method='new';
	
	my $self={
			  error=>undef,
			  errorString=>'',
			  module=>'Mail-Maildir-Is-a',
			  };
	bless $self;

	return $self;
}

=head2 isAmaildir

This returns true or false based on if specified directory is a maildir
or not.

    my $returned=$foo->isAmaildir('/somedir');
    if($foo->error){
        warn('Error:'.$self->error.':'.$self->errorString);
    }
    if(! $returned){
        print "It is a maildir."\n";
    }

=cut

sub isAmaildir{
	my $self=$_[0];
	my $dir=$_[1];
	my $method='isAmaildir';

	$self->errorblank;

	if (!defined( $dir )) {
		$self->{error}=3;
		$self->{errorString}='No directory specified';
		warn($self->{module}.' ',$method.':'.$self->error.': '.$self->{errorString});
		return undef;
	}

	if (! -e $dir) {
		$self->{error}=1;
		$self->{errorString}='The specified item does not exist';
		warn($self->{module}.' ',$method.':'.$self->error.': '.$self->{errorString});
		return undef;
	}

	if (! -d $dir) {
		$self->{error}=2;
		$self->{errorString}='The specified item does not exist';
		warn($self->{module}.' ',$method.':'.$self->error.': '.$self->{errorString});
		return undef;
	}

	#makes sure all the directories exist
	if (! -d $dir.'/new/') {
		return undef;
	}
	if (! -d $dir.'/cur/') {
		return undef;
	}
	if (! -d $dir.'/tmp/') {
		return undef;
	}

	return 1;
}

=head1 ERROR HANDLING METHODS

=head2 error

Returns the current error code and true if there is an error.

If there is no error, undef is returned.

    my $error=$foo->error;
    if($error){
        print 'error code: '.$error."\n";
    }

=cut

sub error{
    return $_[0]->{error};
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $zconf->{error}=undef;
    $zconf->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
	my $self=$_[0];
	
	$self->{error}=undef;
	$self->{errorString}="";
	
	return 1;
};

=head1 ERROR CODES

=head2 1

The item does not exist.

=head2 2

The item is not a directory.

=head2 3

No directory specified.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-maildir-is-a at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-Maildir-Is-A>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::Maildir::Is::A


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-Maildir-Is-A>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-Maildir-Is-A>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-Maildir-Is-A>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-Maildir-Is-A/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Zane C. Bowers.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Mail::Maildir::Is::A
