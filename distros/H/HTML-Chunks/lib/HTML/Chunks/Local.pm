package HTML::Chunks::Local;

our $VERSION = "1.02";

use strict;
use base qw(HTML::Chunks);

sub new
{
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	
	$self->{langdefaults} = [];

	return $self;
}

sub output {
	my $self = shift;
	my $name = shift;
	my $uselang = shift;

	foreach my $lang (@{$uselang}, @{$self->{langdefaults}}) {
		if (defined($self->{chunk}{"$name\_$lang"})) {
			return $self->SUPER::output("$name\_$lang", @_);
		}
	}
	# our last default is the chunk name with no language suffix
	return $self->SUPER::output($name, @_);
}

sub setLangDefaults {
	my $self = shift;
	($self->{langdefaults}) = @_;
}

sub getLangDefaults {
	my $self = shift;
	return $self->{langdefaults};
}

sub guessLanguage {
	my $self = shift;
	my @return;
	
	foreach my $lang (@_) {
		$lang =~ s/\-/\_/;
		push(@return, $lang);
		if ($lang =~ /(.+)\_/) {
			push(@return, $1);
		}
	}
	return \@return;
}

1;

__END__

=pod

=head1 NAME

HTML::Chunks::Local - A simple localization layer for HTML::Chunks

=head1 VERSION

1.02

=head1 DESCRIPTION

This subclass of HTML::Chunks is geared for sites which deliver multi-lingual
content. This works by making chunks that have a similar name but with a
language or country code appended to the name (e.g. chunk_en) in your template
files. When you call I<output()>, you pass in an array reference which
contains the user's language preference(s) after the chunk name. The subclass
goes through that list, followed by default language codes, and finally tries
no language code to find the most appropriate chunk to output. Simple.

=head1 SYNOPSIS

 use HTML::Chunks::Local;
 $chunks = new HTML::Chunks::Local('chunkfile.html');
 $chunks->output('sample_chunk', [pt, sp], @data);

=head1 ROUTINES

=over

=item my $chunks = new HTML::Chunks::Local('chunkfile.html');

Create a new Chunks instance, and load up any chunk files supplied.

=item $chunks->output('chunkid', \@languagepref, ... );

Same as HTML::Chunks->output(), but requires an array ref with the user's
language preference(s).

=item $chunks->setLangDefaults(\@default_language_list);

=item $chunks->getLangDefaults();

Accessor methods to set and retrieve the default language list. Note that is
expects and returns array references.

=item $chunks->guessLanguage(\@languagepref);

Returns an array reference with a best guess language list. This expects to
see typical HTTP header for language with country code (e.g. en-us), and
returns a list of probable fallbacks, like [en_us, en]. Note that it converts
the '-' into a more easily used '_', though it will accept any non-alpha
character as a language/country spearator. This sub can be made to be much
more intelligent, but this is a nice 80/20 solution for now.

=head1 CREDITS

Created, developed and maintained by Mark W Blythe and Dave Balmer, Jr.
Contact dbalmer@cpan.org or mblythe@cpan.org for comments or questions.

=head1 LICENSE

(C)2001-2004 Mark W Blythe and Dave Balmer Jr, all rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

