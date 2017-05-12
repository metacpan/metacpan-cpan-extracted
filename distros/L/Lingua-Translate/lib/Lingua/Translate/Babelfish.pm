#!/usr/bin/perl -w

# Copyright (c) 2002, Sam Vilain.  All rights reserved. This program
# is free software; you may use it under the same terms as Perl
# itself.
#
# Portions taken from WWW::Babelfish, by Daniel J. Urist
# <durist@world.std.com>

package Lingua::Translate::Babelfish;

use strict;
use Carp;
use LWP::UserAgent;
use HTTP::Request::Common qw(GET POST);

# package globals:
# %config is default values to use for new objects
# %valid_langs is a hash from a babelfish URI to a hash of "XX_YY"
# language pair tags to true values.
use vars qw($VERSION %config %valid_langs);

# WARNING: Some constants have their default values extracted from the
# POD.  See the bottom of the file for the code that does this.

=head1 NAME

Lingua::Translate::Babelfish - Translation back-end for Altavista's
                               Babelfish, version 0.01

=head1 SYNOPSIS

 use Lingua::Translate;

 Lingua::Translate::config
     (
       backend => "Babelfish",
       babelfish_uri =>
           'http://babelfish.yahoo.com/translate_txt',
       ua => LWP::UserAgent->new(),
     );

 my $xl8r = Lingua::Translate->new(src => "de", dest => "en");

 # prints "My hovercraft is full of eels"
 print $xl8r->translate("Mein Luftkissenfahrzeug ist voll von den Aalen");

=head1 DESCRIPTION

Lingua::Translate::Babelfish is a translation back-end for
Lingua::Translate that contacts babelfish.altavisa.com to do the real
work.

It is normally invoked by Lingua::Translate; there should be no need
to call it directly.  If you do call it directly, you will lose the
ability to easily switch your programs over to alternate back-ends
that are later produced.

=head1 CONSTRUCTOR

=head2 new(src => $lang, dest => lang, option => $value)

Creates a new translation handle.  This method contacts Babelfish to
determine whether the requested language pair is available.

=over

=item src

Source language, in RFC-3066 form.  See L<I18N::LangTags> for a
discussion of RFC-3066 language tags.

=item dest

Destination Language

=item ua

=back

Other options that may be passed to the config() function (see below)
may also be passed as arguments to this constructor.

=cut

use I18N::LangTags qw(is_language_tag);

sub new {
    my ($class, %options) = (@_);

    my $self = bless { %config }, $class;

    croak "Must supply source and destination language"
	unless (defined $options{src} and defined $options{dest});

    is_language_tag($self->{src} = delete $options{src})
	or croak "$self->{src} is not a valid RFC3066 language tag";

    is_language_tag($self->{dest} = delete $options{dest})
	or croak "$self->{dest} is not a valid RFC3066 language tag";

    $self->config(%options);

    return $self;
}

=head1 METHODS

The following methods may be called on Lingua::Translate::Babelfish
objects.

=head2 translate($text) : $translated

Translates the given text.  die's on any kind of error.

If too large a block of text is given to translate, it is broken up to
the nearest sentence, which may fail if you have extremely long
sentences that wouldn't normally be found in normal language, unless
you were either sending in some text that has no punctuation at all in
it or for some reason some person was rambling on and on about totally
irrelevant things such as cheese, one of the finest foods produced by
mankind, or simply was the sort of person who don't like ending
sentences but instead merely keep going with one big sentence with the
hope that it keeps readers going, though its usual effect is merely to
confuse.

The previous paragraph gets translated by Babelfish OK.


=cut

sub translate {
    my $self = shift;
    UNIVERSAL::isa($self, __PACKAGE__)
	    or croak __PACKAGE__."::translate() called as function";

    my $text = shift;

    # chunkify the text.  Knowing how to do this properly is really
    # the job of an expert system, so I'll keep it simple and break on
    # English sentence terminators (which might be completely the
    # wrong thing to do for other languages.  Oh well)
    my @chunks = ($text =~ m/\G\s*   # strip excess white space
			     (
			         # some non-whitespace, then some data
			         \S.{0,$self->{chunk_size}}

			         # either a full stop or the end of
			         # string
			         (?:[\.;:!\?]|$)
			     )
			     /xsg);
    die "Could not break up given text into chunks"
	if (pos($text) and pos($text) < length($text));

    # the translated text
    my ($translated, $error);

  CHUNK:
    for my $chunk ( @chunks ) {
	# make a new request object
	my $req = POST ($self->{babelfish_uri},
			[
			 'doit' => 'done',
			 'intl' => '1',
			 'tt' => 'urltext',
			 'trtext' => $chunk,
			 'lp' => join("_", @{$self}{qw(src dest)}),
			 'Submit' => 'Translate',
			 'ei' => 'UTF-8',
			 'fr' => 'bf-res',
			]);

	$req->header("Accept-Charset", "utf-8");

    RETRY:
	# try several times to reach babelfish
	for my $attempt ( 1 .. $self->{retries} + 1 ) {

	    # go go gadget LWP::UserAgent
	    my $res = $self->agent->request($req);

	    if( $res->is_success ){

		my $output = $self->_extract_text($res->as_string, $res->header("Content-Type"));

		# Reject outputs that are too useless.
		next RETRY if $output =~ /^\*\*time-out\*\*|^&nbsp;$/;

		# babelfish errors (will these always be reported in
		# English?)
		next RETRY if $output =~ /We were unable to process your? request within the available time/;

		# Babelfish likes to append newlines
		$output =~ s/\n$//;

		$translated .= $output;

		next CHUNK;
	    } else {
		$error .= "Request $attempt:".$res->status_line."; ";
	    }
	}

	# give up
	die "Request timed out more than $self->{retries} times ($error)";

    }  # for my $chunk ...

    return $translated;

}

use Unicode::MapUTF8 qw(to_utf8);

# Extract the text from the html we get back from babelfish and return
# it.  It seems that SysTrans are really trying to make this hard to
# screen scrape, oh well.
sub _extract_text {
    my($self, $html, $contenttype) = @_;

    my ($translated) =
	($html =~ m{<div \s id="result[^>]*>
		    (?:<div \s style="padding:0.6em;">)?
		    ([^<]*)</}xs)
	    or die "Babelfish response unparsable, brain needed";

    my ($encoding) = ($contenttype =~ m/charset=(\S*)/);

    if ( $encoding =~ /^utf-?8$/i ) {
	return $translated
    } else {
	return to_utf8({ -string => $translated, -charset => $encoding });
    }
}

=head2 available() : @list

Returns a list of available language pairs, in the form of "XX_YY",
where XX is the source language and YY is the destination.  If you
want the english name of a language tag, call
I18N::LangTags::List::name() on it.  See L<I18N::LangTags::List>.

=cut

sub available {

    my $self = shift;
    UNIVERSAL::isa($self, __PACKAGE__)
	    or croak __PACKAGE__."::available() called as function";

    # return a cached result
    if ( my $ok_langs = $valid_langs{$self->{babelfish_uri}} ) {
	return keys %$ok_langs;
    }

    # create a new request
    my $req = GET $self->{babelfish_uri};

    # go get it
    my $res = $self->agent->request($req);
    die "Babelfish fetch failed; ".$res->status_line
	unless $res->is_success;

    # extract out the languages
    my $page = $res->content;

    # OK, so this only works for languages with two letter language
    # codes.  But can YOU see babelfish supporting any language that
    # don't have a two letter code in the near future?
    my @list;
    for my $pair ($page =~ m/option value="([a-z][a-z]_[a-z][a-z])"/g) {

	# check that the pair is really a language
	my ($src, $dest) = split /_/, $pair;
	unless ( is_language_tag($src) and is_language_tag($dest) ) {
	    warn "Don't recognise `$pair' as a valid language pair";
	    next;
	};

	push @list, $pair;
    }

    # save the result
    $valid_langs{$self->{babelfish_uri}} = map { $_ => 1 } @list;

    return @list;
}

=head2 agent() : LWP::UserAgent

Returns the LWP::UserAgent object used to contact Babelfish.

=cut

sub agent {

    my $self;
    if ( UNIVERSAL::isa($_[0], __PACKAGE__) ) {
        $self = shift;
    } else {
	$self = \%config;
    }

    unless ( $self->{ua} ) {
	$self->{ua} = LWP::UserAgent->new();
	$self->{ua}->agent($self->{agent});
	$self->{ua}->env_proxy();
    }

    $self->{ua};
}


=head1 CONFIGURATION FUNCTIONS

The following are functions, and not method calls.  You will probably
not need them with normal use of the module.

=head2 config(option => $value)

This function sets defaults for use when constructing objects.

=cut

sub config {

    my $self;
    if ( UNIVERSAL::isa($_[0], __PACKAGE__) ) {
        $self = shift;
    } else {
	$self = \%config;
    }

    while ( my ($option, $value) = splice @_, 0, 2 ) {

	if ( $option eq "babelfish_uri" ) {

	    # set the Babelfish URI
	    ($self->{babelfish_uri} = $value) =~ m/\?(.*&)?$/
		or croak "Babelfish URI `$value' not a query URI";

	} elsif ( $option eq "ua" ) {
	    $self->{ua} = $value;

	} elsif ( $option eq "agent" ) {

	    # set the user-agent
	    $self->{agent} = $value;
	    $self->{ua}->agent($value) if $self->{ua};

	} elsif ( $option eq "chunk_size" ) {

	    $self->{chunk_size} = $value;

	} elsif ( $option eq "retries" ) {

	    $self->{retries} = $value;

	} else {

	    croak "Unknown configuration option $option";
	}
    }
}

=over

=item babelfish_uri

The uri to use when contacting Babelfish.

The default value is
"http://babelfish.yahoo.com/translate_txt?"

=item agent

The User-Agent to pretend to be when contacting Babelfish.

The default value is "Lingua::Translate::Babelfish/", plus the version
number of the package.

=item chunk_size

The size to break chunks into before handing them off to Babelfish.
The default value is "1000" (bytes).

=item retries

The number of times to retry contacting Babelfish if the first attempt
fails.  The default value is "2".

=back

=cut

# extract configuration options from the POD
use Pod::Constants
    'NAME' => sub { ($VERSION) = (m/(\d+\.\d+)/); },
    'CONFIGURATION FUNCTIONS' => sub {
	Pod::Constants::add_hook
		('*item' => sub {
		     my ($varname) = m/(\w+)/;
		     #my ($default) = m/The default value is\s+"(.*)"\./s;
		     my ($default) = m/The default value is\s+"(.*)"/s;
		     config($varname => $default);
		 }
		);
	Pod::Constants::add_hook
		(
		 '*back' => sub {

		     # an ugly hack?
		     $config{agent} .= $VERSION;

		     Pod::Constants::delete_hook('*item');
		     Pod::Constants::delete_hook('*back');
		 }
		);
    };

1;

__END__

=head1 BUGS/TODO

Strings are sent and received in UTF8 without any processing.

=head1 SEE ALSO

L<Lingua::Translate>, L<LWP::UserAgent>, L<Unicode::MapUTF8>

The original interface to the fish - L<WWW::Babelfish>, by Daniel
J. Urist <durist@world.std.com>

=head1 AUTHOR

Sam Vilain, <enki@snowcra.sh>

=cut
