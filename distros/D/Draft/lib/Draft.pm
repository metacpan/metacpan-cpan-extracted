package Draft;

=head1 NAME

Draft - CAD directory-based file format demo

=head1 SYNOPSIS

This is just a demonstration, nobody in their right-mind would go
and create GUI CAD applications in perl.

=head1 DESCRIPTION

An implementation of "An open file format for Computer Aided Design (CAD)"

    L<http://bugbear.blackfish.org.uk/~bruno/draft/>

=head1 USAGE

    $Draft::PATH = '/path/to.drawing/';
    Draft->Read;

The 'Draft' module itself is mainly used to bootstrap the
world-space that drawings are loaded into - This is accessible via
the package variable $Draft::WORLD.

=cut

use strict;
use warnings;
use Draft::Drawing;

our $VERSION = '0.06';
our $WORLD = undef;
our $PATH = undef;

sub Read
{
    $PATH =~ s/\/*$/\//;
    $WORLD->{$PATH} = Draft::Drawing->new ($PATH)
        unless exists $WORLD->{$PATH};

    $WORLD->{$PATH}->Read;
}

1;
