package Labyrinth::Plugin::Guestbook;

use warnings;
use strict;

use vars qw($VERSION);

$VERSION = '1.06';

=head1 NAME

Labyrinth::Plugin::Guestbook - Guestbook plugin handler for Labyrinth

=head1 DESCRIPTION

Contains all the Guestbook handling functionality for the Labyrinth Web
Framework.

=cut

#----------------------------------------------------------------------------
# Libraries

use base qw(Labyrinth::Plugin::Base);

use Data::Pageset;

use Labyrinth::Audit;
use Labyrinth::DTUtils;
use Labyrinth::IPAddr;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;
use Labyrinth::Plugin::Hits;

#----------------------------------------------------------------------------
# Variables

use vars qw(%fields @mandatory @allfields);

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

%fields = (
    realname    => { type => 1, html => 1 },
    email       => { type => 0, html => 1 },
    city        => { type => 0, html => 1 },
    country     => { type => 0, html => 1 },
    url         => { type => 0, html => 1 },
    guestpass   => { type => 0, html => 1 },
    comments    => { type => 1, html => 1 },
);

for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $hits   = Labyrinth::Plugin::Hits->new();

#----------------------------------------------------------------------------
# Public Interface Functions

sub Read {
    my $stop = 10;
    my $page = $cgiparams{page} || 1;
    my $from = (($page - 1) * $stop) + 1;
    my @rows = $dbi->GetQuery('array','CountGuestbook');
    my $max = $rows[0]->[0];
    
    my $info = Data::Pageset->new({
        'total_entries'     => $max,
        'entries_per_page'  => $stop,
        'current_page'      => $page,
        'pages_per_set'     => $stop}
    );
    
    $tvars{first} = $info->first_page;
    $tvars{last}  = $info->last_page;
    $tvars{next}  = $info->next_page;
    $tvars{prev}  = $info->previous_page;
    $tvars{page}  = $page;
    
    # Print the page numbers of the current set
    my @pages = (@{$info->pages_in_set()});
    $tvars{pages} = \@pages if(@pages);
    @rows = ();
    my $next = $dbi->Iterator('hash','ListGuestbook');
    while(@rows < $stop && (my $row = $next->())) {
        next    if(--$from > 0);
        $row->{postdate} = formatDate(7,$row->{createdate});
        push @rows, $row
    }
    $tvars{data} = \@rows   if(@rows);
}

sub Save {
    my $check = CheckIP();
    if(    $check == BLOCK
        || $cgiparams{typekey}
        || !$cgiparams{loopback}
        || $cgiparams{loopback} ne $settings{ipaddr}) {
        $tvars{thanks} = 3;
        return;
    }
    $cgiparams{publish} = $check == ALLOW ? 3 : 2;
    # Strip out HTML unless we are allowing it.  The process_html
    # sub should take care of everything.
    for(keys %fields) {
          if($fields{$_}->{html} == 1)  { $cgiparams{$_} = CleanHTML($cgiparams{$_}); }
       elsif($fields{$_}->{html} == 2)  { $cgiparams{$_} = SafeHTML($cgiparams{$_});  }
    }
    #$cgiparams{comments} = LinkSpam($cgiparams{comments});
#    $cgiparams{guestpass} = ''  unless(lc($cgiparams{guestpass}) eq 'rubery');
    return  if FieldCheck(\@allfields,\@mandatory);

    $tvars{data}->{'url'} = '';
    $tvars{data}->{email} = '';
    my @fields = (  
        $tvars{data}->{realname},
        $tvars{data}->{email},
        $tvars{data}->{url},
        $tvars{data}->{city},
        $tvars{data}->{country},
        $tvars{data}->{comments},
        time(),
        $tvars{data}->{publish},
        $settings{ipaddr}
    );
    $dbi->DoQuery('SaveGuestbook',@fields);
    $hits->SetUpdates('guest',0);
    $tvars{thanks} = 1;
}

#----------------------------------------------------------------------------
# Admistration Interface Functions

sub List {
    return  unless AccessUser(EDITOR);
    my @rs = $dbi->GetQuery('hash','ListAllGuestbook');
    foreach my $row (@rs) {
        $row->{createdate} = formatDate(18,$row->{createdate});
        if(length($row->{comments}) > 100) {
            $row->{comments} = substr($row->{comments},0,97);
            $row->{comments} .= '...';
        }
    }
    if(@rs) {
        $tvars{records} = \@rs;
        $tvars{count} = scalar(@rs);
    } else {
        $tvars{count} = 0;
    }
}

sub MultiBlock {
    return  unless AccessUser(ADMIN);
    return  unless($cgiparams{pattern});

    my @ids;
    my @rs = $dbi->GetQuery('hash','GetGuestbookByText','%'.$cgiparams{pattern}.'%');
    for my $rs (@rs) {
        BlockIP($rs->{author},$rs->{ipaddr});
        push @ids, $rs->{'entryid'};
        LogDebug('MultiBlock:' . scalar(@ids));
    }
    $dbi->DoQuery('DeleteGuestbook',{ids => join(',',@ids)})    if(@ids);
    $tvars{thanks} = 1;
}

sub Block {
    return  unless AccessUser(ADMIN);
    return  unless AuthorCheck('GetGuestbookByID','entryid',ADMIN);
    BlockIP($tvars{data}->{author},$tvars{data}->{ipaddr});
    my @rows = $dbi->GetQuery('hash','GetGuestbookByIP',$tvars{data}->{ipaddr});
    return unless(@rows);
    my @ids  = map {$_->{'entryid'}} @rows;
    $dbi->DoQuery('DeleteGuestbook',{ids => join(',',@ids)});
    $tvars{thanks} = 1;
}

sub Allow {
    return  unless AccessUser(ADMIN);
    return  unless AuthorCheck('GetGuestbookByID','entryid',ADMIN);
    AllowIP($tvars{data}->{author},$tvars{data}->{ipaddr});
    my @rows = $dbi->GetQuery('hash','GetGuestbookByIP',$tvars{data}->{ipaddr});
    return unless(@rows);
    my @ids  = map {$_->{'entryid'}} @rows;
    $dbi->DoQuery('AcceptGuestbook',{ids => join(',',@ids)});
    $tvars{thanks} = 2;
}

sub Approve {
    return  unless AccessUser(ADMIN);
    my @ids = ($cgiparams{entryid});
    return  unless(@ids);
    $dbi->DoQuery('AcceptGuestbook',{ids => join(',',@ids)});
    $tvars{thanks} = 3;
}

sub Delete {
    return  unless AccessUser(ADMIN);
    my @ids = ($cgiparams{entryid});
    return  unless(@ids);
    $dbi->DoQuery('DeleteGuestbook',{ids => join(',',@ids)});
    $tvars{thanks} = 4;
}

sub Edit {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetGuestbookByID','entryid',EDITOR);
}

sub Update {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetGuestbookByID','entryid',EDITOR);

    # Strip out HTML unless we are allowing it.  The process_html
    # sub should take care of everything.
    for(keys %fields) {
          if($fields{$_}->{html} == 1)  { $cgiparams{$_} = CleanHTML($cgiparams{$_}); }
       elsif($fields{$_}->{html} == 2)  { $cgiparams{$_} = SafeHTML($cgiparams{$_});  }
    }
    #$cgiparams{comments} = LinkSpam($cgiparams{comments});
    return  if FieldCheck(\@allfields,\@mandatory);

    $tvars{data}->{'url'} = '';
    $tvars{data}->{email} = '';
    $dbi->DoQuery(
        'UpdateGuestbook',
        $tvars{data}->{realname},
        $tvars{data}->{email},
        $tvars{data}->{url},
        $tvars{data}->{city},
        $tvars{data}->{country},
        $tvars{data}->{comments},
        $cgiparams{entryid});
    $tvars{thanks} = 1;
}

1;

__END__

=head1 PUBLIC INTERFACE METHODS

=over 4

=item * Read

Lists all the publicly visable posts.

=item * Save

Save a message to be moderated.

=back

=head1 ADMIN INTERFACE METHODS

=head2 MP3s Methods

=over 4

=item * List

List and manage/moderate messages posted to the guestbook.

=item * MultiBlock

Block the IPs and delete messages based on content.

=item * Block

Block the IP of a single and delete it.

=item * Allow

Allow the IP of a message, and approve all messages with this IP.

=item * Approve

Approve a single message, ignoring the IP.

=item * Delete

Delete a single message, ignoring the IP.

=item * Edit

Edit a post.

=item * Update

Validates the fields returned from the edit page, and saves the record back to
the database.

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
