package Mail::IMAPTalk::SortHelper;

use warnings;
use strict;
use Mail::IMAPTalk::MailCache;

=head1 NAME

Mail::IMAPTalk::SortHelper - Handles some processing of the returns from sort and thread.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

Generates a array from the sorted return of either
Mail::IMAPTalk->sort or Mail::IMAPTalk->thread.

Mail::Cache is used to speed this up.

    use Mail::IMAPTalk::SortHelper;

    my $sh = Mail::IMAPTalk::SortHelper->new();
    ...

=head1 FUNCTIONS

=head2 new

This initiates the object.

    my $sh = Mail::IMAPTalk::SortHelper->new();

=cut

sub new{
	my $self={error=>undef, errorString=>'', inline=>0, char=>'>'};
	bless $self;

	return $self;
}

=head2 process

This processes the returned data from either sort or thread.

Three arguements are required. The first is the data returned from
it, the second is the Mail::IMAPTalk object, and the third is
a Mail::Cache object.

    my $sorted=$imap->thread('REFERENCES', 'UTF8', 'NOT', 'DELETED');
    $mc->init('My::Module', 'imap', 'myAccount', 'INBOX');
    my @processed=$sh->(@{$sorted}, $imap, $mc);
    
    use Data::Dumper;
    print Data::Dumper->Dump(\@processed);

=cut

sub process{
	my $self=$_[0];
	my @r=@{$_[1]};
	my $i=$_[2];
	my $mc=$_[3];

	#makes sure the cache is up to date
	my %mimcr=Mail::IMAPTalk::MailCache->cache($i, $mc, 0);

	my %dates=$mc->getDates;
	$self->{dates}=\%dates;
	my %sizes=$mc->getSizes;
	$self->{sizes}=\%sizes;
	my %froms=$mc->getFroms;
	$self->{froms}=\%froms;
	my %subjects=$mc->getSubjects;
	$self->{subjects}=\%subjects;

	my @p;

	my $int=0;
	while (defined($r[$int])) {
		#if it is a array, then it is threaded and we need to handle this differently...
		if (ref($r[$int]) eq 'ARRAY') {
			my $t=$r[$int];
			my @additionalP=$self->processArray($t, $i, $mc, 0);
			push(@p, @additionalP);
		}else {
			my $uid=$r[$int];

			my $toadd={};
			$toadd->{uid}=$uid;

            $toadd->{subject}=$self->{subjects}{$uid};
			$toadd->{date}=$self->{dates}->{$uid};
			$toadd->{from}=$self->{froms}->{$uid};
			$toadd->{size}=$self->{sizes}->{$uid};
			$toadd->{over}='0';

			#make sure they are all defined...
			if (!defined($toadd->{subject})) {
				$toadd->{subject}='';
			}
			if (!defined($toadd->{date})) {
				$toadd->{date}='';
			}
			if (!defined($toadd->{from})) {
				$toadd->{from}='';
			}
			if (!defined($toadd->{size})) {
				$toadd->{size}='';
			}

			push(@p, $toadd);
		}
	
		$int++;
	}

	return @p;
}

=head2 processArray

This is a internal function used for when dealing with threads.

=cut

sub processArray{
	my $self=$_[0];
	my $i=$_[2];
	my $mc=$_[3];
	my $over=$_[4];
	my @r; #if we don't get handed an array, we don't do any thing that would be annoying
	if (ref($_[1]) eq 'ARRAY') {
		@r=@{$_[1]}
	}

	#puts together the inline
	my $inlineappend='';
	my $int=1;#we start at one as zero does not have one
	while ($int <= $over) {
		$inlineappend=$self->{char}.$inlineappend;

		$int++;
	}

	my @p; #holds what will be returned

	$int=0;
	while (defined($r[$int])) {
		if (ref($r[$int]) eq 'ARRAY') {
			#handles any sub threads
			my $t=$r[$int];
			my $newover=$over;
			$newover++;
			my @additionalP=$self->processArray($t, $i, $mc, $newover);
			push(@p, @additionalP);
		}else {
			#handles any message for this over lovel
			my $uid=$r[$int];

			my $toadd={};
			$toadd->{uid}=$uid;

            $toadd->{subject}=$inlineappend.$self->{subjects}->{$uid};
			$toadd->{date}=$self->{dates}->{$uid};
			$toadd->{from}=$self->{froms}->{$uid};
			$toadd->{size}=$self->{sizes}->{$uid};
			$toadd->{over}=$over;

			#make sure they are all defined...
			if (!defined($toadd->{subject})) {
				$toadd->{subject}='';
			}
			if (!defined($toadd->{date})) {
				$toadd->{date}='';
			}
			if (!defined($toadd->{from})) {
				$toadd->{from}='';
			}
			if (!defined($toadd->{size})) {
				$toadd->{size}='';
			}

			push(@p, $toadd);
		}
	
		$int++;
	}

#	print "processed array\n";

	return @p;
}

=head2 getInline

Gets the inline mode setting.

=cut

sub getInline{
	return $_[0]->{inline};
}

=head2 getInlineCharacter

This fetches what is currently being used for the inline character.

=cut

sub getInlineCharacter{
	return $_[0]->{char};
}

=head2 setInline

Turn inline mode on or off.

=cut

sub setInline{
	$_[0]->{inline}=$_[1];

	return 1;
}

=head2 setInlineCharacter

This sets the inline over character.

If it is undef or '', then it is reset to '>'.

    $sh->setInlineCharacter('=');

=cut

sub setInlineCharacter{
	if (!defined($_[1])) {
		$_[0]->{char}='-';
	}

	if ($_[1] eq '') {
		$_[0]->{char}='-';
		return 1;
	}

	$_[0]->{char}=$_[1];

	return 1;
}

=head1 RETRUNED ARRAY FORMAT

The returned a is a  array of hashes.

=head2 HASH KEYS

=head3 over

This is how far over a item a thread. A value of zero
indicates it's the root of the thread.

Unless this is a threaded search, it will always be 0.

=head3 uid

This is the IMAP UID of the message.

=head3 from

This is the From header of the message.

=head3 date

This is the Date header of the message.

=head3 subject

This is the subject header of the message.

If inline mode is turned on the number of inline characters
will be appended to it determines by how far over it is.

=head3 size

This is the size of the message.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-imaptalk-sorthelper at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-IMAPTalk-SortHelper>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::IMAPTalk::SortHelper


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-IMAPTalk-SortHelper>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-IMAPTalk-SortHelper>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-IMAPTalk-SortHelper>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-IMAPTalk-SortHelper/>

=back


=head1 ACKNOWLEDGEMENTS

ANDK, #52167, pointed out the missing dependency in Makefile.PL

=head1 COPYRIGHT & LICENSE

Copyright 2011 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Mail::IMAPTalk::SortHelper
