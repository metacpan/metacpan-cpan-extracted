package HTML::Email::Obfuscate;

=pod

=head1 NAME

HTML::Email::Obfuscate - Obfuscated HTML email addresses that look normal

=head1 DESCRIPTION

I<"Don't put emails directly on the page, they will be scraped">

Stuff that, I'm sick of looking at C<bob at smith dot com>. Why can't we
just write emails in a way that looks normal to people, but is very, very
difficult to scrape off. Most email scrapers only use very very simple
parsing methods. And it isn't as if it is hard to just do.

  # Before we search for email addresses...
  $page =~ s/\s+at\s+/@/g;
  $page =~ s/\s+dot\s+/./g;

This is an arms war dammit, and I want nukes!

=head2 About this Module

This module was written during OSDC/YAPC.AU to demonstrate how quick and
easy it is to write a basic module and put it on CPAN. The code was
written in about 40 minutes, the documentation was added during a break
period before drinks and dinner, and the packing and test files were
added during the python keynote (significant whitespace... ew...).

=head2 How this works

This module starts by applying a fairly basic set of character escapes to
avoid the most basic scrapers, and then layers more and more crap on
randomly, so that any scraper will need to implement more and more of a
full web browser, while keeping the email looking "normal" to anyone
browsing.

I've only scraped the surface of what we can achieve, and I'll leave it to
others to submit patches to improve it from here on.

=head2 Using HTML::Email::Obfuscate

This is a pretty simple module.

First, create an obfuscator object. This is just a simple object that holds
some preferences about how extreme you want to be about the obfuscation.

  # Create a default obfuscation object
  my $Email = HTML::Email::Obfuscate->new;

Now to turn a normal email string into an obfuscated and fully escaped HTML
one, just provide it to the escape_html method.

  # Obfuscate my email address
  my $html = $Email->escape_html( 'cpan@ali.as' );

And we get something like this

  ***Example here once I get a chance to run it***

The defaults are fairly insane, so for people that just want veeeery simple
escaping, we'll provide a lite version.

  # Create a "lite" obfuscator
  my $Email = HTML::Email::Obfuscate->new( lite => 1 );
  
  # Access the lite escape method directly, regardless of the
  # obfuscator's constructor params.
  my $html = $Email->escape_html_lite( 'cpan@ali.as' );

For the more serious people, we can also add some more extreme measures
that are probably not going to be compatible with everything, such as
JavaScript. :/

  # Allow the obfuscator to use JavaScript
  my $Email = HTML::Email::Obfuscator->new( javascript => 1 );

Best not to use that unless you have a JavaScript-capable browser.

I think that just about covers it, and my 7 minute lightning talk is
probably almost up.

=head1 METHODS

=cut

use 5.005;
use strict;
use HTML::Entities ();

use vars qw{$VERSION @WRAP_METHOD};
BEGIN {
	$VERSION = '1.00';

	# The list of modifier methods
	@WRAP_METHOD = qw{
		_random_modifier_span
		_random_modifier_comment
		_random_modifier_javascript
		};
}





#####################################################################
# Constructor

=pod

=head2 new $param => $value [, ... ]

The C<new> constructor creates a new obfuscation object, which use can
then use to obfuscate as many email addresses as you like, at whatever
severity you want it to be done.

It takes two optional parameters.

If you set the C<'javascript'> param, the obfuscator will add JavaScript
obfuscation (possibly, and randomly) to the mix of obfuscation routines.

If you set the C<'lite'> param, the obfuscator will only use the most
basic form of escaping, which will only fool scanner that don't do
HTML entity decoding. Setting 'lite' implies that JavaScript should not
be used, even if you explicitly try to turn it on.

Returns a new C<HTML::Email::Obfuscate> object.

=cut

sub new {
	my $class = shift;
	my %args  = ref $_[0] eq 'HASH' ? %{shift()} : @_;
	%args = map { lc $_ } %args;

	# Create the defailt HTML generation object
	my $self = bless {
		lite       => '',
		javascript => '',
		}, $class;

	# Flag control
	$self->{javascript} = 1  if $args{javascript};
	$self->{javascript} = '' if $args{lite};
	$self->{lite}       = 1  if $args{lite};

	$self;
}

=pod

=head2 escape_html_lite $email

On an otherwise normal obfuscator, the C<escape_html_lite> method provides
direct access to the lite method for obfuscating emails.

Returns a HTML string, or C<undef> if passed no params, or and undefined
param.

=cut

sub escape_html_lite {
	my $either = shift;
	my $email  = defined $_[0] ? shift : return undef;
	my $self   = ref($either) ? $either : $either->new(@_) or return undef;

	# Just escape @ and add a single HTML comment
	$email =~ s/\@/<!-- \@ -->&#64;/sg;

	$email;
}		

=pod

=head2 escape_html $email

The C<escape_html> method obfuscates an email according to the params
provided to the constructor.

Returns a HTML string, or C<undef> if passed no params, or and undefined
param.

=cut

sub escape_html {
	my $either = shift;
	my $email  = defined $_[0] ? shift : return undef;
	my $self   = ref $either ? $either : $either->new(@_) or return undef;

	# Split into a set of characters
	my @chars = split //, $email;

	foreach my $char ( @chars ) {
		# Escape individual characters
		$char = $self->_escape_char($char);

		# Randomly wrap 20% of characters
		next unless rand(1) < 0.1;
		$char = $self->_random_modifier($char);		
	}

	# Join and return
	join '', @chars;
}

sub _escape_char {
	my $self = shift;
	my $char = shift;

	# Handle various characters
	return '<!-- @ -->&#64;' if $char eq '@';
	return '<B>&#46;</b>'    if $char eq '.';

	# Force the numberic escape of 20% of the characters.
	# Allow the remaining 80% to escape by the normal rules.
	return (rand(1) < 0.2)
		? HTML::Entities::encode_numeric($char, '^ ')
		: HTML::Entities::encode_numeric($char);
}

sub _random_modifier {
	my $self = shift;

	# Which wrap style do we want to use?
	my $max    = $self->{javascript} ? 2 : 1;
	my $method = $WRAP_METHOD[int(rand($max))];
	$self->$method(shift);
}

sub _random_modifier_span {
	"<span>$_[1]</span>";
}

sub _random_modifier_comment {
	(rand > 0.5) ? "<!-- @ -->$_[1]" : "$_[1]<!-- @ -->";
}

sub _random_modifier_javascript {
	my $self = shift;
	my $html = shift;
	$html =~ s/'/&quot;/g;
	qq~<script language="JavaScript">document.write('$html')</script>~;
}

1;

=pod

=head1 TO DO

OK, other than compile testing, I admit that I haven't really done
anything significant in the way of testing. I mean, there was B<SUCH>
an interesting python talk on, and how on earth do you test something
that has randomised output. :/

So yeah, it would be nice to write some better tests.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Email-Obfuscate>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright 2004 - 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
