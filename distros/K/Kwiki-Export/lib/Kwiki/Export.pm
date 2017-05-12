package Kwiki::Export;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use Kwiki;

our $VERSION = '0.02';

const class_id => 'export';
const class_title => 'Export Content';
const cgi_class => 'Kwiki::Export::CGI';
const config_file => 'export.yaml';

use Archive::Any::Create;
use DirHandle;
use File::Spec;
use HTML::WikiConverter;

sub register {
    my $registry = shift;
    $registry->add(action => 'export');
    $registry->add(toolbar => 'export_button',
                   template => 'export_button.html',
                   show_for => [ 'display', 'revisions', 'edit', 'edit_contention' ]);
}

sub export {
    my $page = $self->pages->current;
    my $formatter = $self->cgi->formatter || $self->config->default_export;

    if ($self->cgi->export_all) {
        return $self->export_all($formatter);
    }

    my $content = $self->cgi->revision_id
        ? $self->hub->archive->fetch($page, $self->cgi->revision_id)
        : $page->content;

    $content ||= $self->config->default_content;
    if ($formatter) {
        $content = $self->convert_wiki($self->hub->formatter->text_to_html($content), $formatter);
    }

    $self->render_screen(
        screen_title => $page->title,
        page_content => $content,
        formatter    => $formatter,
        formats      => [ $self->get_dialects ],
    );
}

sub export_all {
    my $formatter = shift;
    my $ext  = $self->hub->config->export_format;
    my $name = "kwiki-$formatter.$ext";
    my $archive = Archive::Any::Create->new;
    $archive->container("kwiki-$formatter");
    for my $page ($self->pages->all) {
        my $newformat = $self->convert_wiki($page->to_html, $formatter);
        $archive->add_file($page->id, $newformat);
    }

    print "Content-Type: application/octet-stream; name=$name\r\n",
        "Content-Disposition: attachment; filename=$name\r\n\r\n";
    $archive->write_filehandle(\*STDOUT, $ext);
    return '';
}

sub get_dialects {
    my @dialects;
    for my $inc (@INC) {
        my $dir = File::Spec->catfile($inc, 'HTML', 'WikiConverter');
        my $dh  = DirHandle->new($dir) or next;
        while (my $f = $dh->read) {
            next if $f !~ /^(\w+)\.pm$/ || $f eq 'Kwiki.pm';
            push @dialects, $1;
        }
    }
    return @dialects;
}

sub convert_wiki {
    my($html, $formatter) = @_;
    utf8::encode($html);
    my $c = HTML::WikiConverter->new( dialect => $formatter );
    my $wiki = $c->html2wiki($html);
    utf8::decode($wiki);
    $wiki;
}

package Kwiki::Export::CGI;
use base 'Kwiki::CGI';
cgi 'formatter';
cgi 'revision_id';
cgi 'export_all';

package Kwiki::Export;


1;
__DATA__

=head1 NAME

Kwiki::Export - export Kwiki content into other Wiki formats

=head1 SYNOPSIS

  % echo Kwiki::Export >> plugins
  % kwiki -update

=head1 DESCRIPTION

Kwiki::Export is a Kwiki plugin to export Kwiki saved page into other
Wiki formats like MediaWiki, using L<HTML::WikiConverter> modules. You
can export all the pages on your Wiki into a single zip file, too, in
an original Kwiki format or other Wiki dialects supported by
HTML::WikiConveter.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::WikiConverter>, L<Kwiki::Edit>

=cut

__config/export.yaml__
default_export: Kwiki
export_format: zip
__template/tt2/export_content.html__
<form method="POST">
<select name="formatter">
<option value="">Kwiki</option>
[% FOREACH f = formats %]
<option [% IF formatter == f %]selected="selected"[% END %] value="[% f %]">[% f %]</option>
[% END -%]
</select>
<input type="submit" value="Export This Page" />
<input type="submit" name="export_all" value="Export All Pages" />
<br />
<br />
<input type="hidden" name="action" value="export" />
<textarea name="page_content" rows="25" cols="80" onfocus="this.select()">
[%- page_content -%]
</textarea>
</form>
__template/tt2/export_button.html__
[% rev_id = hub.have_plugin('revisions') ? hub.revisions.revision_id : 0 %]
<a href="[% script_name %]?action=export;page_name=[% page_uri %][% IF rev_id %];revision_id=[% rev_id %][% END %]" accesskey="x" title="Export This Page">
[% INCLUDE export_button_icon.html %]
</a>
__template/tt2/export_button_icon.html__
 Export
