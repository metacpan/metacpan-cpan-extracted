package Kwiki::NavigationToolbar;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.02';
const class_id => 'navigation_toolbar';
const class_title => 'Kwiki Navigation Toolbar';
const navigation_toolbar_template => 'navigation_toolbar_pane.html';
const css_file => 'navigation_toolbar.css';
const config_file => 'navigation_toolbar.yaml';

sub html {
    my $nav = $self->pages->new_page($self->config->navigation_toolbar_page);
    my @navs = split/\n+/,$nav->content;
    my $content = join('|', map { "<a href=\"?$_->{name}\">$_->{display}</a>" }
			   map {
			       my ($name,$display) = split/,/;
			       $display ||= $name;
			       {name => $name, display => $display,}
			   }
		       @navs);
    $self->template->process(
	$self->navigation_toolbar_template,
	navigation_toolbar_content => $content
       );
}

=head1 NAME

Kwiki::Navigation_Toolbar - Navigation Toolbar

=head1 DESCRIPTION

This plugin provids an extra toolbar other then L<Kwiki::Toolbar>,
and you may manage it from web interface. Combine with
privacy feature provided from Kwiki 0.37, you may make a
simple content-manage system.

The idea is to have a special page contain the content of menu;
by default it's called C<KwikiNavigationToolbar>, it is not
created automatically, you'll have to edit it after you install
this plugin. This syntax inside is quite stright-forward:
one menu-item each line, contain a KwikiPageName, and an optional
label, seperated by a comma. For example:

    HomePage
    Research,My Research Topic
    PerlStudy,Study Perl

This create a menu with 3 items associated to "HomePage",
"Research","PerlStudy" respectively. If labels are not given,
page name are displayed.

Currently,L<Kwiki::Theme::ColumnLayout> make use of this plugin;
if you want to add it into your theme, place the following line
into somewhere of C<kwiki_screen.html>:

    [% hub.navigator_toolbar.html %]

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__DATA__
__css/navigation_toolbar.css__

__template/tt2/navigation_toolbar_pane.html__
<!-- BEGIN navigation_toolbar_pane.html -->
<div class="navigation_toolbar">
[% navigation_toolbar_content %]
</div>
<!-- END navigation_toolbar_pane.html -->
__config/navigation_toolbar.yaml__
navigation_toolbar_page: KwikiNavigationToolbar

