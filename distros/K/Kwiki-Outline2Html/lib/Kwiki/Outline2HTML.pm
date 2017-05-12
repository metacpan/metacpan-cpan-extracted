package Kwiki::Outline2HTML;
use Kwiki::Plugin -Base;
our $VERSION = '0.02';

const class_id => 'outline2html_blocks';
const class_title => 'Outline2HTML blocks';

sub register {
    my $registry = shift;
    $registry->add(wafl => outline2html => 'Kwiki::Outilne2HTML::Wafl');
}

package Kwiki::Outilne2HTML::Wafl;
use base 'Spoon::Formatter::WaflBlock';

sub to_html {
    $self->render_outline($self->units->[0]);
}

sub render_outline {
    my $wafl_block = shift;
    my @tree = $self->get_outline_tree($wafl_block);
    my $toc_string = $self->get_toc(@tree);
    my $content = $self->get_content(@tree);
    return $toc_string . $content;
}

sub get_outline_tree {
    my $block = shift;
    my @whole_content = split(/\n/,$block);
    $_ .= "\n" foreach(@whole_content);
    my @tree;
    my $last_level  = 1;
    my ($last_title,$last_content);
    foreach(@whole_content) {
	if (m/^(\*+)\s*(.+)$/) {
	    push @tree,
		{ title   => $last_title,
		  content => $last_content,
		  level   => $last_level
		 };
	    $last_level = length($1);
	    $last_title = $2;
	    $last_content = '';
	} else {
	    $last_content .= $_;
	}
    }
    push @tree,
	{ title   => $last_title,
	  content => $last_content,
	  level   => $last_level
	 };
    shift @tree; # the first one is empty.
    return @tree;
}

sub get_toc {
    my @tree = @_;

    my ($title,$before,$after,$close_last,$toc_string);
    my $open_tag = 0;
    my $last_level  = 1;
    my $root_i = -1;
    $toc_string  = "<div id='toc'>\n<h1>Table of Contents</h1>\n<ul class='ullevel1'>\n";
    for my $i (0..$#tree) {
	$_ = $tree[$i];
	if ($_->{level} == 1) {
	    $root_i++;
	    $title = "<a href='#section_root_$i'>$_->{title}</a>";
	} else {
	    $title = "<a href='#section_$i'>$_->{title}</a>";
	}

	my $liclass = "class='lilevel" . $_->{level} . "'";
	my $ulclass = "class='ullevel" . $_->{level} . "'";
	my $ulid    = "id='ulrootsection${root_i}'" if($_->{level} == 2);
	$before = "<li ${liclass}>"; $after  = "</li>"; $close_last = '';
	if ($_->{level} > $last_level) {
	    $before = "\n<li><ul $ulclass $ulid>\n<li ${liclass}>";
	    $open_tag = 1;
	} elsif ($_->{level} < $last_level) {
	    $close_last = "</ul></li>" x ($last_level - $_->{level}) . "\n\n";
	    $open_tag = 0;
	    $before  = "<li ${liclass}>";
	}
	my $this_title = "${close_last}${before}${title}${after}";
	$toc_string .= "${this_title}\n";
	$last_level = $_->{level};
    }
    $toc_string .= "</ul></li>" if ($open_tag);
    $toc_string .= "</ul></div>\n\n";
    return $toc_string;
}

sub get_content {
    my @tree = @_;
    my @sections_content;
    my $section_content;
    $section_content = "<div id='sections'>\n";
    for my $i (0..$#tree) {
	$_ = $tree[$i];
	if ($_->{level} == 1) {
	    if ($i > 0) {
		$section_content .= "</div> <!-- section_root or section_$i-->\n";
		push @sections_content,$section_content;
		$section_content = '';
	    }
	    $section_content .=
		"<a id='section_root_$i'></a><div class='section_root' >\n";
	} else {
	    $section_content .= "<div class='section' id='section_$i'>\n";
	}
	$section_content .= "<h$_->{level}>$_->{title}</h$_->{level}>";
	$section_content .= $self->gencontent($_->{content}) . "\n"
	    if ($_->{content} =~ /[^\s]/);
	$section_content .= "</div>\n" unless($_->{level} == 1);
    }
    $section_content .= "</div> <!-- last section_root -->\n";
    $section_content .= "</div> <!-- sections -->\n";
    push @sections_content,$section_content;
    my $content = join('',@sections_content);
    return $content;
}

sub gencontent {
    my $content = shift;
    my @paragraphs = split(/\n\n\n*/,$content);

    # enum, list <ul>,<li>
    foreach (@paragraphs) {
	s/^\n+//s; s/\s+\n//s;

	# Escape html entitites, but not those in the [ ].
	# http://www.gugod.org/  => <a ...>http://www.gugod.org</a>
	my $urlpattern = '(?:http|https|ftp)://(?:[^/\[\]:]+)(?::\d+)?/[^\|\s\[\]\(\)\<\>]*';
	my $emailpattern= '(?:[\w\d\.-]+@[\w\d\.-]+)';

	use English;
	my @lines = split /\n/;
	my $prefixed = 0;
	foreach(@lines) {
	    if(/$urlpattern/) {
		my($pre,$post) = ($PREMATCH, $POSTMATCH);
		unless(($pre =~ /\[/ && $post =~ /\]/) ||
		       ($pre =~ /\(/ && $post =~ /\)/)) {
		    s{($urlpattern)}{[$1|$1]};
		}
	    } elsif (/$emailpattern/ ) {
		my($pre,$post) = ($PREMATCH, $POSTMATCH);
		unless($pre =~ /\[/ && $post =~ /\]/) {
		    s{($emailpattern)}{[link:$1,mailto:$1]};
		}
	    }
	}
	$_ = join("\n", @lines);

	# It could be considered as everyhing in a [ ] are left untouched.
	s{(?<!\[)\G([^\[\]]*?)&([^\[\]]*?)(?!\])}{$1&amp;$2}g;
	s{(?<!\[)\G([^\[\]]*?)<([^\[\]]*?)(?!\])}{$1&lt;$2}g;
	s{(?<!\[)\G([^\[\]]*?)>([^\[\]]*?)(?!\])}{$1&gt;$2}g;

	# Handle special instructions
	s{\[image:\s*(.+?)\s*\]}{<img src="$1"/>}ig;
	s{\[link:\s*(\S+?)\s*,\s*(.+?)\s*\]}{<a href="$2">$1</a>}ig;
	s{\[(${urlpattern})\|(.+?)\]}{<a href="$1">$2</a>}ig;
	s{([^\s]+?)\s*\((${urlpattern})\)}{<a href="$2">$1</a>}ig;

	# Else, Treat anything in [ ] untouched.
	s{\[(.+?)\]}{$1}g;

	@lines = split /\n/;
	$prefixed = 0;
	foreach(@lines) {
	    $prefixed++ if(/^\s*[\-\.ox#@\+=]\s/);
	}

	if(($prefixed-1 == $#lines) && $#lines > 0) {
	    my $new_p;
	    foreach (@lines) {
		s{^\s*[\-\.ox\#@\+=]\s(.+)$}{<li>$1</li>};
		$new_p .= "$_\n";
	    }
	    $_ = "<ul>\n${new_p}</ul>";
	}
    }

    $content = '';
    foreach (@paragraphs) {
 	if (m/^\s*</ && m/<\/.+>\s*$/) {
	    $content .= "\n$_\n";
	} else {
            $content .= "\n<p>$_</p>\n"
	}
    }

    return $content;
}

__END__

=head1 NAME

Kwiki::Outline2HTML - Kwiki formatter using outline2html syntax

=head1 DESCRIPTION


B<Kwiki::OutlineHTML> is a L<Kwiki> plugin that provide alternative
formatter syntax.

To use this plugin, simply install L<Kwiki> and this module from CPAN,
and do:

    # echo 'Kwiki::Outline2HTML' >> plugins
    # kwiki -update

Please visit L<http://gugod.org/outline2html> and take a look of
POD there, for the syntax of this mode.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>
