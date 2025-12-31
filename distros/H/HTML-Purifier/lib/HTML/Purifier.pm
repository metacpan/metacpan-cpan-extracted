package HTML::Purifier;

use strict;
use warnings;

use HTML::Parser;
use HTML::Entities qw(encode_entities);
use Params::Get;
use Params::Validate::Strict;

our $VERSION = '0.01';

=head1 NAME

HTML::Purifier - Basic HTML purification

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

HTML::Purifier provides basic HTML purification capabilities.
It allows you to define a whitelist of allowed tags and attributes, and it removes or encodes any HTML that is not on the whitelist.
This helps to prevent cross-site scripting (XSS) vulnerabilities.

=head1 SYNOPSIS

=head2 Basic Usage

  use HTML::Purifier;

  my $purifier = HTML::Purifier->new(
    allow_tags => [qw(p b i a)],
    allow_attributes => {
      a => [qw(href title)],
    },
  );

  my $input_html = '<p><b>Hello, <script>alert("XSS");</script></b> <a href="javascript:void(0);">world</a></p>';
  my $purified_html = $purifier->purify($input_html);

  print $purified_html; # Output: <p><b>Hello, </b> <a href="world">world</a></p>

=head2 Allowing Comments

  use HTML::Purifier;

  my $purifier = HTML::Purifier->new(
    allow_tags => [qw(p b i a)],
    allow_attributes => {
      a => [qw(href title)],
    },
    strip_comments => 0, # Do not strip comments
  );

  my $input_html = '<p><b>Hello, </b></p>';
  my $purified_html = $purifier->purify($input_html);

  print $purified_html; # Output: <p><b>Hello, </b></p>

=head2 Encoding Invalid Tags

  use HTML::Purifier;

  my $ourified = HTML::Purifier->new(
    allow_tags => [qw(p b i a)],
    allow_attributes => {
      a => [qw(href title)],
    },
    encode_invalid_tags => 1, # Encode invalid tags.
  );

  my $input_html = '<my-custom-tag>Hello</my-custom-tag>';
  my $purified_html = $purifier->purify($input_html);

  print $purified_html; # Output: &lt;my-custom-tag&gt;Hello&lt;/my-custom-tag&gt;

=head1 METHODS

=head2 new(%args)

Creates a new HTML::Purifier object.

=over 4

=item allow_tags

An array reference containing the allowed HTML tags (case-insensitive).

=item allow_attributes

A hash reference where the keys are allowed tags (lowercase), and the values are array references of allowed attributes for that tag.

=item strip_comments

A boolean value (default: 1) indicating whether HTML comments should be removed.

=item encode_invalid_tags

A boolean value (default: 1) indicating whether invalid tags should be encoded or removed.

=back

=cut

sub new {
	my $class = shift;
	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params(undef, \@_),
		schema => {
			allow_tags => {
				type => 'arrayref',
				optional => 1,
			}, 'allow_attributes' => {
				type => 'hashref',
				optional => 1,
			}, 'strip_comments' => {
				type => 'boolean',
				optional => 1,
			}, 'encode_invalid_tags' => {
				type => 'boolean',
				optional => 1,
			}
		}
	});

	return bless {
		allow_tags => $params->{allow_tags} || [],
		allow_attributes => $params->{allow_attributes} || {},
		strip_comments => $params->{strip_comments} // 1, # Default to stripping comments
		encode_invalid_tags => $params->{encode_invalid_tags} // 1, # Default to encoding invalid tags
	}, $class;
}

=head2 purify($html)

Purifies the given HTML string.

=over 4

=item $html

The HTML string to be purified.

=back

Returns the purified HTML string.

=cut

sub purify {
	my $self = shift;
	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params('html', \@_),
		schema => { html => { type => 'string' } }
	});
	my $html = $params->{'html'};

	my $output = '';
	my $skip_content = 0;
	my @stack;

	my $parser = HTML::Parser->new(
		api_version => 3,
		marked_sections => 1,
		handlers => {
			start => [ sub {
				my ($tag, $attr, $text) = @_;
				my $lc_tag = lc $tag;

				if ($lc_tag eq 'script' || $lc_tag eq 'style') {
					$skip_content = 1;
					push @stack, $lc_tag;
					return;
				}

				if (grep { lc $_ eq $lc_tag } @{$self->{allow_tags}}) {
					$output .= "<$lc_tag";
					foreach my $attr_name (keys %$attr) {
						my $lc_attr = lc $attr_name;
						if (exists $self->{allow_attributes}->{$lc_tag}
							&& grep { lc $_ eq $lc_attr } @{$self->{allow_attributes}->{$lc_tag}}) {
							$output .= " $lc_attr=\"" . encode_entities($attr->{$attr_name}) . "\"";
						}
					}
					$output .= '>';
					push @stack, $lc_tag;
				}
				elsif ($self->{encode_invalid_tags}) {
					$output .= encode_entities("<$tag" . (join " ", map {$_ . "=\"" . encode_entities($attr->{$_}) . "\""} keys %$attr) . ">");
				}
			}, "tagname, attr, text"],

			end => [ sub {
				my ($tag, $text) = @_;
				my $lc_tag = lc $tag;

				if ($skip_content && $lc_tag eq $stack[-1]) {
					pop @stack;
					$skip_content = 0;
					return;
				}

				if (grep { lc $_ eq $lc_tag } @{$self->{allow_tags}}) {
					# Close only if it was opened
					if ($stack[-1] && $stack[-1] eq $lc_tag) {
						$output .= "</$lc_tag>";
						pop @stack;
					}
				}
				elsif ($self->{encode_invalid_tags}) {
					$output .= encode_entities("</$tag>");
				}
			}, "tagname, text"],

			text => [ sub {
				my ($text) = @_;
				return if $skip_content;
				$output .= encode_entities($text);
			}, "text"],

			comment => [ sub {
				my ($comment) = @_;
				if (!$self->{strip_comments}) {
					$comment =~ s/^<!--\s*//;
					$comment =~ s/\s*-->$//;
					$output .= "<!-- $comment -->";
				}
			}, "text"],
		}
	);

	$parser->parse($html);
	$parser->eof;
	return $output;
}

=head1 DEPENDENCIES

* HTML::Parser
* HTML::Entities

=head1 CAVEATS

This is a basic HTML purifier.
For production environments, consider using more mature and actively maintained libraries like C<http://htmlpurifier.org/> or L<Mojolicious::Plugin::TagHelpers>.

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne C< << njh @ nigelhorne.com >> >

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
