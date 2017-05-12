package EveOnline::Api;

use strict;
use warnings;
use v5.12;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use XML::Simple;
use Time::Local;
use Moose;
use namespace::autoclean;
use EveOnline::Character;
use EveOnline::CharacterInfo;
use EveOnline::AccountStatus;
use EveOnline::SkillQueue;
use EveOnline::Contact;

=head1 NAME

EveOnline::Api - the Perl version of the Eve Online API system.

=head1 VERSION

Version 0.051

=cut

our $VERSION = '0.051';

has 'apiroot'   =>  (
    is      =>  'rw',
    isa     =>  'Str',
    default =>  'https://api.eveonline.com'
    );

has 'keyid' =>  (
    is   =>  'rw',
    isa  =>  'Int'
    );

has 'vcode' =>  (
    is  =>  'rw',
    isa =>  'Str'
    );

=head1 SYNOPSYS

	my $eve = EveOnline::Api->new(keyid => 'XXXXXXX', vcode => 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX');

	# return char list
	my @list = $eve->get_character_list();

=head1 DESCRIPTION

The module allows to programatically access to the Eve Online Game API system. Currently, there are several methods available for
information retieval and this module only cover a few o them. 

=head1 SUBROUTINES/METHODS

=head2 get_character_list

Access the complete character list of a given account. Returns a list of Character objects.
	
	my @list = $eve->get_characer_list();

=cut

sub get_character_list {
    my $self        = shift;
    #my $keyID       = shift;
    #my $vCode       = shift;

    my $path = '/account/Characters.xml.aspx';
    my $char = undef;

    my $text = &connect($self, $self->keyid, $self->vcode, $path, $char);

    my $xml = XMLin($text, KeepRoot => 1, KeyAttr => {rowset => '+name', row => '+characterID'}, ForceArray => [ 'row' ]);
    $xml->{eveapi}{$xml->{eveapi}{result}{rowset}{name}} = $xml->{eveapi}{result}{rowset}; delete $xml->{eveapi}{result};

    my @result;

    for my $id ( keys %{ $xml->{eveapi}{characters}{row} } ) {

        my $char = EveOnline::Character->new();
        
        $char->name($xml->{eveapi}{characters}{row}{$id}{name});
        $char->characterID($xml->{eveapi}{characters}{row}{$id}{characterID});
        $char->corporationID($xml->{eveapi}{characters}{row}{$id}{corporationID});
        $char->corporationName($xml->{eveapi}{characters}{row}{$id}{corporationName});
        $char->allianceID($xml->{eveapi}{characters}{row}{$id}{allianceID});
        $char->allianceName($xml->{eveapi}{characters}{row}{$id}{allianceName});
        $char->factionID($xml->{eveapi}{characters}{row}{$id}{factionID});
        $char->factionName($xml->{eveapi}{characters}{row}{$id}{factionName});
        $char->cachedUntil($xml->{eveapi}->{cachedUntil});

        push(@result, $char);

    }

    return \@result;
}

=head2 get_char_info_list

Access the descritive information from a character. Returns a list of CharacterInfo objects.

	my @list = $eve->get_char_info_list();

=cut

sub get_char_info_list {
    my $self     = shift;
    my $charlist = shift;

    my @charlist = @{$charlist};
    my @charinfolist;
    my $path = '/eve/CharacterInfo.xml.aspx';

    for my $char ( @charlist ) {

        my $text     = &connect($self, $self->keyid, $self->vcode, $path, $char);
        my $xml      = XMLin($text, KeepRoot => 1);
        my $charinfo = EveOnline::CharacterInfo->new();
        my $data     = $xml->{eveapi}->{result};        

        while ( my ($key, $value) = each(%$data) ) {

            $charinfo->characterID($value)       if $key eq 'characterID';
            $charinfo->characterName($value)     if $key eq 'characterName';
            $charinfo->race($value)              if $key eq 'race';
            $charinfo->bloodline($value)         if $key eq 'bloodline';
            $charinfo->accountBalance($value)    if $key eq 'accountBalance';
            $charinfo->skillPoints($value)       if $key eq 'skillPoints';
            $charinfo->shipName($value)          if $key eq 'shipName';
            $charinfo->shipTypeID($value)        if $key eq 'shipTypeID';
            $charinfo->shipTypeName($value)      if $key eq 'shipTypeName';
            $charinfo->corporationID($value)     if $key eq 'corporationID';
            $charinfo->corporation($value)       if $key eq 'corporation';
            $charinfo->corporationDate($value)   if $key eq 'corporationDate';
            $charinfo->allianceID($value)        if $key eq 'allianceID';
            $charinfo->alliance($value)          if $key eq 'alliance';
            $charinfo->allianceDate($value)      if $key eq 'allianceDate';
            $charinfo->lastKnownLocation($value) if $key eq 'lastKnownLocation';
            $charinfo->securityStatus($value)    if $key eq 'securityStatus';
            $charinfo->cachedUntil($xml->{eveapi}->{cachedUntil});

        }
    
        push(@charinfolist, $charinfo);
    }

    return \@charinfolist;

}

=head2 get_account_status

Access the status of the account. Returns an AccountStatus object.
	
	my $obj = $eve->get_account_status();

=cut

sub get_account_status {
    my $self = shift;

    my $path = '/account/AccountStatus.xml.aspx';
    my $char = undef;

    my $text = &connect($self, $self->keyid, $self->vcode, $path, $char);
    my $obj = EveOnline::AccountStatus->new();
    my $xml = XMLin($text, KeepRoot => 1);
    my $data = $xml->{eveapi}->{result};
    
    while ( my ($key, $value ) = each (%$data) ) {

        $obj->paidUntil($value)     if $key eq 'paidUntil';
        $obj->createDate($value)    if $key eq 'createDate';
        $obj->logonCount($value)    if $key eq 'logonCount';
        $obj->logonMinutes($value)  if $key eq 'logonMinutes';

    }

    $obj->cachedUntil($xml->{eveapi}->{cachedUntil});

    return $obj;
}


sub get_char_skill_queue {
    my $self     = shift;
    my $charlist = shift;

    # TODO #

    my @charlist = @{$charlist};
    my @skillQueueList;
    my $path = '/char/SkillQueue.xml.aspx';

    for my $char ( @charlist ) {
        
        my $text = &connect($self, $self->keyid, $self->vcode, $path, $char);

        my $xml = XMLin($text, KeepRoot => 1);

        my $obj;

        for my $id ( keys %{ $xml->{eveapi}{result}{rowset}{row} } ) {
            
            $obj = EveOnline::SkillQueue->new();

            $obj->characterID($char->characterID);
            $obj->queuePosition($xml->{eveapi}{result}{rowset}{row}{queuePosition});
            $obj->typeID($xml->{eveapi}{result}{rowset}{row}{typeID});
            $obj->level($xml->{eveapi}{result}{rowset}{row}{level});
            $obj->startSP($xml->{eveapi}{result}{rowset}{row}{startSP});
            $obj->endSP($xml->{eveapi}{result}{rowset}{row}{endSP});
            $obj->startTime($xml->{eveapi}{result}{rowset}{row}{startTime});
            $obj->endTime($xml->{eveapi}{result}{rowset}{row}{endTime});
            $obj->cachedUntil($xml->{eveapi}->{cachedUntil});
        }

        push(@skillQueueList, $obj);
                                
    }
    
    return \@skillQueueList;
}

sub get_contact_list {
    my $self     = shift;
    my $charlist = shift;

    my @charlist = @{$charlist};
    my $path     = '/char/ContactList.xml.aspx';

	# TODO #

#    my $text = &connect($self, $keyID, $vCode, $path, $char);
#    my $obj  = EveOnline::Contact->new();
#    my $xml  = XMLin($text, KeepRoot => 1);
#    my $data = $xml->{eveapi}->{result};

    return;
}

#=head2 connect

#This is the most impotant method of the API. The method recieves the API keys and verification codes from the class and execute a request to the Eve Server.

#=cut

sub connect {
    my ($self, $keyID, $vCode, $path, $char)  = @_;

    my $ua = LWP::UserAgent->new;
    my $req;

    if ( $char ) {

        $req = POST $self->apiroot.$path, [ keyID => $keyID, vCode => $vCode, characterID => $char->characterID ];

    } else {
        
        $req = POST $self->apiroot.$path, [ keyID => $keyID, vCode => $vCode ];

    }

    my $res = $ua->request($req);

    unless ( $res->is_success ) {

        die "Error: " . $res->status_line . "\n";

    }

    my $text = $res->decoded_content;
       
    return $text;
}

1;

=head1 AUTHOR

Felipe da Veiga Leprevost, C<< <leprevost@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-myapp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MyApp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc EveOnline::Api


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=EveOnline-Api>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/EveOnline-Api>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/EveOnline-Api>

=item * Search CPAN

L<http://search.cpan.org/dist/EveOnline-Api/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Felipe da Veiga Leprevost.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of EveOnline::Api
