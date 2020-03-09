package Devel::CompileLevel;
use strict;
use warnings;
no warnings 'once';

our $VERSION = '0.001004';
$VERSION =~ tr/_//d;

use Exporter (); BEGIN { *import = \&Exporter::import }
BEGIN {
  *_WARNING_BITS_CHECK = "$]" <= 5.030001 ? sub(){1} : sub(){0};
}

our @EXPORT_OK = qw(
  compile_level
  compile_caller
);

sub compile_level () {
  no warnings;
  if (_WARNING_BITS_CHECK) {
    local ${^WARNING_BITS} = $warnings::NONE;
    my $level = 0;
    while (my @caller = caller(++$level)) {
      my $hints = $caller[9];
      next
        if $hints ne ${^WARNING_BITS};
      ${^WARNING_BITS} ^= "\x01";
      my $newhints = (caller($level))[9];
      if ($newhints ne $hints) {
        return $level - 1;
      }
    }
  }
  else {
    my $level = 0;
    while (my @caller = caller(++$level)) {
      return $level - 1
        if $caller[3] =~ /::BEGIN\z/;
    }
  }
  return undef;
}

sub compile_caller () {
  my $level = compile_level;
  return
    unless defined $level;

  if (caller eq 'DB') {
    package
      DB;
    caller($level - 1);
  }
  else {
    caller($level - 1);
  }
}

1;

__END__

=head1 NAME

Devel::CompileLevel - Detect caller level of compiling code

=head1 SYNOPSIS

  package ExportToCompile;
  use strict;
  use warnings;
  use Devel::CompileLevel qw(compile_caller);

  sub import {
    my $target = compile_caller or die "not compiling!";
    strict->import;
    warnings->import;
    no strict 'refs';
    # will export to same level as strict/warnings are applied to
    *{"${target}::exported_sub"} = sub { ... };
  }

=head1 DESCRIPTION

Detects the caller level where compilation is being performed.  When applying
pragmas in an import sub, they will be applied to the currently compiling scope.
Some modules may want to both apply a pragma, and export functions.  This
requires knowing the package in that scope.  It's usually possible to track this
manually, but that won't always be accurate.

This module can provide the caller level where compilation is happening,
allowing you to always find the correct package.

=head1 FUNCTIONS

=head2 compile_level ()

Returns the distance to the code being compiled.  This will start at 0 in a
BEGIN block and increase for each sub call away.  In an import sub, it will be
1 rather than the 0 that would normally be used with caller to find the caller's
information.  You must subtract 1 from this value to use it with caller.

=head2 compile_caller ()

Returns the caller information of the compiling code.  This will give all the
same information as the normal L<caller() builtin|perlfunc/caller>.

=head1 SEE ALSO

=over 4

=item * L<Import::Into>

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head1 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2015 the Devel::CompileLevel L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
