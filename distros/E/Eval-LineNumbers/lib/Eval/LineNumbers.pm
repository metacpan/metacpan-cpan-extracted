package Eval::LineNumbers;

use warnings;
use strict;

use Exporter 5.57 'import';
our @EXPORT_OK = qw(eval_line_numbers eval_line_numbers_offset);

# ABSTRACT: Add line numbers to heredoc blocks that contain perl source code
our $VERSION = '0.35'; # VERSION

my %offset;

sub eval_line_numbers_offset
{
  my(undef, $file) = caller;
  $offset{$file} = shift;
}

sub eval_line_numbers
{
  my(undef, $file, $line) = caller(
    # Optional first arg is the caller level
    $_[0] =~ /^[0-9]+$/ ? (shift) : 0
  );
  if(defined $offset{$file}) {
    $line += $offset{$file};
  } else {
    $line++;
  }
  return join('', qq{#line $line "$file"\n}, @_)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Eval::LineNumbers - Add line numbers to heredoc blocks that contain perl source code

=head1 VERSION

version 0.35

=head1 SYNOPSIS

 use Eval::LineNumbers qw(eval_line_numbers);

 eval eval_line_numbers(<<END_HEREIS);
   code
 END_HEREIS

 eval eval_line_numbers($caller_level, $code)

=head1 DESCRIPTION

Add a C<#line "this-file" 392> comment to heredoc/hereis text that is going
to be eval'ed so that error messages will point back to the right place.

Please note: when you embed C<\n> in your code, it gets expanded in
double-quote hereis documents so it will mess up your line numbering.
Use C<\\n> instead when you can.

=head2 Caller Level Example

The second form of eval_line_numbers where a caller-level is provided
is for the situation where the code is generated in one place and 
eval'ed in another place.  The caller level should be the number of
stack levels between where the heredoc was created and where it is
eval'ed.

 sub example {
   return <<END_HEREIS
     code
END_HEREIS
 }

 eval eval_line_numbers(1, example())

=head1 FUNCTIONS

All functions are exportable on request, but not by default.

=head2 eval_line_numbers

 eval eval_line_numbers($code);
 eval eval_line_numbers($caller_level, $code);

=head2 eval_line_numbers_offset

 eval_line_numbers_offset $offset;

Sets the offset, which is by default 1.  The offset is file scoped.  This
is useful if you want to pass a string without a heredoc.  For example:

 eval_line_numbers_offset 0;
 eval eval_line_numbers q{
   die "here";
 };

=head1 AUTHOR

Original author: David Muir Sharnoff

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Olivier Mengué (DOLMEN)

David Steinbrunner (dsteinbrunner)

Alexey Ugnichev (thaewrapt)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009-2021 by David Muir Sharnoff.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
