package Exporter::Simple;

use 5.008;
use warnings;
use strict;
use Attribute::Handlers;
use base 'Exporter';

our $VERSION = '1.10';
no warnings 'redefine';

sub UNIVERSAL::Exported :ATTR(SCALAR,BEGIN) { export('$', BEGIN => @_) }
sub UNIVERSAL::Exported :ATTR(ARRAY,BEGIN)  { export('@', BEGIN => @_) }
sub UNIVERSAL::Exported :ATTR(HASH,BEGIN)   { export('%', BEGIN => @_) }
sub UNIVERSAL::Exported :ATTR(CODE,BEGIN,CHECK) { export('', INIT => @_)  }

sub UNIVERSAL::Exportable :ATTR(SCALAR,BEGIN) { exportable('$', BEGIN => @_) }
sub UNIVERSAL::Exportable :ATTR(ARRAY,BEGIN)  { exportable('@', BEGIN => @_) }
sub UNIVERSAL::Exportable :ATTR(HASH,BEGIN)   { exportable('%', BEGIN => @_) }
sub UNIVERSAL::Exportable :ATTR(CODE,BEGIN,CHECK) { exportable('', INIT => @_) }

# Build a structure in which we remember what to export when (in
# which phase, BEGIN or INIT) to whom. Scalars, arrays and hashes are exported
# during BEGIN, but subroutines need to be exported during CHECK, because
# their names aren't known during BEGIN (they're 'ANON' in this phase). But
# because of a bug in Attribute::Handlers, we can't just declare
# :ATTR(CODE,CHECK), because that would make the handlers for scalars, arrays
# and hashes run during CHECK as well, even though they were declared as
# :ATTR(...,BEGIN). But each handler specifies in the call to export() or
# exportable() which phase the symbol is to be exported in.
#
# The structure is %EXPORTDEF and is built when the attribute handlers run,
# and consulted during do_export(), which is called both from import() and
# INIT(), see below.
#
# An example structure is shown here and is built by declaring the following
# exports in a module that subclasses Exporter::Simple:
#
# our @bar : Exportable(vars) = (2, 3, 5, 7);
# our $foo : Exported(vars)   = 42;
# our %baz : Exported         = (a => 65, b => 66);
#
# sub hello : Exported(greet,uk)   { "hello there" }
# sub askme : Exportable           { "what you will" }
# sub hi    : Exportable(greet,us) { "hi there" }
#
# sub get_foo : Exported(vars) { $foo }
# sub get_bar : Exportable(vars) { @bar }
# 
# results in:
#
# %EXPORTDEF = 
# --- #YAML:1.0
# BEGIN:
#   MyExport:
#     EXPORT:
#       - '$foo'
#       - '%baz'
#     EXPORT_OK:
#       - '@bar'
#     EXPORT_TAGS:
#       all:
#         - '@bar'
#         - '$foo'
#         - '%baz'
#       greet: []
#       uk: []
#       us: []
#       vars:
#         - '@bar'
#         - '$foo'
# INIT:
#   MyExport:
#     EXPORT:
#       - hello
#       - get_foo
#     EXPORT_OK:
#       - askme
#       - hi
#       - get_bar
#     EXPORT_TAGS:
#       all:
#         - hello
#         - askme
#         - hi
#         - get_foo
#         - get_bar
#       greet:
#         - hello
#         - hi
#       uk:
#         - hello
#       us:
#         - hi
#       vars:
#         - get_foo
#         - get_bar

sub add {
	my ($arrname, $sigil, $exp_phase, $pkg, $symbol, $ref, $attr, $tags) = @_;
	$symbol = *{$symbol}{NAME} if ref $symbol;
	$symbol = "$sigil$symbol";
	$tags = [ $tags || () ] unless ref $tags eq 'ARRAY';

    our %EXPORTDEF;

    if ($symbol eq 'ANON') {

# see the empty arrays in keys 'greet', 'uk' and 'us' in the above
# sample of $EXPORT{BEGIN}{MyExport}{EXPORT_TAGS} ? They need to be
# there because these tags are only defined by subroutines (hello()
# and hi(); see sample code above), and hence they would appear in
# %EXPORTDEF only during CHECK, but the tag ':greet' still gets passed
# to Exporter::import() during BEGIN (which is necessary because some
# scalars, arrays and hashes *could* still have used these tags in
# their attribute declarations). Therefore, when we handle a subroutine
# attribute during BEGIN (recognized by the symbol name being 'ANON'),
# we make empty entries for the tags in %EXPORTDEF. Now Exporter is
# happy and the tests are happy and we are all happy.

        $EXPORTDEF{BEGIN}{$pkg}{EXPORT_TAGS}{$_} ||= [] for @$tags, 'all';

# we'll see the sub again during CHECK, to be exported during INIT, so:

        return;
    }

    push @{ $EXPORTDEF{$exp_phase}{$pkg}{$arrname} } => $symbol unless
        grep { $_ eq $symbol } @{ $EXPORTDEF{$exp_phase}{$pkg}{$arrname} };

    for my $tag (@$tags, 'all') {
        push @{ $EXPORTDEF{$exp_phase}{$pkg}{EXPORT_TAGS}{$tag} } => $symbol
            unless grep { $_ eq $symbol }
                @{ $EXPORTDEF{$exp_phase}{$pkg}{EXPORT_TAGS}{$tag} };
    }
}

sub export     { add(EXPORT    => @_) }
sub exportable { add(EXPORT_OK => @_) }

# import() could be called several times, from different packages
# who want to import symbols from us. So we remember who gets to
# import what in which phase. Scalars, arrays and hashes are imported
# during BEGIN (that's why import() also calls do_export('BEGIN') at
# the end, while subroutines are exported during INIT. Tags, starting
# with a colon, need to be seen both during BEGIN and END.

sub import {
    my $pkg = shift;
    our %wants_import;

    for (@_) {
        if (/^:/) {
            push @{ $wants_import{BEGIN}{$pkg} } => $_;
            push @{ $wants_import{INIT}{$pkg} } => $_;
        } elsif (/^[\$\@%]/) {
            push @{ $wants_import{BEGIN}{$pkg} } => $_;
        } else {
            push @{ $wants_import{INIT}{$pkg} } => $_;
        }
    }

    do_export('BEGIN');
}

sub do_export {
    my $phase = shift;
    our (%EXPORTDEF, %wants_import);

    while (my ($pkg, $def) = each %{ $EXPORTDEF{$phase} }) {
        no strict 'refs';

# remove export cache; without this, we can't export in both BEGIN
# and INIT phases

        undef %{ "$pkg\::EXPORT" };

# build the variables Exporter requires to do its work and ask it to export
# the symbols we remembered during import().

        @{ "$pkg\::EXPORT" }      = @{ $def->{EXPORT} || [] };
        @{ "$pkg\::EXPORT_OK" }   = @{ $def->{EXPORT_OK}  || [] };
        %{ "$pkg\::EXPORT_TAGS" } = %{ $def->{EXPORT_TAGS} || {} };

        local $Exporter::ExportLevel = 2;
        Exporter::import($pkg => @{ $wants_import{$phase}{$pkg} || [] });
    }
}

INIT { do_export('INIT') }

1;

__END__

=head1 NAME

Exporter::Simple - Easier set-up of module exports

=head1 SYNOPSIS

  package MyExport;
  use base 'Exporter::Simple';

  our @bar : Exportable(vars) = (2, 3, 5, 7);
  our $foo : Exported(vars)   = 42;
  our %baz : Exported         = (a => 65, b => 66);

  sub hello : Exported(greet,uk)   { "hello there" }
  sub askme : Exportable           { "what you will" }
  sub hi    : Exportable(greet,us) { "hi there" }

  # meanwhile, in a module far, far away
  use MyExport qw(:greet);
  print hello();
  $baz{c} = 67;

=head1 DESCRIPTION

This module, when subclassed by a package, allows that package to define
exports in a more concise way than using C<Exporter>. Instead of having to
worry what goes in C<@EXPORT>, C<@EXPORT_OK> and C<%EXPORT_TAGS>, you can
use two attributes to define exporter behavior. This has two advantages:
It frees you from the implementation details of C<Exporter>, and it
keeps the export definitions where they belong, with the subroutines
and variables.

The attributes provided by this module are:

=over 4

=item C<Exported>

Indicates that the associated subroutine or global variable should
be automatically exported. It will also go into the C<:all> tag
(per the rules of C<%EXPORT_TAGS>), as well as any tags you specify
as options of this attribute.

For example, the following declaration

  sub hello : Exported(greet,uk)   { ... }

will cause C<hello()> to be exported, but also be available in the
tags C<:all>, C<:greet> and C<:uk>.

=item C<Exportable>

Is like C<Exported>, except that the associated subroutine or
global variable won't be automatically exported.  It will still
go to the C<:all> tag in any case and all other tags specified as
attribute options.

=back

=head1 BUGS

If you find any bugs or oddities, please do inform the author.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 VERSION

This document describes version 1.10 of C<Exporter::Simple>.

=head1 AUTHOR

Marcel GrE<uuml>nauer <marcel@cpan.org>

=head1 CONTRIBUTORS

Damian Conway <damian@conway.org>

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2001-2002 Marcel GrE<uuml>nauer. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Attribute::Handlers(3pm), Exporter(3pm).

=cut
