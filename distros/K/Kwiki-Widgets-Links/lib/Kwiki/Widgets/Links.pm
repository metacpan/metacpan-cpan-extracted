package Kwiki::Widgets::Links;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_id => 'widgets_links';
const class_title => 'Links widget';
const config_file => 'widgets_links.yaml';

sub register {
    my $registry = shift;
    $registry->add(widget => 'widgets_links',
		   template => 'widgets_links.html');
}

sub get_links {
    my @l = @{$self->hub->config->widgets_links};
    map { { title => $l[$_], url => $l[$_+1] } } map { $_ * 2 } 0..$#l/2;
}

__DATA__

=head1 NAME

  Kwiki::Widgets::Links - Just put some links on your widget pane.

=head1 SYNOPSIS

  % kwiki -add Kwiki::Widgets::Links
  % vim config.yaml
  # edit "widgets_links"' value

=head1 DESCRIPTION

There are just some times you just want to put some convienent links on the
side of your Kwiki screen, and this is the plugin that does it. After
installing this plugin, please edit C<config.yaml>, and add a keyword
"widgets_links" like this:

  widgets_links:
  - Kwiki
  - http://kwiki.org
  - Perl
  - http://perl.org
  - CPAN
  - http://cpan.org

You could also find the default value in C<config/widgets_links.yaml>. It is a
list that has titles of links in the odds elements, with its url next to it.
It has to be written in this way because C<Kwiki::Config> doesn't fully
implement YAML syntax. So this is a work-around.

After editing, these links would appear on the widget pane of your kwiki
screen. (So please make sure you're using a theme with widget pane.)

Enjoy it.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__template/tt2/widgets_links.html__
<div id="widgets_links">
<h4>Links</h4>
<ul>
[% FOREACH l = hub.widgets_links.get_links %]
<li><a href="[% l.url %]">[% l.title %]</a></li>
[% END %]
</ul>
</diV>
__config/widgets_links.yaml__
widgets_links:
- Kwiki
- http://kwiki.org
- Perl
- http://perl.org
- CPAN
- http://cpan.org
