#===============================================================================
#
#         FILE:  Games::Go::AGA::Parse::Round.pm
#
#      PODNAME:  Games::Go::AGA::Parse::Round
#     ABSTRACT:  Parses lines from an AGA Tournament Round file
#
#       AUTHOR:  Reid Augustin (REID), <reid@lucidport.com>
#      COMPANY:  LucidPort Technology, Inc.
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::Parse::Round;
use parent 'Games::Go::AGA::Parse';

use Carp;
use Readonly;
use String::Tokenizer;
use Games::Go::AGA::Parse::Exceptions;
use Games::Go::AGA::Parse::Util qw( normalize_ID );

our $VERSION = '0.042'; # VERSION

sub white_id {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{white_id} = $new;
    }
    return $self->{white_id} || '';
}

sub black_id {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{black_id} = $new;
    }
    return $self->{black_id} || '';
}

sub result {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{result} = $new;
    }
    return $self->{result} || '';
}

sub handicap {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{handicap} = $new;
    }
    return defined $self->{handicap} ? $self->{handicap} : '0';
}

sub komi {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{komi} = $new;
    }
    return defined $self->{komi} ? $self->{komi} : '0';
}

sub comment {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{comment} = $new;
    }
    return $self->{comment} || '';
}

sub as_array {
    my ($self, $new) = @_;

    my @ret;
    if ($self->white_id) {
        @ret = map(
            { $self->$_ }
            # fields, in order
            qw(
                white_id
                black_id
                result
                handicap
                komi
                comment
            ),
        );
    }
    elsif (exists $self->{comment}) {
        @ret = ($self->comment);
    }
    return wantarray ? @ret : \@ret;
}

sub as_hash {
    my ($self, $new) = @_;

    my %ret;
    if ($self->white_id) {
        %ret =  map(
            { $_, $self->$_ }
            # fields
            qw(
                white_id
                black_id
                result
                handicap
                komi
                comment
            ),
        );
    }
    elsif (exists $self->{comment}) {
        %ret = (comment => $self->comment);
    }
    return wantarray ? %ret : \%ret;
}

Readonly my $WHITE_ID   => 0;
Readonly my $BLACK_ID   => 1;
Readonly my $RESULT     => 2;
Readonly my $HANDICAP   => 3;
Readonly my $KOMI       => 4;

Readonly my %name_of_state => (
    $WHITE_ID   => 'white_id',
    $BLACK_ID   => 'black_id',
    $RESULT     => 'result',
    $HANDICAP   => 'handicap',
    $KOMI       => 'komi',
);

*parse = \&parse_line;  # alias parse to parse_line
sub parse_line  {
    my ($self, $string) = @_;

    map { delete $self->{$_} }
        qw(
            white_id
            black_id
            result
            handicap
            komi
            comment
        );
    return $self->as_hash if (not $string);
    my $tokenizer = String::Tokenizer->new(
                $string,                                # source string
                # delimiters
             #  "~!@#\$\%^&*()`={}[]:;\"'<>,?/|\\\n",
                "@#\$\n",
                String::Tokenizer->RETAIN_WHITESPACE,
                );
    my $iter = $tokenizer->iterator;
    $self->{source} = $string;
    my $state = $WHITE_ID;
    TOKEN:
    while ($iter->hasNextToken) {
        my $token = $iter->nextToken;
#print $self->err("state $state, token $token");
        if ($token eq "\n") {            # a carriage return?
            last TOKEN;
        }
        elsif ($token !~ m/\S/ or       # only whitespace
               $token eq '') {          # empty
            next TOKEN;   # ignore
        }
        elsif ($token eq '#') {             # comment
            if ($state != $WHITE_ID) {
                $self->_parse_error(
                    error => "got comment, expected $name_of_state{$state}",
                    source => $self->{source},
                    );
            }
            $self->{comment} = join q{}, $iter->collectTokensUntil("\n");
            last TOKEN;
        }
        else {
#print $self->err("state $state, token $token");
            if ($state == $WHITE_ID) {
                $self->{white_id} = normalize_ID($token);
                $state = $BLACK_ID;
            }
            elsif ($state == $BLACK_ID) {
                $self->{black_id} = normalize_ID($token);
                $state = $RESULT;
            }
            elsif ($state == $RESULT) {
                $self->{result} = $token;
                $state = $HANDICAP;
            }
            elsif ($state == $HANDICAP) {
                $self->{handicap} = 0 + $token;    # numerify
                $state = $KOMI;
            }
            elsif ($state == $KOMI) {
                $self->{komi} = 0 + $token;        # numerify
                $state = $WHITE_ID;
            }
            else {
                $self->_parse_error(
                    error => "unknown state: $state",
                    source => $self->{source},
                    );
            }
            next TOKEN;
        }
    }
    if ($state != $WHITE_ID) {
        $self->_parse_error(
            error => "got end of line, expected $name_of_state{$state}",
            source => $self->{source},
            );
    }
    return $self->as_hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::Parse::Round - Parses lines from an AGA Tournament Round file

=head1 VERSION

version 0.042

=head1 SYNOPSIS

  use Games::Go::AGA::Parse::Round;
  my $parser = Games::Go::AGA::Parse::Round->new;
  my %line_info = $parser->parse_line($line);   # where $line is a line from
                                                # the rounds file

=head1 DESCRIPTION

Games::Go::AGA::Parse::Round can parse lines of information from an AGA
tournament rounds file.  The file contains a list of games that were played
during the round.

=head1 METHODS

=over

=item my $parser = Games::Go::AGA::Parse::Round->new;

Creates a parser object.

=item my $parser = $parser->filename( ['new_name'])

Get/set a filename (used in error messages)

=item my $file_handle = $parser->filename( [$new_file_handle ])

Get/set a file handle (used in error messages)

=item my %line_info = $parser->parse_line( $line );

=item my %line_info = $parser->parse( $line );

$line is a line of text from a round.tde format file.  Returns
the same as B<as_hash> below.

=item %as_hash = $parser->as_hash()

Retuns the parsed line as a hash.  Missing fields will be empty strings
('').   The hash keys are

    (
        white_id  => string containing the white ID,
        black_id  => string containing the black ID,
        result    => a single character containg either 'w', 'b', or '?',
        handicap  => a number containing the number of handicap stones,
        komi      => a number containing the komi,
        comment   => string following the '#' comment marker (if any)
    )

If B<$line> is empty, the hash will also be empty.  If B<$line> contains
only a comment, the hash will contain only the comment.

Note that BYES are not explicitly listed in a round.tde file.  Instead,
they must be found by a process of elimination with respect to the players
in the registration file.

In scalar context, returns a reference to the hash.

=item @as_array = $parser->as_array()

Retuns the parsed line as an array.  Missing fields will be empty strings
('').  The order is:

    (
        white_id
        black_id
        result
        handicap
        komi
        comment
    )

In scalar context, returns a reference to the array.

=item $field_by_name = $parser-> < name >

Individual fields may be set or retrieved by name.  E.g:

    $handicap = $parser->handicap
     . . .
    $parser->komi(6.5);

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
