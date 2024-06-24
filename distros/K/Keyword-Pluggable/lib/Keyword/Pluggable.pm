package Keyword::Pluggable;

use v5.14.0;
use warnings;
our %kw;

use Carp qw(croak);

use XSLoader;
BEGIN {
	our $VERSION = '1.05';
	XSLoader::load __PACKAGE__, $VERSION;
}

my %modes = (
	'statement'  => MODE_STATEMENT,
	'expression' => MODE_EXPRESSION,
	'dynamic'    => MODE_DYNAMIC,
);

sub define {
	my %p = @_;
	my ($kw, $sub, $expression, $global, $package) = @p{qw(keyword code expression global package)};
	$kw =~ /^\p{XIDS}\p{XIDC}*\z/ or croak "'$kw' doesn't look like an identifier";
	defined($sub) or croak "'code' is not defined";
	$expression //= 'statement';
	my $sub_is_code = (ref($sub) and
	                   (UNIVERSAL::isa($sub, 'CODE') or
	                    $sub->isa('CODE')));
	$sub_is_code or $expression ne 'dynamic' or croak("expression=dynamic requires a coderef");

	my $xsub = $sub_is_code ? $sub : sub { substr ${$_[0]}, 0, 0, $sub };

	my $entry = [ $xsub,
	              ($modes{$expression} //
	               ($expression? MODE_EXPRESSION: MODE_STATEMENT)) ];

	if ( defined $package) {
		no strict 'refs';
		my $keywords = \%{$package . '::/keywords' };
		$keywords->{$kw} = $entry;
	} elsif ( $global ) {
		define_global($kw, $entry);
	} else {
		my %keywords = %{$^H{+HINTK_KEYWORDS} // {}};
		$keywords{$kw} = $entry;
		$^H{+HINTK_KEYWORDS} = \%keywords;
	}
}

sub undefine {
	my %p = @_;
	my ($kw, $global, $package) = @p{qw(keyword global package)};
	$kw =~ /^\p{XIDS}\p{XIDC}*\z/ or croak "'$kw' doesn't look like an identifier";

	if ( defined $package ) {
		no strict 'refs';
		my $keywords = \%{$package . '::/keywords' };
		delete $keywords->{$kw};
	} elsif ( $global ) {
		undefine_global($kw);
	} else {
		my %keywords = %{$^H{+HINTK_KEYWORDS} // {}};
		delete $keywords{$kw};
		$^H{+HINTK_KEYWORDS} = \%keywords;
	}
}

END { cleanup() }

'ok'

__END__

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

Keyword::Pluggable - define new keywords in pure Perl

=head1 SYNOPSIS

 package Some::Module;

 use Keyword::Pluggable;

 sub import {
     # create keyword 'provided', expand it to 'if' at parse time
     Keyword::Pluggable::define
	 keyword => 'provided',
	 package => scalar(caller),
	 code    => 'if',
     ;
 }

 sub unimport {
    # disable keyword again
    Keyword::Pluggable::undefine keyword => 'provided', package => scalar(caller);
 }

 'ok'

=head1 DESCRIPTION

Warning: This module is still new and experimental. The API may change in
future versions. The code may be buggy. Also, this module is a fork from
C<Keyword::Simple>, that somehow got stalled. If its author accepts pull
requests, then it will probably be best to use it instead.

This module lets you implement new keywords in pure Perl. To do this, you need
to write a module and call
L<C<Keyword::Pluggable::define>|/Keyword::Pluggable::define> in your C<import>
method. Any keywords defined this way will be available in the scope
that's currently being compiled. The scope can be lexical, packaged, and global.

=head2 Functions

=over

=item C<Keyword::Pluggable::define %options>

=over

=item keyword

The keyword is injected in the scope currently being compiled

=item code (string or coderef)

For every occurrence of the keyword, your coderef will be called and its result
will be injected into perl's parse buffer, so perl will continue parsing as if
its contents had been the real source code in the first place. First paramater
to the eventual coderef will be all code textref following the keyword to be replaced,
if examination and change is needed.

=item expression

String value; if C<"statement">, then the injected code will be parsed as a
statement.  If C<"expression">, if will be parsed as an expression.  If
C<"dynamic">, then C<code> must be a coderef rather than a string, returning
a true value to indicate an expression or a false value to indicate a
statement.  (For backward compatibility, a false value for C<expression> is
treated as C<"statement">, and any unrecognized value is treated as
C<"expression">.)

=item global

Boolean flag; if set, then the scope is global, otherwise it is lexical or packaged

=item package

If set, the scope will be limited to that package, otherwise it will be lexical

=back

=item C<Keyword::Pluggable::undefine %options>

Allows options: C<keyword>, C<global>, C<package> (see above).

Disables the keyword in the given scope. You can call this from your
C<unimport> method to make the C<no Foo;> syntax work.

=back

=head1 BUGS AND LIMITATIONS

This module depends on the L<pluggable keyword|perlapi.html/PL_keyword_plugin>
API introduced in perl 5.12. C<parse_> functions were introduced in 5.14.
Older versions of perl are not supported.

Every new keyword is actually a complete statement or an expression by itself. The parsing magic
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
and the rest of the file is unchanged. This also means your it can
only occur at the beginning of a statement, not embedded in an expression.
To be able to do that, use C<< expression => 1 >> flag.

Keywords in the replacement part of a C<s//.../e> substitution aren't handled
correctly and break parsing.

There are barely any tests.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

Dmitry Karasik , C<< <dmitry at karasik.eu.org> >>

=head1 THANKS

Paul Jarc

=head1 COPYRIGHT & LICENSE

Copyright (C) 2012, 2013 Lukas Mai.
Copyright (C) 2018-2024 Dmitry Karasik

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
