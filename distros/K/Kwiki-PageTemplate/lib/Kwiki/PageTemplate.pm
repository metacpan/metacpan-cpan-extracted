package Kwiki::PageTemplate;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.04';

use YAML;
use List::Util qw(max);

const class_id => 'page_template';
const cgi_class => 'Kwiki::PageTemplate::CGI';
const config_file => 'page_template.yaml';
const css_file => 'page_template.css';

field fields => {};
field previewed => 0;

sub register {
    my $reg = shift;
    $reg->add(action => 'new_from_page_template');
    $reg->add(action => 'edit_page_template_content');
    $reg->add(wafl   => field => 'Kwiki::PageTemplate::FieldPhrase');
    $reg->add(wafl   => page_template => 'Kwiki::PageTemplate::TemplateBlock');
    $reg->add(wafl   => page_template_display => 'Kwiki::PageTemplate::DisplayBlock');
    $reg->add(wafl   => page_template_fields  => 'Kwiki::PageTemplate::FieldBlock');
    $reg->add(wafl   => page_template_content => 'Kwiki::PageTemplate::ContentBlock');
}

sub init {
    super;
    $self->use_class('formatter');
}

sub new_from_page_template {
    my $fields = $self->fields_of($self->cgi->template_page);
    $self->fields($fields);
    my %raw = $self->cgi->vars;
    my %values;
    $values{$_} = $raw{"field_$_"} for keys %$fields;
    my $tpinfo = {template => $self->cgi->template_page, values => \%values};
    my $waflblock  = $self->make_page_template_content($tpinfo);
    $self->cgi->button eq $self->config->page_template_save_button_text ?
        $self->save_new_page($waflblock): $self->preview($waflblock,$tpinfo);
}

sub preview {
    my ($waflblock,$tpinfo) = @_;
    my $preview = $self->formatter->text_to_html($waflblock);
    $preview =~ s{</?(form|input)[^>]*?>}{}gs;
    my $page = $self->cgi->defined('save_to_page') ?
        $self->cgi->save_to_page : '';
    $self->previewed(1);
    $self->render_edit_form($tpinfo,$page,$preview);
}

sub save_new_page {
    my $content = shift;
    my $page = $self->get_page;
    $page->content($content);
    $page->store;
    $self->redirect($page->id);
}

sub make_page_template_content {
    my $mark = ".page_template_content\n";
    $mark.YAML::Dump(shift)."\n$mark";
}

sub extract_page_template_content {
    my $page_content = shift;
    $page_content =~ s{(\.page_template_content)\n(.+)\n\1}{$2}sg;
    YAML::Load($page_content);
}

sub render_edit_form {
    my ($content,$page_id,$preview) = @_;
    my $tp = $self->pages->new_page($content->{template})->content;
    while(my ($k,$v) = each %{$content->{values}}) {
        # XXX: $self->uri_escape() somehow doesn't work well
        $v =~ s/%/%25/g; $v =~ s/\n/%0A/g; $v =~ s/\r/%0D/g;
        $tp =~ s/{field:\s*$k(.*?)?}/{field: $k , value:$v}/sg;
    }
    my $html = $self->formatter->text_to_html($tp);
    my $save_to = $page_id ?
        qq{<input type="hidden" name="save_to_page" value="$page_id" />} :
        "<!-- No save_to_page -->";
    $html =~ s{(<input type="hidden" name="template_page" value=)".+?" />}
        {$1"$content->{template}" />$save_to}s;
    $self->render_screen(
        content_pane => 'page_template_edit_content.html',
        preview => $preview,
        page_template_content => $html
    );
}

sub edit_page_template_content {
    my $page_id = $self->cgi->page_id;
    my $ptc = $self->hub->pages->new_page($page_id)->content;
    my $content = $self->extract_page_template_content($ptc);
    $self->render_edit_form($content,$page_id);
}

sub fields_of {
    my $content = $self->hub->pages->new_page(shift)->content;
    my $mark = ".page_template_fields";
    $content =~ /$mark\n(.+?)$mark/s;
    YAML::Load($1);
}

sub get_page {
    $self->cgi->defined('save_to_page') ?
    $self->pages->new_page($self->cgi->save_to_page) :
    $self->create_page($self->cgi->page_id_prefix)   ;
}

sub create_page {
    my $prefix = shift;
    my $num = 1 + max(map {s/^.*?(\d+)$/$1/; $_} grep { /^$prefix/ }
			  $self->hub->pages->all_ids_newest_first);
    $self->pages->new_page("${prefix}${num}");
}

sub extract_display_block {
    my $content = shift;
    if( $content =~ /^\.page_template_display$/m ) {
        $content =~ s{.*(\.page_template_display)\s+(.*)\s+\1.*}{$2}s;
    } else {
        $content =~ s{.*(\.page_template)\s+(.*)\s+\1.*}{$2}s;
    }
    $content;
}

sub render {
    my ($template_page,$values) = @_;
    my $c = $self->extract_display_block
        ($self->pages->new_page($template_page)->content);
    $c =~ s/{field:\s*$_\s*.*}/$values->{$_}/ for keys %$values;
    $self->template_process(
	'page_template_content.html',
	content => $self->formatter->text_to_html($c)
       );
}

package Kwiki::PageTemplate::FieldBlock;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    $self->hub->page_template->fields(YAML::Load($self->block_text));
    "";
}

package Kwiki::PageTemplate::ContentBlock;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    my $p = YAML::Load($self->block_text);
    $self->hub->page_template->render($p->{template},$p->{values});
}

package Kwiki::PageTemplate::DisplayBlock;
use base 'Spoon::Formatter::WaflBlock';

sub to_html { '' }

package Kwiki::PageTemplate::TemplateBlock;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    my $plugin = $self->hub->page_template;
    my $prefix = $plugin->fields->{page_id_prefix}
        || $self->hub->config->page_template_page_id_prefix;
    $plugin->template_process(
	'page_template_form.html',
	template_page => $plugin->pages->current->id,
	content => $self->hub->formatter->text_to_html($self->block_text) ,
        page_template_page_id_prefix => $prefix
       );
}

package Kwiki::PageTemplate::CGI;
use base 'Kwiki::CGI';

cgi 'template_page';
cgi 'page_id';
cgi 'page_id_prefix';
cgi 'button' => '-utf8';
cgi 'save_to_page';

package Kwiki::PageTemplate::FieldPhrase;
use base 'Spoon::Formatter::WaflPhrase';

# Without default: {field: foo}
# Default value: {field: foo, value:bar}
# the value of "value:" should be URI-escaped.
# Because wafl-phrase can only in a single line.
sub to_html {
    my $fields = $self->hub->page_template->fields;
    my ($name,$defvalue) = split/\s+,\s*value:\s*/,$self->arguments;
    my $type = $fields->{$name};
    $defvalue = $self->uri_unescape($defvalue||'');
    $name = "field_$name";
    if($type eq 'textarea') {
	return qq{<textarea name="$name">$defvalue</textarea>};
    } elsif (ref($type) eq 'ARRAY') {
	my $ret = qq{<select name="$name">};
        my $selected = '';
	for(@$type) {
            $selected = 'selected' if($defvalue eq $_);
	    $ret .= qq{<option value="$_" $selected >$_</option>};
	}
	$ret .= "</select>";
	return $ret;
    }
    qq{<input type="text" name="$name" value="$defvalue"/>};
}

package Kwiki::PageTemplate;

1;

=head1 NAME

  Kwiki::PageTemplate - pre-fill kwiki page with this template

=head1 SYNOPSIS

Paste this into your SandBox and visit the SandBox.

  .page_template_fields
  page_id_prefix: Resume
  name: text
  gender:
      - Woman
      - Woman-in-man
  bio: textarea
  .page_template_fields

  .page_template
  = Resume form

  My name: {field:name}

  Email: {field:name}

  Biograph:
  {field:bio}
  .page_template

  Fill the above form and you will probabally get the job.

=head1 DESCRIPTION

This purpose of this plugin is to let your Kwiki User edit
pages even more easily. They only have to type some characters
into a given form, submit it, and done. Not even Kwiki formatter
syntax knowledged required.

The basic idea is from mac.com hompage editing, they provide a nearly
WYSIWYG web interface to edit your homepage, because the have many
pr-defined HTML templates, which are a big form, after you submit that
form, what you just inputed replace the original input fields, becomes
the content of the generated page.

The "page_template_fields" wafl block is a YAML block where you can
define your form variables, and their input types, if the type is a
array, it'll become a pull-down select menu. After user submit the
form, this plugin will generate a page prefixed with the value
"page_template_page_id_prefix", default to "PageTemplateGenerated" in
your config/page_template.yaml, but you may specify "page_id_prefix"
in the page_template_fields wafl block to override this. The example
given in SYNOPSIS demostrate this feature, let the form generate a
page named like "Resume3", the number afterwards are increased
automatically each time somebody submit the form.

By default, the generated page will preserve same look as in the
"page_template" block. But if you want to display the generated page
in another look, you may write the template code in
"page_template_display" wafl block.

This plugin is still in it's early development and currently,
re-editing the generated page is not implemented, and something may
break in the future. So use it at your on risk.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__DATA__
__css/page_template.css__
.page_template textarea
{ 
  width: 40em;
  height: 20em;
}

__config/page_template.yaml__
# DO NOT EDIT THIS FILE
# Put overrides in the top level config.yaml
# See: http://www.kwiki.org/?ChangingConfigDotYaml
#
page_template_save_button_text: SAVE
page_template_edit_button_text: EDIT
page_template_preview_button_text: PREVIEW
page_template_page_id_prefix: PageTemplateGenerated
__template/tt2/page_template_form.html__
<form class="page_template" method="POST">
<input type="hidden" name="action" value="new_from_page_template" />
<input type="hidden" name="page_id_prefix" value="[% page_template_page_id_prefix %]" />
<input type="hidden" name="template_page" value="[% template_page %]" />
[% IF hub.have_plugin('edit') || hub.page_template.previewed %] <input type="submit" name="button" value="[% page_template_save_button_text %]" /> [% END %]
<input type="submit" name="button" value="[% page_template_preview_button_text %]" />
[% content %]
[% IF hub.have_plugin('edit') || hub.page_template.previewed %] <input type="submit" name="button" value="[% page_template_save_button_text %]" /> [% END %]
<input type="submit" name="button" value="[% page_template_preview_button_text %]" />
</form>
__template/tt2/page_template_content.html__
<form method="POST">
<input type="hidden" name="action" value="edit_page_template_content" />
<input type="hidden" name="page_id" value="[% page_uri %]" />
[% IF hub.have_plugin('edit') -%]
<input type="submit" name="button" value="[% page_template_edit_button_text %]" />
[%- END %]
[% content %]
[% IF hub.have_plugin('edit') -%]
<input type="submit" name="button" value="[% page_template_edit_button_text %]" />
[%- END %]
</form>
__template/tt2/page_template_edit_content.html__
[% IF preview -%]
<h2>This is a preview page, press SAVE button to save</h2>
[% preview %]
<hr />
[%- END %]
[% page_template_content %]
