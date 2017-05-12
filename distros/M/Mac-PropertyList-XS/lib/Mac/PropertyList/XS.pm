=head1 NAME

Mac::PropertyList::XS - work with Mac plists at a low level, really fast

=cut

package Mac::PropertyList::XS;

=head1 SYNOPSIS

See L<Mac::PropertyList> and L<Mac::PropertyList::SAX>

=head1 DESCRIPTION

L<Mac::PropertyList::SAX> was my first attempt to speed up property-list
parsing. It achieves about a 30x speed boost, but large files still take
too long for my taste. This module addresses some remaining speed gains
by implementing some expensive operations in C.

This module is intended to be a drop-in replacement for
L<Mac::PropertyList::SAX>, which is itself a drop-in replacement for
L<Mac::PropertyList>.

=cut

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

# Passthrough function
use Mac::PropertyList qw(plist_as_string);
use Mac::PropertyList::SAX qw(create_from_ref create_from_hash create_from_array);
use XML::Parser;

use base qw(Exporter);

our @EXPORT_OK = qw(
    parse_plist 
    parse_plist_fh
    parse_plist_file
    parse_plist_string
    plist_as_string
    create_from_ref
    create_from_hash
    create_from_array
);

our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    create => [ qw(create_from_ref create_from_hash create_from_array plist_as_string) ],
    parse  => [ qw(parse_plist parse_plist_fh parse_plist_file parse_plist_string) ],
);

our $VERSION = '0.02';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;  # see L<perlmodstyle>

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Mac::PropertyList::XS::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        # Fixed between 5.005_53 and 5.005_61
#XXX    if ($] >= 5.00561) {
#XXX        *$AUTOLOAD = sub () { $val };
#XXX    }
#XXX    else {
            *$AUTOLOAD = sub { $val };
#XXX    }
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Mac::PropertyList::XS', $XS_VERSION);

=head1 EXPORTS

By default, no functions are exported. Specify individual functions to export
as usual, or use the tags ':all', ':create', and ':parse' for the appropriate
sets of functions (':create' includes the create* functions as well as
plist_as_string; ':parse' includes the parse* functions).

=head1 FUNCTIONS

=over 4

=item parse_plist_file

See L<Mac::PropertyList/parse_plist_file>

=cut

sub parse_plist_file
{
    my $file = shift;

    if (ref $file) {
        _parse(parse => $file);
    } else {
        carp("parse_plist_file: file [$file] does not exist!"), return unless -e $file;
        open my $fh, "<", $file;
        _parse(parse => $fh);
    }
}

sub _parse
{
    my ($how, $what) = @_;
    my $p = new XML::Parser(Handlers => { Init  => \&handle_init,
                                          Start => \&handle_start,
                                          End   => \&handle_end,
                                          Char  => \&handle_char,
                                          Final => \&handle_final });
    return $p->$how($what);
}

=item parse_plist_fh

See L<Mac::PropertyList/parse_plist_fh>

=cut

sub parse_plist_fh { _parse(parse => @_) }

=item parse_plist

See L<Mac::PropertyList/parse_plist>

=cut

sub parse_plist { _parse(parse => @_) }

=item parse_plist_string

An alias to parse_plist, provided for better regularity compared to Perl SAX.

=cut

*parse_plist_string = \&parse_plist;

=item create_from_ref( HASH_REF | ARRAY_REF )

Create a plist from an array or hash reference.

The values of the hash can be simple scalars or references. Hash and array
references are handled recursively, and L<Mac::PropertyList> objects are output
correctly.  All other scalars are treated as strings (use L<Mac::PropertyList>
objects to represent other types of scalars).

Returns a string representing the reference in serialized plist format.

=item create_from_hash( HASH_REF )

Provided for backward compatibility with L<Mac::PropertyList>: aliases
create_from_ref.

=item create_from_array( ARRAY_REF )

Provided for backward compatibility with L<Mac::PropertyList>: aliases
create_from_ref.

=back

=head1 BUGS / CAVEATS

Certainly !

=head1 SUPPORT

Please contact the author with bug reports or feature requests.

=head1 AUTHOR

Darren M. Kulp, C<< <kulp @ cpan.org> >>

=head1 THANKS

brian d foy, who created the L<Mac::PropertyList> module whose tests were
appropriated for this module.

=head1 SEE ALSO

L<Mac::PropertyList>, the inspiration for this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Darren Kulp

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
__END__

# vi: set et ts=4 sw=4: #

