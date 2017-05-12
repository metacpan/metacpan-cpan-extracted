package MediaWiki::Bot::Plugin::Admin;
# ABSTRACT: A plugin to MediaWiki::Bot providing admin functions

use strict;
use warnings;
#use diagnostics;
use Carp;
use List::Compare;

our $VERSION = '3.004000'; # VERSION


use Exporter qw(import);
our @EXPORT = qw(
    rollback
    delete undelete delete_archived_image
    block unblock
    protect unprotect
    transwiki_import xml_import
    set_usergroups add_usergroups remove_usergroups
);


sub rollback {
    my $self      = shift;
    my $page      = shift;
    my $user      = shift;
    my $summary   = shift;
    my $markbot   = shift;

    my $res = $self->{api}->edit({
        action  => 'rollback',
        title   => $page,
        user    => $user,
        summary => $summary,
        markbot => $markbot,
    });
    return $self->_handle_api_error() unless $res;

    return $res;
}


sub delete {
    my $self    = shift;
    my $page    = shift;
    my $summary = shift || 'BOT: deleted page by command';

    my $res = $self->{api}->api({
        action  => 'query',
        titles  => $page,
        prop    => 'info|revisions',
        intoken => 'delete'
    });
    my $data = [ %{ $res->{query}->{pages} } ]->[1];
    my $edittoken = $data->{deletetoken};

    $res = $self->{api}->api({
        action => 'delete',
        title  => $page,
        token  => $edittoken,
        reason => $summary
    });
    return $self->_handle_api_error() unless $res;

    return $res;
}


sub undelete {
    my $self    = shift;
    my $page    = shift;
    my $summary = shift || 'BOT: undeleting page by command';

    # http://meta.wikimedia.org/w/api.php?action=query&list=deletedrevs&titles=User:Mike.lifeguard/sandbox&drprop=token&drlimit=1
    my $token_results = $self->{api}->api({
        action  => 'query',
        list    => 'deletedrevs',
        titles  => $page,
        drlimit => 1,
        drprop  => 'token',
    });
    my $token = $token_results->{query}->{deletedrevs}->[0]->{token};

    my $res = $self->{api}->api({
        action  => 'undelete',
        title   => $page,
        reason  => $summary,
        token   => $token,
    });
    return $self->_handle_api_error() unless $res;

    return $res;
}


sub delete_archived_image {
    my $self    = shift;
    my $archive = shift;
    my $summary = shift || 'BOT: deleting old version of image by command';

    my $file = [ split m/!/, $archive ]->[1];

    my ($token) = $self->_get_edittoken($file);

    my $res = $self->{api}->api({
        action   => 'delete',
        title    => "File:$file",
        token    => $token,
        reason   => $summary,
        oldimage => $archive,
    });
    return $self->_handle_api_error() unless $res;

    return $res;

}


sub block {
    my $self = shift;
    my $user;
    my $length;
    my $summary;
    my $anononly;
    my $autoblock;
    my $blockac;
    my $blockemail;
    my $blocktalk;
    if (ref $_[0] eq 'HASH') {
        $user       = $_[0]->{user};
        $length     = $_[0]->{length};
        $summary    = $_[0]->{summary};
        $anononly   = $_[0]->{anononly};
        $autoblock  = $_[0]->{autoblock};
        $blockac    = $_[0]->{blockac};
        $blockemail = $_[0]->{blockemail};
        $blocktalk  = $_[0]->{blocktalk};
    }
    else {
        $user       = shift;
        $length     = shift;
        $summary    = shift;
        $anononly   = shift;
        $autoblock  = shift;
        $blockac    = shift;
        $blockemail = shift;
        $blocktalk  = shift;
    }

    my $res;
    my $edittoken;

    if ($self->{blocktoken}) {
        $edittoken = $self->{blocktoken};
    }
    else {
        $res = $self->{api}->api({
            action  => 'query',
            titles  => 'Main_Page',
            prop    => 'info|revisions',
            intoken => 'block'
        });
        my $data = [ %{ $res->{query}->{pages} } ]->[1];
        $edittoken = $data->{blocktoken};
        $self->{blocktoken} = $edittoken;
    }
    my $hash = {
        action => 'block',
        user   => $user,
        token  => $edittoken,
        expiry => $length,
        reason => $summary
    };
    $hash->{anononly}      = $anononly   if ($anononly);
    $hash->{autoblock}     = $autoblock  if ($autoblock);
    $hash->{nocreate}      = $blockac    if ($blockac);
    $hash->{noemail}       = $blockemail if ($blockemail);
    $hash->{allowusertalk} = 1           if (!$blocktalk);

    $res = $self->{api}->api($hash);
    if (!$res) {
        return $self->_handle_api_error();
    }

    return $res;
}


sub unblock {
    my $self    = shift;
    my $user    = shift;
    my $summary = shift;

    my $res;
    my $edittoken;
    if ($self->{unblocktoken}) {
        $edittoken = $self->{unblocktoken};
    }
    else {
        $res = $self->{api}->api({
            action  => 'query',
            titles  => 'Main_Page',
            prop    => 'info|revisions',
            intoken => 'unblock',
        });
        my $data = [ %{ $res->{query}->{pages} } ]->[1];
        $edittoken = $data->{unblocktoken};
        $self->{unblocktoken} = $edittoken;
    }

    my $hash = {
        action => 'unblock',
        user   => $user,
        token  => $edittoken,
        reason => $summary,
    };
    $res = $self->{api}->api($hash);
    return $self->_handle_api_error() unless $res;

    return $res;
}


sub unprotect { # A convenience function
    my $self   = shift;
    my $page   = shift;
    my $reason = shift;

    return $self->protect($page, $reason, 'all', 'all');
}


sub protect {
    my $self    = shift;
    my $page    = shift;
    my $reason  = shift;
    my $editlvl = defined($_[0]) ? shift : 'sysop';
    my $movelvl = defined($_[0]) ? shift : 'sysop';
    my $time    = shift || 'infinite';
    my $cascade = shift;

    $editlvl = 'all' if $editlvl eq '';
    $movelvl = 'all' if $movelvl eq '';

    if ($cascade and ($editlvl ne 'sysop' or $movelvl ne 'sysop')) {
        carp "Can't set cascading unless both editlvl and movelvl are sysop." if $self->{debug};
    }
    my $res = $self->{api}->api({
        action  => 'query',
        titles  => $page,
        prop    => 'info|revisions',
        intoken => 'protect'
    });

    my $data = [ %{ $res->{query}->{pages} } ]->[1];
    my $edittoken = $data->{protecttoken};

    $res = $self->{api}->api({
        action      => 'protect',
        title       => $page,
        token       => $edittoken,
        reason      => $reason,
        protections => "edit=$editlvl|move=$movelvl",
        expiry      => $time,
        cascade     => $cascade,
    });
    return $self->_handle_api_error() unless $res;

    return $res;
}

sub transwiki_import {
    my $self = shift;
    my $prefix      = $_[0]->{prefix} || 'w';
    my $page        = $_[0]->{page};
    my $namespace   = $_[0]->{ns} || 0;
    my $history     = defined($_[0]->{history}) ? $_[0]->{history} : 1;
    my $templates   = defined($_[0]->{templates}) ? $_[0]->{templates} : 0;

    my $res = $self->{api}->api({
        action  => 'query',
        prop    => 'info',
        titles  => 'Main Page',
        intoken => 'import',
    });
    return $self->_handle_api_error() unless $res;

    my $data = [ %{ $res->{query}->{pages} } ]->[1];
    my $importtoken = $data->{importtoken};

    $res = $self->{api}->api({
        action          => 'import',
        token           => $importtoken,
        interwikisource => $prefix,
        interwikipage   => $page,
        fullhistory     => $history,
        namespace       => $namespace,
        templates       => $templates,
    });
    return $self->_handle_api_error() unless $res;

    return $res;
}


sub xml_import {
    my $self     = shift;
    my $filename = shift or die 'No filename given';

    my $success = $self->{api}->edit({
        action  => 'import',
        xml     => [ $filename ],
    });
    return $self->_handle_api_error() unless $success;
    return $success;
}


sub set_usergroups {
    my $self    = shift;
    my $user    = shift;
    my $rights  = shift;
    my $summary = shift;

    $user =~ s/^User://;

    unless (
        exists $self->{userrightscache}
        and $self->{userrightscache}
        and $self->{userrightscache}->{user} eq $user
    ) {
        $self->usergroups($user);
    }
    my $compare = List::Compare->new({
        lists => [ $self->{userrightscache}->{groups}, $rights ],
        unsorted    => 1,
    });
    my %add    = map { $_ => 1 } $compare->get_complement;
    my %remove = map { $_ => 1 } $compare->get_unique;
    delete $add{ $_ }    for qw(* user autoconfirmed);
    delete $remove{ $_ } for qw(* user autoconfirmed);

    my $hash = {
        action  => 'userrights',
        user    => $user,
        add     => join('|', keys %add),
        remove  => join('|', keys %remove),
        reason  => $summary,
        token   => $self->{userrightscache}->{token},
    };
    my $res = $self->{api}->api($hash);
    return $self->_handle_api_error() unless $res;

    my %new_usergroups = map { $_ => 1 } @{ $self->{userrightscache}->{groups} };
    delete $new_usergroups{ $_ } for @{ $res->{userrights}->{removed} };
    $new_usergroups{ $_ } = 1 for @{ $res->{userrights}->{added} };
    delete $self->{userrightscache};
    return keys %new_usergroups;
}


sub add_usergroups {
    my $self    = shift;
    my $user    = shift;
    my $rights  = shift;
    my $summary = shift;

    $user =~ s/^User://;

    unless (
        exists $self->{userrightscache}
        and exists $self->{userrightscache}->{user}
        and $self->{userrightscache}->{user} eq $user
    ) {
        $self->usergroups($user);
    }

    my $res = $self->{api}->api({
        action  => 'userrights',
        user    => $user,
        add     => @$rights,
        reason  => $summary,
        token   => $self->{userrightscache}->{token},
    });
    return $self->_handle_api_error() unless $res;

    delete $self->{userrightscache};
    return @{ $res->{userrights}->{added} };
}



sub remove_usergroups {
    my $self    = shift;
    my $user    = shift;
    my $rights  = shift;
    my $summary = shift;

    $user =~ s/^User://;

    unless (
        exists $self->{userrightscache}
        and exists $self->{userrightscache}->{user}
        and $self->{userrightscache}->{user} eq $user
    ) {
        $self->usergroups($user);
    }

    my $res = $self->{api}->api({
        action  => 'userrights',
        user    => $user,
        remove  => @$rights,
        reason  => $summary,
        token   => $self->{userrightscache}->{token},
    });
    return $self->_handle_api_error() unless $res;

    delete $self->{userrightscache};
    return @{ $res->{userrights}->{removed} };
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

MediaWiki::Bot::Plugin::Admin - A plugin to MediaWiki::Bot providing admin functions

=head1 VERSION

version 3.004000

=head1 SYNOPSIS

    use MediaWiki::Bot;

    my $bot = MediaWiki::Bot->new('Account');
    $bot->login('Account', 'password');
    my @pages = ('one', 'two', 'three');
    foreach my $page (@pages) {
        $bot->delete($page, 'Deleting [[:Category:Pages to delete]] en masse');
    }

=head1 DESCRIPTION

A plugin to the MediaWiki::Bot framework to provide administrative
functions to a bot.

=head1 METHODS

=head2 import()

Calling import from any module will, quite simply, transfer these
subroutines into that module's namespace. This is possible from any
module which is compatible with MediaWiki::Bot. Typically, you will
C<use MediaWiki::Bot> and nothing else. Just use the methods,
MediaWiki::Bot automatically imports plugins if found.

=head2 rollback($pagename, $username[,$summary[,$markbot]])

Uses rollback to revert to the last revision of $pagename not edited
by the latest editor of that page. If $username is not the last editor
of $pagename, you will get an error; that's why it is a I<very good
idea> to set this. If you do not, the latest edit(s) will be rolled
back, and you could end up rolling back something you didn't intend
to. Therefore, $username should be considered B<required>. The
remaining parameters are optional: $summary (to set a custom rollback
edit summary), and $markbot (which marks both the rollback and the
edits that were rolled back as bot edits).

    $bot->rollback("Linux", "Some Vandal");
    # OR
    $bot->rollback("Wikibooks:Sandbox", "Mike.lifeguard", "rvv", 1);

=head2 delete($page[,$summary])

Deletes the page with the specified summary. If you omit $summary,
a generic one will be used.

    my @pages = ('Junk page 1', 'Junk page 2', 'Junk page 3');
    foreach my $page (@pages) {
        $bot->delete($page, 'Deleting junk pages');
    }

=head2 undelete($page[,$summary])

Undeletes $page with $summary. If you omit $summary, a generic one
will be used.

    $bot->undelete($page);

=head2 delete_archived_image($archivename, $summary)

Deletes the specified revision of the image with the specified summary.
A generic summary will be used if you omit $summary.

    # Get the archivename somehow (from iiprop)
    $bot->delete_archived_image('20080606222744!Albert_Einstein_Head.jpg', 'test');

=head2 block($options_hashref)

Blocks the user with the specified options. All options optional except
user and length. Anononly, autoblock, blockac, blockemail and blocktalk
are true/false. Defaults to a generic summary, with all options disabled.

    $bot->block({
        user        => 'Vandal account 2',
        length      => 'indefinite',
        summary     => '[[Project:Vandalism|Vandalism]]',
        anononly    => 1,
        autoblock   => 1,
    });

For backwards compatibility, you can still use this deprecated method call:

    $bot->block('Vandal account', 'infinite', 'Vandalism-only account', 1, 1, 1, 0, 1);

=head2 unblock($user[,$summary])

Unblocks the user with the specified summary.

    $bot->unblock('Jimbo Wales', 'Blocked in error');

=head2 unprotect($page, $reason)

Unprotects a page. You can also set parameters for protect() such that 
the page is unprotected.

    my @obsolete_protections = ('Main Page', 'Project:Community Portal', 'Template:Tlx');
    foreach my $page (@obsolete_protections) {
        $bot->unprotect($page, 'Removing old obsolete page protection');
    }

=head2 protect($page, $reason, $editlvl, $movelvl, $time, $cascade)

Protects (or unprotects) the page. $editlvl and $movelvl may be 'all',
'autoconfirmed', or 'sysop'. $cascade is true/false.

=head2 transwiki_import($options_hashref)

Do a I<transwiki> import of a page specified in the hashref.

=over 4

=item *
prefix must be a valid interwiki on the wiki you're importing to. It
specifies where to import from.

=item *
page is the title to import from the remote wiki, including namespace

=item *
ns is the namespace I<number> to import I<to>. For example, some wikis
have a "Transwiki" namespace to import into where cleanup happens before
pages are moved into the main namespace. This defaults to 0.

=item *
history specifies whether or not to include the full page history. Defaults
to 1. In general, you should import the full history, but on very large page
histories, this may not be possible. In such cases, try disabling this, or
do an L<XML import|/xml_import>.

=item *
templates specifies whether or not to include templates. Defaults to 0;

=back

=head2 xml_import

    $bot->xml_import($filename);

Import an XML file to the wiki. Specify the filename of an XML dump.

=head2 set_usergroups

Sets the user's group membership to the given list. You cannot change membership in
*, user, or autoconfirmed, so you don't need to list them. There may also be other
limits on which groups you can set/unset on a given wiki with a given account which
may result in an error. In an error condition, it is undefined whether any group
membership changes are made.

The list returned is the user's new group membership.

    $bot->set_usergroups('Mike.lifeguard', ['sysop'], "He deserves it");

=head2 add_usergroups

Add the user to the specified usergroups:

    $bot->add_usergroups('Mike.lifeguard', ['sysop', 'editor'], "for fun");

Returns the list of added usergroups, not the full group membership list like set_usergroups does.

=head2 remove_usergroups

Revoke the user's membership in the listed groups:

    $bot->remove_usergroups('Mike.lifeguard', ['sysop', 'editor'], "Danger to himself & others");

Returns the list of removed groups, not the full group membership list like set_usergroups does.

=head1 AVAILABILITY

The project homepage is L<https://metacpan.org/module/MediaWiki::Bot::Plugin::Admin>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/MediaWiki::Bot::Plugin::Admin/>.

=head1 SOURCE

The development version is on github at L<http://github.com/MediaWiki-Bot/MediaWiki-Bot-Plugin-Admin>
and may be cloned from L<git://github.com/MediaWiki-Bot/MediaWiki-Bot-Plugin-Admin.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/MediaWiki-Bot/MediaWiki-Bot-Plugin-Admin/issues>.

=head1 AUTHORS

=over 4

=item *

Dan Collins <en.wp.2t47@gmail.com>

=item *

Mike.lifeguard <mike.lifeguard@gmail.com>

=item *

patch and bug report contributors

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by the MediaWiki::Bot team <perlwikibot@googlegroups.com>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

