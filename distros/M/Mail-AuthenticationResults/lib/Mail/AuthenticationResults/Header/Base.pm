package Mail::AuthenticationResults::Header::Base;
# ABSTRACT: Base class for modelling parts of the Authentication Results Header

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Scalar::Util qw{ weaken refaddr };
use JSON;
use Carp;
use Clone qw{ clone };

use Mail::AuthenticationResults::Header::Group;
use Mail::AuthenticationResults::FoldableHeader;


sub _HAS_KEY{ return 0; }
sub _HAS_VALUE{ return 0; }
sub _HAS_CHILDREN{ return 0; }
sub _ALLOWED_CHILDREN{ # uncoverable subroutine
    # does not run in Base as HAS_CHILDREN returns 0
    return 0; # uncoverable statement
}


sub new {
    my ( $class ) = @_;
    my $self = {};
    bless $self, $class;
    return $self;
}


sub set_key {
    my ( $self, $key ) = @_;
    croak 'Does not have key' if ! $self->_HAS_KEY();
    croak 'Key cannot be undefined' if ! defined $key;
    croak 'Key cannot be empty' if $key eq q{};
    croak 'Invalid characters in key' if $key =~ /"/;
    croak 'Invalid characters in key' if $key =~ /\n/;
    croak 'Invalid characters in key' if $key =~ /\r/;
    $self->{ 'key' } = $key;
    return $self;
}


sub key {
    my ( $self ) = @_;
    croak 'Does not have key' if ! $self->_HAS_KEY();
    return q{} if ! defined $self->{ 'key' }; #5.8
    return $self->{ 'key' };
}


sub safe_set_value {
    my ( $self, $value ) = @_;

    $value = q{} if ! defined $value;

    $value =~ s/\t/ /g;
    $value =~ s/\n/ /g;
    $value =~ s/\r/ /g;
    $value =~ s/\(/ /g;
    $value =~ s/\)/ /g;
    $value =~ s/\\/ /g;
    $value =~ s/"/ /g;
    $value =~ s/;/ /g;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

    #$value =~ s/ /_/g;

    $self->set_value( $value );
    return $self;
}


sub set_value {
    my ( $self, $value ) = @_;
    croak 'Does not have value' if ! $self->_HAS_VALUE();
    croak 'Value cannot be undefined' if ! defined $value;
    #croak 'Value cannot be empty' if $value eq q{};
    croak 'Invalid characters in value' if $value =~ /"/;
    croak 'Invalid characters in value' if $value =~ /\n/;
    croak 'Invalid characters in value' if $value =~ /\r/;
    $self->{ 'value' } = $value;
    return $self;
}


sub value {
    my ( $self ) = @_;
    croak 'Does not have value' if ! $self->_HAS_VALUE();
    return q{} if ! defined $self->{ 'value' }; # 5.8
    return $self->{ 'value' };
}


sub stringify {
    my ( $self, $value ) = @_;
    my $string = $value;
    $string = q{} if ! defined $string; #5.8;

    if ( $string =~ /[\s\t \(\);=]/ ) {
        $string = '"' . $string . '"';
    }

    return $string;
}


sub children {
    my ( $self ) = @_;
    croak 'Does not have children' if ! $self->_HAS_CHILDREN();
    return [] if ! defined $self->{ 'children' }; #5.8
    return $self->{ 'children' };
}


sub orphan {
    my ( $self, $parent ) = @_;
    croak 'Child does not have a parent' if ! exists $self->{ 'parent' };
    delete $self->{ 'parent' };
    return;
}


sub copy_children_from {
  my ( $self, $object ) = @_;
  for my $original_entry (@{$object->children()}) {
    my $entry = clone $original_entry;
    $entry->orphan if exists $entry->{ 'parent' };;
    $self->add_child( $entry );
  }
}


sub add_parent {
    my ( $self, $parent ) = @_;
    return if ( ref $parent eq 'Mail::AuthenticationResults::Header::Group' );
    croak 'Child already has a parent' if exists $self->{ 'parent' };
    croak 'Cannot add parent' if ! $parent->_ALLOWED_CHILDREN( $self ); # uncoverable branch true
    # Does not run as test is also done in add_child before add_parent is called.
    $self->{ 'parent' } = $parent;
    weaken $self->{ 'parent' };
    return;
}


sub parent {
    my ( $self ) = @_;
    return $self->{ 'parent' };
}


sub remove_child {
    my ( $self, $child ) = @_;
    croak 'Does not have children' if ! $self->_HAS_CHILDREN();
    croak 'Cannot add child' if ! $self->_ALLOWED_CHILDREN( $child );
    croak 'Cannot add a class as its own parent' if refaddr $self == refaddr $child; # uncoverable branch true
    # Does not run as there are no ALLOWED_CHILDREN results which permit this

    my @children;
    my $child_removed = 0;
    foreach my $mychild ( @{ $self->{ 'children' } } ) {
        if ( refaddr $child == refaddr $mychild ) {
            if ( ref $self ne 'Mail::AuthenticationResults::Header::Group' ) {
                $child->orphan();
            }
            $child_removed = 1;
        }
        else {
            push @children, $mychild;
        }
    }
    my $children = $self->{ 'children' };

    croak 'Not a child of this class' if ! $child_removed;

    $self->{ 'children' } = \@children;

    return $self;
}


sub add_child {
    my ( $self, $child ) = @_;
    croak 'Does not have children' if ! $self->_HAS_CHILDREN();
    croak 'Cannot add child' if ! $self->_ALLOWED_CHILDREN( $child );
    croak 'Cannot add a class as its own parent' if refaddr $self == refaddr $child; # uncoverable branch true
    # Does not run as there are no ALLOWED_CHILDREN results which permit this

    $child->add_parent( $self );
    push @{ $self->{ 'children' } }, $child;

    return $child;
}


sub ancestor {
    my ( $self ) = @_;

    my $depth = 0;
    my $ancestor = $self->parent();
    my $eldest = $self;
    while ( defined $ancestor ) {
        $eldest = $ancestor;
        $ancestor = $ancestor->parent();
        $depth++;
    }

    return ( $eldest, $depth );
}


sub as_string_prefix {
    my ( $self, $header ) = @_;

    my ( $eldest, $depth ) = $self->ancestor();

    my $indents = 1;
    if ( $eldest->can( 'indent_by' ) ) {
        $indents = $eldest->indent_by();
    }

    my $eol = "\n";
    if ( $eldest->can( 'eol' ) ) {
        $eol = $eldest->eol();
    }

    my $indent = ' ';
    my $added = 0;
    if ( $eldest->can( 'indent_on' ) ) {
        if ( $eldest->indent_on( ref $self ) ) {
            $header->space( $eol );
            $header->space( ' ' x ( $indents * $depth ) );
            $added = 1;
        }
    }
    $header->space( ' ' ) if ! $added;

    return $indent;
}

sub _as_hashref {
    my ( $self ) = @_;

    my $type = lc ref $self;
    $type =~ s/^(.*::)//;
    my $hashref = { 'type' => $type };

    $hashref->{'key'} = $self->key() if $self->_HAS_KEY();
    $hashref->{'value'} = $self->value() if $self->_HAS_VALUE();
    if ( $self->_HAS_CHILDREN() ) {
        my @children = map { $_->_as_hashref() } @{ $self->children() };
        $hashref->{'children'} = \@children;
    }
    return $hashref;
}


sub as_json {
    my ( $self ) = @_;
    my $J = JSON->new();
    $J->canonical();
    return $J->encode( $self->_as_hashref() );
}


sub as_string {
    my ( $self ) = @_;
    my $header = Mail::AuthenticationResults::FoldableHeader->new();
    $self->build_string( $header );
    return $header->as_string();
}


sub build_string {
    my ( $self, $header ) = @_;

    if ( ! $self->key() ) {
        return;
    }

    $header->string( $self->stringify( $self->key() ) );
    if ( $self->value() ) {
        $header->assignment( '=' );
        $header->string( $self->stringify( $self->value() ) );
    }
    elsif ( $self->value() eq '0' ) {
        $header->assignment( '=' );
        $header->string( '0' );
    }
    elsif ( $self->value() eq q{} ) {
        # special case none here
        if ( $self->key() ne 'none' ) {
            $header->assignment( '=' );
            $header->string( '""' );
        }
    }
    if ( $self->_HAS_CHILDREN() ) { # uncoverable branch false
        # There are no classes which run this code without having children
        foreach my $child ( @{$self->children()} ) {
            $child->as_string_prefix( $header );
            $child->build_string( $header );
        }
    }
    return;
}


sub search {
    my ( $self, $search ) = @_;

    my $group = Mail::AuthenticationResults::Header::Group->new();

    my $match = 1;

    if ( exists( $search->{ 'key' } ) ) {
        if ( $self->_HAS_KEY() ) {
            if ( ref $search->{ 'key' } eq 'Regexp' && $self->key() =~ m/$search->{'key'}/ ) {
                $match = $match && 1; # uncoverable statement
                # $match is always 1 at this point, left this way for consistency
            }
            elsif ( lc $search->{ 'key' } eq lc $self->key() ) {
                $match = $match && 1; # uncoverable statement
                # $match is always 1 at this point, left this way for consistency
            }
            else {
                $match = 0;
            }
        }
        else {
            $match = 0;
        }
    }

    if ( exists( $search->{ 'value' } ) ) {
        $search->{ 'value' } = '' if ! defined $search->{ 'value' };
        if ( $self->_HAS_VALUE() ) {
            if ( ref $search->{ 'value' } eq 'Regexp' && $self->value() =~ m/$search->{'value'}/ ) {
                $match = $match && 1;
            }
            elsif ( lc $search->{ 'value' } eq lc $self->value() ) {
                $match = $match && 1;
            }
            else {
                $match = 0;
            }
        }
        else {
            $match = 0; # uncoverable statement
            # There are no code paths with the current classes which end up here
        }
    }

    if ( exists( $search->{ 'authserv_id' } ) ) {
        if ( $self->_HAS_VALUE() ) {
            if ( lc ref $self eq 'mail::authenticationresults::header' ) {
                my $authserv_id = eval{ $self->value()->value() } || q{};
                if ( ref $search->{ 'authserv_id' } eq 'Regexp' && $authserv_id =~ m/$search->{'authserv_id'}/ ) {
                    $match = $match && 1;
                }
                elsif ( lc $search->{ 'authserv_id' } eq lc $authserv_id ) {
                    $match = $match && 1;
                }
                else {
                    $match = 0;
                }
            }
            else {
                $match = 0;
            }
        }
        else {
            $match = 0; # uncoverable statement
            # There are no code paths with the current classes which end up here
        }
    }

    if ( exists( $search->{ 'isa' } ) ) {
        if ( lc ref $self eq 'mail::authenticationresults::header::' . lc $search->{ 'isa' } ) {
            $match = $match && 1;
        }
        elsif ( lc ref $self eq 'mail::authenticationresults::header' && lc $search->{ 'isa' } eq 'header' ) {
            $match = $match && 1;
        }
        else {
            $match = 0;
        }
    }

    if ( exists( $search->{ 'has' } ) ) {
        foreach my $query ( @{ $search->{ 'has' } } ) {
            $match = 0 if ( scalar @{ $self->search( $query )->children() } == 0 );
        }
    }

    if ( $match ) {
        $group->add_child( $self );
    }

    if ( $self->_HAS_CHILDREN() ) {
        foreach my $child ( @{$self->children()} ) {
            my $childfound = $child->search( $search );
            if ( scalar @{ $childfound->children() } ) {
                $group->add_child( $childfound );
            }
        }
    }

    return $group;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header::Base - Base class for modelling parts of the Authentication Results Header

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

Set of classes representing the various parts and sub parts of Authentication Results Headers.

=over

=item *

L<Mail::AuthenticationResults::Header> represents a complete Authentication Results Header set

=item * 

L<Mail::AuthenticationResults::Header::AuthServID> represents the AuthServID part of the set

=item * 

L<Mail::AuthenticationResults::Header::Comment> represents a comment

=item * 

L<Mail::AuthenticationResults::Header::Entry> represents a main entry

=item * 

L<Mail::AuthenticationResults::Header::Group> represents a group of parts, typically as a search result

=item * 

L<Mail::AuthenticationResults::Header::SubEntry> represents a sub entry part

=item * 

L<Mail::AuthenticationResults::Header::Version> represents a version part

=back

    Header
        AuthServID
            Version
            Comment
            SubEntry
        Entry
            Comment
        Entry
            Comment
            SubEntry
                Comment
        Entry
            SubEntry
            SubEntry

    Group
        Entry
            Comment
        SubEntry
            Comment
        Entry
            SubEntry

=head1 METHODS

=head2 new()

Return a new instance of this class

=head2 set_key( $key )

Set the key for this instance.

Croaks if $key is invalid.

=head2 key()

Return the current key for this instance.

Croaks if this instance type can not have a key.

=head2 safe_set_value( $value )

Set the value for this instance.

Munges the value to remove invalid characters before setting.

This method also removes some value characters when their inclusion
would be likely to break simple parsers.

=head2 set_value( $value )

Set the value for this instance.

Croaks if the value contains invalid characters.

=head2 value()

Returns the current value for this instance.

=head2 stringify( $value )

Returns $value with stringify rules applied.

=head2 children()

Returns a listref of this instances children.

Croaks if this instance type can not have children.

=head2 orphan()

Removes the parent for this instance.

Croaks if this instance does not have a parent.

=head2 copy_children_from( $object )

Copy (clone) all of the children from the given object
into this object.

=head2 add_parent( $parent )

Sets the parent for this instance to the supplied object.

Croaks if the relationship between $parent and $self is not valid.

=head2 parent()

Returns the parent object for this instance.

=head2 remove_child( $child )

Removes $child as a child of this instance.

Croaks if the relationship between $child and $self is not valid.

=head2 add_child( $child )

Adds $child as a child of this instance.

Croaks if the relationship between $child and $self is not valid.

=head2 ancestor()

Returns the top Header object and depth of this child

=head2 as_string_prefix( $header )

Add the prefix to as_string for this object when calledas a child
of another objects as_string method call.

=head2 as_json()

Return this instance as a JSON serialised string

=head2 as_string()

Returns this instance as a string.

=head2 build_string( $header )

Build a string using the supplied Mail::AuthenticationResults::FoldableHeader object.

=head2 search( $search )

Apply search rules in $search to this instance and return a
Mail::AuthenticationResults::Header::Group object containing the matches.

$search is a HASHREF with the following possible key/value pairs

=over

=item key

Match if the instance key matches the supplied value (string or regex)

=item value

Match if the instance value matches the supplied value (string or regex)

=item isa

Match is the instance class typs matches the supplied value. This is a lowercase version
of the class type, (comment,entry,subentry,etc))

=item has

An arrayref of searches, match this class if the supplied search queries would return at
least 1 result each

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
