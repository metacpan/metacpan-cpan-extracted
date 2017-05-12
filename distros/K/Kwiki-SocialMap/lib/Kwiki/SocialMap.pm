package Kwiki::SocialMap;

=head1 NAME

Kwiki::SocialMap - Display social relation of this kwiki site

=head1 DESCRIPTION

Please see L<Graph::SocialMap> to know something about Social Map.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

use strict;
use warnings;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
use YAML;

our $VERSION = '0.09';

const class_id => 'socialmap';
const class_title => 'SocialMap Blocks';
const screen_template => 'site_socialmap_screen.html';

sub register {
    my $registry = shift;
    $registry->add(wafl => socialmap => 'Kwiki::SocialMap::Wafl');
    $registry->add(action => 'socialmap');
    $registry->add(toolbar => 'socialmap_button',
		   template => 'socialmap_button.html');
}

sub socialmap {
    my $relation = $self->find_kwiki_social_relation;
    $self->render_socialmap($relation);
    $self->render_screen;
}

sub find_kwiki_social_relation {
    my $db = $self->hub->config->database_directory;
    my $relation;
    for my $page ($self->pages->all) {
	my $history = $self->hub->load_class('archive')->history($page);
	my @edit_by = map { $_->{edit_by} } @$history;
	$relation->{$page->id} = \@edit_by;
    }
    return $relation;
}

sub socialmap_file {
    # XXX: always regen the graph. Not good.
    my $path = $self->plugin_directory;
    io->catfile($path, 'socialmap.png')->unlink;
    return io->catfile($path,'socialmap.png')->assert;
}

sub render_socialmap {
    my $relation = shift;
    my $gsmio = $self->socialmap_file;
    my $gsm = Graph::SocialMap->new(-relation => $relation);
    $gsm->save(-format=> 'png',-file=> $gsmio);
}

package Kwiki::SocialMap::Wafl;
use base 'Spoon::Formatter::WaflBlock';
use Graph::SocialMap;
use Digest::MD5;

sub to_html {
    $self->cleanup;
    $self->render_socialmap($self->units->[0]);
}

# XXX: I think cleanup should be called ony once per-page.
# (If a page is modified, re-generate all the socialmap inside)
# but put it in here will make it be called once per-socialmap-block.
sub cleanup {
    my $path = $self->hub->socialmap->plugin_directory;
    my $page =$self->hub->pages->current;
    my $page_id = $page->id;
    for(<$path/$page_id/*.png>) {
	my $mt = (stat($_))[9];
	unlink($_) if $mt < $page->modified_time;
    }
}

# use md5 as filename because I don't want to regenerate all the graphs
# on every page rendering. That's totally a waste of time.
sub render_socialmap {
    my $reldump = shift;
    my $page = $self->hub->pages->current->id;
    my $digest = Digest::MD5::md5_hex($reldump);
    my $path = $self->hub->socialmap->plugin_directory;
    my $file = io->catfile($path,$page,"$digest.png")->assert;
    unless(-f "$file") {
        $file->lock;
	my $relation;
	eval { $relation = YAML::Load($reldump) };
	return qq{<span style="color: red;">Error: Input is not valide YAML. Please go back and edit it again</span>} if $@;
	my $gsm = Graph::SocialMap->new(-relation => $relation);
	$gsm->no_overlap(1);
	$gsm->save(-format=> 'png',-file=> $file);
        $file->unlock;
    }
    return qq{<img src="$file" />};
}

1;
package Kwiki::SocialMap;
__DATA__
__template/tt2/socialmap_button.html__
<!-- BEGIN socialmap_button.html -->
<a href="[% script_name %]?action=socialmap" title="Social Map">
Social Map
</a>
<!-- END socialmap_button.html -->
__template/tt2/site_socialmap_screen.html__
<!-- BEGIN site_socialmap_screen.html -->
[% screen_title = 'Site Social Map' %]
[% INCLUDE kwiki_layout_begin.html %]
<div class="site_socialmap">
<img src="plugin/socialmap/socialmap.png"/>
</div>
[% INCLUDE kwiki_layout_end.html %]
<!-- END site_socialmap_screen.html -->
