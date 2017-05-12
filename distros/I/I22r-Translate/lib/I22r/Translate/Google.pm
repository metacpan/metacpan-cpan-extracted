package I22r::Translate::Google;
use Moose;
use MooseX::ClassAttribute;
use I22r::Translate::Result;
use Carp;
use Data::Dumper;
with 'I22r::Translate::Backend';

our $VERSION = '0.96';

{
    # code from REST::Google and REST::Google::Translate2 packages.
    # REST::Google code is copyright 2008 by Eugen Sobchenko <ejs@cpan.org>
    # and Sergey Sinkovskiy <glorybox@cpan.org>
    #
    # These distributions are on CPAN, but REST::Google::Translate2
    # tests won't pass without an API key, and REST::Google tests
    # won't pass because of an obsolete REST::Google::Translate
    # package, so including these modules as dependencies would
    # be a giant headache.

    package I22r::REST::Google;
    use strict;
    use warnings;
    use Carp qw/carp croak/;
    use JSON::MaybeXS;
    use HTTP::Request;
    use LWP::UserAgent;
    use URI;
    require Class::Data::Inheritable;
    require Class::Accessor;
    use base qw/Class::Data::Inheritable Class::Accessor/;
    __PACKAGE__->mk_classdata("http_referer");
    __PACKAGE__->mk_classdata("service");
    __PACKAGE__->mk_accessors(qw/responseDetails responseStatus/);
    use constant DEFAULT_ARGS => ( 'v' => '1.0', );
    use constant DEFAULT_REFERER => 'http://example.com/';
    sub _get_args {
	my $proto = shift;
	my %args;
        if ( scalar(@_) > 1 ) {
                if ( @_ % 2 ) {
                        croak "odd number of parameters";
                }
                %args = @_;
        } elsif ( ref $_[0] ) {
                unless ( eval { local $SIG{'__DIE__'}; %{ $_[0] } || 1 } ) {
                        croak "not a hashref in args";
                }
                %args = %{ $_[0] };
        } else {
                %args = ( 'q' => shift );
        }
        return { $proto->DEFAULT_ARGS, %args };
    }
    sub new {
        my $class = shift;
        my $args = $class->_get_args(@_);
        croak "request attempted without setting a service URL"
                unless ( defined $class->service );
        my $uri = URI->new( $class->service );
        $uri->query_form( $args );
        unless ( defined $class->http_referer ) {
	    carp "search attempted without setting a valid http referer header";
	    $class->http_referer( DEFAULT_REFERER );
        }
	my $request;
	$request = HTTP::Request->new(
	    GET => $uri, 
	    [ 'Referer', $class->http_referer ] );
        my $ua = LWP::UserAgent->new();
        $ua->env_proxy;
        my $response = $ua->request( $request );
	if (!$response->is_success) {
	    croak sprintf qq/HTTP request failed: %s/, $response->status_line;
	}
        my $content = $response->content;
        my $json = JSON::MaybeXS->new(utf8 => 1);
        my $self = $json->decode($content);
        return bless $self, $class;
    }
    sub responseData { return $_[0]->{responseData} }
    ##################################################################
    package I22r::REST::Google::Translate;
    use strict;
    use warnings;
    use base qw/Exporter I22r::REST::Google/;
    __PACKAGE__->service( 'https://www.googleapis.com/language/translate/v2' );
    sub responseData {
	my $self = shift;
	my $rd = $self->{responseData} // $self->{data}{translations}[0];
	return bless $rd, 'I22r::REST::Google::Data';
    }
    ##################################################################
    package I22r::REST::Google::Data;
    require Class::Accessor;
    use base qw/Class::Accessor/;
    __PACKAGE__->mk_ro_accessors( qw/translatedText/ );
}

our %remap = ( he => 'iw' );
our %unremap = ( iw => 'he' );
our @google_languages = qw(
af sq ar az eu bn be bg ca zh zh-CN zh-TW hr cs da nl en eo
et tl fi fr gl ka de el gu ht iw he hi hu is id ga it ja kn
ko la lv lt mk ms mt no fa pl pt ro ru sr sk sl es sw sv ta
te th tr uk ur vi cy yi
);

sub BUILD {
    my $self = shift;
    $self->name('Google') unless $self->name;
}

sub can_translate {
    my ($self, $lang1, $lang2) = @_;
    if ($lang1 eq $lang2) {
	return 1;
    }
    my $langs = join(" ", @google_languages, values %remap);
    return -1 unless " $langs " =~ / $lang1 / && " $langs " =~ / $lang2 /;

    if ($lang1 =~ /zh/ && $lang2 =~ /zh/) {
	# assume translation between zh-CN and zh-TW is easy
	return 0.9;
    }

    return 0.4; 
}

sub get_translations {
    my ($self, $req) = @_;
    return unless $req->config("ENABLED");
    return unless $self->network_available;
    my $api_key = $req->config("API_KEY");
    return unless $api_key;

    if (!$self->config("REFERER_SET")) {
	$self->set_referer( $req->config("REFERER") );
    }


    # XXX - source encoding

    my %result;
    my %untext;
    my %text = %{$req->text};
    while (my ($id,$text) = each %text) {
	push @{$untext{$text}}, $id;
    }

    # XXX - refactor candidate. Can we pass multiple  &q=...
    #       params for efficiency

    my @text = keys %untext;
    my @translated;

    while (@text) {
	last if $req->timed_out;

	my @itext;
	my $otext = shift @text;
	my $uri = URI->new();
	$uri->query_form( 'q' => [ @itext, $otext ] );
	while ( length($uri) < 1500 ) {
	    push @itext, $otext;
	    $otext = shift @text;
	    last if !defined $otext;
	    $uri = URI->new();
	    $uri->query_form( 'q' => [ @itext, $otext ] );
	}
	if (defined $otext) {
	    unshift @text, $otext;
	}

	if (@itext == 0 && @text > 0) {
	    carp "Can't perform translation on next element '$text[0]'. ",
	        "Content length would be ",length($uri);
	    last;
	}

	eval {
	    my $res;
	    $res = eval { I22r::REST::Google::Translate->new(
		'q' => [ @itext ],
		'key' => $self->config->{API_KEY},
		'source' => $remap{$req->src} // $req->src,
		'target' => $remap{$req->dest} // $req->dest,
		'v' => '2.0'
		) } ;

	    if ($res) {
		eval {
		    my @output = map {
			$_->{translatedText}
			} @{ $res->{data}{translations} };
		    for my $i (0 .. $#itext) {
			my $ids = $untext{ $itext[$i] };
			foreach my $id (@$ids) {
			    $req->results->{$id} = I22r::Translate::Result->new(
				id => $id,
				otext => $itext[$i],
				olang => $unremap{ $req->src } // $req->src,
				lang => $unremap{ $req->dest } // $req->dest,
				text => $output[$i],
				source => $self->name,
				length => length($output[$i]),
				time => time
				);
			    push @translated, $id;
			}
		    }
		    
		    $self->config->{_NETWORK_ERR} = 0;
		};
	    } elsif ($@ =~ /connect to www.googleapis.com/) {
		if (++$self->config->{_NETWORK_ERR} > 100) {
		    carp "network issues.";
		    # how to disable for 30-60 seconds?
		}
	    } elsif ($@ =~ /HTTP response failed: 400/) {
		local $, = " , ";
		carp "Error in request, which had  q => [ @itext ]";
	    } elsif ($@) {
		carp $@;
	    }
	};
	if ($@) {
	    carp $@;
	}
    }
    return @translated;
}

sub network_available { !$ENV{NO_NETWORK} }

sub set_referer {
    my ($self, $referer) = @_;
    $referer //= $self->config->{REFERER} // "http://just.doing.some.testing/";
    I22r::REST::Google->http_referer( $referer );
    $self->config->{_REFERER_SET} = 1;
}

1;

=head1 NAME

I22r::Translate::Google - Google backend for I22r::Translate framework

=head1 SYNOPSIS

    I22r::Translate->config(
        'I22r::Translate::Google' => {
            ENABLED => 1,
            API_KEY => "your_required_API_key_goes_here",
            REFERER => "http://mywebsite.com/"
        }
    );

    $translation = I22r::Translate->translate_string(
        src => 'en', dest => 'es', text => 'hello world',
        quality => { 'I22r::Translate::Google' => 2.0 } );

=head1 DESCRIPTION

Invokes Google's translation webservice to translate content
from one language to another.

You instruct the L<I22r::Translate> package to use the
Google backend by passing a key-value pair to the
L<I22r::Translate::config|I22r::Translate/"config"> method
where the key is the string "C<I22r::Translate::Google>"
and the value is a hash reference with at least the following
key-value pairs:

=over 4

=item ENABLED => 0 | 1

Must be set to a true value for the Google backend to be enabled.

=item API_KEY => string

An API key is required to use the Google Translate web service.
You can get an API key from L<https://code.google.com/apis/console>
(note: this is not a free service).
(other note: if you can't get an API key from the above URL, but
then you do figure out where to get one, L<let me know|mailto:mob@cpan.org>
or L<file a bug report|I22r::Translate/"SUPPORT"> and 
I'll update these instructions).

=back

Configuration for the Google backend also recognizes these
options:

=over 4

=item REFERER => URL

Sets a URL that will passed to the Google Translate service as
your application's referer. If not set, this package will set
the referer to C<http://just.doing.some.testing/>.

=item timeout => integer

Stops a translation job after a certain number of seconds have
passed.

=item callback => code reference or function name

A function to be invoked when the Google backend obtains
a translation result. The function will be called with a single
hash reference argument, containing the available data about
the translation input and output.

=item filter => array reference

List of filters to use (see L<I22r::Translate::Filter>) when
sending text to the Google Translate webservice.

=back

When you use the L<I22r::Translate/"translate_string">,
L<I22r::Translate/"translate_list">, or
L<I22r::Translate/"translate_hash"> function, the
L<I22r::Translate> module will decide when to use the
Google backend for translation. Most users do not need to
know anything else about the methods in this package.

=head1 TODO

=over 4

=item 1. You typically make a GET request to the Google webservice,
which has a limit of 2000 characters (that's 2000 URL encoded and
UTF-8 encoded bytes, right?). If you use a POST request, you can
send up to 5000 bytes. L<WWW::Google::Translate> does this.

=item 2. Provide a way to override the C<can_translate> method
and plug in your own opinion of how well Google translates between
language pairs (ultimately, want to be able to do this for every
backend).

=item 3. Dynamically determine the list of languages supported by
Google translate. Either that or release a new version of this
module each time a language is added/deleted.

=back

=head1 AUTHOR

Marty O'Brien, C<< <mob@cpan.org> >>

=head1 SEE ALSO

L<WWW::Google::Translate>, L<Lingua::Translate::Google>,
L<REST::Google::Translate>, L<REST::Google::Translate2>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2016 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
