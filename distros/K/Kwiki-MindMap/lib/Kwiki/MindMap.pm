package Kwiki::MindMap;
use Kwiki::Plugin -Base;
use YAML;

our $VERSION = '0.09';

const class_id => 'mindmap';
const class_title => 'MindMap Blocks';
const screen_template => 'site_mindmap_screen.html';

field prefix => '[*+0=]';
field fontsize => 12;
field fontname => 'Times';

sub register {
    my $registry = shift;
    $registry->add(wafl => mindmap => 'Kwiki::MindMap::Wafl');
}

package Kwiki::MindMap::Wafl;
use base 'Spoon::Formatter::WaflBlock';
use Digest::MD5;
use GraphViz;

sub to_html {
    $self->cleanup;
    $self->read_pageconf;
    $self->render_mindmap($self->units->[0]);
}

# XXX: I think cleanup should be called ony once per-page.
# (If a page is modified, re-generate all the mindmap inside)
# but put it in here will make it be called once per-mindmap-block.
sub cleanup {
    my $path = $self->hub->mindmap->plugin_directory;
    my $page =$self->hub->pages->current;
    my $page_id = $page->id;
    for(<$path/$page_id/*.png>) {
	my $mt = (stat($_))[9];
	unlink($_) if $mt < $page->modified_time;
    }
}

sub read_pageconf {
    if(my $obj = $self->hub->load_class('config_blocks')) {
	my $conf = $obj->pageconf;
	$self->hub->mindmap->fontsize($conf->{mindmap_fontsize}) if defined $conf->{mindmap_fontsize};
	$self->hub->mindmap->fontname($conf->{mindmap_fontname}) if defined $conf->{mindmap_fontname};
    }
}

# use md5 as filename because I don't want to regenerate all the graphs
# on every page rendering. That's totally a waste of time.
sub render_mindmap {
    my $reldump = shift;
    $reldump =~ s/^\s+$//gm;
    $reldump =~ s/\n\n+/\n/gs;
    my $page = $self->hub->pages->current->id;
    my $digest = Digest::MD5::md5_hex($reldump);
    my $path = $self->hub->mindmap->plugin_directory;
    my ($title,$tree) = $self->load_mindmap($reldump);
    my $file = io->catfile($path,$page,"$digest.png")->assert;
    my $svg = io->catfile($path,$page,"$digest.svg")->assert;
    unless(-f "$file") {
	my $grvz = $self->hash2graph($tree,$title);
	$grvz->as_png > $file;
	$grvz->as_svg > $svg;
    }
    if(my $obj = $self->hub->load_class('config_blocks')) {
	my $conf = $obj->pageconf;
	if(defined $conf->{mindmap_as_svg}) {
	    my $width = $conf->{mindmap_svg_width} || 800;
	    my $height = $conf->{mindmap_svg_height} || $width;
	    return qq{<embed src="$svg" name="$title" width="$width" height="$height" type="image/svg-xml" pluginspage="http://www.adobe.com/svg/viewer/install/">};
	}
    }
    return qq{<img src="$file">};
}

my $hue = 0;

sub hash2graph {
    my ($tree,$title) = @_;
    my $g = GraphViz->new(graph => {rankdir=>"LR", ranksep=>'0.05', nodesep=>'0.10'},
			  node => {label=>"",width=>0.04,height=>0.04,style=>'filled',fixedsize=>'true'},
			  edge => {arrowhead=>'none',style=>"setlinewidth(2)",
				   tailclip=>'false',headclip=>'false',
				   fontsize=> $self->hub->mindmap->fontsize,fontname=>$self->hub->mindmap->fontname },
			 );

    $g->add_node('root_left',label=>'');
    $g->add_node('root_right',label=>'');
    $g->add_edge('root_right' => 'root_left', label => $title);

    my @kids = sort { $self->count_kids($tree->{$a}) <=> $self->count_kids($tree->{$b}) } keys %$tree;
    my $hue_step = 1 / @kids;
    my (@left, @right);
    while (@kids) {
	push @left, shift @kids;
	push @right, shift @kids if @kids;
	push @right, pop @kids if @kids;
	push @left, pop @kids if @kids;
    }

    foreach my $left (@left) {
	$self->draw_left_kids($g,"root_left","root_left/$left",$tree->{$left});
	$hue += $hue_step;
    }

    foreach my $right (@right) {
	$self->draw_right_kids($g,"root_right","root_right/$right",$tree->{$right});
	$hue += $hue_step;
    }

    $hue = 0;
    return $g;
}

sub load_mindmap {
    my $dump = shift;
    my @lines = split/\n/,$dump;
    my $title = shift @lines;
    my $tree = $self->load_mindmap_subtree(@lines);
    return ($title,$tree);
}

sub load_mindmap_subtree {
    my @lines = @_;

    return '' unless(defined($lines[0]));

    my $tree = {};
    my @scope = $self->subtree_scopes(@lines);
    my $i = 0;
    my $prefix = $self->hub->mindmap->prefix;
    while($i < @scope) {
	my $node = $lines[$i]; $node =~ s/^($prefix)+\s*//;
	$tree->{$node} = $self->load_mindmap_subtree(@lines[$i+1..$scope[$i]]);
	$i = $scope[$i] + 1;
    }
    return $tree;
}

sub subtree_scopes {
    my @lines = @_;
    my @levels = $self->all_node_level(@lines);
    my @scope;

    # O(n^2). Could be better.
    for my $i (0..$#lines) {
	$scope[$i] = $i;
	for my $j ($i+1..$#lines) {
	    if($levels[$j] > $levels[$i]) {
		$scope[$i] = $j
	    } else {
		last;
	    }
	}
    }
    return @scope;
}

sub all_node_level {
    my @lines = @_;
    my @levels;
    for(@lines) {
	push @levels, $self->node_level($_);
    }
    return @levels;
}

sub node_level {
    my $line = shift;
    my $prefix = $self->hub->mindmap->prefix;
    if ($line =~ /^(($prefix)+)/) {
	return length($1);
    } else {
	return -1;
    }
}

sub draw_left_kids {
    my ($graph, $parent_symbol,$this_symbol,$tree) = @_;
    $graph->add_node($this_symbol, label=>'',color=>"$hue,1,1");
    $graph->add_edge($parent_symbol => $this_symbol,
		     color => "$hue,1,1",
		     label => (split('/',$this_symbol))[-1],
		    );
    return unless (ref($tree) eq 'HASH');
    foreach my $kid (keys %$tree) {
	$self->draw_left_kids($graph,$this_symbol, "$this_symbol/$kid", $tree->{$kid});
    }
}

sub draw_right_kids {
    my ($graph, $parent_symbol,$this_symbol,$tree) = @_;
    $graph->add_node($this_symbol, label=>'',color=>"$hue,1,1");
    $graph->add_edge($this_symbol => $parent_symbol,
		     color => "$hue,1,1",
		     label => (split('/',$this_symbol))[-1],
		    );
    return unless (ref($tree) eq 'HASH');
    foreach my $kid (keys %$tree) {
	$self->draw_right_kids($graph,$this_symbol, "$this_symbol/$kid", $tree->{$kid});
    }
}


sub count_kids {
  my $root = shift;
  return 0 unless ref($root) eq 'HASH';

  my @kids = keys %$root;
  my $count = @kids;
  foreach my $kid (@kids) {
      $count += $self->count_kids($root->{$kid});
  }

  return $count;
}

__END__
=head1 NAME

Kwiki::MindMap - Display what's on your mind.

=head1 DESCRIPTION

Display what's on your mind.

Thanks to dngor for providing beautiful GraphViz mindmap rendering code :)

Here's a quick example how to use this plugin after you installed it:

    .mindmap
    computer
    * laptop
    ** huge
    *** IBM
    *** Mac
    ** small
    *** sony
    *** toshiba
    * desktop
    ** pretty
    ** ugly
    .mindmap

The string 'computer' means the root node, and sub-nodes are prefixed
with '*', you may use any of [*+0=] for the tree prefix.

=head1 SEE ALSO

L<Kwiki::GDGraphGenerator>, L<Kwiki::SocialMap>

=head1 COPYRIGHT

Copyright 2004,2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut


