package Keyword::Simple;

use v5.12.0;
use warnings;

use Carp qw(croak);
use B::Hooks::EndOfScope;

use XSLoader;
BEGIN {
	our $VERSION = '0.03';
	XSLoader::load __PACKAGE__, $VERSION;
}

# all shall burn
our @meta;

sub define {
	my ($kw, $sub) = @_;
	$kw =~ /^\p{XIDS}\p{XIDC}*\z/ or croak "'$kw' doesn't look like an identifier";
	ref($sub) eq 'CODE' or croak "'$sub' doesn't look like a coderef";

	my $n = @meta;
	push @meta, $sub;

	$^H{+HINTK_KEYWORDS} .= " $kw:$n";
	on_scope_end {
		delete $meta[$n];
	};
}

sub undefine {
	my ($kw) = @_;
	$kw =~ /^\p{XIDS}\p{XIDC}*\z/ or croak "'$kw' doesn't look like an identifier";

	$^H{+HINTK_KEYWORDS} .= " $kw:-";
}

'ok'

__END__

=encoding UTF-8

=head1 NAME

Keyword::Simple - define new keywords in pure Perl

=head1 SYNOPSIS

 package Some::Module;
 
 use Keyword::Simple;
 
 sub import {
     # create keyword 'provided', expand it to 'if' at parse time
     Keyword::Simple::define 'provided', sub {
         my ($ref) = @_;
         substr($$ref, 0, 0) = 'if';  # inject 'if' at beginning of parse buffer
     };
 }
 
 sub unimport {
     # lexically disable keyword again
     Keyword::Simple::undefine 'provided';
 }

 'ok'

=head1 DESCRIPTION

Warning: This module is still new and experimental. The API may change in
future versions. The code may be buggy.

This module lets you implement new keywords in pure Perl. To do this, you need
to write a module and call
L<C<Keyword::Simple::define>|/Keyword::Simple::define> in your C<import>
method. Any keywords defined this way will be available in the lexical scope
that's currently being compiled.

=head2 Functions

=over

=item C<Keyword::Simple::define>

Takes two arguments, the name of a keyword and a coderef. Injects the keyword
in the lexical scope currently being compiled. For every occurrence of the
keyword, your coderef will be called with one argument: A reference to a scalar
holding the rest of the source code (following the keyword).

You can modify this scalar in any way you like and after your coderef returns,
perl will continue parsing from that scalar as if its contents had been the
real source code in the first place.

=item C<Keyword::Simple::undefine>

Takes one argument, the name of a keyword. Disables that keyword in the lexical
scope that's currently being compiled. You can call this from your C<unimport>
method to make the C<no Foo;> syntax work.

=back

=head1 BUGS AND LIMITATIONS

This module depends on the L<pluggable keyword|perlapi.html/PL_keyword_plugin>
API introduced in perl 5.12. Older versions of perl are not supported.

Every new keyword is actually a complete statement by itself. The parsing magic
only happens afterwards. This means that e.g. the code in the L</SYNOPSIS>
actually does this:

  provided ($foo > 2) {
    ...
  }

  # expands to

  ; if
  ($foo > 2) {
    ...
  }

The C<;> represents a no-op statement, the C<if> was injected by the Perl code,
and the rest of the file is unchanged.

This also means your new keywords can only occur at the beginning of a
statement, not embedded in an expression.

There are barely any tests.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012, 2013 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
