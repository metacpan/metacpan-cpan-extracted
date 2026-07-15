use strict;
use warnings;
use Test::More;
use Eshu;

sub pod { Eshu->indent_pod($_[0]) }

# ── already-formatted snippets ─────────────────────────────────────
# POD directives always start at column 0; verbatim blocks preserve
# their indentation exactly as written.

# 1. minimal module doc
{
    my $code = <<'END';
=head1 NAME

Acme::Module - A sample module

=head1 SYNOPSIS

	use Acme::Module;
	my $obj = Acme::Module->new;

=head1 DESCRIPTION

This module does something useful.

=cut
END
    is(pod($code), $code, 'POD: minimal module NAME/SYNOPSIS/DESCRIPTION');
}

# 2. =head1 through =head3
{
    my $code = <<'END';
=head1 NAME

App - Main application class

=head1 METHODS

=head2 new

Constructs a new App object.

=head3 Parameters

=over 4

=item * C<name> - Application name

=item * C<version> - Version string

=back

=cut
END
    is(pod($code), $code, 'POD: nested =head1/=head2/=head3 with =over/=back');
}

# 3. verbatim block preserves indentation
{
    my $code = <<'END';
=head1 EXAMPLES

Basic usage:

	my $obj = Foo->new(name => 'example');
	$obj->do_thing(
	    arg1 => 1,
	    arg2 => 2,
	);

Advanced:

	for my $item (@list) {
	    $obj->process($item);
	}

=cut
END
    is(pod($code), $code, 'POD: verbatim blocks preserve indentation');
}

# 4. =over / =item list
{
    my $code = <<'END';
=head1 OPTIONS

=over 8

=item B<--help>

Print a help message and exit.

=item B<--verbose>

Enable verbose output.

=item B<--output> I<FILE>

Write output to I<FILE> instead of STDOUT.

=back

=cut
END
    is(pod($code), $code, 'POD: =over/=item option list');
}

# 5. numbered list
{
    my $code = <<'END';
=head1 PROCEDURE

=over 4

=item 1.

Install dependencies with C<cpanm --installdeps .>

=item 2.

Run C<perl Makefile.PL> to generate the Makefile.

=item 3.

Run C<make> to build the distribution.

=item 4.

Run C<make test> to verify everything works.

=back

=cut
END
    is(pod($code), $code, 'POD: numbered list');
}

# 6. =begin / =end block
{
    my $code = <<'END';
=head1 DESCRIPTION

Normal paragraph here.

=begin html

<table border="1">
	<tr><th>Name</th><th>Value</th></tr>
	<tr><td>foo</td><td>42</td></tr>
</table>

=end html

More normal text.

=cut
END
    is(pod($code), $code, 'POD: =begin/=end html block');
}

# 7. =for directive
{
    my $code = <<'END';
=for comment
This is an internal comment not rendered in output.

=for html <br />

=for text
----

=cut
END
    is(pod($code), $code, 'POD: =for directives');
}

# 8. inline formatting codes
{
    my $code = <<'END';
=head1 DESCRIPTION

This module uses B<bold> for important terms, I<italic> for emphasis,
C<code> for method names, and L<Other::Module> for links.

See L<perldoc/perlpod> for the full spec.

Use F</path/to/file> for filenames and E<lt>angle bracketsE<gt> for
literal angle brackets.

=cut
END
    is(pod($code), $code, 'POD: inline B<> I<> C<> L<> F<> E<>');
}

# 9. =encoding
{
    my $code = <<'END';
=encoding utf-8

=head1 NAME

Intl::Module - Module with UTF-8 documentation

=head1 DESCRIPTION

Supports characters like C<U+00E9> (E<eacute>).

=cut
END
    is(pod($code), $code, 'POD: =encoding directive');
}

# 10. full SYNOPSIS with multiline verbatim
{
    my $code = <<'END';
=head1 SYNOPSIS

	use HTTP::Tiny;
	my $http = HTTP::Tiny->new(
	    timeout    => 30,
	    verify_SSL => 1,
	);

	my $response = $http->get('https://example.com/api');
	if ($response->{success}) {
	    print $response->{content};
	} else {
	    die "Request failed: $response->{status} $response->{reason}\n";
	}

=cut
END
    is(pod($code), $code, 'POD: SYNOPSIS with complex verbatim');
}

# 11. method documentation
{
    my $code = <<'END';
=head2 process( $input [, %opts] )

Process the given C<$input> and return the result.

Parameters:

=over 4

=item $input

The input to process. Can be a string or an arrayref.

=item %opts (optional)

=over 4

=item encoding

Input encoding. Defaults to C<utf-8>.

=item strict

If true, raise an error on invalid input. Defaults to false.

=back

=back

Returns a hashref with keys C<result>, C<warnings>, and C<elapsed>.

=cut
END
    is(pod($code), $code, 'POD: method doc with nested =over');
}

# 12. BUGS section
{
    my $code = <<'END';
=head1 BUGS

Please report bugs at L<https://github.com/example/module/issues>.

Known issues:

=over 4

=item *

Behaviour under C<strict> mode may differ on Perl < 5.28.

=item *

Unicode normalisation is not applied to input strings.

=back

=cut
END
    is(pod($code), $code, 'POD: BUGS section');
}

# 13. SEE ALSO
{
    my $code = <<'END';
=head1 SEE ALSO

=over 4

=item L<Moose>

Full-featured OO system for Perl.

=item L<Moo>

Lighter-weight alternative to Moose.

=item L<perlobj>

The Perl documentation on objects.

=back

=cut
END
    is(pod($code), $code, 'POD: SEE ALSO with L<> items');
}

# 14. AUTHOR / COPYRIGHT
{
    my $code = <<'END';
=head1 AUTHOR

Jane Smith E<lt>jane@example.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 Jane Smith.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
END
    is(pod($code), $code, 'POD: AUTHOR and COPYRIGHT sections');
}

# 15. perlfunc-style entry
{
    my $code = <<'END';
=item chomp VARIABLE

=item chomp( LIST )

=item chomp

This safer version of L</chop> removes any trailing string that
corresponds to the current value of C<$/> (also known as $INPUT_RECORD_SEPARATOR
in the L<English> module).

	local $/ = "\n";
	chomp($str);   # removes trailing newline if present

Returns the total number of characters removed from all its arguments.

=cut
END
    is(pod($code), $code, 'POD: perlfunc-style =item with verbatim');
}

# 16. X<> index entry
{
    my $code = <<'END';
=head1 DESCRIPTION

X<interpolation> X<variable interpolation>

Perl I<interpolates> variables and certain backslash escape sequences
into double-quoted strings.

	my $name = "World";
	print "Hello, $name!\n";   # prints: Hello, World!

=cut
END
    is(pod($code), $code, 'POD: X<> indexing entries');
}

# 17. mixed verbatim and paragraphs
{
    my $code = <<'END';
=head2 Caching

Results are cached by default. To disable:

	my $obj = Foo->new(cache => 0);

Or clear the cache at runtime:

	$obj->clear_cache;

The cache is stored as a plain hash in C<$obj-E<gt>{_cache}>.

=cut
END
    is(pod($code), $code, 'POD: mixed verbatim and paragraphs');
}

# 18. Z<> null element
{
    my $code = <<'END';
=head1 NAME

Z<>App - The main application

=head1 DESCRIPTION

Use Z<> to force a new paragraph without visible output.

=cut
END
    is(pod($code), $code, 'POD: Z<> null element');
}

# 19. S<> non-breaking spaces
{
    my $code = <<'END';
=head1 DESCRIPTION

See S<C<perl -e 'print "Hello"'>> for an example of a one-liner.

Options are separated by S<non-breaking spaces> to prevent line-wrapping.

=cut
END
    is(pod($code), $code, 'POD: S<> non-breaking space');
}

# 20. multi-column verbatim alignment
{
    my $code = <<'END';
=head1 METHODS

=head2 new

	my $obj = Module->new(
	    host    => 'localhost',
	    port    => 8080,
	    timeout => 30,
	    debug   => 0,
	);

Creates a new object. All parameters are optional.

=cut
END
    is(pod($code), $code, 'POD: constructor with aligned verbatim');
}

# 21. deeply nested =over
{
    my $code = <<'END';
=head2 Configuration

=over 4

=item C<database>

Database connection settings.

=over 4

=item C<host>

Hostname. Default C<localhost>.

=item C<port>

Port number. Default C<5432>.

=item C<name>

Database name. Required.

=back

=item C<logging>

Logging configuration.

=over 4

=item C<level>

Log level: C<debug>, C<info>, C<warn>, or C<error>.

=back

=back

=cut
END
    is(pod($code), $code, 'POD: nested =over blocks');
}

# 22. =pod / =cut pairing
{
    my $code = <<'END';
=pod

=head1 NAME

Foo - Just a test

=head1 DESCRIPTION

This tests that C<=pod> opens a POD section correctly.

=cut
END
    is(pod($code), $code, 'POD: explicit =pod opener');
}

# 23. RETURNS section
{
    my $code = <<'END';
=head2 find_user( $id )

Look up a user by numeric ID.

=over 4

=item Arguments

=over 4

=item $id

Positive integer user ID.

=back

=item Returns

A L<User> object on success, or C<undef> if no user with that ID exists.

=item Throws

L<Database::Error> if the database connection fails.

=back

=cut
END
    is(pod($code), $code, 'POD: RETURNS/Throws in =over');
}

# 24. CONFIGURATION AND ENVIRONMENT
{
    my $code = <<'END';
=head1 CONFIGURATION AND ENVIRONMENT

B<MyApp> reads the following environment variables:

=over 4

=item C<MYAPP_CONFIG>

Path to the configuration file. Defaults to F</etc/myapp/config.yaml>.

=item C<MYAPP_LOG_LEVEL>

Logging level (C<debug>, C<info>, C<warn>, C<error>).

=item C<MYAPP_PORT>

Port to listen on. Defaults to C<8080>.

=back

=cut
END
    is(pod($code), $code, 'POD: CONFIGURATION AND ENVIRONMENT');
}

# 25. DIAGNOSTICS section
{
    my $code = <<'END';
=head1 DIAGNOSTICS

=over 4

=item C<< Invalid argument: %s >>

A method was called with an argument of the wrong type.

=item C<< Connection refused at %s line %d >>

The remote host refused the connection. Check that the server is running
and that the host and port are correct.

=item C<< Timed out after %d seconds >>

The request exceeded the configured timeout. Increase C<timeout> or
check for network issues.

=back

=cut
END
    is(pod($code), $code, 'POD: DIAGNOSTICS section');
}

# ── normalization tests ────────────────────────────────────────────
# POD directives that appear with wrong indentation get moved to col 0.

# 26. directives with leading spaces normalised to col 0
{
    my $in = <<'END';
  =head1 NAME

  Foo - test module

  =cut
END
    my $exp = <<'END';
=head1 NAME

	Foo - test module

=cut
END
    is(pod($in), $exp, 'POD: leading spaces on directives removed');
}

# 27. multiple directives de-indented
{
    my $in = <<'END';
  =head1 SYNOPSIS

      use Foo;

  =head1 DESCRIPTION

  A test module.

  =cut
END
    my $exp = <<'END';
=head1 SYNOPSIS

	use Foo;

=head1 DESCRIPTION

	A test module.

=cut
END
    is(pod($in), $exp, 'POD: multiple directive indentation removed');
}

# 28. =over/=back de-indented
{
    my $in = <<'END';
  =over 4

  =item * First

  =item * Second

  =back
END
    my $exp = <<'END';
=over 4

=item * First

=item * Second

=back
END
    is(pod($in), $exp, 'POD: =over/=item/=back de-indented');
}

# 29. mixed indented and clean
{
    my $in = <<'END';
=head1 NAME

  =head2 Sub-section

  Text here.

=head1 AUTHOR

Author name.
END
    my $exp = <<'END';
=head1 NAME

=head2 Sub-section

	Text here.

=head1 AUTHOR

Author name.
END
    is(pod($in), $exp, 'POD: mixed indented sub-directive de-indented');
}

# 30. =begin/=end with indented directives
{
    my $in = <<'END';
  =begin text

  This is a text block.

  =end text
END
    my $exp = <<'END';
=begin text

	This is a text block.

=end text
END
    is(pod($in), $exp, 'POD: =begin/=end directives de-indented');
}

# ── idempotency tests ──────────────────────────────────────────────

for my $snippet (
    "=head1 NAME\n\nFoo - a module\n\n=cut\n",
    "=head2 new\n\nConstructor.\n\n    my \$obj = Foo->new;\n\n=cut\n",
    "=over 4\n\n=item * alpha\n\n=item * beta\n\n=back\n",
    "=head1 DESCRIPTION\n\nThis module does B<something> useful.\n\nSee L<Other::Module> for details.\n\n=cut\n",
    "=begin html\n\n<p>An HTML paragraph.</p>\n\n=end html\n",
    "=for comment this is invisible\n\n=head1 AUTHOR\n\nJane E<lt>jane\@example.comE<gt>\n\n=cut\n",
    "=head1 SYNOPSIS\n\n    use Module;\n    my \$m = Module->new(\n        opt => 1,\n    );\n\n=cut\n",
    "=over 4\n\n=item Arguments\n\n=over 4\n\n=item \$x\n\nA number.\n\n=back\n\n=item Returns\n\nA string.\n\n=back\n",
    "=encoding utf-8\n\n=head1 NAME\n\nUTF::Module - UTF-8 module\n\n=cut\n",
    "=head1 SEE ALSO\n\nL<Moose>, L<Moo>, L<Mouse>\n\n=head1 COPYRIGHT\n\nCopyright 2024.\n\n=cut\n",
) {
    my $once = pod($snippet);
    is(pod($once), $once, 'POD: snippet idempotent');
}

done_testing;
