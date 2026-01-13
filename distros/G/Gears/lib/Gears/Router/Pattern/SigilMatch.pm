package Gears::Router::Pattern::SigilMatch;
$Gears::Router::Pattern::SigilMatch::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Gears::X;
use URI::Escape;

extends 'Gears::Router::Pattern';

has extended 'location' => (
	handles => [
		qw(
			checks
			defaults
		)
	],
);

has field '_regex' => (
	isa => RegexpRef,
	lazy => 1,
);

has field 'tokens' => (
	isa => ArrayRef,
	default => sub { [] },
);

# helpers for matching different types of wildcards
my sub noslash ($sigil)
{
	return 1 == grep { $sigil eq $_ } ':', '?';
}

my sub matchall ($sigil)
{
	return 1 == grep { $sigil eq $_ } '*', '>';
}

my sub optional ($sigil)
{
	return 1 == grep { $sigil eq $_ } '?', '>';
}

sub _rep_regex
{
	my ($self, $char, $switch, $token, $out) = @_;
	my $qchar = quotemeta $char;
	my $re;

	push $self->tokens->@*, {
		sigil => $switch,
		label => $token,
	};

	my ($prefix, $suffix) = ("(?<$token>", ')');
	if (noslash($switch)) {
		$re = $qchar . $prefix . ($self->checks->{$token} // '[^\/]+') . $suffix;
	}
	elsif (matchall($switch)) {
		$re = $qchar . $prefix . ($self->checks->{$token} // '.+') . $suffix;
	}

	if (optional($switch)) {
		$re = "(?:$re)" if $char eq '/';
		$re .= '?';
	}

	push $out->@*, $re;
	return '{}';
}

sub _build_regex ($self)
{
	my $pattern = $self->pattern;

	my $placeholder_pattern = qr{
		( [^\0]? ) # preceding char, may change behavior of some placeholders
		( [:*?>] ) # placeholder sigil
		( \w+ )    # placeholder label
	}x;

	# Curly braces and brackets are only used for separation.
	# We replace all of them with \0, then convert the pattern
	# into a regular expression. This way if the regular expression
	# contains curlies, they won't be removed.
	$pattern =~ s/[{}]/\0/g;

	my @rep_regex_parts;
	$pattern =~ s{
		$placeholder_pattern
	}{
		$self->_rep_regex($1, $2, $3, \@rep_regex_parts)
	}egx;

	# Now remove all curlies remembered as \0 - We will use curlies again for
	# special behavior in a moment
	$pattern =~ s/\0//g;

	# remember if the pattern has a trailing slash before we quote it
	my $trailing_slash = $pattern =~ m{/$};

	# _rep_regex reused curies for {} placeholders, so we want to split the
	# string by that (and include them in the result by capturing the
	# separator)
	my @parts = split /(\Q{}\E)/, $pattern, -1;

	# If we have a placeholder, replace it with next part. If not, quote it to
	# avoid misusing regex in patterns.
	foreach my $part (@parts) {
		if ($part eq '{}') {
			$part = shift @rep_regex_parts;
		}
		else {
			$part = quotemeta $part;
		}
	}

	$pattern = join '', @parts;
	if ($self->is_bridge) {

		# bridge must be followed by a slash or end of string, so that:
		# - /test matches
		# - /test/ matches
		# - /test/something matches
		# - /testsomething does not match
		# if the bridge is already followed by a trailing slash, it's not a
		# concern
		$pattern .= '(?:/|$)' unless $trailing_slash;
	}
	else {

		# regular pattern must end immediately
		$pattern .= quotemeta('/') . '?' unless $trailing_slash;
		$pattern .= '$';
	}

	return qr{^$pattern};
}

sub BUILD ($self, $)
{
	$self->_regex;    # ensure tokens are created
}

sub compare ($self, $request_path)
{
	return undef unless $request_path =~ $self->_regex;

	# initialize the named parameters hash and its default values
	my %named = ($self->defaults->%*, %+);

	# transform into a list of parameters
	return [map { $named{$_->{label}} } $self->tokens->@*];
}

sub build ($self, %args)
{
	my $pattern = $self->pattern;
	my $checks = $self->checks;
	%args = ($self->defaults->%*, %args);

	foreach my $token ($self->tokens->@*) {
		my $value = $args{$token->{label}};

		Gears::X->raise("no value for placeholder $token->{sigil}$token->{label}")
			unless defined $value || optional $token->{sigil};

		if (defined $value) {
			my $safe = '^A-Za-z0-9\-\._~';
			$safe .= '/' unless noslash $token->{sigil};
			$value = uri_escape_utf8 $value, "^$safe";
		}

		my $to_replace = qr{
			\Q$token->{sigil}\E
			$token->{label}
		}x;

		if (defined $value) {
			my $check = $checks->{$token->{label}};
			Gears::X->raise("bad value for placeholder $token->{sigil}$token->{label}")
				if $check && $value !~ /^$check$/;

			$pattern =~ s{\{?$to_replace\}?}{$value};
		}
		else {
			# slash should be removed as well for optional placeholders (if no brackets)
			$pattern =~ s{/$to_replace|\{?$to_replace\}?}{};
		}
	}

	return $pattern;
}

__END__

=head1 NAME

Gears::Router::Pattern::SigilMatch - Pattern matching with placeholder support

=head1 SYNOPSIS

	use Gears::Router::Pattern::SigilMatch;

	my $pattern = Gears::Router::Pattern::SigilMatch->new(
		location => $location,
	);

	# Match and extract placeholders
	my $match_data = $pattern->compare('/user/123/post/my-slug');
	# $match_data = ['123', 'my-slug']

	# Build URL from placeholders
	my $url = $pattern->build(id => 456, slug => 'new-slug');
	# $url = '/user/456/post/new-slug'

=head1 DESCRIPTION

Gears::Router::Pattern::SigilMatch provides pattern matching with support for
placeholders using sigils. It converts patterns with sigils into regular
expressions for matching and can build URLs by substituting placeholder values.

See L<Gears::Router::Location::SigilMatch>, which discusses placeholder types
and their behavior.

=head1 INTERFACE

Inherits interface from L<Gears::Router::Pattern>.

=head2 Attributes

=head3 tokens

An array reference of token definitions extracted from the pattern. Each token
is a hash with C<sigil> and C<label> keys. This is populated automatically when
the pattern object is built.

I<Not available in constructor>

=head3 checks

A hash reference of validation patterns for placeholders, taken from the
location data.

I<Not available in constructor>

=head3 defaults

A hash reference of default values for placeholders, taken from the location
data.

I<Not available in constructor>

=head2 Methods

=head3 compare

	$match_data = $pattern->compare($request_path)

Matches the request path against the pattern's compiled regular expression.
Returns an array reference containing the extracted placeholder values in the
order they appear in the pattern. Returns C<undef> if the path doesn't match.
Default values are applied for optional placeholders that weren't matched.

=head3 build

	$url = $pattern->build(%params)

Builds a URL by substituting placeholders in the pattern with provided
parameter values. Default values are used for parameters not provided. Throws
an exception if required parameters are missing or if parameter values don't
pass their checks.

Passed params will be URI-encoded properly. Two types of sigils which allow
slashes in them, C<*wildcard> and C<< >slurpy >>, will not URI-encode slashes.
If you need to do that, it should be done manually with L<URI::Encode>.

