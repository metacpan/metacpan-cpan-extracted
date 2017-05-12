#!/usr/bin/perl

package Mail::Summary::Tools::CLI::ToText;
use base qw/Mail::Summary::Tools::CLI::Command/;

use strict;
use warnings;

use Class::Autouse (<<'#\'END_USE' =~ m!(\w+::[\w:]+)!g);
#\

use Mail::Summary::Tools::Summary;
use Mail::Summary::Tools::Output::TT;

#'END_USE

use Text::Wrap ();

use constant options => (
	[ 'verbose|v!'    => "Output progress information" ],
    [ 'input|i=s'     => 'Summary file to read' ],
    [ 'output|o=s'    => 'The file to output (defaults to STDOUT)' ],
	[ 'shortening|s!' => "Enable URI shortening (defaults to true)", { default => 1 } ],
    [ 'shorten=s'     => 'shortening service (defaults to "Metamark" -- http://xrl.us/)' ], #{ implies => "shortening", default => "Metamark" } ],
    [ 'archive|a=s'   => 'The on-line archive to use (defaults to "google")', { default => "google" }],
	[ 'columns|c=i'   => 'The column width to wrap to (defaults to 75)', { default => 75 } ],
    [ 'force_wrap|w!' => 'Force wrapping of overflowed text (like long URIs)' ], # whether or not to force wrapping of overflowing text
	[ 'template=s'    => "Override the template toolkit file used to format the text" ],
);

sub usage_desc {
	"%c totext %o [summary.yaml]"
}

sub wrap {
    my ( $self, $text, $columns, $first_indent, $rest_indent ) = @_;

    $columns ||= $self->{opt}{columns} || 80;
    $first_indent ||= '    ';
    $rest_indent  ||= '    ';

    no warnings 'once';
    local $Text::Wrap::huge = $self->_wrap_huge;
    local $Text::Wrap::columns = $columns;

	$text =~ s/\\(\S)/$1/g; # unquotemeta

    Text::Wrap::fill( $first_indent, $rest_indent, $self->process_body($text) );
}

sub process_body {
	my ( $self, $text ) = @_;

	$text =~ s/<(\w+:\S+?)>/$self->expand_uri($1)/ge;
	$text =~ s/\[(.*?)\]\((\w+:\S+?)\)/$self->expand_uri($2, $1)/sge;

	return $text;
}

sub bullet {
    my ( $self, $text, $columns ) = @_;
    $self->wrap( $text, $columns, '    * ', '      ' );
}

sub subject {
    my ( $self, $text, $columns ) = @_;
    $self->wrap( $text, $columns, '  ', '  ' );
}

sub heading {
    my ( $self, $text, $columns ) = @_;
    $self->wrap( $text, $columns, ' ', ' ' );
}

sub _wrap_huge {
    my $self = shift;
    return $self->{opt}{force_wrap} ? 'wrap' : 'overflow'; # default to not breaking URIs
}

sub shorten {
    my ( $self, $uri ) = @_;

	if ( $self->should_shorten($uri) ) {
		$self->really_shorten( $uri );
	} else {
		return $uri;
	}
}

sub rt_uri {
	my ( $self, $rt, $id ) = @_;

	if ( $rt eq "perl" ) {
		return $self->shorten("http://rt.perl.org/rt3/Ticket/Display.html?id=$id");
	} else {
		die "unknown rt installation: $rt";
	}
}

sub link_to_message {
	my ( $self, $message_id, $text ) = @_;

	my $thread = $self->{__summary}->get_thread_by_id( $message_id )
		|| die "The link to <$message_id> could not be resolved, because no thread with that message ID is in the summary data";

	my $uri = $self->shorten($thread->archive_link->thread_uri);
	
	$text ||= $thread->subject;

	"$text <$uri>";
}

sub expand_uri {
	my ( $self, $uri_string, $text ) = @_;

	my $uri = URI->new($uri_string);

	if ( $uri->scheme eq 'rt' ) {
		my ( $rt, $id ) = ( $uri->authority, substr($uri->path, 1) );
	   	my $rt_uri = $self->rt_uri($rt, $id);
		$text ||= "[$rt #$id]";
		return "$text <$rt_uri>";
	} elsif ( $uri->scheme eq 'msgid' ) {
		return $self->link_to_message( join("", grep { defined } $uri->authority, $uri->path), $text );
	} else {
		my $short_uri = $self->shorten($uri) || $uri;
		return $text ? "$text <$short_uri>" : "<$short_uri>";
	}
}

sub really_shorten {
    my ( $self, $uri ) = @_;
    my $service = $self->{opt}{shorten};

	my $cache = $self->app->context->cache;

	my $cache_key = join(":", "shorten", $service, $uri);

	if ( my $short = $cache->get($cache_key) ) {
		return $short;
	} else {
		$self->diag( "Shortening URI (cache miss): $uri" );
		my $mod = "WWW::Shorten::$service";
		unless ( $mod->can("makeashorterlink") ) {
			my $file = join("/", split("::", $mod ) ) . ".pm";
			require $file;
		}

		no strict 'refs';
		my $short = &{"${mod}::makeashorterlink"}( $uri );
		$cache->set( $cache_key, $short ) if $short;
		return $short || "$uri";
	}
}

sub shortening_enabled {
    my ( $self, $uri ) = @_;
    if ( $self->{opt}{shorten} ) {
        return 1;
    } else {
        return;
    }
}

sub should_shorten {
    my ( $self, $uri ) = @_;
    return unless $self->shortening_enabled;

    length($uri) > 40 || $uri =~ /gmane|groups\.google/
}

sub template_input {
    my $self = shift;

    if ( my $file = $self->{opt}{template} ) {
        open my $fh, "<", $file or die "Couldn't open template (open($file): $!)\n";
		binmode $fh, ":utf8";
        return $fh;
    } else {
		binmode DATA, ":utf8";
        return \*DATA;
    }
}

sub template_output {
    my $self = shift;
	my $opt = $self->{opt};
    
    if ( !$opt->{output} or $opt->{output} eq '-' ) {
		binmode STDOUT, ":utf8";
        return \*STDOUT;
    } elsif ( my $file = $opt->{output} ) {
        open my $fh, ">", $file or die "Couldn't open output (open($file): $!)\n";
		binmode $fh, ":utf8";
        return $fh;
    }
}

sub validate {
	my ( $self, $opt, $args ) = @_;
	@$args and $opt->{$_} ||= shift @$args for qw/input output/;

	unless ( $opt->{input} ) {
		$self->usage_error("Please specify an input summary YAML file.");
	}
	
	if ( @$args ) {
		$self->usage_error("Unknown arguments: @$args.");
	}

	# FIXME implies is broken
	$opt->{shortening} = 1 if exists $opt->{shorten};
	$opt->{shorten} ||= 'Metamark' if $opt->{shortening};

	$self->{opt} = $opt;
}

sub run {
    my ( $self, $opt, $args ) = @_;

    my $summary = Mail::Summary::Tools::Summary->load(
        $opt->{input},
        thread => {
            default_archive => $opt->{archive} || "google",
			archive_link_params => { cache => $self->app->context->cache },
        },
    );

	my $o = Mail::Summary::Tools::Output::TT->new(
		template_input  => $self->template_input,
		template_output => $self->template_output,
	);

	$o->process(
		$self->{__summary} = $summary, # FIXME Output::Plain
		{
			shorten => sub { $self->shorten(shift) },
			wrap    => sub { $self->wrap(shift) },
			bullet  => sub { $self->bullet(shift) },
			heading => sub { $self->heading(shift) },
			subject => sub { $self->subject(shift) },
		},
	);
}

__PACKAGE__;

=pod

=head1 NAME

Mail::Summary::Tools::CLI::ToText - Emit a formatted plain text summary

=head1 SYNOPSIS

	# see command line usage

=head1 DESCRIPTION

=cut

__DATA__
[% summary.title %]

[% IF summary.extra.header %][% FOREACH section IN summary.extra.header %][% heading(section.title) %]

[% wrap(section.body) %]
[% END %]
[% END %][% FOREACH list IN summary.lists %][% num_threads = 0 %][% list_block = BLOCK %]
 [% list.title %]
[% IF list.extra.description %]
[% wrap(list.extra.description) %]
[% END %][% FOREACH thread IN list.threads %][% IF thread.hidden %][% NEXT %][% END %][% num_threads = num_threads + 1 %]
[% head = BLOCK %][% thread.subject %] <[% shorten(thread.archive_link.thread_uri) %]>[% END %][% subject(head) %]

[% IF thread.summary %][% wrap(thread.summary) %]
[% ELSE %]    Posters:[% FOREACH participant IN thread.extra.posters %]
    - [% participant.name %][% END %]
[% END %][% END %][% END %][% IF num_threads > 0 %][% list_block %][% END %][% END %][% IF summary.extra.footer %][% FOREACH section IN summary.extra.footer %]
[% heading(section.title) %]

[% wrap(section.body) %]
[% END %]
[% END %][% IF summary.extra.see_also %][% heading("See Also") %]

[% FOREACH item IN summary.extra.see_also %][% link = BLOCK %][% item.name %] <[% shorten(item.uri ) %]>[% END %][% bullet(link) %]
[% END %]
[% END %]
