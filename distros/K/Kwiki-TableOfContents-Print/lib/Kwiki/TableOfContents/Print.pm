package Kwiki::TableOfContents::Print;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
use IO::All;
use JSON;
use Data::Dumper;
our $VERSION = '0.02';

const class_title => 'Table of Contents Print';
const class_id => 'toc_print';

sub register {
	my $registry = shift;
	$registry->add(prerequisite => 'toc');
	$registry->add(preload => 'toc_print');
	$registry->add(action => 'print_toc');
}

sub print_toc {
	my $print_page = CGI::param('page_name');
	my $content = join('', map({
		my $page_key = $_->[0];
		my $page_name = $_->[1];
		my $level = $_->[2];
		my $html = $self->hub->pages->new_page($page_key)->to_html;
		$html =~ s|attachments/$print_page/|attachments/$page_key/|gi
			unless $page_key eq $print_page;
		('<h', $level, ' class="toc_header">',
			$page_name,
		'</h', $level, '>',
		$html)
	} $self->print_pages));
	$self->hub->css->add_file('jstree_print.css');
	$self->render_screen(
		page_html => $content,
	);
}

sub print_pages {
	my $page_name = CGI::param('page_name');
	my $structure = jsonToObj(io->catfile($self->plugin_base_directory,
		'toc', 'structure')->slurp);

	return $page_name eq $self->config->main_page
		? (['HomePage', 'Home Page', 1], $self->tree_to_list($structure, 0))
		: $self->tree_to_list($self->find_node($page_name, $structure), 1);
}

sub tree_to_list {
	my ( $structure, $level, @list ) = @_;
	if( ref($structure) eq 'HASH' ) {
		my $page_name = $self->link_to_pagename(
			$structure->{data}->{href});
		push( @list, [
			$page_name,
			$structure->{data}->{text},
			$level,
		]) if defined $page_name;
		$structure = $structure->{subtree};
	}
	$level++;
	foreach ( @$structure ) {
		@list = $self->tree_to_list($_, $level, @list);
	}
	return @list;
}

sub find_node {
	my ( $page_name, $structure ) = @_;
	foreach ( @$structure ) {
		my $cur = $self->link_to_pagename($_->{data}->{href});
		return $_ if $page_name eq $cur;
		my $next = $self->find_node($page_name, $_->{subtree});
		return $next if defined $next;
	}
	return undef;
}

sub link_to_pagename {
	my ( $link ) = @_;
	return $link =~ /\?(.+)$/ ? $1 : undef;
}

1; # End of Kwiki::TableOfContents::Print
__DATA__
=head1 NAME

Kwiki::TableOfContents::Print - Provides ability to print entire sections of
the kwiki website based on the table of contents information.

=head1 SYNOPSIS

Install this module and have your theme provide a button that will call the
JSTree.print() method when clicked and it will print the current page and
all child pages. If you are on the home page it will print the entire site.

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/jstree_print.css__
#toc_pane,
#toc_toggler,
#toolbar_pane,
#status_pane,
#heading {
	display: none;
}
#content_pane {
	overflow: visible;
	position: static;
	height: auto;
	width: 100% !important;
}
body {
	overflow: auto;
	height: auto;
}
.toc_header {
	margin-top: 1ex;
	margin-bottom: 2ex;
	text-align: center;
	background-color: white;
	border-width: 0px;
	text-decoration: underline;
	text-transform: uppercase;
}
__template/tt2/toc_print_content.html__
<script type="text/javascript">
	window.onload = function() {
		window.print();
	}
</script>
<div class="wiki">
[% page_html -%]
</div>
