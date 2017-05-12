#===============================================================================
#
#         FILE:  Games::Go::AGA::Parse::TDList.pm
#
#      PODNAME:  Games::Go::AGA::Parse::TDList
#     ABSTRACT:  Parses lines from an AGA TDLISTlist
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      CREATED:  Tue Jan 18 16:12:35 PST 2011
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::Parse::TDList;
use parent 'Games::Go::AGA::Parse';

use Carp;
use Readonly;
use String::Tokenizer;
use Scalar::Util qw( looks_like_number );
use Games::Go::AGA::Parse::Util qw( is_Rating is_Rank_or_Rating normalize_ID  );
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

sub membership {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{membership} = $new;
    }
    return $self->{membership} || '';
}

sub rank {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{rank} = $new;
        $self->{rank} += 0 if (is_Rating($new));   # numify
    }
    return $self->{rank} || '';
}

sub date {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{date} = $new;
    }
    return $self->{date} || '';
}

sub club {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{club} = $new;
    }
    return $self->{club} || '';
}

sub state {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{state} = $new;
    }
    return $self->{state} || '';
}

sub extra {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{extra} = $new;
    }
    return $self->{extra} || '';
}

sub as_array {
    my ($self, $new) = @_;

    my @ret = map
        { $self->$_ }
        # fields, in order
        qw(
            last_name
            first_name
            id
            membership
            rank
            date
            club
            state
            extra
    );
    return wantarray ? @ret : \@ret;
}

sub as_hash {
    my ($self, $new) = @_;

    my %ret = map
        { $_, $self->$_ }
        # fields
        qw(
            last_name
            first_name
            id
            membership
            rank
            date
            club
            state
            extra
    );
    return wantarray ? %ret : \%ret;
}

Readonly my $LAST_NAME  => 0;
Readonly my $FIRST_NAME => 1;
Readonly my $ID         => 2;
Readonly my $MEMBERSHIP => 3;
Readonly my $RANK       => 4;
Readonly my $DATE       => 5;
Readonly my $CLUB       => 6;
Readonly my $STATE      => 7;
Readonly my $EXTRA      => 8;

Readonly my %name_of_state => (
    $FIRST_NAME => 'first_name',
    $ID         => 'id',
    $MEMBERSHIP => 'membership',
    $RANK       => 'rank',
    $DATE       => 'date',
    $CLUB       => 'club',
    $STATE      => 'state',
    $EXTRA      => 'extra',
);

Readonly my %MEMBERSHIP_TYPES => (
    Full  => 1,
    Youth => 1,
    Limit => 1,
    Non   => 1,
    Sust  => 1,
    Spons => 1,
    Forgn => 1,
    Comp  => 1,
    Life  => 1,
    Donar => 1,
);

Readonly my %state_functions => (
    $LAST_NAME => sub {
        my ($self, $token) = @_;

        if ($token eq ',') {
            return $FIRST_NAME;
        }
        if ($token =~ m/^\w*\d+$/ and    # IDs are numbers with possible alpha prefix
            @{$self->{last_name}}) {  # but only if we already have a name
            $self->{id} = $token;
            return $MEMBERSHIP;
        }
        push @{$self->{last_name}}, $token;
        return $LAST_NAME;
    },
    $FIRST_NAME => sub {
        my ($self, $token) = @_;

        if ($token eq ',') {
            # Oops.  transfer anything we saved in first_name back to
            # last_name
            push @{$self->{last_name}}, @{$self->{first_name}};
            $self->{first_name} = [];
            return $FIRST_NAME;
        }
        if ($token =~ m/^\w*\d+$/) {    # IDs are numbers with possible alpha prefix
            $self->{id} = $token;
            return $MEMBERSHIP;
        }
        if (exists $MEMBERSHIP_TYPES{$token}) { # skipped over ID?
            $self->{membership} = $token;
            return $RANK;
        }
        if (is_Rank_or_Rating($token)) {
            Games::Go::AGA::Parse::Exception->throw(
                error       => "Invalid membership",
                filename    => 'fake_file',
                source      => $self->{source},
                line_number => 321,
            );
        }
        push @{$self->{first_name}}, $token;
        return $FIRST_NAME;     # first name may have several parts
    },
    $ID => sub {
        my ($self, $token) = @_;

        if (exists $MEMBERSHIP_TYPES{$token}) {
            $self->{membership} = $token;
            return $RANK;
        }
        $self->{id} = $token;
        return $MEMBERSHIP;
    },
    $MEMBERSHIP => sub {
        my ($self, $token) = @_;

        if ($token eq ',') {
            # Oops.  We got here because something looked like an ID
            #   but was really part of the last name.  transfer
            #   anything we saved in first_name and id back to last_name
            push @{$self->{last_name}}, @{$self->{first_name}}, $self->{id};
            $self->{first_name} = [];
            $self->{id} = '';
            return $FIRST_NAME;
        }
        if (not exists $MEMBERSHIP_TYPES{$token}) {
            if ($token eq '0.0' or
                is_Rank_or_Rating($token)) {
                $self->{membership} = '';   # shrug
                $self->rank($token);
                return $DATE;
            }
            $self->_parse_error(
                error => "Invalid membership: $token",
                source => $self->{source},
            );
        }
        $self->{membership} = $token;
        return $RANK;
    },
    $RANK => sub {
        my ($self, $token) = @_;

        if ($token eq '0.0' or
            is_Rank_or_Rating($token)) {
            $self->rank($token);
            return $DATE;
        }
        # grrr: AGA changed the format; rank can be blank or 0.0
        if ($token =~ m/^\d\d?\/\d\d?\/\d{2,4}$/) {
            $self->rank(0);
            $self->{date} = $token;
            return $CLUB;
        }
        $self->_parse_error(
            error  => "Invalid rank $token",
            source => $self->{source},
            );
    },
    $DATE => sub {
        my ($self, $token) = @_;

        if ($token =~ m/^\d\d?\D\d\d?\D\d{2,4}$/) {
            $self->{date} = $token;
            return $CLUB;
        }
        if ($token =~ m/^[A-Z][A-Z]$/) {
            $self->{state} = $token;
            return $EXTRA;
        }
        $self->{club} = $token; # shrug - best guess is this is a club
        return $STATE;
    },
    $CLUB => sub {
        my ($self, $token) = @_;

        if ($token =~ m/^[A-Z][A-Z]$/) {
            $self->{state} = $token;
            return $EXTRA;
        }
        $self->{club} = $token;
        return $STATE;
    },
    $STATE => sub {
        my ($self, $token) = @_;

        if (($token eq '-') and
            ($self->{state} eq '-')) {
            $self->{state} = '';
            return $LAST_NAME;
        }
        $self->{state} = $token;
        if ($token eq '-') {
            return $STATE;      # wait for second '-';
        }
        return $EXTRA;          # done with 'official' TDList format,
                                #   anything left over is extra
    },
);

*parse = \&parse_line;  # alias parse to parse_line
sub parse_line {
    my ($self, $string) = @_;

    $self->{source} = $string;
    map { $self->{$_} = [] } qw( last_name first_name );               # empty arrays
    map { $self->{$_} = '' } qw( id membership rank date club state ); # empty strings

    return $self->as_hash if (not $string);

    my $tokenizer = String::Tokenizer->new(
                $string,                # source string
                ",\n",                  # delimiters
                String::Tokenizer->RETAIN_WHITESPACE,
                );
    my $iter = $tokenizer->iterator;
    my $state = $LAST_NAME;

    TOKEN:
    while ($iter->hasNextToken) {
        my $token = $iter->nextToken;
        if ($token eq "\n") {    # a carriage return?
            last TOKEN;
        }
        elsif ($token !~ m/\S/ or           # only whitespace
                $token eq '') {             # empty
            next TOKEN;
        }
        elsif ($token eq '#') {             # comment
            if ($state ne $FIRST_NAME) {
                $self->_parse_error(
                    error  => "got comment, expected $name_of_state{$state}",
                    source => $self->{source},
                    );
            }
            # dump the rest of the line
            $iter->collectTokensUntil("\n") if ($iter->hasNextToken);
            next TOKEN;
        }
        elsif (exists $state_functions{$state}) {
            $state = $state_functions{$state}($self, $token);
            next TOKEN;
        }
        elsif ($state == $EXTRA) {
            if ($iter->hasNextToken) {
                $token .= $iter->collectTokensUntil("\n") || '';  # slurp the rest
            }
            chomp $token;
            $self->{extra} = $token;
            next TOKEN;
        }
        else {
            $self->_parse_error(
                error  => "Unknown state: $state",
                source => $self->{source},
                );
        }
    }
    if (length $self->{state} == 0 and
        length $self->{club}  == 2 and
        uc $self->{club} eq $self->{club}) {   # state is in club field
        $self->{state} = $self->{club};
        $self->{club} = '';
    }
    if (not $self->{id} and
        @{$self->{first_name}} > 1 and
        $self->{first_name}[-1] =~ m/\d/) {   # digit(s) present?
        $self->{id} = pop @{$self->{first_name}};   # probably
    }
    $self->{last_name} =  join(q{ }, @{$self->{last_name}});
    $self->{first_name} = join(q{ }, @{$self->{first_name}});
    if ($self->rank eq '' and
        is_Rank_or_Rating($self->{id})) {
        # hmm, this is more likely:
        $self->rank = $self->{id};
        $self->{id} = '';
    }
    $self->{id} = normalize_ID($self->{id}) if ($self->{id});
    $self->{club} = '' if (lc $self->{club} eq 'none');
    return $self->as_hash;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::Parse::TDList - Parses lines from an AGA TDLISTlist

=head1 VERSION

version 0.042

=head1 SYNOPSIS

use Games::Go::Parse::TDList;

    my $parser = Games::Go::AGA::Parse::TDList->new;
    while (my $line = <$tdlist_fh>) {
        my $hash = $parser->parse($line); # ref to a hash
        ...
    }

=head1 DESCRIPTION

A parser to break out and return fields of a line from an AGA TDListN.txt
file.  The fields are usually:

    last_name
    first_name
    id
    membership
    rank
    date
    club
    state
    extra

but some fields could be empty ('').

Note that the B<rank> field may be either rank format (3K, 4d, etc) or a
numerical rating (from -100 to +20 with a gap from -1 to +1). Rank
format implies less certainty in the accuracy of the rank.  The
B<Rank_to_Rating> function in Games::Go::AGA::Parse::Utils can be used
to force the numerical format.

=head1 METHODS

=over

=item $parser = Games::Go::AGA::Parse::TDList->new;

Creates a new parser object.

=item $parser = $parser->filename( ['new_name'])

Get/set a filename (used in error messages)

=item $file_handle = $parser->filename( [$new_file_handle ])

Get/set a file handle (used in error messages)

=item %result_hash = $parser->parse_line('a TDListN line')

=item %result_hash = $parser->parse()

Parses a single line from the TDListN.txt file and returns a hash with the
fields as listed in B<as_hash>.  Calling this function removes any field
results from previous lines.

=item %as_hash = $parser->as_hash()

Retuns the parsed line as a hash.  Missing fields will be empty strings
('').   The hash keys are

    (
        last_name  => 'last name of player',
        first_name => 'first name of player',
        id         => 'player ID',
        membership => 'AGA membership type (if any)',
        rank       => 'player's rank or rating',
        date       => 'date player's membership is valid until',
        club       => 'club player usually plays at',
        state      => 'state player lives in',
        extra      => 'any extra stuff',
    )

In scalar context, returns a reference to the hash.

=item @as_array = $parser->as_array()

Retuns the parsed line as an array.  Missing fields will be empty strings
('').  The order is:

    (
        last_name
        first_name
        id
        membership
        rank
        date
        club
        state
        extra
    )

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

__END__


# # FOR TESTING: the following format is used strictly for testing.  it is
# # designed to produce the same output as the tdlist input file.
# #          1         2         3         4         5         6
# # 1234567890123456789012345678901234567890123456789012345678901234567890
# # Augustin, Reid                2122 Full     5.1  4/23/2009 PALO CA

our ( $_full_name, $_id, $_mem, $_rt, $_date, $_clb, $_state, $loopback );

format =    # with no name. format writes to STDOUT
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<@#### @<<<<<<@##.# @>>>>>>>>> @<<<<@<
$_full_name,                 $_id, $_mem, $_rt, $_date,   $_clb, $_state


$_full_name = sprintf("%s, %s", join(q{ }, @{$self->{last_name}}),
                                join(q{ }, @{$self->{first_name}}));
$_id    = $self->{id};
$_mem   = $self->{membership};
$_rt    = $self->{rank};
$_date  = $self->{date};
$_clb   = $self->{club};
$_state = $self->{state};
write;  # write format to STDOUt
