# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Mail::Alias::Reader;

use strict;
use warnings;

use Mail::Alias::Reader::Parser ();

use Carp;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    $VERSION = '0.06';
    @ISA     = qw(Exporter);

    @EXPORT      = ();
    @EXPORT_OK   = ();
    %EXPORT_TAGS = ();
}

=head1 NAME

Mail::Alias::Reader - Read aliases(5) and ~/.forward declarations

=head1 SYNOPSIS

    my $reader = Mail::Alias::Reader->open(
        'handle' => \*STDIN,
        'mode'   => 'aliases'
    );

    while (my ($name, $destinations) = $reader->read) {
        my @addresses = grep { $_->is_address } @{$destinations};

        print "$name: " . join(', ', map { $_->to_string } @addresses) . "\n";
    }

    $reader->close;

=head1 DESCRIPTION

Mail::Alias::Reader is a small but oddly flexible module that facilitates the
reading of aliases(5)-style mail alias and ~/.forward declarations.  It does
not directly provide support for the writing and in-memory manipulation of
these files as a whole, however its limited feature set may be considered to
be a virtue.

The module can read mail aliases or ~/.forward declarations from a file, or
from an arbitrary file handle, as specified at the time of file reader
instantiation.  The destination objects returned are the same parser tokens
used internally, keeping code footprint low without being too much of a hassle.

=head1 STARTING UP THE MODULE

=over

=item Mail::Alias::Reader->open(%opts)

Open a file (C<file>) or stream (C<handle>) based on the values provided in
C<%opts>, returning a mail alias reader as a result.  A parsing C<mode> can be
supplied; by default, I<aliases> are expected, whereas a C<mode> of I<forward>
can be specified as well.

=back

=cut

sub open {
    my ( $class, %opts ) = @_;

    #
    # If no parsing mode is specified, then assume a default of 'aliases',
    # for aliases(5) mode parsing.  Otherwise, a value of 'forward' can be
    # passed, suitable for parsing ~/.forward declarations.
    #
    $opts{'mode'} ||= 'aliases';

    confess('Unknown parsing mode') unless $opts{'mode'} =~ /^aliases|forward$/;

    my $fh;

    if ( defined $opts{'file'} ) {
        open( $fh, '<', $opts{'file'} ) or confess("Unable to open aliases file $opts{'file'}: $!");
    }
    elsif ( defined $opts{'handle'} ) {
        $fh = $opts{'handle'};
    }
    else {
        confess('No file or file handle specified');
    }

    return bless {
        'mode'   => $opts{'mode'},
        'handle' => $fh
    }, $class;
}

=head1 READING DECLARATIONS

=over

=item $reader->read()

Seeks the current file stream for the next available declaration, and passes it
through the parser, returning the data given by the parser, without any further
manipulation.

Depending on the parsing mode, the nature of the returned data will differ.
Each of the following modes will cause C<$reader-E<gt>read()> to operate in the
following manners:

=over

=item C<aliases>

When Mail::Alias::Reader is set to read in C<aliases> mode, a plain scalar
value reflecting the name of the alias, followed by an C<ARRAY> reference
containing mail destinations, is returned, in list context.

    my ($name, $destinations) = $reader->read;

=item C<forward>

    my $destinations = $reader->read;

When Mail::Alias::Reader is set to read in C<forward> mode, an C<ARRAY>
reference containing mail destinations is returned in a single scalar.

=back

=back

=head1 THE MAIL DESTINATION TOKEN

Mail destination objects returned by C<$reader-E<gt>read()> are C<HASH> objects
bless()ed into the Mail::Alias::Reader::Token package, and contain a small
handful of data attributes, but can be inspected with a variety of helper
functions in the form of instance methods.  Please see the
L<Mail::Alias::Reader::Token> documentation for a listing of these helper
functions.

The mail destination attributes include:

=over

=item C<type>

The type of token dealt with.  This can be one of I<T_ADDRESS>, I<T_COMMAND>,
I<T_FILE>, or I<T_DIRECTIVE>.

=over

=item I<T_ADDRESS>

A mail destination token of type I<T_ADDRESS> may indicate either a full mail
address, or a local part.

=item I<T_COMMAND>

A destination token of type I<T_COMMAND> indicates that mail destined for the
current alias is to be pipe()d to the specified command.

=item I<T_FILE>

Any mail destined for the current alias will be appended to the file indicated
by this destination token.

=item I<T_DIRECTIVE>

Indicates any special destination in the format of C<:directive:I<argument>>.
These are of course specific to the system's configured mail transfer agent.
In this case, the name of the directive is captured in the token object's
C<name> attribute.

=back

=item C<value>

The textual value of the mail destination, parsed, cleansed of escape sequences
that may have been present in the source file, containing only the data that
is uniquely specified by the type of mail destination token given.  As an
example, I<T_COMMAND> destinations do not include the pipe ('|') symbol as a
prefix; this is implied in the destination token type, rather.

=item C<name>

Only appears in the prsence of a token typed I<T_DIRECTIVE>  When a mail alias
destination in the form of C<:directive:I<argument>> is parsed, this contains
the name of the 'C<directive>' portion.  Of course, the value in the
'I<argument>' portion is contained in the token's C<value> field, but is
considered optional, especially in the presence of a directive such as C<:fail>.

=back

=cut

sub read {
    my ($self) = @_;

    while ( my $line = readline( $self->{'handle'} ) ) {
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next unless $line;
        next if $line =~ /^(#|$)/;

        return Mail::Alias::Reader::Parser->parse( $line, $self->{'mode'} );
    }

    return;
}

=head1 CLOSING THE STREAM

=over

=item $reader->close()

Close the current file stream.  Any subsequent C<$reader-E<gt>read()> calls will
return nothing.

=cut

sub close {
    close shift->{'handle'};
}

=back

=cut

1;

__END__

=head1 ERROR HANDLING

Carp::confess() is used internally for passing any error conditions detected
during the runtime of this module.

=head1 AUTHOR

Written and maintained by Erin Schoenhals <erin@cpanel.net>.

=head1 COPYRIGHT

Copyright (c) 2012, cPanel, Inc.
All rights reserved.
http://cpanel.net/

This is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.  See the LICENSE file for further details.
