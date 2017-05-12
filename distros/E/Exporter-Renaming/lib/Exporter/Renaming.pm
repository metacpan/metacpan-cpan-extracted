package Exporter::Renaming;

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = 1.19;

my $renaming_on; # are we active?
my $exporter_import; # holds coderef to original Exporter behavior, if defined
my $exporter_to_level; # same for Export::Heavy::heavy_export_to_level

# switch on renaming behavior of Exporter
sub import {
    return if $renaming_on; # never do this twice
    require Exporter;
    require Exporter::Heavy;
    $exporter_import = \ &Exporter::import; # alias for original
    $exporter_to_level = \ &Exporter::Heavy::heavy_export_to_level;
    no warnings 'redefine';
    *Exporter::import = \ &renaming_import; # renaming behavior
    *Exporter::Heavy::heavy_export_to_level = \ &renaming_to_level;
    $renaming_on = 1;
}

# restore Exporter's original behavior
sub unimport {
    return unless $renaming_on;
    no warnings 'redefine';
    *Exporter::import = $exporter_import; # normal behavior
    *Exporter::Heavy::heavy_export_to_level = $exporter_to_level;
    $renaming_on = 0; # allow import again
}

# This is the import routine we supplant into Exporter.  It interprets
# a renaming package, if any, then resumes normal import through
# "goto &$exporter_import".  This is this sub's way of returning
sub renaming_import {
    # be as inconspicious as possible
    goto $exporter_import unless $renaming_on;
    my ($from_module, $key, $renamings, @normal) = @_;
    # check if we are needed at all
    goto $exporter_import unless
        $key and $key eq 'Renaming' and ref $renamings eq 'ARRAY';

    my $to_module = caller;
    process_renaming($from_module, $to_module, $renamings);

    # do any remaining straight imports
    return unless @normal;
    @_ = ($from_module, @normal);
    goto $exporter_import;
}

# replacement for Exporter::Heavy::heavy_export_to_level
sub renaming_to_level {
    goto $exporter_to_level unless $renaming_on;
    my $pkg = shift;
    my $level = shift;
    (undef) = shift;                  # XXX redundant arg
    my $callpkg = caller($level);
    my ($key, $renamings, @normal) = @_;
    return $pkg->export($callpkg, @_) unless
        $key and $key eq 'Renaming' and ref $renamings eq 'ARRAY';
    process_renaming($pkg, $callpkg, $renamings);
    $pkg->export($callpkg, @normal) if @normal;
}

sub process_renaming {
    my ($from, $to, $renamings) = @_;
    my %table;
    # build renaming table, basically as %table = reverse @$renamings,
    # but do error checking and type (sigil) propagation
    croak( "Odd number of renaming elements") if @$renamings % 2;
    while ( @$renamings ) {
        my ( $old_sym, $new_sym) = ( shift @$renamings, shift @$renamings);
        $new_sym ||= $old_sym; # default to straight import
        my ( $old_type, $old_name) = _get_type( $old_sym);
        my ( $new_type, $new_name) = _get_type( $new_sym);
        # check type and name
        croak( "Invalid type character in '$old_sym'") unless
            defined $old_type;
        croak( "Invalid type character in '$new_sym'") unless
            defined $new_type;
        # Check if $new_name is valid ($old_name will be checked by
        # standard Exporter)
        croak( "Invalid name in '$new_sym'") unless
            $new_name =~ /^[A-Za-z_]\w*$/;
        # type propagation
        my $type = $old_type || $new_type || '&';
        $old_type ||= $type;
        $new_type ||= $type;
        croak( "Different types: old '$old_sym', new '$new_sym'") if
            $old_type ne $new_type;
        $new_sym = "$type$new_name";
        $old_sym = "$type$old_name";
        # Check table for multiple entries
        croak( "Multiple renamings to '$new_sym'") if exists $table{ $new_sym};
        $table{ $new_sym} = $old_sym;
    }

    # Jump through Exporter's hoops for all original symbols
    {
        package Exporter::Renaming::Inter; # name space for importing

        # We want Exporter's messages passed on to our user
        our @CARP_NOT = qw(Exporter Exporter::Renaming);
        # "values %table" may list some symbols more than once, but Exporter
        # sorts that out.
        $exporter_import->($from, values %table); # original names
    }

    # If we are here, all imports are ok (under the original names)
    # now alias symbols into user space according to table
    while ( my ( $new, $old) = each %table ) {
        ( my( $type), $new) = _get_type( $new);
        ( undef, $old) = _get_type( $old);
        _sym_alias( $type, "${from}::$old", "${to}::$new");
    }
}

# split off type character
sub _get_type {
    local $_ = shift;
    my ( $type, $name) = /(\W?)(.*)/;
    return if $type and $type !~ /[\$@%&*]/; # reject invalid type chars
    ( $type, $name);
}

# create alias of any type (the only substantial copy of code from Exporter)
sub _sym_alias {
    my ( $type, $old, $new) = @_;
    $type ||= '&';
    no strict 'refs';
    *{$new} =
       $type eq '$' ? \ ${ $old} :
       $type eq '@' ? \ @{ $old} :
       $type eq '%' ? \ %{ $old} :
       $type eq '&' ? \ &{ $old} :
       $type eq '*' ? \ *{ $old} :
       undef;
   ;
}

1;
__END__

=head1 NAME

Exporter::Renaming - Allow renaming of symbols on import

=head1 SYNOPSIS

    # Enable renaming in Exporter
    use Exporter::Renaming;

    # Import File::Find::find as main::search
    use File::Find Renaming => [ find => search];
      
    # Disable renaming
    no Exporter::Renaming

=head1 ABSTRACT

Allow Renaming of symbols on Import

=head1 DESCRIPTION


=head2 Overview

This module adds the ability to rename symbols to the standard Exporter
module.  After C<use Exporter::Renaming>, you can import symbols from
exporting modules not only under their original names, but also under
names of your choosing.

Here, I<symbol> is used to mean anything that could be
exported by a Module, that is, a Perl function or variable.
Thus a symbol begins with an optional I<type character> (one of C<$>, C<@>,
C<%>, C<&>, and C<*>), followed by a name (a Perl identifier, made up of
alphanumerics and C<_>, starting with a non-digit).

To trigger renaming behavior, the import list of a subsequent
C<use E<lt>moduleE<gt>> statement must begin with the keyword 'Renaming',
followed by a list reference, the <renaming list|/Renaming List>, which
describes the renaming imports (see below). After that, a normal import
list may follow, which Exporter processes as usual.

=head2 Renaming List

The renaming list contains I<renaming pairs>, which are pairs of symbols.
The first part of a pair is the original symbol (as known to the exporting
module) and the second one is the renamed symbol (as you want to use it
after import).  It is an error (fatal, as all C<Renaming> or C<Exporter>
errors) if the renaming list has an odd number of elements, or if one of
its symbols is invalid.

If none of the symbols in a I<renaming pair> contains a I<type character>,
an C<&> is assumed.  If only one has a I<type character>, this type is
assumed for the other one too.  If both have type characters, it is an
error if they don't agree.

If the renamed symbol (the second part) of a I<renaming pair> is undefined,
the original symbol is imported unchanged, so you can include normal
imports in a renaming list without retyping the name.

It is an error for a symbol to appear more than once as the second
part of a I<renaming pair>, that is, to specify the same thing twice
as the target of a renaming operation.  It is allowed to import
the same symbol multiple times with different targets.  Maybe it
even makes sense in some situations.

=head2 Operation

Exporter continues to behave normally for normal imports while renaming
behavior is switched on.  Only the presence of the keyword C<Renaming>,
followed by an array reference in the first and second positions
after a C<use> statement triggers renaming.

The renaming behavior of Exporter is thus compatible with its standard
behavior.  If renaming must be switched off for some reason, this can be
done via C<no Export::Renaming>.

If an I<import list> contains both a renaming list and a sequence of normal
import statements, the renaming is done first, as indicated by its
position.  No cross-check is done between the results of renaming and
the normal imports, as if these resulted from two separate C<use> statements.

=head1 EXAMPLES

All examples assume that

    use Exporter::Renaming;

has been called (and that C<no Exporter::Renaming> hasn't).

The most obvious application of C<Exporter::Renaming> is to solve a name
conflict.  Suppose our module already defines a function C<find>, and
we want to use the standard C<File::Find> module.  We could then rename
C<find> from C<File::Find> to C<search> in our own module:

    use File::Find Renaming => [ find => 'search' ];

Let's assume the C<finddepth> function from File::Find doesn't cause a name
conflict, and we want to import it under its original name as well.

This does it in the renaming list:

    use File::Find Renaming => [
        find      => 'search',
        finddepth => undef,
    ];

...as does this, but explicitly:

    use File::Find Renaming => [
        find      => 'search',
        finddepth => 'finddepth',
    ];

...while this uses a regular import:

    use File::Find Renaming => [ find => 'search' ], 'finddepth';

Should you find it annoying that a pedantic module author has chosen to adorn
all of the module's exports with a redundant prefix (these things happen),
you could do this:

    use Mythical::Graphics::Module Renaming => [
          gfxColor => '%color', # this imports a hash
          gfxPen   => 'pen',
          gfxLine  => 'line',
          # ....
          # etc
    ];

...lower-casing the names as well.

If you need to add clarifying prefixes that a sloppy module author has
neglected to provide in the exports (these things happen), you go the
other way around:

    use Legendary::Graphics::Module Renaming [
        Color => '%gfxColor',
        Pen => 'gfxPen',
        Line => 'gfxLine',
        # ...
        # etc
    ];

...also lower-casing the initial letters.

If you are confronted with a standard module that uses a slightly
non-standard naming convention (it happens), you can rectify the
situation:

    use Data::Dumper Renaming => [ Dumper => 'dump' ];

Now you can say C<print dump \ %some_hash> instead of C<print Dumper ...>;

=head1 CAVEATS

=over

=item *

As has been mentioned in section L<Operation|/Operation>, no cross-check
is done between renaming exports and normal exports that go on in the
same C<use> statement.  This means that a renaming import may later
be overwritten by a normal import without a clear indication.
This happens when one of the new names given in renaming coincides
with one of the original ones imported through normal import.

=item *

C<Exporter::Renaming> only affects modules that do standard
exporting, that is, modules that inherit their C<import> method
from Exporter.  Modules that use a different C<import> method are
unaffected and don't understand L<renaming lists|/Renaming Lists>.

=item *

Renaming doesn't affect the name c<caller> sees for a function.  This
should come as no surprise, since normal export doesn't affect this
name either.  It is always the (package-qualified) name the function
was originally compiled with.

=back

=head1 BUGS

=over

=item * 

The lack of a cross-check between renaming and normal imports is
regrettable, but unlikely to be fixed unless Renaming is made part
of Exporter.  Except for the simplest cases, only Exporter can
parse an export list.

=item *

Calls of C<use Exporter::Renaming> and C<no Exporter::Renaming> don't
nest.  Instead of switching unconditionally, C<no Renaming> should
only switch off the behavior if it was off in the corresponding call 
to C<use Exporter::Renaming>.  A future release may address this.

=back

=head1 SEE ALSO

Exporter, Perl

=head1 AUTHOR

Anno Siegel, E<lt>siegel@zrz.tu-berlin.deE<gt>

=head1 ACKNOWLEDGEMENTS

Thanks to Avi Finkel (avi@finkel.org) and Simon Cozens
(simon@simon-cozens.org) for a discussion of this project on IRC.
While brief, their remarks helped me think about things the
right way.

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Anno Siegel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
