package Kwiki::RecentChanges::Atom;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';
use XML::Atom::Feed;
use XML::Atom::Entry;

our $VERSION = "0.03";

const class_id        => 'RecentChangesAtom';
const class_title     => 'RecentChangesAtom';
const screen_template => 'atom_screen.xml';
const config_file     => 'atom.yaml';

sub register {
  my $registry = shift;
  $registry->add(action   => 'RecentChangesAtom');
  $registry->add(toolbar  => 'atom_button',
      		 template => 'atom_button.html',
		);
}

sub RecentChangesAtom {
    my $feed = new XML::Atom::Feed;
    $feed->title($self->config->atom_title);
    $ENV{SERVER_PROTOCOL} =~ m!^(\w+)/!;
    my $protocol = $1;
    my $depth_object = $self->preferences->recent_changes_depth;
    my $depth = 7;
    my $label = +{@{$depth_object->choices}}->{$depth}; 
    my $pages;
    @$pages = sort {
        $b->modified_time <=> $a->modified_time;
    } $self->pages->all_since($depth * 1440);

    foreach my $page (@$pages) {
        my $entry = new XML::Atom::Entry;
	$entry->title($page->id);
	$entry->content("Last edited by " . $page->metadata->edit_by);
	$entry->link("\L$protocol" . "://" . $ENV{SERVER_NAME} . 
	              $page->hub->config->script_name . "?" . $page->id);
        $feed->add_entry($entry);
    }

    {
        no warnings 'redefine';
	eval "*Spoon::Cookie::content_type = sub {(-type=>'application/xml')};"
    }

    $self->render_screen(xml          => $feed->as_xml,
    		         screen_title => "Changes in the $label:",
		       	 );
}

=head1 NAME

Kwiki::RecentChanges::Atom - Kwiki Plugin to create an Atom feed of recent changes

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

 $ cpan Kwiki::RecentChanges::Atom
 $ cd /path/to/kwiki
 $ vim plugins
 $ kwiki -update

=head1 DESCRIPTION

This module adds a Atom feed of recent changes to your Kwiki.  It also 
adds an Atom icon to your toolbar.

=head1 AUTHOR

Steve Peters, C<< <steve@fisharerojo.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-kwiki-recentchanges-atom@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 TODO

The documentation for L<XML::Atom::Feed> doesn't suggest that it populates a
lot of fields typical to an Atom feed.  I need to investigate to see if that 
module creates a very simple feed or if there are a lot of undocumented 
methods.

=head1 ACKNOWLEDGEMENTS

James Peregrino's Kwiki::RecentChangesRSS helped this module along.

=head1 SEE ALSO

L<Kwiki>, L<XML::Atom>

=head1 COPYRIGHT & LICENSE

Copyright 2004-5 Steve Peters, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Kwiki::RecentChanges::Atom
__DATA__
__config/atom.yaml__
atom_title: a title goes here
__template/tt2/atom_button.html__
<!-- BEGIN atom_button.html -->
<a href="[% script_name %]?action=RecentChangesAtom" accesskey="a" title="Atom">
[% INCLUDE atom_button_icon.html %]
</a>
<!-- END atom_button.html -->
__template/tt2/atom_button_icon.html__
<!-- BEGIN atom_button_icon.html -->
<img src="icons/atom.png" alt="atom" />
<!-- END atom_button_icon.html -->
__template/tt2/atom_screen.xml__
[% xml %]
__icons/atom.png__
iVBORw0KGgoAAAANSUhEUgAAAFAAAAAPCAMAAAEzEIgrAAAAwFBMVEUiIiKZmZlmZmaIiIi7u7vM
zMwzMzP5+fkRERHu7u6Wlpb9/f3KyspVVVXGxsb7+/t3d3fPz8/S0tLDw8P8/Py9vb2xsbG+vr6r
q6u/v79ERETl5eXKq6vFxcXb29txcXGpqamysrLOzs6zu+J+fn4eHh56enoDHH7W1tb01NS3t7dS
UlKrtN7ExMSzs7OapdXHx8e6urrLy8vAwMDHpaXMlZWstd/Jycm1veSurq6YmJibptXIyMgAAACI
jXj///+BJyE6AAABVklEQVQ4y52T6VLbMBRGryRvIWSBhL0t0FL2rWXt8um8/1vxQ44xwemEfuOx
RpqjoyvZMjUxBT1LMRKtNYqdI4gxmhACrKiIdUwA03WA1mBHjGDV4BdZ4RsSQ3LAMThiJEYiBgBf
207SQoCA9TXO6m6zaBt0qBgr+wHfOFKmIMdMXz8JlKxCAthyQiRw3rhklgfr2oMHNkruu/cSZYDJ
ZxJsAt+DcoVuMB8H9bTLNpegQrrQHEgCd4WQ/wk3DOXNVhaAmUwU+gLk/U5wVmPKDqOtptMBLn+O
zGW1bkerG5O/nx74WOaFTvIAXG+XSb/3dkL8d2bCIFUmjV39TQ836/m/W5vpNcLUvn+/CnuDKqmc
5BkdlPB48gf6+5LHZKyk+7JQmP7tRmhS8JKRSxqclnV9+cR1CxdoX4WQ9WaSbG8IwPTqc//9oS95
hm+ztvN0ezcs+Z/oBckmBmW7bigcAAAAAElFTkSuQmCC
