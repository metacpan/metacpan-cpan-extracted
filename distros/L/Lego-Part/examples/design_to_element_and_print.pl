#!/usr/bin/env perl

package Lego::Part::Transfer::Example;

use base qw(Lego::Part::Transfer);
use strict;
use warnings;

# Convert design to element.
sub design2element {
        my ($self, $part) = @_;
        $self->_check_part($part);
        if ($part->color eq 'red' && $part->design_id eq '3002') {
                $part->element_id('300221');
        }
        return;
}

package main;

use strict;
use warnings;

use Lego::Part;
use Lego::Part::Action;

# Lego part.
my $part = Lego::Part->new(
        'color' => 'red',
        'design_id' => '3002',
);

#  Lego part action.
my $act = Lego::Part::Action->new;

# Transfer class.
my $trans = Lego::Part::Transfer::Example->new;

# Load element id.
$act->load_element_id($trans, $part);

# Print color and design ID.
print 'Color: '.$part->color."\n";
print 'Design ID: '.$part->design_id."\n";
print 'Element ID: '.$part->element_id."\n";

# Output:
# Color: red
# Design ID: 3002
# Element ID: 300221