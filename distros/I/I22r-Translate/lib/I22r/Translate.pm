package I22r::Translate;
use strict;
use warnings;
use Carp;
use I22r::Translate::Request;

our $VERSION = '0.96';
our %config;
our %backends;
my $translate_calls = 0;

sub config {
    my ($class, @options) = @_;
    if (@options == 0) {
	return \%config;
    }
    if (@options == 1) {
	return $config{ $options[0] };
    }
    my %options = @options;
    foreach my $key (keys %options) {

	if ($key =~ /::/) {
	    $backends{$key} = eval "use $key; 1";
	    if ($@) {
		carp "Failed to load back end class $key.\n$@";
		next;
	    } else {
		# warn "Loaded back end $key.\n";
	    }
	    if ('HASH' eq ref $options{$key}) {
		$key->config( %{$options{$key}} );
	    } else {
		carp "Config not correct.\n";
	    }
	} else {
	    $config{$key} = $options{$key};
	}
    }
}

sub translate_string {
    my ($pkg, %input) = @_;
    my $text = delete $input{text};
    if (!defined $text) {
	carp "I22r::Translate::translate_string: missing 'text' specifier";
	return;
    }
    my %r = $pkg->translate( %input, text => { string => $text } );
    return $r{string};
}

sub translate_list {
    my ($pkg, %input) = @_;
    my $text = delete $input{text};
    if (!defined $text) {
	carp "I22r::Translate::translate_list: missing 'text' specified";
	return;
    }
    my $n = -1;
    my $texthash = { map { $n++; "string$n" => $_ } @$text };
    my %r = $pkg->translate( %input, text => $texthash );
    my @r = map { $r{"string$_"} } 0 .. $n;
    return @r;
}

sub translate_hash {
    my ($pkg, %input) = @_;
    my $text = delete $input{text};
    if (!defined $text) {
	carp "I22r::Translate::translate_list: missing 'text' specified";
	return;
    }
    my $n = -1;
    my %r = $pkg->translate( %input, text => $text );
    return %r;
}

sub translate {
    my ($pkg, %input) = @_;
    my $src = delete $input{src};
    my $dest = delete $input{dest};
    $translate_calls++;

    my $text = delete $input{text};
    my %options = %input;

    my $req = I22r::Translate::Request->new(
	src => $src, dest => $dest, text => $text, %options );
    $pkg->log($req->{logger}, "Built request object" );

    # 1. see which backends are capable of translating  $src|$dest
    # 2. iterate through backends
    #    3. pass untranslated entries in %$text to the backend
    #    4. get results
    # 5. return all results

    my %quality = map {
	$_ => $_->can_translate($src,$dest) 
    } keys %backends;

    # TODO - adjust $quality for request, backend adjustments
    my @backends = sort { $quality{$b} <=> $quality{$a} } keys %quality;
    foreach my $backend (@backends) {
	next if $quality{$backend} <= 0;

	$pkg->log($req->{logger}, "using backend: $backend");

	$req->backend($backend);
	$req->{backend_start} = time;
	$req->apply_filters;
	$pkg->log($req->{logger}, "applied input filters");
	my @t = $backend->get_translations($req);
	$pkg->log($req->{logger}, "got translations for ",
	    scalar(@t), " inputs");
	$req->unapply_filters;
	$pkg->log($req->{logger}, "removed filters");
	$req->invoke_callbacks(@t);
	$pkg->log($req->{logger}, "ran callbacks");
	delete $req->{backend_start};
	$req->backend( undef );

	last if $req->translations_complete;
	last if $req->timed_out;
    }
    return $req->return_results;
}

sub log {
    my ($pkg, $logger, @msg) = @_;
    $logger //= $config{logger};
    return if !defined $logger;
    return eval { $logger->debug(@msg); 1 } ||
	   eval { $logger->log(@msg); 1 } ||
	   print STDERR "I22r::Translate: ",@msg,"\n";
}

=head1 NAME

I22r::Translate - Translate content with the Internationalizationizer

=head1 VERSION

Version 0.96

=head1 SYNOPSIS

    use I22r::Translate;

    I22r::Translate->config( ... );

    $r = I22r::Translate->translate_string(
        src => 'en', dest => 'de', text => 'Good morning.' );

    @r = I22r::Translate->translate_list(
        src => 'es', dest => 'en', 
        text => [ 'Buenos dias.', 'Tengo hambre.' ],
        filter => [ 'HTML' ]);

    %r = I22r::Translate->translate_hash(
        src => 'en',
        dest => 'es',
        text => {
            field1 => 'hello world',
            field2 => 'How are you?'
        },
        timeout => 10 );

=head1 DESCRIPTION

C<I22r::Translate> is a feature-ful, flexible, extensible framework
for translating content between different languages.

You start by calling the package L<"config"> method, where you
set some global options and configure one or more
L<I22r::Translate::Backend> packages.

Pass text to be translated with the L<"translate_string">,
L<"translate_list">, or L<"translate_hash"> methods. These
methods will choose an available backend class to perform the
translation(s).

=head1 CONFIG

There are three levels of configuration that affect every
translation request. 

First, there is global configuration, set with this package's
L<"config"> method.

Second, there is configuration for each backend. This is also
set with this package's L<"config"> method, or with each backend
package's C<config> method.

Finally, there is configuration that can be set for each
individual translation request.

Some configuration options are recognized at all three of these
levels. Some other options may only be recognized by some of
the backends (API keys, for example).

Some of the most commonly used configuration options are:

=over 4

=item timeout => int

Stops processing the translation request if this many seconds have
passed since the request / current backend was started. Only the
completed translations will be returned. You can have a global timeout
setting, a separate timeout for each backend, and a separate timeout
for the current request.

=item callback => CODE

Specifies a code reference or a subroutine name that will be invoked
when a new translation result is available. 

The function will be called with two arguments: the
L<request|I22r::Translate::Request> object that is handling the
translation, and a hash reference containing the fields and values
for the new translation result.

You can have separate callbacks in
the global configuration, for each backend, and for the current
request.

=item filter => ARRAY

Specifies one or more I<filters> to apply to the translation input
before text is passed to the backend(s). See L<"FILTERS">, below,
for more information. The global configuration, each backend configuration,
and each request can specify different filters to use.

=item return_type => C<simple> | C<object> | C<hash>

By default, return values (include the values from C<translate_hash>)
are simple scalars containing translated text, but supplying a
C<return_type> configuration parameter can instruct this module to 
return either a L<I22r::Translate::Result> object or a hash reference
for each translation result, either of which will provide access
to additional data about the translation.

=back

=head1 SUBROUTINES/METHODS

=head2 config

=head2 I22r::Translate->config( \%opts )

You must call the C<config> method before you can use the
C<I22r::Translate> package. At least one of the options should be
the name of a L<I22r::Translate::Backend> with a hash reference
of options to configure the backend. A minimal configuration call
that uses the L<Google|I22r::Translate::Google> translation backend
might look like:

    I22r::Translate->config(
        'I22r::Translate::Google' => {
            ENABLED => 1,
            API_KEY => 'abcdefghijklmnopqrstuvwxyz0123456789',
            REFERER => 'http://mysite.com/'
        },
    );

See the L<"CONFIG"> section above for other common parameters
to pass to the C<config> method. See the documentation for each
backend for the configuration parameters recognized and required
for that backend.

=head2 translate_string

=head2 $text_in_lang2 = I22r::Translate->translate_string(
src => I<lang1>, dest => I<lang2>, text => I<text in lang1>,
I<option> => I<value>, ...)

Attempt to translate the text in a single scalar from language
I<lang1> to language I<lang2>. The C<src>, C<dest>, and C<text>
arguments are required. Any other parameters are interpreted as
configuration that applies to the translation. See the L<"CONFIG">
section for some possible choices.

=head2 translate_list

=head2 @text_in_lang2 = I22r::Translate->translate_list(
src => I<lang1>, dest => I<lang2>, text => [ I<text1>, I<text2>, ... ],
I<option> => I<value>, ...)

Translate a list of text strings between languages I<lang1>
and I<lang2>, returning the translated list. The C<src> and
C<dest> arguments are required, and the C<text> argument must
be an array reference. Other parameter are interpreted as 
configuration that applies to the current translation.

The output array will have the same number of elements as the
C<text> input. If any of the input string were not translated,
some or all of the output elements may be C<undef>.

For some backends, it may be much more efficient to translate a list
of strings at once rather than to call C<translate_string>
repeatedly.

=head2 translate_hash

=head2 %text_in_lang2 = I22r::Translate->translate_hash(
src => I<lang1>, dest => I<lang2>, text => [ I<text1>, I<text2>, ... ],
I<option> => I<value>, ...)

Translate the text string values of a hash reference 
between languages I<lang1> and I<lang2>, returning a hash with the
same keys as the input and translated text as the values.
The C<src> and C<dest> arguments are required, 
and the C<text> argument must
be a hash reference with arbitrary keys and values as text
strings in I<lang1>. Other parameter are interpreted as 
configuration that applies to the current translation.

The output will not contain key-value pairs for the 
some or all of the output elements may be C<undef>.

=head1 FILTERS

Sometimes you do not want to pass a piece of text directly to
a translation engine. The text might contain HTML tags or 
other markup. It might contain proper nouns or other words that
you don't intend to translate. 

The L<I22r::Translate::Filter> provides a mechanism to
adjust the text before it is passed to a translation engine and
to unadjust the output from the translator.

The C<filter> configuration parameter may be used in
global configuration (the L<"config"> method), backend
configuration (also the L<"config"> method), or in a 
translation request (the L<translate_XXX|"translate_string">
methods). The filter config value is an array reference of
the filters to apply to translator input, in the order
they are to be applied. You may either provide the name
of the filter class (an implementor of the
L<I22r::Translation::Filter> role), an instance of a filter
class, or a sinple string. In the latter case, C<I22r::Translate>
will attempt to convert it to the name of a filter class by
prepending C<I22r::Translate::Filter::> to the string.

See L<I22r::Translate::Filter::Literal> and
L<I22r::Translate::Filter::HTML> for examples of
filters that are included with this distribution,
and L<I22r::Translate::Filter> for general information and
instructions for creating your own filters.

=head1 AUTHOR

Marty O'Brien, C<< <mob at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-i22r-translate at rt.cpan.org>, or through the web interface at 
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=I22r-Translate>.  
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc I22r::Translate


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=I22r-Translate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/I22r-Translate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/I22r-Translate>

=item * Search CPAN

L<http://search.cpan.org/dist/I22r-Translate/>

=back

=head1 SEE ALSO

L<Lingua::Translate>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2016 Marty O'Brien.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of I22r::Translate

__END__

TO DO:

    quality => { backend1 => float, backend2 => float }

        adjust the quality calculation for backends

    src_enc, dest_enc
