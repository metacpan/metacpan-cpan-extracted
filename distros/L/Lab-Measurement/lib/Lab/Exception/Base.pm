#!/usr/bin/perl -w

package Lab::Exception::Base;
our $VERSION = '3.542';

#
# This is for comfy optional adding of custom methods via our own exception base class later
#

our @ISA = ("Exception::Class::Base");

#use Carp;
use Data::Dumper;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->Trace(1);  # Append stack trace to string representation by default
    return $self;
}

sub full_message {
    my $self = shift;

    return
          $self->message()
        . "\nFile: "
        . $self->file()
        . "\nPackage: "
        . $self->package()
        . "\nLine:"
        . $self->package() . "\n";
}

1;
