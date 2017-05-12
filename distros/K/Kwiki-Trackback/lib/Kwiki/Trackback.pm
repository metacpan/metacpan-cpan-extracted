package Kwiki::Trackback;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

const class_id             => 'trackback';
const class_title          => 'Trackback';
const cgi_class            => 'Kwiki::Trackback::CGI';

our $VERSION = '0.01';

sub register {
    my $registry = shift;
    $registry->add(action => 'trackback_ping');
    $registry->add(widget => 'trackback_pings',
                template => 'trackbacks.html',
                show_for => 'display',
            );
    $registry->add(status => 'trackback_info',
                   template => 'trackback_info.html',
                   show_for => 'display',
               );
    super;
}


## minimize extent of cgi processing #####
# receive a ping
sub trackback_ping {
    my $page_id = $self->cgi->trackback_id;
    my $content = $self->ping_content;
    $self->trackback_ping_receive($page_id, $content);
}
#
# extra ping contents
sub ping_content {
    +{ url => $self->cgi->url,
      title => $self->cgi->title,
      blog_name => $self->cgi->blog_name,
      excerpt => substr($self->cgi->excerpt, 0, 100),
    };
}
#
##########################################


sub trackback_ping_receive {
    my $page_id = shift;
    my $content = shift;
    require Net::Trackback::Message;
    my $msg = Net::Trackback::Message->new();
    # don't trackback for just anybody
    if ($self->hub->pages->new_from_name($page_id)->exists) {
        $self->store_ping($page_id, $content)
        ? $msg->code(0)
        : $msg->code(1);
    } else {
        $msg->code(1);
    }
    $msg->to_xml;
}

sub store_ping {
    my $id = shift;
    my $content = shift;
    require Storable;
    Storable::lock_store(
        $content,
        $self->path_to_store($id) . '/' . $self->md5_name($id, $content),
    );
}

sub md5_name {
    require Digest::MD5;
    use bytes;
    my $id = shift;
    my $content = shift;
    Digest::MD5::md5_hex($id . $content->{url} . time);
}


sub path_to_store {
    my $id = shift;
    my $dir = $self->plugin_directory . '/' . $id;
    mkdir($dir); # XXX better to skip the stat or not?
    return $dir;
}


# return a list of trackbacks for presentation
sub trackbacks {
    my $page_id = $self->hub->pages->current->id;
    [
        map{ Storable::lock_retrieve($_) }
        sort { $a->mtime <=> $b->mtime }
         io($self->path_to_store($page_id))->all_files
    ];
}

sub identifier {
    my $url = CGI::url(-full => 1);
    $url . '?' . $self->hub->pages->current->uri;
}

sub ping_url {
    my $url = CGI::url(-full => 1);
    $url . '?action=trackback_ping;trackback_id=' .
        $self->hub->pages->current->uri;
}

package Kwiki::Trackback::CGI;
use base 'Kwiki::CGI';

cgi 'trackback_id';
cgi 'trackback_ping';
cgi 'url';
cgi 'title';
cgi 'excerpt';
cgi 'blog_name';

package Kwiki::Trackback;

__DATA__

=head1 NAME

Kwiki::Trackback - Provide a trackback server within Kwiki and a place to
display those trackbacks.

=head1 DESCRIPTION

Trackback is a protocol developed by Six Apart to facillitate conversation
amongst disparate content sources. It was first used between blogs, but is
useful for proactively telling any piece of content that something out there
is talking about it.

You can see Kwiki::Trackback in action at L<http://www.burningchrome.com/wiki/>

=head1 AUTHORS

Chris Dent, <cdent@burningchrome.com>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__template/tt2/trackbacks.html__
<!-- BEGIN trackback -->
<div style="font-family: Helvetica, Arial, sans-serif; overflow: hidden;"
     id="trackbacks">
<a style="text-align: center;font-size: x-small" href="[% hub.trackback.ping_url %]">Trackback URL</a>
[% trackbacks = hub.trackback.trackbacks %]
[% IF trackbacks.size %]
<h3 style="font-size: small; text-align: center; letter-spacing: .25em; padding-bottom: .25em;">TRACKBACKS</h3>
[% FOREACH link = trackbacks %]
<div class="trackback_title"
     style="font-size: small; display:block; 
     text-decoration: none; padding-bottom: .25em;">
   <a href="[% link.url %]">[% link.blog_name %] [% link.title %]</a>
</div>
<div class="trackback_summary" style="font-size: small;
   padding-bottom: .25em; padding-left: 1em;">
   [% link.excerpt %]
</div>
[% END %]
[% END %]
</div> 
<!-- END trackback -->
__template/tt2/trackback_info.html__
<div id="trackback_info">
<!-- BEGIN trackback_info -->
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
         xmlns:trackback="http://madskills.com/public/xml/rss/module/trackback/"
         xmlns:dc="http://purl.org/dc/elements/1.1/">
<rdf:Description
    rdf:about="[% hub.trackback.identifier %]"
    trackback:ping="[% hub.trackback.ping_url %]"
    dc:title="[% self.uri_escape(hub.pages.current.title) %]"
    dc:identifier="[% hub.trackback.identifier %]" />
</rdf:RDF>
</div>
<!-- END trackback_info -->
