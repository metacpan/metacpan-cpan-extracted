package JavaScript::Minifier::XS;

use 5.8.1;
use strict;
use warnings;

require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our @EXPORT_OK = qw(minify);

our $VERSION = '0.13';

bootstrap JavaScript::Minifier::XS $VERSION;

1;

=for stopwords minifies minified minifier minification tokenizing EOL

=head1 NAME

JavaScript::Minifier::XS - XS based JavaScript minifier

=head1 SYNOPSIS

  use JavaScript::Minifier::XS qw(minify);
  my $js       = '...';
  my $minified = minify($js);

=head1 DESCRIPTION

C<JavaScript::Minifier::XS> is a JavaScript "minifier"; its designed to remove
unnecessary whitespace and comments from JavaScript files, which also B<not>
breaking the JavaScript.

C<JavaScript::Minifier::XS> is similar in function to C<JavaScript::Minifier>,
but is substantially faster as its written in XS and not just pure Perl.

=head1 METHODS

=over

=item minify($js)

Minifies the given C<$js>, returning the minified JavaScript back to the
caller.

=back

=head1 HOW IT WORKS

C<JavaScript::Minifier::XS> minifies the JavaScript by removing unnecessary
whitespace from JavaScript documents.  Comments (both block and line) are also
removed, I<except> when (a) they contain the word "copyright" in them, or (b)
they're needed to implement "IE Conditional Compilation".

Internally, the minification process is done by taking multiple passes through
the JavaScript document:

=head2 Pass 1: Tokenize

First, we go through and parse the JavaScript document into a series of tokens
internally.  The tokenizing process B<does not> check to make sure you've got
syntactically valid JavaScript, it just breaks up the text into a stream of
tokens suitable for processing by the subsequent stages.

=head2 Pass 2: Collapse

We then march through the token list and collapse certain tokens down to their
smallest possible representation.  I<If> they're still included in the final
results we only want to include them at their shortest.

=over

=item Whitespace

Runs of multiple whitespace characters are reduced down to a single whitespace
character.  If the whitespace contains any "end of line" (EOL) characters, then
the end result is the I<first> EOL character encountered.  Otherwise, the
result is the first whitespace character in the run.

=back

=head2 Pass 3: Pruning

We then go back through the token list and prune and remove unnecessary
tokens.

=over

=item Whitespace

Wherever possible, whitespace is removed; before+after comment blocks, and
before+after various symbols/sigils.

=item Comments

Comments that are either (a) IE conditional compilation comments, or that (b)
contain the word "copyright" in them are preserved.  B<All> other comments
(line and block) are removed.

=item Everything else

We keep everything else; identifiers, quoted literal strings, symbols/sigils,
etc.

=back

=head2 Pass 4: Re-assembly

Lastly, we go back through the token list and re-assemble it all back into a
single JavaScript string, which is then returned back to the caller.

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT

Copyright (C) 2007-, Graham TerMarsch.  All Rights Reserved.

This is free software; you can redistribute it and/or modify it under the same
license as Perl itself.

=head1 SEE ALSO

C<JavaScript::Minifier>.

=cut
