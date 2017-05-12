#===============================================================================
#
#         FILE:  Games::Go::AGA::Parse::Register.pm
#
#      PODNAME:  Games::Go::AGA::Parse::Register
#     ABSTRACT:  models AGA register.tde file information
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::Parse::Register;
use parent 'Games::Go::AGA::Parse';

use Carp;
use Readonly;
use Scalar::Util qw( looks_like_number );
use String::Tokenizer;
use Games::Go::AGA::Parse::Util qw( is_ID is_Rating is_Rank_or_Rating normalize_ID );
use Games::Go::AGA::Parse::Exceptions;

our $VERSION = '0.042'; # VERSION

sub last_name {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{last_name} = $new;
    }
    return $self->{last_name} || '';
}

sub first_name {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{first_name} = $new;
    }
    return $self->{first_name} || '';
}

sub id {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{id} = $new;
    }
    return $self->{id} || '';
}

sub rank {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{rank} = $new;
        $self->{rank} += 0 if (is_Rating($new));   # numify
    }
    return $self->{rank} || '';
}

sub flags {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{flags} = $new;
    }
    return $self->{flags} || [];
}

sub club {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{club} = $new;
    }
    return $self->{club} || '';
}

sub comment {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{comment} = $new;
    }
    return $self->{comment} || '';
}

sub directive {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{directive} = $new;
    }
    return $self->{directive} || '';
}

sub value {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{value} = $new;
    }
    return defined $self->{value} ? $self->{value} : '';
}

sub as_array {
    my ($self, $new) = @_;

    my @ret;
    if ($self->id) {
        @ret = map
            { $self->$_ }
            # fields, in order
            qw(
                id
                last_name
                first_name
                rank
                flags
                club
                comment
        );
    }
    elsif ($self->directive) {
        @ret = ($self->directive, $self->value);
    }
    else {
        @ret = ($self->comment);
    }
    return wantarray ? @ret : \@ret;
}

sub as_hash {
    my ($self, $new) = @_;

    my %ret;
    if ($self->id) {
        %ret = map
            { $_, $self->$_ }
            # fields, in order
            qw(
                id
                last_name
                first_name
                rank
                flags
                club
                comment
        );
    }
    elsif ($self->directive) {
        %ret = (
            directive => $self->directive,
            value     => $self->value,
        );
    }
    else {
        %ret = (
            comment => $self->comment,
        );
    }
    return wantarray ? %ret : \%ret;
}


Readonly my $ID         => 0;
Readonly my $LAST_NAME  => 1;
Readonly my $FIRST_NAME => 2;
Readonly my $FLAGS      => 3;

Readonly my %name_of_state => (
    $ID         => 'ID',
    $LAST_NAME  => 'LAST_NAME',
    $FIRST_NAME => 'FIRST_NAME',
    $FLAGS      => 'FLAGS',
);

Readonly my %state_functions => (
    $ID         => \&_get_id,
    $LAST_NAME  => \&_get_last_name,
    $FIRST_NAME => \&_get_first_name,
    $FLAGS      => \&_get_flags,
);

*parse = \&parse_line;  # alias parse to parse_line
sub parse_line {
    my ($self, $string) = @_;

    # initialize
    $self->{source} = $string;
    map { delete $self->{$_} } qw(
        id
        last_name
        first_name
        rank
        flags
        club
        comment
        directive
        value
        comment
    );               # empty arrays

    return $self->as_hash if (not $string);

    my $tokenizer = String::Tokenizer->new(
                $string,                                # source string
                #"~!@#\$\%^&*()`={}[]:;\"'<>,?/|\\\n",   # delimiters (doesn't include +-.)
                "#,=\n",
                String::Tokenizer->RETAIN_WHITESPACE,
                );
    my $iter = $tokenizer->iterator;

    my $state = $ID;                # assume we will see ID first

    TOKEN:
    while ($iter->hasNextToken) {
        my $token = $iter->nextToken;
# warn "state $name_of_state{$state}:  token=<$token>\n";

        if ($token eq "\n") {           # a carriage return
            last TOKEN;
        }
        elsif ($token !~ m/\S/ or       # only whitespace
               $token eq '') {          # empty
            next TOKEN;
        }
        elsif ($token eq '#') {             # comment
            my @remainder;
            push (@remainder, $iter->nextToken) while $iter->hasNextToken;
            $token = join('', @remainder);
            $state = $self->_get_comment($token);
            last TOKEN;
        }
        elsif (exists $state_functions{$state}) {
            $state = $state_functions{$state}($self, $token);
            next TOKEN;
        }
        else {
            $self->_parse_error(
                error => "Unknown state: $state",
                source => $token,
                );
        }
    }
    if (exists $self->{id}) {
        $self->{last_name}  = join(' ', @{$self->{last_name}} ) if exists $self->{last_name};
        $self->{first_name} = join(' ', @{$self->{first_name}}) if exists $self->{first_name};
        my @missing = grep
            { not $self->{$_} }
            ( qw( id last_name rank ) );
        if (@missing) {
            $self->_parse_error(
                error  => "missing: @missing",
                source => $string,
                );
        }

        # transfer dropN from comment to flags
        if (exists $self->{comment}) {
            while ($self->{comment} =~ s/\b(drop\d+)\s*//) {
                push @{$self->{flags}}, $1;
            }
        }
    }
    return $self->as_hash;
}

sub _get_id {
    my ($self, $token) = @_;

    my $id = normalize_ID($token);
    if (not is_ID($id)) {
        $self->_parse_error(
            error  => "<$token> is not a valid AGA ID",
            source => $self->{source},
            );
    }
    $self->{id} = $id;
    return $LAST_NAME;        # next state
}

sub _get_last_name {
    my ($self, $token) = @_;

    if ($token eq ',') {
        if (exists $self->{last_name}) {
            return $FIRST_NAME;
        } else {
            $self->_parse_error(
                error  => 'missing ID or last name before comma',
                source => $self->{source},
                );
        }
    }
    if (is_Rank_or_Rating($token)) {
        $self->rank(uc $token);
        return $FLAGS;          # either flag or trailing comments is next
    }
    push(@{$self->{last_name}}, $token);
    return $LAST_NAME;
}

sub _get_first_name {
    my ($self, $token) = @_;

    if (is_Rank_or_Rating($token)) {
        $self->rank(uc $token);
        return $FLAGS;          # either flag or trailing comments is next
    }
    push(@{$self->{first_name}}, $token);
    return $FIRST_NAME;
}

sub _get_flags {
    my ($self, $token) = @_;

    my $flags_ref = $self->{flags};
    if ($flags_ref and
        @{$flags_ref} and
        ($flags_ref->[-1] eq '=')) {  # last entry was '='

        # Flags formed like Bar = Foo got turned into
        #    three seperate tokens: 'Bar', '=', and 'Foo'.
        #    Combine them into one array element here, and upper-case the
        #    key (i.e: BAR)

        pop @{$flags_ref};                  # remove equals sign
        my $key = uc(pop(@{$flags_ref}));   # remove key and upper-case it
        if ($key eq 'CLUB') {
            $self->{club} = $token;       # turn CLUB= flags into the club
        }
        else {
            # concatenate with equal sign and current token
            push @{$flags_ref}, "$key=$token";
        }
    }
    else {
        push( @{$self->{flags}}, $token );
    }
    return $FLAGS;
}

# $token is the rest of the line following the #
sub _get_comment {
    my ($self, $token) = @_;

    if ($token =~ m/\A#\s*(\w+)\s*(.*)/) {
        # lines starting with ## are directives
        $self->{directive} = $1;
        $self->{value}     = $2;
        $self->{value} =~ s/\s*$//; # trim trailing whitespace
    }
    else {
        $self->{comment} = $token;
        $self->{comment} =~ s/\s*$//; # trim trailing whitespace
    }
    return $ID;           # comments go to end of line, wrap back to start
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::Parse::Register - models AGA register.tde file information

=head1 VERSION

version 0.042

=head1 SYNOPSIS

  use Games::Go::AGA::Parse::Register;
  my $parser = Games::Go::AGA::Parse::Register->new;

  $parser->parse_line('line from register.tde file'); # parse a line

=head1 DESCRIPTION

Games::Go::AGA::Parse::Register parses single lines from an AGA
register.tde format file and returns a reference to a hash representing the
contents of the line.

register.tde files contain the tournemant registration information for an
American Go Association (AGA) go tournament.  There are three types of line
that can occur in a register file: directives, comments, and player
information:

    ## directive
    # comment
    id last name, first name  rank  CLUB=club DROP # comment

Directives are global configuration for the tournament, and include such
things as TOURNEY (the tournament name), RULES (e.g. Ing or AGA), etc.

Comments may contain any text which is ignored.

Player information lines contain the registration information.

=head1 METHODS

=over

=item my $parser = Games::Go::AGA::Parse::Register->new;

Creates a new parser object.

=item my $parser = $parser->filename( ['new_name'])

Get/set a filename (used in error messages)

=item my $file_handle = $parser->filename( [$new_file_handle ])

Get/set a file handle (used in error messages)

=item my $hash_ref = $parser->parse_line('line');

B<line> is a line of text from a register.tde format file.

The return value is the same as returned by B<$parser-E<gt>as_hash>

=item %as_hash = $parser->as_hash()

Retuns the parsed line as a hash.  Missing fields will be empty strings
('').

There are three 'flavors' of hash depending on which of the three types of
line is parsed:

=over

=item Directives

A directives line is a 'key/value' pair and is returned as:

    (
        directive    => 'directive name'
        value        => 'directive value'
    )

=item Comments

A comment line is returned as:

    (
        comment      => 'the comment'
    )

=item Player

A player line is returned as:

    (
        id          => 'unique identifier'  # AGA ID or temporary ID
        last_name   => 'last name'          # may contain spaces
        first_name  => 'first name'         # may contain spaces
        rank        => 'rank or rating'     # either a rank or a rating
        flags       => [flag1, ...]         # ref to array of flags (DROP,
                                            #    DROPn, BYE, BAR=Foo, etc)
        club        => 'club'               # a CLUB=XYZ flag is turned into this
        comment     => 'comment field'      # player comment
    )

B<id> is single token, unique per player (usually the AGA ID).

From after the ID to the first comma (',') is the player's B<last_name>.

From after the comma to the rank is the B<first_name>.

If no comma is found, the B<first_name> field is not defined.

B<rank> may be either a dan/kuy rank or an AGA numeric rating.  If it is a
rank, it is an integer followed by either D, or K (for dan or kyu).  If it
is a rating, it is a decimal number between 20 and -99 excluding the range
from .9999 to -.9999.  Positive numbers represent dan and negative
represent kyu.  The convention is that decimal numbers (ratings) represent
a more reliable value than the D/K representation.

B<flags> formed with an equals sign (e.g. Bar=Foo) are returned as a
single array element, and the key is upper-cased ('Bar' is changed to
'BAR' in this example).

DROPn flags refer to specific rounds (n).

For historical reasons, DROPn may be found in the comment section.  If so,
they are removed from the comment and added to the flags.

Note that the 'Club=' flag is handled differently: it is removed from the
B<flags> list and the club name is instead loaded into the B<club>
field.

B<flags> may be a reference to an empty array.   B<comments> may be an
empty string.

=back

In scalar context, returns a reference to the hash.

=item @as_array = $parser->as_array()

Retuns the parsed line as an array.  Missing fields will be empty strings
('').  The order is the same as listed above for B<as_hash>.

In scalar context, returns a reference to the array.

=item $field_by_name = $parser-> < name >

Individual fields may be set or retrieved by name.  E.g:

    $last_name = $parser->last_name
     . . .
    $parser->rank('4d');

=back

=head1 OPTIONS

Options to the B<-E<gt>new> method are:

=over

=item filename => 'file name'

=item handle   => $file_handle

=back

These are not required to create a parser, but if supplied, error
exceptions will include more useful information.

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
