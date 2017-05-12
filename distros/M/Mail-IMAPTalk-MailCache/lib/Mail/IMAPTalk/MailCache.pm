package Mail::IMAPTalk::MailCache;

use warnings;
use strict;

=head1 NAME

Mail::IMAPTalk::MailCache - Handles building a Mail::Cache cache for Mail::IMAPTalk

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Mail::IMAPTalk::MailCache;

    my $mc=Mail::Cache->new();
    $mc->init('My::Module', 'imap', 'someAccount', 'INBOX');
    if(!$mc->{error}){
        my %returned=Mail::IMAPTalk::MailCache->cache($imap, $mc);
        if(!$returned{error}){
            print "Error caching it.\n";
        }
    }

    my $foo = Mail::IMAPTalk::MailCache->new();
    ...

=head1 FUNCTIONS

=head2 cache

This caches the currently selected IMAP folder into a specified Mail::Cache.

Three arguements are taken. The first that is taken is Mail::IMAPTalk object.
The second is the Mail::Cache object. The third is if it should forcefully
regenerate the the entire cache instead of just the new stuff.

    my $mc=Mail::Cache->new();
    $mc->init('My::Module', 'imap', 'someAccount', 'INBOX');
    if(!$mc->{error}){
        my %returned=Mail::IMAPTalk::MailCache->cache($imap, $mc, 0);
        if(!$returned{error}){
            print "Error: ".$returned{error}."\n";
        }
    }else{
        print "Failed to init the mail cache.\n";
    }

=cut

sub cache {
	my $self=$_[0];
	my $imap=$_[1];
	my $mc=$_[2];
	my $force=$_[3];

	my $sorted = $imap->sort('(subject)', 'US-ASCII', 'NOT', 'DELETED');

	my %returned;
	my %processed;

	#builds hash of already existing ones
	my @uids;
	my $int=0;
	my %exists;
	if (!$force) {
		@uids=$mc->listUIDs;
		while (defined($uids[$int])) {
			$exists{$uids[$int]}='';
			$int++;
		}
	}

	#go through the list and add them al
	$int=0;
	while (defined($sorted->[$int])) {
		my $uid=$sorted->[$int];

		#process it if it is set to force
		#or if it does not exist
		if( $force || (!defined($exists{$uid})) ){
#			my $headers=$imap->fetch($uid, 'rfc822.header');
			my $headers=$imap->fetch($uid, 'body.peek[HEADER]');
#			use Data::Dumper;
#			print Dumper($headers2->{$uid}{body})."\n\n\n";
#			print Dumper($headers->{$uid}{'rfc822.header'})."\n";
			
			my $size=$imap->fetch($sorted->[$int], 'rfc822.size');

#			sleep 50000;
			
			$mc->setUID($uid, $headers->{$uid}{'body'},
						$size->{$uid}{'rfc822.size'});
		}

		#add it to the hash of processed
		$processed{$sorted->[$int]}='';

		$int++;
	}

	my @toremove;
	@uids=$mc->listUIDs;
	if ($mc->{error}) {
		warn('Macil::IMAPTalk::MailCache cache:1: Failed to get a list of cached UIDs for cleanup');
		$returned{error}=1;
		return %returned;
	}

	$int=0;
	while (defined($uids[$int])) {
		if (!defined($processed{$uids[$int]})) {
			push(@toremove, $uids[$int]);
		}

		$int++;
	}

	$mc->removeUIDs(\@toremove);

	#success
	$returned{error}=0;

	return %returned;
}

=head1 ERRORS

=head2 1

Failed to get a list of UIDs for the 

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-imaptalk-mailcache at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-IMAPTalk-MailCache>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::IMAPTalk::MailCache


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-IMAPTalk-MailCache>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-IMAPTalk-MailCache>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-IMAPTalk-MailCache>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-IMAPTalk-MailCache/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Mail::IMAPTalk::MailCache
