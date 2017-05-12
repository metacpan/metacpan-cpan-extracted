#!/usr/bin/perl

package Mail::Summary::Tools::Output::HTML;
use Moose;

use HTML::Element;
use Text::Markdown ();
use HTML::Entities;

use utf8;

has body_only => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has strip_divs => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has lang => (
	isa => "Str",
	is  => "rw",
	default => "en",
);

has summary => (
	isa => "Mail::Summary::Tools::Summary",
	is  => "rw",
	required => 1,
);

has description => (
	isa => "Str",
	is  => "rw",
	default => "Mailing list summary",
);

has generator => (
	isa  => "Str",
	is   => "rw",
	lazy => 1,
	default => sub {
		my $self = shift;
		require Mail::Summary::Tools;
		return __PACKAGE__ . " version $Mail::Summary::Tools::VERSION";
	},
);

sub process {
	my $self = shift;

	my @tree = HTML::Element->new_from_lol( $self->body_only ? $self->body : $self->document_structure );

	@tree = $self->scrub(@tree);

	$self->emit(@tree);

}

sub document_structure {
	my $self = shift;

	return (
		[html => { xmlns => "http://www.w3.org/1999/xhtml", 'xml:lang' => $self->lang },
			[head =>
				[title => $self->summary->title ],
				[meta => { 'http-equiv' => "Content-Type", content => "text/html; charset=utf-8" }],
				[meta => { name => "description", content => $self->description }],
				[meta => { name => "generator",   content => $self->generator }],
				$self->css,
			],
			[body => 
				$self->toc,
				$self->body,
			],
		
		]
	);
}

sub scrub {
	my ( $self, @tree ) = @_;

	if ( $self->strip_divs ) {
		@tree = $self->scrub_strip_divs(@tree);
	}

	return @tree;
}

sub scrub_strip_divs {
	my ( $self, @tree ) = @_;

	foreach my $subtree ( @tree ) {
		foreach my $div ( $subtree->find_by_tag_name('div') ) {
			$div->replace_with_content if defined $div->parent;
		}
	}

	map { ($_->tag eq "div") ? $_->content_list : $_ } @tree;
}

sub emit {
	my ( $self, @tree ) = @_;
	return @tree;
}

sub template_snippet {
	my ( $self, $snippet, %vars ) = @_;
	
	my $out;	

	my $tt = $self->template_obj;

	$tt->process(
		\$snippet,
		{
			%vars,
			html => $self,
		},
		\$out,		
	) || warn $tt->error . " in $snippet";

	return $out;
}

sub markdown {
	my ( $self, $text ) = @_;

	$text =~ s/<((?:msgid|rt):\S+?)>/$self->expand_uri($1)/ge;
	$text =~ s/\[(.*?)\]\(((?:msgid|rt):\S+?)\)/$self->expand_uri($2, $1)/ge;

	my $html = Text::Markdown::markdown( $text );

	# non ascii stuff gets escaped (accents, etc), but not punctuation, which
	# markdown will handle for us
	['~literal' => { text => $self->escape_unicode($html) } ];
}

sub rt_uri {
	my ( $self, $rt, $id ) = @_;
	
	if ( $rt eq "perl" ) {
		return "http://rt.perl.org/rt3/Public/Bug/Display.html?id=$id";
	} else {
		die "unknown rt installation: $rt";
	}
}

sub link_to_message {
	my ( $self, $message_id, $text ) = @_;

	my $thread = $self->summary->get_thread_by_id( $message_id )
		|| die "The link to <$message_id> could not be resolved, because no thread with that message ID is in the summary data";

	my $uri;
	
	if ( $thread->hidden ) {
		$uri = $thread->archive_link->thread_uri;
	} else {
		$uri = URI->new;
		$uri->fragment($message_id);
	}

	$text ||= $thread->subject;

	"[$text]($uri)";
}

sub expand_uri {
	my ( $self, $uri_string, $text ) = @_;

	my $uri = URI->new($uri_string);

	if ( $uri->scheme eq 'rt' ) {
		my ( $rt, $id ) = ( $uri->authority, substr($uri->path, 1) );
	   	my $rt_uri = $self->rt_uri($rt, $id);
		$text ||= "[$rt #$id]";
		return "[$text]($rt_uri)";
	} elsif ( $uri->scheme eq 'msgid' ) {
		return $self->link_to_message( join("", grep { defined } $uri->authority, $uri->path), $text );
	} else {
		die "unknown uri scheme: $uri";
	}
}

sub escape_unicode {
	my ( $self, $text ) = @_;
	$self->escape_html($text, '^\p{IsASCII}');
}

sub escape_html {
	my ( $self, $text, @extra ) = @_;
	HTML::Entities::encode_entities($text, @extra);
}

sub div {
	my ( $self, $class_spec, @elems ) = @_;

	my $class_attr = (ref $class_spec
		? join(" ", @$class_spec)
		: $class_spec );

	[ div => { class => $class_attr }, @elems ];
}

has h1_tag => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default => sub { ["h1"] },
);

sub wrap_tags {
	my ( $self, $tags, @elems ) = @_;

	if ( @$tags ) {
		my ( $outer, @inner ) = @$tags;
		return [ $outer => $self->wrap_tags( \@inner, @elems ) ];
	} else {
		return @elems;
	}
}

sub h1 {
	my ( $self, @inner ) = @_;
	my $tag = $self->h1_tag;
	$self->wrap_tags( $tag, @inner );
}

has h2_tag => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default => sub { ["h2"] },
);

sub h2 {
	my ( $self, @inner ) = @_;
	my $tag = $self->h2_tag;
	$self->wrap_tags( $tag, @inner );
}

has h3_tag => (
	isa => "ArrayRef",
	is  => "rw",
	auto_deref => 1,
	default => sub { ["h3"] },
);

sub h3 {
	my ( $self, @inner ) = @_;
	my $tag = $self->h3_tag;
	$self->wrap_tags( $tag, @inner );
}

sub toc {
	my $self = shift;
	return ();
}

sub body {
	my $self = shift;

	return [ div => { id => "summary_container" },
		$self->header,
		$self->lists,
		$self->footer,
	];
}

sub header {
	my $self = shift;
	my @parts;
	
	return [ div => { id => "summary_header" },
		$self->h1( $self->summary->title || "Mailing list summary" ),
		$self->custom_header,
	];
}

sub custom_header {
	my $self = shift;

	if ( my $header = eval { $self->summary->extra->{header} } ) {
		return ( map { $self->custom_header_section( $_ ) } @$header );
	} else {
		return;
	}
}

sub custom_header_section {
	my ( $self, $section ) = @_;

	return $self->div( header_section => $self->generic_custom_section( $section ) );
}

sub footer {
	my $self = shift;
	
	return [ div => { id => "summary_footer" },
		$self->custom_footer,
		$self->see_also,
	];
}

sub custom_footer {
	my $self = shift;

	if ( my $footer = eval { $self->summary->extra->{footer} } ) {
		return ( map { $self->custom_footer_section( $_ ) } @$footer );
	} else {
		return;
	}
}

sub custom_footer_section {
	my ( $self, $section ) = @_;
	return $self->div( footer_section => 
		$self->generic_custom_section( $section ),
	);
}

sub generic_custom_section {
	my ( $self, $section ) = @_;

	my $title = $section->{title} || return;

	my $heading = $self->h2( $title );

	if ( my $body = $section->{body} ) {
		return (
			$heading,
			$self->markdown( $section->{body} ),
		);
	} else {
		return $heading;
	}
}

sub see_also {
	my $self = shift;

	if ( my $see_also = eval { $self->summary->extra->{see_also} } ) {
		return [ div => { id => "see_also", class => "footer_section" },
			$self->see_also_heading($see_also),
			$self->see_also_links($see_also),
		];
	} else {
		return;
	}
}

sub see_also_heading {
	my ( $self, $see_also ) = @_;
	$self->h2("See Also");
}	

sub see_also_links {
	my ( $self, $see_also ) = @_;	
	[ ul => map { [ li => $self->see_also_link($_) ] } @$see_also ];
}

sub see_also_link {
	my ( $self, $item ) = @_;
	[a => { href => $item->{uri} }, $item->{name} ];
}

sub lists {
	my $self = shift;

	return $self->div( summary_container_body => 
		map { $self->list($_) } $self->summary->lists
	);
}

sub list {
	my ( $self, $list ) = @_;

	( my $id = $list->name ) =~ s/[^\w]+/_/g;
	
	my @body = $self->list_body($list);

	if ( @body ) {
		return [ div => { id => "summay_list_$id", class => 'summary_list' },
			$self->list_header($list),
			@body,
			$self->list_footer($list),
		];
	} else {
		return;
	}
}

sub list_header {
	my ( $self, $list ) = @_;

	return (
		$self->list_heading($list),
		$self->list_description($list),
	);
}

sub list_heading {
	my ( $self, $list ) = @_;

	my $title = $self->list_title($list) || return;

	$self->h2( $title, $self->list_heading_extra($list) );
}

sub list_heading_extra {
	my ( $self, $list ) = @_;
	# e.g. " (perl6-compiler)"... maybe $list->extra->{remark} || $list->name
	return;
}

sub list_title {
	my ( $self, $list ) = @_;

	my $title = $list->title || $list->name || return;

	if ( my $uri = eval { $list->extra->{uri} } ) {
		return [a => { href => $uri }, $title ],
	} else {
		return $title,
	}
}

sub list_description {
	my ( $self, $list ) = @_;

	if ( my $description = eval { $list->extra->{description} } ) {
		$self->markdown( $description );
	} else {
		return;
	}
}

sub list_body {
	my ( $self, $list ) = @_;

	( my $id = $list->name ) =~ s/[^\w]+/_/g;

	if ( my @threads = map { $self->thread($_) } $list->threads ) {
		return [ div => { id => "summary_list_body_$id", class => 'summary_list_body'  },
			@threads,
		];
	} else {
		return;
	}
}

sub list_footer {
	my ( $self, $list ) = @_;
	return ();
}

sub thread {
	my ( $self, $thread ) = @_;

	return if $thread->hidden;

	return $self->div( thread_summary =>
		$self->thread_header($thread),
		$self->thread_body($thread),
		$self->thread_footer($thread),
	);
}

sub thread_header {
	my ( $self, $thread ) = @_;
	$self->h3( $self->thread_link($thread) );
}

sub thread_link {
	my ( $self, $thread ) = @_;

	my $uri = $thread->archive_link->thread_uri;

	[a => { href => $uri, name=> $thread->message_id }, $thread->subject ],
}

sub thread_body {
	my ( $self, $thread ) = @_;

	if ( my $summary = $thread->summary ) {
		return $self->div( thread_summary_body => $self->markdown($summary) );
	} else {
		return $self->div(
			[qw/thread_summary_body empty_thread_summary_body/],
			$self->thread_body_no_summary($thread),
		);
	}
}

sub thread_body_no_summary {
	my ( $self, $thread ) = @_;

	my $posters = eval { $thread->extra->{posters} };

	return (
		[p => 'No summary provided.' ],
		($posters ? $self->thread_posters($posters) : ()),
	);
}

sub thread_posters {
	my ( $self, $posters ) = @_;

	return (
		[p => "The following people participated in this thread:" ],
		[ul => map { [li => ['~literal' => { text => $self->escape_unicode($_->{name} || $_->{email}) } ] ] } @$posters ],
	);
}

sub thread_footer {
	my ( $self, $thread ) = @_;
	return ();
}

sub css {
	my $self = shift;
	return ();
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::Output::HTML - 

=head1 SYNOPSIS

	use Mail::Summary::Tools::Output::HTML;

=head1 DESCRIPTION

=cut
