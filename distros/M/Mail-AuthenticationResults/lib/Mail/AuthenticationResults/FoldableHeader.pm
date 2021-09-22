package Mail::AuthenticationResults::FoldableHeader;
# ABSTRACT: Class for modelling a foldable header string

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Carp;

use Mail::AuthenticationResults::Token::String;
use Mail::AuthenticationResults::Token::Space;
use Mail::AuthenticationResults::Token::Separator;
use Mail::AuthenticationResults::Token::Comment;
use Mail::AuthenticationResults::Token::Assignment;


sub new {
    my ( $class, $args ) = @_;

    my $self = {};
    bless $self, $class;

    $self->{ 'string' } = [];

    return $self;
}


sub eol {
    my ( $self ) = @_;
    return $self->{ 'eol' } if exists ( $self->{ 'eol' } );
    return "\n";
}


sub set_eol {
    my ( $self, $eol ) = @_;
    $self->{ 'eol' } = $eol;
    return $self;
}


sub indent {
    my ( $self ) = @_;
    return $self->{ 'indent' } if exists ( $self->{ 'indent' } );
    return '    ';
}


sub set_indent {
    my ( $self, $indent ) = @_;
    $self->{ 'indent' } = $indent;
    return $self;
}


sub sub_indent {
    my ( $self ) = @_;
    return $self->{ 'sub_indent' } if exists ( $self->{ 'sub_indent' } );
    return '  ';
}


sub set_sub_indent {
    my ( $self, $indent ) = @_;
    $self->{ 'sub_indent' } = $indent;
    return $self;
}


sub try_fold_at {
    my ( $self ) = @_;
    return $self->{ 'try_fold_at' } if exists ( $self->{ 'try_fold_at' } );
    return 800;
}


sub set_try_fold_at {
    my ( $self, $length ) = @_;
    $self->{ 'try_fold_at' } = $length;
    return $self;
}


sub force_fold_at {
    my ( $self ) = @_;
    return $self->{ 'force_fold_at' } if exists ( $self->{ 'force_fold_at' } );
    return 900;
}


sub set_force_fold_at {
    my ( $self, $length ) = @_;
    $self->{ 'force_fold_at' } = $length;
    return $self;
}


sub string {
    my( $self, $string ) = @_;
    push @{ $self->{ 'string' } }, Mail::AuthenticationResults::Token::String->new_from_value( $string );
    return $self;
}


sub space {
    my ( $self, $string ) = @_;
    push @{ $self->{ 'string' } }, Mail::AuthenticationResults::Token::Space->new_from_value( $string );
    return $self;
}


sub separator {
    my ( $self, $string ) = @_;
    push @{ $self->{ 'string' } }, Mail::AuthenticationResults::Token::Separator->new_from_value( $string );
    return $self;
}


sub comment {
    my ( $self, $string ) = @_;
    push @{ $self->{ 'string' } }, Mail::AuthenticationResults::Token::Comment->new_from_value( $string );
    return $self;
}


sub assignment {
    my ( $self, $string ) = @_;
    push @{ $self->{ 'string' } }, Mail::AuthenticationResults::Token::Assignment->new_from_value( $string );
    return $self;
}


sub as_string {
    my ( $self ) = @_;

    my $string = q{};
    my $string_length = 0;
    my $content_added = 0;

    my $sections = [];
    my $stack = [];
    my $last_type;

    foreach my $part ( @{ $self->{ 'string' } } ) {
        if ( $part->is() eq 'space' && $last_type ne 'space' ) {
            # We have a folding space
            push @$sections, $stack if @$stack;
            $stack = [];
        }
        push @$stack, $part;
        $last_type = $part->is();
    }
    push @$sections, $stack if @$stack;

    my $eol        = $self->eol();;
    my $indent     = $self->indent();
    my $sub_indent = $self->sub_indent();

    my $fold_length = 0;
    SECTION:
    while ( my $section = shift @$sections ) {
        if ( $section->[0]->is() eq 'space' && $section->[0]->value() eq $eol ) {
            # This section starts a new line
            $fold_length = 0;
            if ( ! exists( $section->[0]->{ '_folded' } ) ) {
                if ( $section->[1]->is() eq 'space' ) {
                    # Take the last indent value for the fold indent
                    $indent = $section->[1]->value();
                }
            }
        }

        my $section_string = join( q{}, map { $_->value() } @$section );
        my $section_length = length( $section_string );

        if ( $fold_length + $section_length > $self->try_fold_at() ) {
if ( $fold_length > 0 ) {
                # Remove whitespace tokens at beginning of section
                while ( $section->[0]->is() eq 'space' ) {
                    shift @$section;
                }
                # Insert new folding whitespace at beginning of section
                unshift @$section, Mail::AuthenticationResults::Token::Space->new_from_value( $indent . $sub_indent );
                unshift @$section, Mail::AuthenticationResults::Token::Space->new_from_value( $eol );
                $section->[0]->{ '_folded' } = 1;
                unshift @$sections, $section;
                next SECTION;
            }
            else {
            # ToDo:
                # This section alone is over the line limit
                # It already starts with a fold, so we need to remove
                # some of it to a new line if we can.

                # Strategy 1: Fold at a relevant token boundary
                my $first_section = [];
                my $second_section = [];
                push @$second_section, Mail::AuthenticationResults::Token::Space->new_from_value( $eol );
                push @$second_section, Mail::AuthenticationResults::Token::Space->new_from_value( $indent . $sub_indent );
                $second_section->[0]->{ '_folded' } = 1;
                my $first_section_length = 0;
                foreach my $part ( @$section ) {
                    my $part_length = length $part->value();
                    if ( $part_length + $first_section_length < $self->try_fold_at() ) {
                        push @$first_section, $part;
                        $first_section_length += $part_length;
                    }
                    else {
                        push @$second_section, $part;
                        $first_section_length = $self->try_fold_at() + 1; # everything from this point goes onto second
                    }
                }
                # Do we have a first and second section with actual content?
                if ( ( grep { $_->is() ne 'space' } @$first_section ) &&
                     ( grep { $_->is() ne 'space' } @$second_section ) ) {
                    unshift @$sections, $second_section;
                    unshift @$sections, $first_section;
                    next SECTION;
                }

                # We MUST fold at $self->force_fold_at();
                # Strategy 2: Force fold at a space within a string
                # Strategy 3: Force fold anywhere

                # We assume that force fold is greater than try fold
            }
        }

        $string .= $section_string;
        $fold_length += $section_length;
    }

    return $string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::FoldableHeader - Class for modelling a foldable header string

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

Class representing a foldable Authentication Results header string

=head1 METHODS

=head2 new( $args )

Return a new instance of this class

=head2 eol()

Return the current eol marker.

=head2 set_eol( $eol )

Set the current eol marker.

=head2 indent()

Return the current base indent string.

Defaults to 4 spaces.

=head2 set_indent( $indent )

Set the current base indent string.

=head2 sub_indent()

Return the current fold indent string.
This is added to the current indent for folded headers.

Defaults to 2 spaces.

=head2 set_sub_indent( $indent )

Set the current fold indent string.

=head2 try_fold_at()

Return the length of header line for triggering a fold attempt

=head2 set_try_fold_at( $length )

Set the length of header line for triggering a fold attempt.

Defaults to 800.

=head2 force_fold_at()

Return the length of header line for forcing a fold.

=head2 set_force_fold_at( $length )

Set the length of header line for forcing a fold.

Defaults to 900.

=head2 string( $string )

Add $string to this header string

In this context, string can include a quoted string, or a string with assignment operators embedded within it.
A string is a unit of data which we do not want to break with a fold.

=head2 space( $string )

Add a space $string to this header string

In this context, a space can be a single space, multiple spaces, or a folding space.
A space is a unit of data which would be an ideal spot to insert a fold.

=head2 separator( $string )

Add a separator $string to this header string

In this context, a separator is the ; string or the / string.

=head2 comment( $string )

Add a comment $string to this header string

In this context, a comment is a comment string. A comment is a unit of data which we do not want to break with a fold.

=head2 assignment( $string )

Add an assignment $string to this header string

In this context, as assignment is the = string.

=head2 as_string()

Return the current header string

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
