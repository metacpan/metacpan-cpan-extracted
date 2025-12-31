# NAME

HTML::Purifier - Basic HTML purification

# VERSION

Version 0.01

# DESCRIPTION

HTML::Purifier provides basic HTML purification capabilities.
It allows you to define a whitelist of allowed tags and attributes, and it removes or encodes any HTML that is not on the whitelist.
This helps to prevent cross-site scripting (XSS) vulnerabilities.

# SYNOPSIS

## Basic Usage

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

## Allowing Comments

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

## Encoding Invalid Tags

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

# METHODS

## new(%args)

Creates a new HTML::Purifier object.

- allow\_tags

    An array reference containing the allowed HTML tags (case-insensitive).

- allow\_attributes

    A hash reference where the keys are allowed tags (lowercase), and the values are array references of allowed attributes for that tag.

- strip\_comments

    A boolean value (default: 1) indicating whether HTML comments should be removed.

- encode\_invalid\_tags

    A boolean value (default: 1) indicating whether invalid tags should be encoded or removed.

## purify($html)

Purifies the given HTML string.

- $html

    The HTML string to be purified.

Returns the purified HTML string.

# DEPENDENCIES

\* HTML::Parser
\* HTML::Entities

# CAVEATS

This is a basic HTML purifier.
For production environments, consider using more mature and actively maintained libraries like `http://htmlpurifier.org/` or [Mojolicious::Plugin::TagHelpers](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3ATagHelpers).

# SUPPORT

This module is provided as-is without any warranty.

# AUTHOR

Nigel Horne ` << njh @ nigelhorne.com `> >

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
