package Dir::Watch;

use warnings;
use strict;
use Cwd;

=head1 NAME

Dir::Watch - Watches the current directory for file additions or removals.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Dir::Watch;

    $dirwatch=Dir::Watch->new;

    if($dirwatch->check){
        print "There are new items\n";
    }

=head1 METHODS

=head2 new

This initiates the object.

    $dirwatch=Dir::Watch->new;

=cut

sub new{
	my %args;
#	if (defined($_[1])) {
#		%args=%{$_[1]};
#	}

	$args{dir}=cwd;

	my $self={ dir=>$args{dir} };
	bless $self;

	#get the stuff in the current directory
	opendir(NEWREAD, $args{dir});
	my @direntries=readdir(NEWREAD);
	closedir(NEWREAD);

	#builds the hash that will be used for checking
	my %dirhash;
	my $int=0;
	while(defined($direntries[$int])){
		$dirhash{$direntries[$int]}=1;

		$int++;
	}
	$self->{dirhash}=\%dirhash;
	
	return $self;
}

=head2 check

This checks for a new directories or files.

If any thing has been added or removed, true is returned.

If nothing has been added or removed, false is returned.

    if(!$dirwatch->check){
        print "There have been either files/directories added or removed.\n";
    }

=cut

sub check{
	my $self=$_[0];

	#get the stuff in the current directory
	opendir(CHECKREAD, $self->{dir});
	my @direntries=readdir(CHECKREAD);
	closedir(CHECKREAD);

	#builds the hash that will be used for checking
	my %dirhash;
	my $int=0;
	while(defined($direntries[$int])){
		$dirhash{$direntries[$int]}=1;

		$int++;
	}

	#check for anything new
	$int=0;
	while (defined($direntries[$int])) {
		if (!defined( $self->{dirhash}{ $direntries[$int] } )) {
			$self->{dirhash}=\%dirhash;
			return 1;
		}

		$int++;
	}

	#check for any thing removed
	$int=0;
	my @keys=keys(%{ $self->{dirhash} });
	while (defined( $keys[$int] )) {
		if (!defined( $dirhash{ $keys[$int] } )) {
			$self->{dirhash}=\%dirhash;
			return 1;
		}

		$int++;
	}

	#saves the dir hash for checking later
	$self->{dirhash}=\%dirhash;

	#return false as if we got here nothing new was found or old was removed
	return 0;
}

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dir-watch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dir-Watch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dir::Watch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dir-Watch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dir-Watch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dir-Watch>

=item * Search CPAN

L<http://search.cpan.org/dist/Dir-Watch/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Dir::Watch
