package Kwiki::Theme::PerlMongers;

use strict;
use warnings;

our $VERSION = '0.01';

use Kwiki::Theme '-Base';
use mixin 'Kwiki::Installer';

const theme_id => 'perl-mongers';
const class_title => 'Theme for Perl Mongers groups';


1;

__DATA__

=head1 NAME

Kwiki::Theme::PerlMongers - A theme for Perl Mongers websites

=head1 SYNOPSIS

In your Kwiki's F<plugins> file simply use
C<Kwiki::Theme::PerlMongers> instead of C<Kwiki::Theme::Basic>.  Add a
line to your F<config.yaml> like this:

 group_name: My Perl Mongers

That's it!

=head1 DESCRIPTION

I wanted to make the Minneapolis PM site a wiki, but thought it'd be
nice to have a Perl Mongers theme.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-kwiki-theme-perlmongers@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__theme/perl-mongers/css/kwiki.css__
html {
    padding: 0;
    margin: 0;
}

body {
    padding: 0;
    margin: 0 50px 0 50px;
    font-size: 90%;
}

#header_pane {
    border: 1px solid black;
    height: 100px;
    background-color: #0087d9;
    border-bottom: 1px solid black;
}

#header_pane img#logo {
    border: 1px solid black;
    position: absolute;
    left: 100px;
    top: 25px;
}

#header_pane h1 {
    margin: 0;
    padding: 0;
    color: white;
    font-size: 250%;
    position: absolute;
    top: 30px;
    left: 300px;
}

h1, h2, h3, h4, h5, h6 {
    margin: 0px;
    padding: 0px;
    font-weight: bold;
}

.error, .empty {
    color: #f00;
}

div.navigation a:visited {
    color: #00f;
}

#widgets_pane {
    float: right;
    width: 20%;
    background-color: #eee;
}

#content_pane {
}

__theme/perl-mongers/template/tt2/kwiki_screen.html__
[%- INCLUDE kwiki_doctype.html %]
<!-- BEGIN kwiki_screen.html -->
[% INCLUDE kwiki_begin.html %]
<div id="container">

 <div id="header_pane">
  <a href="/"><img src="theme/perl-mongers/images/perl-onion.png" alt="Perl Onion Logo" width="160" height="49" id="logo" /></a>
  <h1>[% group_name %]</h1>
 </div>

 <div id="left_pane">
 </div>

 <div class="navigation">
  <div id="title_pane">
   <h1>[% screen_title || self.class_title %]</h1>
  </div>
  <div id="toolbar_pane">
   [% hub.toolbar.html %]
   [% IF hub.have_plugin('user_name') %]
   [% INCLUDE user_name_title.html %]
   [% END %]
  </div>
  <div id="status_pane">
  [% hub.status.html %]
  </div>
 </div>

 <hr />
 <div id="content_pane">
  <div id="widgets_pane">
   [% hub.widgets.html %]
  </div>
  [% INCLUDE $content_pane %]
 </div>
 <hr />

 <div class="navigation">
  <div id="toolbar_pane_2">
   [% hub.toolbar.html %]
  </div>
 </div><!-- navigation -->
 [% INCLUDE kwiki_end.html %]
</div><!-- container -->

<div id="right_pane">
</div>

<!-- END kwiki_screen.html -->

__theme/perl-mongers/images/perl-onion.png__
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
