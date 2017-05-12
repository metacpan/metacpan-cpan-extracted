#!/usr/bin/perl

package Lingua::Phonology::Segment::Rules;

use strict;
use warnings;
use warnings::register;
use Lingua::Phonology::Common;

our $VERSION = 0.2;

# This class acts just like a Segment, but adds the INSERT_RIGHT, INSERT_LEFT,
# etc.  methods. It is not a proper subclass, because there's no way to get the
# proper behavior, but the utility function _is_seg is designed to recognize
# this class as a segment also. We are named as if we were an actual subclass.

# To properly mimic Segment.pm, we have to overload
use overload 
    # The fun stuff
    '""' => sub { "$_[0]->{seg}" },
    'cmp' => sub { 
        my ($l, $r, $swap) = @_;
        if ($swap) { return "$r" cmp "$l" }
        else { return "$l" cmp "$r" } },
    '0+' => sub { int $_[0]->{seg} }, 
    'fallback' => 1;


sub err ($) { _err($_[0]) if warnings::enabled() };

sub new {
    my $proto = shift;

    # If new() was called as an object method, the child should take care of it
    return $proto->{seg}->new(@_) if ref $proto;

    # Don't carp here, so that the caller can make their own error message
    my ($word, $base) = @_;
    return unless _is_seg $base;

    return bless { seg => $base, word => $word, id => int $base }, $proto;
}

sub _insert {
    my $self = shift;
    my ($dir, $seg) = @_;
    return err "Can't INSERT_$dir with a tier in effect" if _is_tier $self->{seg};
    return err "Argument to INSERT_$dir not a segment" unless _is_seg $seg;
    my $pos = ($dir eq 'RIGHT') ? 1 : 0;

    # Always insert into your parent
    $self->{word}->_insert($self->{id}, $pos, $seg);

    # Pass on _insert calls if possible
    $self->{seg}->_insert(@_) if $self->{seg}->can('_insert');

    1;
}

sub INSERT_LEFT {
    (shift)->_insert('LEFT', @_);
}

sub INSERT_RIGHT {
    (shift)->_insert('RIGHT', @_);
}

sub DELETE {
    my $self = shift;
    return err "Can't DELETE with a tier in effect" if _is_tier $self->{seg};
    $self->{word}->_delete($self->{id});
    $self->{seg}->DELETE if $self->{seg}->can('DELETE');
}

sub _getid {
    return $_[0]->{id};
}

# Override clear() to do a DELETE as well
sub clear {
    my $self = shift;
    $self->DELETE unless _is_tier $self->{seg};
    $self->{seg}->clear;
}

sub _RULE {
    return $_[0]->{word}->rule;
}

# Don't be a boundary unless the seg you're holding has a method for deciding
sub BOUNDARY {
    my $self = shift;
    return $self->{seg}->BOUNDARY if $self->{seg}->can('BOUNDARY');
	return;
}

# AUTOLOAD dispatches all other methods to the seg
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    no strict 'refs';
    *$method = sub { (shift)->{seg}->$method(@_); };
    $self->$method(@_);
}

# Don't destroy your children!
sub DESTROY {}

1;
