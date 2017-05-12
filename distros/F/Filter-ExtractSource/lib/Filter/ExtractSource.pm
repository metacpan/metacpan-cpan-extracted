package Filter::ExtractSource;

use warnings;
use strict;
use Filter::Simple;
use Filter::ExtractSource::CodeObj;

our $VERSION = '0.02';
our $codeobj = Filter::ExtractSource::CodeObj->new;

FILTER {
  s/^(\s*use .*;)/$1\nuse Filter::ExtractSource;/m;
  $codeobj->merge(split /use Filter::ExtractSource;\n/);
};

=head1 NAME

Filter::ExtractSource - captures Perl code after processing by source filters

=head1 SYNOPSIS

 perl -c -MFilter::ExtractSource input.pl >output.pl

Where F<input.pl> contains Perl code which uses source filters,
F<output.pl> will be the code post filtering as passed to the 
Perl parser.

=head1 DESCRIPTION

The concept of source filtering allows developers to alter and 
extend the Perl language with relative ease. One disadvantage 
however, is that some language extensions can break tools which 
attempt to parse Perl code, such as editors which perform syntax 
highlighting.

For example, the code

 use Filter::Indent::HereDoc;
 my $hello = <<EOT;
   Hello, World!
   EOT
 print $hello;

is perfectly valid, but trying to parse it manually (i.e.
without using C<perl>) will fail as the C<EOT> here-document
terminator will not be found.

After processing by Filter::ExtractSource, the code becomes

 use Filter::Indent::HereDoc;
 my $hello = <<EOT;
 Hello, World!
 EOT
 print $hello;

which can now be correctly parsed.

=head1 DEPENDENCIES

Filter::ExtractSource requires the Filter::Simple module to be installed.

=head1 BUGS / ISSUES

Possibly lots.

Filter::ExtractSource has been tested with the Switch.pm and
Filter::Indent::HereDoc source filters with good results. However
in particular it has not been tested (and is unlikely to work) 
with any source filters which perform encryption or obfuscation 
of Perl code.

Any BEGIN blocks, CHECK blocks or use statements will be executed at 
compile-time (i.e. the code will be executed even when the '-c' switch 
is used). Therefore any data sent to the STDOUT stream by these blocks 
will be output before the filtered source code, so in the example above 
the output.pl file may need to be edited. A future release of 
Filter::ExtractSource will support writing the modified source code 
to a file instead of STDOUT to fix this problem.

Please report any bugs or feature requests to
C<bug-filter-extractsource@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>. I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 SEE ALSO

Filter::ExtractSource homepage - L<http://perl.jonallen.info/projects/filter-extractsource>

Filter::Simple - L<http://search.cpan.org/dist/Filter-Simple>

perlfilter manpage - L<http://www.perldoc.com/perl5.8.0/pod/perlfilter.html>

=head1 AUTHOR

Written by Jon Allen (JJ) <jj@jonallen.info> / L<http://perl.jonallen.info>

=head1 COPYRIGHT and LICENCE

Copyright 2004 Jon Allen (JJ), All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Filter::ExtractSource
