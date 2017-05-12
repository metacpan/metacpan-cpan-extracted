package Kwiki::Theme::BlueOcean;

use warnings;
use strict;
use Kwiki::Theme '-Base';
use mixin 'Kwiki::Installer';
use Template::Stash;
our $VERSION = '0.01';

const theme_id          => 'blueocean';
const class_title       => 'Blue Kwiki Theme';

$Template::Stash::SCALAR_OPS->{'image_desc'} = sub {
	$_[0] =~ s/alt\s*=\s*"([^\"]+)"([^\>]*)\>/alt="$1" $2> <span class="alt">$1<\/span>/gi;
	return $_[0];
};

sub register {
	super
	my $registry = shift;
	$registry->add(hook => 'user_preferences:preference_objects',
		post => 'tweak_kwiki_user_name_query',
	);
	$registry->add(hook => 'user_preferences:preference_objects',
		post => 'remove_show_icons_option',
	);
	$registry->add(hook => 'user_preferences:user_preferences',
		pre => 'redirect_on_pref_save',
	);
	$registry->add(hook => 'icons:init',
		post => 'add_local_template_path',
	);
}

sub add_local_template_path {
	$self->template->add_path('local/template');
}

sub tweak_kwiki_user_name_query {
	my $new_text = <<HTML;
Enter a UserName to identify yourself.<br />
<small>(Must be alphanumeric with NO whitespace)</small>
HTML
	return [map {
		$_->query($new_text)
			if $_->id eq 'user_name';
		$_;
	} @{$_[-1]->returned}];
}

sub remove_show_icons_option {
	return [grep {
		$_->id ne 'use_icons'
	} @{$_[-1]->returned}];
}

sub redirect_on_pref_save {
	$self->get_preference_objects;
	my $errors = 0;
	if( $self->cgi->button ) {
		$errors = $self->save;
		unless( $errors ) {
			$_[-1]->cancel();
			return $self->redirect($self->pages->current->uri);
		}
	}
}

1; # End of Kwiki::Theme::BlueOcean

__DATA__

=head1 NAME

Kwiki::Theme::BlueOcean - Blue Kwiki Theme

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	$ cd /path/to/kwiki
	$ kwiki --remove Kwiki::Theme::YourCurrentTheme
	$ kwiki --add Kwiki::Theme::BlueOcean

=head1 TODO

=over

=item

Get rid of dependency on Kwiki::TableOfContents. This would probably require
me to get rid of the abosute positioning.

=item

The theme includes a link to Kwiki::TableOfContents::Print. Make this optional.

=item

Remove dependency on Kwiki::UserPreferences and Kwiki::Icons. This would
probably just be a matter of doing a quick check before tweaking those modules.

=cut

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See http://www.perl.com/perl/misc/Artistic.html

=cut
__theme/blueocean/css/kwiki.css__
#title_pane, h1, h2, h3, h4, h5, h6 {
    background-color: rgb(220, 225, 235);
    border: thin solid rgb(83, 86, 140);
    margin: 0px;
    padding: 2px;
}
#title_pane,
#title_pane a {
    font-weight: bold;
    font-size: 20px;
}
#toolbar_pane {
    margin: 2px;
}
.toolbar .img {
	vertical-align: top;
}

#heading,
#content_pane,
#toc_pane,
#toc_toggler {
	position: absolute;
	overflow: auto;
	margin: 0px;
	padding: 0px;
}

#heading {
	height: 100px;
	top: 0px;
	left: 0px;
	width: 100%;
	overflow: hidden;
}
#content_pane {
	top: 100px;
	bottom: 0px;
	left: 30px;
	right: 0px;
	padding-right: 10px;
	padding-bottom: 10px;
}
#toc_pane {
	top: 100px;
	left: 0px;
	width: 220px;
	bottom: 0px;
	border-width: 1px;
	border-right-width: 0px;
	border-style: solid;
	border-color: #000000;
}
#toc_toggler {
	top: 100px;
	left: 0px;
	width: 20px;
	bottom: 0px;
	background-color: rgb(220, 225, 235);
	font-weight: bold;
	text-align: center;
	border-width: 1px;
	border-left-width: 0px;
	border-style: solid;
	border-color: #000000;
	cursor: pointer;
}

.navLink:after { content: " | "; }

a:link, a:visited       { color: #333333 }
a.empty                 { background-color: yellow }

body {
    font-family: sans-serif;
    font-size: 12px;
    color: black;
    background-color: white;
}

th, td {
	font-size: 12px;
}

@media screen {
	body {
		overflow: hidden;
		margin: 0px;
		height: 100%;
	}
}

em, a, i {
	font-size: 12px;
	margin: 0px;
	padding: 0px;
}

em {
	font-style: normal;
	color: red;
	text-decoration: none;
}

hr {
    border: 0px;
    padding: 0px;
    margin: 0px;
    clear: both;
    height: 1px;
    background-color: white;
    border-bottom: 1px solid rgb(220, 225, 235);
}

#bread_crumb_trail hr {
	display: none;
}

.error    {color: red;}

ul { list-style-type: circle }

pre {
    background-color: white;
    border: none;
}

input[type=text] {
    height: 14px;
    font-family: sans-serif;
    font-size: 11px;
    color: rgb(83, 86, 140);
    border: 1px solid rgb(83, 86, 140);
    padding: 2px;
}

input[type=submit],
input[type=button] {
    background-color: rgb(83, 86, 140);
    color: white;
    font-weight: bold;
}

form.edit input { position: absolute; left: 3% }

@media print {
	#toc_pane,
	#toc_toggler,
	#toolbar_pane,
	#status_pane {
		display: none;
	}
	#content_pane,
	#heading {
		overflow: visible;
		position: static;
		height: auto;
		width: 100% !important;
	}
}

.example,
.workaround,
.greenbox,
.graybox {
	margin-left: 2em;
	margin-right: 2em;
}

.example,
.graybox {
	background-color: rgb(238, 238, 238);
}

.greenbox,
.workaround {
	background-color: #a7fea4;
}

.warning {
	margin-left: 2em;
	margin-right: 2em;
	margin-top: 1ex;
	margin-bottom: 1ex;

	padding-left: 2em;
	padding-right: 2em;
	padding-top: 1ex;
	padding-bottom: 1ex;

	background-color: #c80202;
	border-width: 2px;
	border-style: solid;
	border-color: #000000;

	color: white;
}

.warning h1 {
	border-width: 0px;
	background-color: transparent;
}
__theme/blueocean/template/tt2/theme_tableofcontents.html__
<div id="toc_pane" style="display: none">
[% IF hub.have_plugin('toc') %]
[% INCLUDE toc_setup.html %]

<script type="text/javascript">
	JSTree.start({
		edit_img:       'theme/blueocean/images/edit.gif',
		open_img:       'theme/blueocean/images/expand.gif',
		close_img:      'theme/blueocean/images/collapse.gif',
		delete_img:     'theme/blueocean/images/trash.gif',
		newcat_img:     'theme/blueocean/images/new_folder.gif',
		afterStart:     function() {
			var toc = JSTree.tree('toc');
			Event.observe('collapse_all', 'click',
				toc.observable_method('collapse_all'));
			Event.observe('show_all', 'click',
				toc.observable_method('expand_all'));
			Event.observe('edit', 'click',
				toc.observable_method('toggle_edit'));
			Event.observe('edit', 'click', function() {
				$('edit').value = $('edit').value == 'Edit'
					? 'Done Editing' : 'Edit';
			});
			var title_links = $A($('title_pane').getElementsByTagName('a'))
			title_links.each(function(link) {
				link.setAttribute('href', '?'+link.innerHTML);
			});
			JSTree.nodable(title_links);

			var old_toggler_indent = '220px';
			var old_content_indent = '250px';
			toggle_toc = function() {
				Element.visible($('toc_pane')) ?
					Element.hide($('toc_pane')) :
					Element.show($('toc_pane'));
				var tmp = Element.getStyle('toc_toggler', 'left');
				$('toc_toggler').style.left = old_toggler_indent;
				old_toggler_indent = tmp;

				tmp = Element.getStyle('content_pane', 'left');
				$('content_pane').style.left = old_content_indent;
				$('content_pane').style.width = document.body.clientWidth - parseInt(old_content_indent) + "px";
				old_content_indent = tmp;
			}
			Event.observe('toc_toggler', 'click', toggle_toc);
		}
	});
</script>

<input type="button" id="collapse_all" value="Collapse All" />
<input type="button" id="show_all" value="Show All" />
[% INCLUDE toc.html %]
<input type="button" id="edit" value="Edit" />
<a href="?action=print_toc;page_name=[% page_uri %]" target="_blank">Print Section</a>

[% END %]
</div>
<div id="toc_toggler">
T<br />
a<br />
b<br />
l<br />
e<br />
<br />
o<br />
f<br />
<br />
C<br />
o<br />
n<br />
t<br />
e<br />
n<br />
t<br />
s<br />
</div>
__theme/blueocean/template/tt2/theme_screen.html__
[%- INCLUDE theme_html_doctype.html %]
[% INCLUDE theme_html_begin.html %]

<div id="heading">
[% INCLUDE theme_title_pane.html %]
[% INCLUDE theme_toolbar_pane.html %]
[% INCLUDE theme_status_pane.html %]
<hr />
</div>

[% IF hub.cgi.action == 'display' || hub.cgi.action == '' %]
[% INCLUDE theme_tableofcontents.html %]
[% END %]

[% INCLUDE theme_content_pane.html %]

[% INCLUDE theme_html_end.html -%]
__theme/blueocean/template/tt2/theme_html_doctype.html__

[%- INCLUDE kwiki_doctype.html %]
__theme/blueocean/template/tt2/theme_html_begin.html__

[%- INCLUDE kwiki_begin.html %]
<!--[if IE]>
<style type="text/css">
#content_pane {
	height: expression(document.body.clientHeight - 100 + "px");
	width: expression(document.body.clientWidth - 30 + "px");
}
#toc_pane {
	height: expression(document.body.clientHeight - 100 + "px");
}
#toc_toggler {
	height: expression(document.body.clientHeight - 100 + "px");
}
</style>
<![endif]-->
__theme/blueocean/template/tt2/theme_html_end.html__
[% INCLUDE kwiki_end.html -%]

__theme/blueocean/template/tt2/theme_logo_pane.html__
<div id="logo_pane">
<img src="[% logo_image %]" align="center" alt="Kwiki Logo" title="[% site_title %]" />
</div>
__theme/blueocean/template/tt2/theme_title_pane.html__
<div id="title_pane">
[% screen_title || self.class_title %]
</div>
__theme/blueocean/template/tt2/theme_toolbar_pane.html__
<div id="toolbar_pane">
[% hub.toolbar.html.image_desc %]
[% INCLUDE theme_login_pane.html %]
</div>
__theme/blueocean/template/tt2/theme_login_pane.html__
[% IF hub.have_plugin('user_name') %]
[% INCLUDE user_name_title.html %]
[% END %]
__theme/blueocean/template/tt2/theme_status_pane.html__
<div id="status_pane">
[% hub.status.html %]
</div>
__theme/blueocean/template/tt2/theme_widgets_pane.html__

__theme/blueocean/template/tt2/theme_content_pane.html__
<div id="content_pane">
[% INCLUDE $content_pane %]
</div>
__theme/blueocean/template/tt2/theme_toolbar2_pane.html__
<div id="toolbar2_pane">
[% hub.toolbar.html %]
</div>
__theme/blueocean/images/collapse.gif__
R0lGODlhEAAQAMQAAMlLSeZ9ff6rrd1kZM9cW//BwuZub/GCg//MzNBTUtNta/+7vP7i4tVZWctL
SvaIiuRrbOx6e+J0dP/Gx/+1tuZzc+Bpaf/FztZSUu9/gPaJivSGh////wAAAAAAAAAAACH5BAEH
ABwALAAAAAAQABAAAAVJICeOZGmeaKqurDgJArUUE2Ij07QszGAZlUjmsNFoNodMpBJINBoDH8RA
rUIsEoA24XxCo9GGRUsuO85ognrNbhMUrbh8Ti+FAAA7
__theme/blueocean/images/expand.gif__
R0lGODlhEAAQANUAAHepUrXekpHJauTx2+Ds2Iq/Y5vYcM/lv4awZ+/46YO8WpbTa63Yi47AasHg
rOX214C3WYe7YojEXpTPa36uXN7v3pnWbdDtvIfCXY/GaOj04HutUoO1X4vEY9731vL47q3ejNbv
vQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEHAB8ALAAAAAAQABAAAAaBwI9Q
mGAEjsNkchBpNCIDpXKgKBQUUelwgMlkJFntR9MRmDVKjefBvkzekwubnfBm4BaD3sKfmDsdXm95
egYLC2YCgIkTh46HiQqSEpRwE4CUEgoHnJwOgRkdDp2caVVXaGIfAxARERBhWgQbHBwbBKofBAAU
FAC4qgQUCAgUwENBADs=
__theme/blueocean/images/edit.gif__
R0lGODlhEAAQAOYAAFWEt+rTudnCsLeomPPcvK+6xnqs5bijoPPU06XD4OXWx46erePQu9deXuHW
zfTq3da+r8nGwMva5W6h2N/Pt2GBpff09MSyrPvqy+zYvpGw0c26qGiPuIK39ejc1Pfmx97OvYup
x/Dew4235+TOt//4zt3HtO/bwPjGx+Ln7bXBzvPs6FOKxmuXyO7h14W38O3S0P/uyP/m3v7397W9
ztRlY9Xb3Y676//41OjUvO/jx/TgxdfCtta9tf7wze7l1lWHu7WtnMLFxsa5sv3p6v///wAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5
BAEHAEUALAAAAAAQABAAAAevgEWCg4SFRRACJoqLPBaGAhknJzuUHworM4UmDIokDJ8MMw+CRCgz
Ajk5kZM7OQoKHkUwDTWQGRkiIh+7uQ43EgcIm4oUFKAMBBodLTZFApMfGD4+ONUqHRMhgsPExgER
LwYcmc6quLofOiMvACmDkLm7GDEJHUAFhIv61ywLMoSoUt3a8UNIBREuAJIgkeoEhQEXhuSI9U6f
iQ0DbmWgKAgCiQABbonYIekExyKBAAA7
__theme/blueocean/images/new_folder.gif__
R0lGODlhIAAgAOYAAHyqWuTQvsGzq6+bk/Hk0abQie/j177dqZDIae7dx+7n5c7CuLDMnJnJct/M
uYvAZOfe0fbt4+jWwvjr1cGsoNS9sNvGtrXPjpfUbd3MxJvNd/n397/Tmufd2NXKwP7w1s22rOzY
w42/aL2mnObTwKfXgPr05bnSkf/z3dTDvc3nupTOa8Wvo9vIu4S2X/Dn4LejmqrUjL/dmuTVy93P
yrXTn9S/tMm8s/Dr6Y3EZprWb+DNu5zace/gzdDdq/ju3Pz36sLfno/GaPz59qPIfOnh3s66rMW1
pbrXltjDtPXw7/fm3raelrbNkfjq1Pf37/bmzr3cp/70397WxajTirLPnZ7Deb2tpdrJwuDXzLfU
oca0rq3ejPLt7JrXcLrYpLTdkebW1sy2qLWllAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5
BAEHAEMALAAAAAAgACAAAAf/gEOCg4SFhoeIiYqLjI2Oj5CQXR0pHohKCkU4iRuYHTNYKUYgYimF
G1gtLQEBCYKdCp8ZLUm1SRUgLCMjTFuFOBYJwsOpLTusARZGujDNVzceWQZAJiZACikBEtsSwxIO
FcwwAgs0EC8/UupOUMIhCSkWJPMkSWIUu8/RBunqExNQAgbsMWyJAmMBjAwgZw7dD4ACoTiZODFi
D4ImUO3YASPLBAI9Qoh8lyDiv5MQoVzsIYiGBQcjNrLaNiyikw84cbIb2IOAoA5JLIxwMJOmMJs5
P1TkuUQQjgpJhhbtVjMgRYoCLyaI8KpCBRjHtBk9GhGKDy5gwPggKAzIoBRf8MOKpVo1YBMReC8M
czWIhhEYRKfSXXnxwoPDeocR6iAGcOC5dPdeEEL5wkiWg7o0dsAZGbexwk6sGH2Cm4FCIBx39ryN
AxIZsEtgmF0iiO0gKgilgKHKmFx6OXIgGI3Bi3Evs1cgQECIBgwL0F+uZhV8+QoMOrJnH72cUJHn
0Tk72LjxQfXho9MrR5CDkBIYtaJDF+/Ain0rRBosR6AhBhUqBRRQyBU2FBiUfC+RcI4SQxwQXA5R
KAKXV14l0cIMRTBYyBeHPaCFIh0YYQMWYSiwgSJauKBiDYq84MEmjVQBwIxVRKKIjDMyYOOOPDYS
CAA7
__theme/blueocean/images/trash.gif__
R0lGODlhFwAgAOYAAD9xqJKw0N7e3mWh4czMzFqV1nuk0eXr8pK+8V2Qx6/K53qx7cbCv22p51SK
xMnc8Ke81LvO4oy78O/1/Obm5leZ302BuH2q3GCSyXWr5WOKtazF4Gak5ZzE89ji7aPM+9bU0IO2
712Z2ZW64mGUzr29vU2Cvf///42pyGig3Yaz40p7sMHT5tfm9ufv+KTG63aj1G6r68/U2VuSz+7m
37jN5Je32Wqe13Su7VeJv4et2H2z7sTU56bF52OY05jE91eEtIS69W2RuK3R/cfJytvf49Hg8G2Z
yvf396fK8FWBsHmt5FKEup7A5kR5tJy10Ed1qIOnzmiOt+Lq9Nvk7mqj4HO172Oa1mum5Yy17+/v
75S992Ke3dLPzFyOxdbW1uPq8lSDtZzI+k+Gw8PFx7zP5Ozx9sTX7qHG9I+35J231Et+tnOl3s7i
98DV7Hun11WNyoaw37XF3qXO/4yqyrjQ663J546+9W6Tu6/O70pzrQAAAAAAAAAAAAAAAAAAACH5
BAEHACcALAAAAAAXACAAAAf/gCeCg4QnSEiFiYqDWlqIi5CGh42OkYmPSFoUAhSPll0EX5wUm18E
FIkTh6tIm11EDAICpkWEbRIIlLqUX11fvQZvDydJHBUbNLLKy19EIF1kTBYzOmkNDSMyINvc3F0M
rwEzV1cJTQ04OCFNdjXuLPAsEREvEgsNKT4wedcLC0F3fnwYQvCDmDtBFsTAkiLfiDPXcOwIgasD
GjQdEEgIsQPHwioprihokQHdAooIEHRYmTJECIVYQN4442IJlhj+UKZMuXHHjoUMU7Q4sYRDDBwn
dfLk6BELFi5sXJxQMSDiRIoSsm5c0LQKlwuC0nBxmu6qS5c+cVyrciWOoCYi0arcxJkTbUe1DaqI
GCFIQYEUcmMcRerPX1OGBXoIcjOjoVPB6SJ7/JiiQB1BRsY1lDtXsGenDWcMOzFlhg8fm6tcW70W
ZIoZQwVhwHC6IWCnuGM2JCdV0JEEJGqnrkLcNrkbhKI4IBFcuG3jV2a8IaTGxGzmPshp334Fjg1C
PNZ48XL9tPnzPsawKBQmx3gvzLGfjk+CiZlCTwAweX+dPokETgSgCARQQLHfeLPNlsMaK6gBCRUo
aKCEEmFUWKEUdHhgyQkHQCCEFCDiAQEYigQCADs=
