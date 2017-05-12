package Kwiki::URLBlock;
use Kwiki::Plugin -Base;
use Kwiki::Installer -base;

our $VERSION = '0.05';

const class_id    => 'urlblock';
const class_title => 'URL Block';
const config_file => 'urlblock.yaml';

sub register {
    require URI::Find;
    my $registry = shift;
    $registry->add(hook => 'edit:save', pre => 'urlblock_hook');
    $registry->add(action => 'blocked_url');
}

sub urlblock_hook {
    my $hook = pop;
    my $urlblock = $self->hub->urlblock;
    my $old_page = $self->hub->pages->new_page($self->pages->current->id);
    my @old_urls = $urlblock->get_urls($old_page->content);
    my @urls = $urlblock->get_urls($self->cgi->page_content);
    my @new_urls = $urlblock->get_new_urls(\@old_urls, \@urls);
    if (@new_urls && $urlblock->is_blocked(\@new_urls)) {
	$hook->cancel();
	return $self->redirect("action=blocked_url");
    }
}

sub get_urls {
    require URI::Find;
    my ($content) = @_;
    my @list;
    my $finder = URI::Find->new( sub {
        my($uri, $orig_uri) = @_;
        push @list, $uri;
        return $orig_uri;
    });
    $finder->find(\$content);
    return @list;
}

sub get_new_urls {
    my ($old_urls, $urls) = @_;
    my @new_urls;
    my %old = map { $_ => 1 } @$old_urls;
    foreach my $url (@$urls) {
	push @new_urls, $url unless $old{$url};
    }
    return @new_urls;
}

sub is_blocked {
    my ($new_urls) = @_;
    my $max_allowed = $self->config->urlblock_max_allowed;
    if ($max_allowed && @$new_urls > $max_allowed) {
	return 1;
    }
    my $blacklist = $self->blacklist($self->config->urlblock_blacklist);
    return unless $blacklist;
    foreach (@$new_urls) {
	return 1 if /$blacklist/;
    }
    return;
}

sub blacklist {
    my ($path) = @_;
    my $file = io($path);
    return unless $file->exists;
    my $list = $file->slurp;
    $list =~ s/\#.*//g;
    $list =~ s/\s+/|/g;
    $list =~ s/^\|//g;
    $list =~ s/\|$//g;
    return qr/$list/;
}

sub blocked_url {
    return $self->render_screen(
        content_pane => 'blocked_url.html',
    );
}

__DATA__

=head1 NAME

Kwiki::URLBlock - Blocks edit based on added URLs

=head1 DESCRIPTION

It blocks an edit if you add too many URLs or if you enter a
blacklisted one.

=head2 Configuration

The default config variables that you can override in config.yaml are:

 urlblock_max_allowed: 3
 urlblock_blacklist:

urlblock_blacklist is a path to a blacklist file.

The syntax is a list of newline separated regexps. Anything after # is
treated as a comment. Whitespace is ignored.

Example taken from L<http://wiki.mozilla.org/wiki/Spam_blacklist>:

 # some known "bad" domains
 ltjz2000\.com
 ticketsmyway\.com
 emmss\.com
 [0-9][0-9][0-9][0-9][0-9][0-9]*\.com # 5 or more character numeric .coms
 # some words frequently used by spammers in urls
 camgirl
 parishilton
 online-casino

=head1 AUTHORS

Jon Aslund <aslund.org>, Jooon at #kwiki on Freenode

=head1 SEE ALSO

L<Kwiki>
L<URI::Find>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Jon Aslund

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__template/tt2/blocked_url.html__
<div class="error">
<p>You were blocked from editing because your edit contains either too many
new URLs or some URL that is banned.</p>
</div>
__config/urlblock.yaml__
urlblock_max_allowed: 3
urlblock_blacklist:
