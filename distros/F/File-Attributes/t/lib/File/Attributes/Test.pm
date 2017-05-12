#!/usr/bin/perl
# Test.pm 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>
# File::Attributes module for testing

package File::Attributes::Test;
use base 'File::Attributes::Base';
our $VERSION = 
  'foo-o-matic';

my %attributes;
my $IGNORE = qr/NONONO/;

# applicible unless filename contains "NONONO"
sub applicable {
    my $self = shift;
    my $file = shift;
    return 0 if $file =~ /$IGNORE/;
    return 1;
}

# message from general pepper -- priority 1_000_000!
sub priority { 1_000_000 }

sub get {
    return if $_[2] =~ /$IGNORE/; # ignore attributes that contain NONONO
    return $attributes{$_[1]}->{$_[2]};
}

sub set {    
    return if $_[2] =~ /$IGNORE/; # ignore
    $attributes{$_[1]}->{$_[2]} = $_[3];
}

sub unset {
    delete $attributes{$_[1]}->{$_[2]};
}

sub list {
    return keys %{$attributes{$_[1]}};
}

1;
