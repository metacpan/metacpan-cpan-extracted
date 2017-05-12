package Labyrinth::Plugin::Wiki;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.06';

=head1 NAME

Labyrinth::Plugin::Wiki - Wiki handler for the Labyrinth framework.

=head1 DESCRIPTION

Contains all the wiki handling functionality for Labyrinth.

=cut

# -------------------------------------
# Library Modules

use Algorithm::Diff;
use VCS::Lite;

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::DTUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

use Labyrinth::Plugin::Wiki::Text;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    pagename    => { type => 1, html => 1 },
    comment     => { type => 0, html => 1 },
    content     => { type => 1, html => 2 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $LEVEL       = ADMIN;

my $wikitext = Labyrinth::Plugin::Wiki::Text->new();

my %valid_limits = map {$_ => 1} qw(10 20 50 100 200 500);

# -------------------------------------
# Public Methods

=head1 PUBLIC INTERFACE METHODS

=over 4

=item Page

Checks for alternative page references and redirects if necessary.

=item Edit

Provides the edit page for the given page.

=item View

Provides the view page for the given page.

=item Save

Saves the given page.

=item History

Provides the history of edits for the given page.

=item Diff

Provides the differences between to versions of the given page.

=item Search

Searches through the current set of pages for the given text string.

=item Recent

Lists the most recent changes.

=back

=cut

sub Page {
    $cgiparams{pagename} ||= 'HomePage';

    # check for special pages first
    return _redirect($cgiparams{pagename})
        if(defined $cgiparams{pagename} &&
            $cgiparams{pagename} =~ /^People|Login|Search|RecentChanges$/);

    # now deal with the page
    return  unless CheckPage();
    if($tvars{wikihash}) {
        #REDIRECT [[PAGE]]
        return _redirect($1)
            if($tvars{wikihash}->{content} =~ /^\#REDIRECT\s+\[\[\s*(.*)\s*\]\]/);

        ($tvars{wikihash}{title},$tvars{wikihash}{html}) = $wikitext->Render($tvars{wikihash});
        $tvars{wikihash}{showmode} = 1;
    } else {
        SetCommand('wiki-edit');
    }
}

sub Edit {
    return  unless AccessUser(USER);
    return  if     RestrictedPage();
    return  unless CheckPage();
    return  if     LockedPage();

    if(!$tvars{wikihash}{version}) {
        $tvars{wikihash}{pagename} = $cgiparams{pagename};
        $tvars{wikihash}{title}    = $cgiparams{pagename};
    }

    $tvars{wikihash}{editmode} = 1;
}

sub View {
    return  unless AccessUser(USER);
    return  if     RestrictedPage();
    return  unless CheckPage(1);
    return  if     LockedPage();

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }

        $tvars{wikihash}->{$_} = $cgiparams{$_};
    }

    ($tvars{wikihash}{title},$tvars{wikihash}{html}) = $wikitext->Render($tvars{wikihash});

    $tvars{wikihash}{editmode} = 1;
}

sub Save {
    return  unless AccessUser(USER);
    return  if     RestrictedPage();
    return  unless CheckPage();
    return  if     LockedPage();

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }

        $tvars{wikihash}->{$_} = $cgiparams{$_};
    }

    return  if FieldCheck(\@allfields,\@mandatory);

    $tvars{wikihash}->{'version'}++;

    # normalise line endings
    $tvars{wikihash}->{'content'} =~ s/\r\n/\n/g;   # Win32
    $tvars{wikihash}->{'content'} =~ s/\r/\n/g;     # Mac

    $dbi->DoQuery('SaveWikiPage',
                        $tvars{wikihash}->{'pagename'},
                        $tvars{wikihash}->{'version'},
                        $tvars{user}->{'userid'},
                        $tvars{wikihash}->{'comment'},
                        $tvars{wikihash}->{'content'},
                        formatDate(0)
    );

    my @rows = $dbi->GetQuery('hash','GetWikiIndex',$tvars{wikihash}->{'pagename'});
    if(@rows) {
        $dbi->DoQuery('UpdateWikiIndex',$tvars{wikihash}->{'version'},$tvars{wikihash}->{'pagename'});
    } else {
        $dbi->DoQuery('InsertWikiIndex',$tvars{wikihash}->{'version'},$tvars{wikihash}->{'pagename'});
    }
}

sub History {
    return  if     RestrictedPage();
    return  unless CheckPage();
    return  if     LockedPage();

    my @rows = $dbi->GetQuery('hash','GetWikiHistory',$cgiparams{'pagename'});
    for (@rows) {
        $_->{postdate} = formatDate(20,$_->{createdate});
    }
    $tvars{wikihash}{history} = \@rows;
    $tvars{wikihash}{histmode} = 1;
}

sub Diff {
    return  if     RestrictedPage();
    return  unless CheckPage();

    if(!$cgiparams{diff1} || !$cgiparams{diff2}) {
#        $tvars{errcode} = 'MESSAGE';
        $tvars{errmess} = 'Need to supply two valid versions to check the differences!';
        return;
    }

    my $diff1 = GetPage($cgiparams{pagename},$cgiparams{diff1});
    my $diff2 = GetPage($cgiparams{pagename},$cgiparams{diff2});

    if(!$diff1 || !$diff2) {
#        $tvars{errcode} = 'MESSAGE';
        $tvars{errmess} = 'Need to supply two valid versions to check the differences!';
        return;
    }

    $tvars{wikihash}{diff1} = $diff1;
    $tvars{wikihash}{diff2} = $diff2;

    $tvars{wikihash}{diff0} = _differences($diff1,$diff2);
}

sub Search {
    if(!$cgiparams{data}) {
#        $tvars{errcode} = 'MESSAGE';
        $tvars{errmess} = 'Need to supply a search term!';
        return;
    }

    $tvars{wikihash}{key}     = $cgiparams{data};
    $tvars{wikihash}{checked} = $cgiparams{allversions};
    my $key = $cgiparams{allversions} ? 'WikiSearchFull' : 'WikiSearch';
    my @rows = $dbi->GetQuery('hash',$key,'%'.$cgiparams{data}.'%');
    for (@rows) {
        $_->{postdate} = formatDate(20,$_->{createdate});
    }
    $tvars{wikihash}{results} = \@rows  if(@rows);
}

sub Recent {
    my $limit = $cgiparams{entries} || 10;
    $limit = 10  unless($valid_limits{$limit});
    my @rows = $dbi->GetQuery('hash','WikiRecentChanges',{limit => "LIMIT $limit"});
    for (@rows) {
        $_->{postdate} = formatDate(20,$_->{createdate});
    }
    $tvars{wikihash}{recent} = \@rows;
    $tvars{wikihash}{entries} = $limit;
}

# -------------------------------------
# Private Methods

sub _redirect {
    my $page = shift;

       if($page eq 'People')        { $tvars{command} = 'user-list'; }
    elsif($page eq 'Login')         { $tvars{command} = 'user-login'; }
    elsif($page eq 'Search')        { $tvars{command} = 'wiki-search'; }
    elsif($page eq 'RecentChanges') { $tvars{command} = 'wiki-recent'; }
    else                            { $tvars{command} = 'wiki-page'; $cgiparams{pagename} = $page; }

    $tvars{errcode} = 'NEXT';
    return;
}

# Subroutine code based on CGI::Wiki::Plugin::Diff by Ivor Williams.
sub _differences {
    my ($d1,$d2) = @_;

    my $el1 = VCS::Lite->new($d1->{version},undef,_content_escape($d1->{content}));
    my $el2 = VCS::Lite->new($d2->{version},undef,_content_escape($d2->{content}));
    my $dlt = $el2->delta($el1) or return;

    my @out;

    for ($dlt->hunks) {
        my ($lin1,$lin2,$lin3,$lin4,$out1,$out2);
        for (@$_) {
            my ($ind,$line,$text) = @$_;
#            LogDebug("hunk:[$ind][$line][$text]");
            if ($ind =~ /^\+/) {
                if($lin1)   { $lin3 = $line }
                else        { $lin1 = $line }
                $out1 .= $text;
                $out1 .= '&nbsp;<br />'   if($text =~ /^$/);
            }
            if ($ind =~ /^\-/) {
                if($lin2)   { $lin4 = $line }
                else        { $lin2 = $line }
                $out2 .= $text;
                $out2 .= '&nbsp;<br />'   if($text =~ /^$/);
            }
        }

        my $left  = $lin3 ? "== Line $lin1-$lin3 ==" : $lin1 ?  "== Line $lin1 ==" : "== END OF FILE ==";
        my $right = $lin4 ? "== Line $lin2-$lin4 ==" : $lin2 ?  "== Line $lin2 ==" : "== END OF FILE ==";

#       push @out,{ left => $left, right => $right };
        my ($text1,$text2) = _intradiff($out1,$out2);
        push @out,{left => "$left<br />$text1", right => "$right<br />$text2"};
    }

    return \@out;
}

sub _content_escape {
    my $txt = shift;
    my @txt = split(/\n/,$txt);
    return \@txt;
}

sub _intradiff {
    my ($str1,$str2) = @_;
#    LogDebug("diff:[$str1][$str2]");

    return (qq{<span class="diff1">$str1</span>},'') unless $str2;
    return ('',qq{<span class="diff2">$str2</span>}) unless $str1;

    my $re_wordmatcher = qr(
            &.+?;                   #HTML special characters e.g. &lt;
            |<br\s*/>               #Line breaks
            |\w+\s*             #Word with trailing spaces
            |.                      #Any other single character
        )xsi;

    my @diffs = Algorithm::Diff::sdiff(
            [$str1 =~ /$re_wordmatcher/sg],
            [$str2 =~ /$re_wordmatcher/sg], sub {_get_token(@_)});
    my $out1 = '';
    my $out2 = '';
    my ($mode1,$mode2);

    for (@diffs) {
        my ($ind,$c1,$c2) = @$_;

        my $newmode1 = $ind =~ /[c\-]/;
        my $newmode2 = $ind =~ /[c+]/;
        $out1 .= '<span class="diff1">' if $newmode1 && !$mode1;
        $out2 .= '<span class="diff2">' if $newmode2 && !$mode2;
        $out1 .= '</span>' if !$newmode1 && $mode1;
        $out2 .= '</span>' if !$newmode2 && $mode2;
        ($mode1,$mode2) = ($newmode1,$newmode2);
        $out1 .= $c1;
        $out2 .= $c2;
    }
    $out1 .= '</span>' if $mode1;
    $out2 .= '</span>' if $mode2;

    ($out1,$out2);
}

sub _get_token {
    my $str = shift;
    $str =~ /^(\S*)\s*$/;   # Match all but trailing whitespace
    $1 || $str;
}

# -------------------------------------
# Admin Methods

=head1 ADMIN INTERFACE METHODS

=over 4

=item Admin

Checks whether user has admin priviledges.

=item Rollback

Rollbacks the given page by one version.

=item Delete

Deletes the given page.

=item Locks

Locks or unlocks the given page.

=back

=cut

sub Admin {
    return  unless AccessUser(ADMIN);
}

sub Rollback {
    return  unless AccessUser(ADMIN);
    LogDebug("Rollback: 1.version=$tvars{wikihash}{version}");
    return  unless CheckPage();
    LogDebug("Rollback: 2.version=$tvars{wikihash}{version}");

    my $version = $tvars{wikihash}{version} - 1;
    $dbi->DoQuery('DeleteWikiPage' ,$version,$tvars{wikihash}->{'pagename'});
    $dbi->DoQuery('UpdateWikiIndex',$version,$tvars{wikihash}->{'pagename'});
}

sub Delete {
    return  unless AccessUser(ADMIN);
    return  unless CheckPage();

    my $version = $tvars{wikihash}{version} - 1;
    $dbi->DoQuery('DeleteWikiPages',$tvars{wikihash}->{'pagename'});
    $dbi->DoQuery('DeleteWikiIndex',$tvars{wikihash}->{'pagename'});
}

sub Locks {
    return  unless AccessUser(ADMIN);
    return  unless CheckPage();

    my $lock = $tvars{wikihash}{locked} ? 0 : 1;
    $dbi->DoQuery('SetWikiLock',$lock,$tvars{wikihash}->{'pagename'});
}

=head1 INTERNAL METHODS

=over 4

=item CheckPage

Checks the page exists.

=item GetPage

Retrieves the page content for a given version or current page.

=item RestrictedPage

Checks whether the page is restricted.

=item LockedPage

Checks whether the page is locked.

=back

=cut

sub CheckPage {
    my $passthru = shift || 0;

    if($cgiparams{'pagename'}) {
        return 1    if($passthru);

        # retrieve the last known version
        $tvars{wikihash} = GetPage($cgiparams{'pagename'},$cgiparams{'version'});
        return 1;
    }

    $tvars{errcode} = 'ERROR';
    return 0;
}

sub GetPage {
    my ($p,$v) = @_;
    return  unless($p);

    my @rows;
    if($v) {
        @rows = $dbi->GetQuery('hash','GetWikiPageVersion',$p,$v);
    } else {
        @rows = $dbi->GetQuery('hash','GetWikiPage',$p);
    }

    return $rows[0] if(@rows);
    return;
}

sub RestrictedPage {
    if($cgiparams{pagename} =~ /^People|Login|Search|RecentChanges$/) {
        $tvars{errcode} = 'MESSAGE';
        $tvars{errmess} = 'This page is restricted.';
        return 1;
    }

    return 0;
}

sub LockedPage {
    if( $tvars{wikihash}->{locked} ) {
        $tvars{errcode} = 'MESSAGE';
        $tvars{errmess} = 'This page is locked.';
        return 1;
    }

    return 0;
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2008-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
