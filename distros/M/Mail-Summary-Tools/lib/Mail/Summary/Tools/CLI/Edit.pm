#!/usr/bin/perl

package Mail::Summary::Tools::CLI::Edit;
use base qw/Mail::Summary::Tools::CLI::Command/;

use strict;
use warnings;

use Class::Autouse (<<'#\'END_USE' =~ m!(\w+::[\w:]+)!g);
#\

use Mail::Summary::Tools::Summary;
use Mail::Summary::Tools::FlatFile;
use Proc::InvokeEditor;

#'END_USE

use constant options => (
	[ 'verbose|v!'        => 'Output progress information' ],
	[ 'input|i=s'         => 'The summary file to edit' ],
	[ 'mode'              => hidden => { default => "interactive", one_of => [
		[ 'interactive'      => "Edit the file interactively (the default)" ],
		[ 'save'             => "Output a flatfile to a file or STDOUT" ],
		[ 'load'             => "Load the specified file or STDIN into the summary" ],
	] } ],
	[ 'skip|s!'           => 'Skip threads that have already been summarized' ],
	[ 'hidden|H!'         => 'Include hidden threads' ],
	[ 'links|l!'          => 'Include links to on-line archives', { default => 1 } ], # TODO shorten
	[ 'archive|a=s'       => 'The rchive to use (defaults to "google")', { default => "google" } ],
	[ 'posters|p!'        => 'Include posters names in the comment section', { default => 1 } ],
	[ 'dates|d!'          => 'Include start and end dates in the comment section', { default => 1 } ],
	[ 'misc|m!'           => 'Include misc info in the comment section', { default => 1 } ],
	[ 'extra_fields|e=s@' => "Additional fields to include in the YAML header (can be used several times)" ],
	[ 'pattern|P=s@'      => "Only include summaries matching this regex (matches against formatted text)" ],
);

sub validate {
	my ( $self, $opt, $args ) = @_;
	@$args and $opt->{$_} ||= shift @$args for qw/input/;

	unless ( $opt->{input} ) {
		$self->usage_error("Please specify an input summary YAML file.");
	}
	
	if ( @$args ) {
		$self->usage_error("Unknown arguments: @$args.");
	}

	if ( defined($opt->{load}) and $opt->{load} eq "" || $opt->{load} ) {
		$self->usage_error("You can choose one and only one of --interactive, --load or --save.") if $opt->{interactive};
		$opt->{load} = \*STDIN;
		unless ( ref( my $file = $opt->{load} ) ) {
			open my $in, "<", $file || die "open($file): $!";
			$opt->{load} = $in;
		}

		binmode $opt->{load}, ":utf8";
	}
	
	if ( defined($opt->{save}) and $opt->{save} eq "" || $opt->{save} ) {
		$self->usage_error("You can choose one and only one of --interactive, --load or --save.") if $opt->{load};
		$opt->{save} = \*STDOUT;
		unless ( ref( my $file = $opt->{save} ) ) {
			open my $out, ">", $file || die "open($file): $!";
			$opt->{save} = $out;
		}

		binmode $opt->{save}, ":utf8";
	}

	$self->{opt} = $opt;
}

sub load_summary {
	my $self = shift;
	my $opt = $self->{opt};

	Mail::Summary::Tools::Summary->load(
		$opt->{input},
		thread => {
			default_archive     => $opt->{archive},
			archive_link_params => { cache => $self->app->context->cache },
		},
	);
}

sub create_flatfile {
	my ( $self, $summary ) = @_;
	my $opt = $self->{opt};

	Mail::Summary::Tools::FlatFile->new(
		summary         => $summary,
		skip_summarized => $opt->{skip},
		include_hidden  => $opt->{hidden},
		list_posters    => $opt->{posters},
		list_dates      => $opt->{dates},
		list_misc       => $opt->{misc},
		add_links       => $opt->{links},
		extra_fields    => [ map { split ',', $_ } @{ $opt->{extra_fields} } ],
		patterns        => [ map { qr/$_/ } @{ $opt->{pattern} || [] } ],
	);
}

sub run {
	my ( $self, $opt, $args ) = @_;
	my $method = "run_$opt->{mode}";
	$self->$method;
}

sub run_save {
	my $self = shift;

	my $out = $self->{opt}{save};
	print $out $self->create_flatfile( $self->load_summary )->save;
}

sub run_load {
	my $self = shift;
	my $opt = $self->{opt};

	my $summary = $self->load_summary;
	my $flat = $self->create_flatfile( $summary );

	my $in = $opt->{load}; # aha
	my $buffer = do { local $/; <$in> };

	$flat->load($buffer);
	$summary->save( $opt->{input} );
}

sub run_interactive {
	my $self = shift;
	my $opt = $self->{opt};

	my $summary = $self->load_summary;
	my $flat = $self->create_flatfile( $summary );
	
	my $buffer = $flat->save;
	do {
		if ( $@ ) {
			my $err = $@;
			$err =~ s/^/# /mg;
			$buffer = "# There was an error in your output:\n\n$err\n\n# to abort clear the entire file\n\n$buffer";
		}

		$buffer = Proc::InvokeEditor->edit( $buffer );

		exit unless $buffer =~ /\S/;

	} until eval { $flat->load($buffer) };

	$summary->save( $opt->{input} );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Mail::Summary::Tools::CLI::Edit - Edit a YAML summary using the FlatFile format

=head1 SYNOPSIS

	# see command line usage

=head1 DESCRIPTION

=cut


