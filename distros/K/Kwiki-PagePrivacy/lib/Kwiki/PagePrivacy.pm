package Kwiki::PagePrivacy;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.10';

const class_id => 'page_privacy';
const cgi_class => 'Kwiki::PagePrivacy::CGI';
const config_file => 'page_privacy.yaml';

sub register {
    my $registry = shift;
    $registry->add(action => 'page_privacy_set');
    $registry->add(widget => 'page_privacy_select',
                   template => 'page_privacy_select.html',
                   show_for => 'display',
                  );
    $registry->add(hook => 'page:is_readable',
        post => 'is_readable',
    );
    $registry->add(hook => 'page:is_writable',
        post => 'is_writable',
    );
    $registry->add(hook => 'page:to_html',
        pre => 'linked_page_formatter',
    );
}

sub linked_page_formatter {
    my $page = $self;
    return unless io($page->file_path)->is_link;
    my $hook = pop;
    $hook->cancel;
    return '<pre>' . $self->html_escape($page->content) . '</pre>';
}

sub is_readable {
    my $page = $self;
    my $hook = pop;
    return unless $hook->returned_true;
    $self = $self->hub->page_privacy;
    my $privacy = $self->page_privacy($page);
    return 1 unless $privacy eq 'private';
    $self->privacy_group eq $self->page_group($page);
}

sub is_writable {
    my $page = $self;
    my $hook = pop;
    return unless $hook->returned_true;
    $self = $self->hub->page_privacy;
    my $privacy = $self->page_privacy($page);
    return 1 if $privacy eq 'public';
    $self->privacy_group eq $self->page_group($page);
}

sub page_privacy_set {
    return unless $self->page_privacy_selectable;
    my $privacy = $self->cgi->privacy;
    my $dir = $self->plugin_directory;
    my $id = $self->pages->current->id;
    my $group = $self->privacy_group;
    if ($privacy eq 'public') {
        io->dir("$dir/$id")->rmtree;
    }
    elsif ($privacy eq 'protected') {
        io->file("$dir/$id/group")->assert->print("$group\n");
        io->file("$dir/$id/protected")->assert->touch;
        io->file("$dir/$id/private")->unlink;
    }
    elsif ($privacy eq 'private') {
        io->file("$dir/$id/group")->assert->print("$group\n");
        io->file("$dir/$id/private")->assert->touch;
        io->file("$dir/$id/protected")->unlink;
    }
}

sub page_privacy_selectable {
    my $group = $self->privacy_group
      or return;
    my $page_group = $self->page_group
      or return 1;
    $group eq $page_group;
}

sub privacy_group {
    $self->config->privacy_group;
}

sub page_group {
    my $id = (shift || $self->pages->current)->id;
    my $dir = $self->plugin_directory;
    my $group_file = "$dir/$id/group";
    -f $group_file ? io($group_file)->chomp->getline : '';
}

sub page_privacy {
    my $id = (shift || $self->pages->current)->id;
    my $dir = $self->plugin_directory;
    -e "$dir/$id/private" ? 'private' :
    -e "$dir/$id/protected" ? 'protected' :
    'public';
}

package Kwiki::PagePrivacy::CGI;
use Kwiki::CGI -base;
cgi 'privacy';

package Kwiki::PagePrivacy;

__DATA__

=head1 NAME 

Kwiki::PagePrivacy - Kwiki Page Privacy Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/page_privacy_select.html__
[% IF hub.page_privacy.page_privacy_selectable %]
<script type="text/javascript">
function page_privacy_change(self) {
    iframe = document.getElementsByTagName("iframe")[0]
    iframe.src = '[% script_name %]?' +
                 'action=page_privacy_set&' +
                 'page_name=[% page_uri %]&' +
                 'privacy=' + self.value
}
</script>
<form>
[% privacy = hub.page_privacy.page_privacy %]
Page Privacy:<br />
<input type="radio" name="page_privacy" value="public" onchange="page_privacy_change(this)" [% IF privacy == 'public' %]checked[% END %] /> Public<br />
<input type="radio" name="page_privacy" value="protected" onchange="page_privacy_change(this)" [% IF privacy == 'protected' %]checked[% END %] /> Protected<br />
<input type="radio" name="page_privacy" value="private" onchange="page_privacy_change(this)" [% IF privacy == 'private' %]checked[% END %] /> Private<br />
<iframe height="0" width="0" frameborder="0"></iframe>
</form>
[% END %]
__config/page_privacy.yaml__
privacy_group:
