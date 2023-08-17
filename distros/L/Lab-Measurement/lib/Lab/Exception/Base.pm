package Lab::Exception::Base;
#ABSTRACT: Exception base class
$Lab::Exception::Base::VERSION = '3.881';
use v5.20;

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Exception::Base - Exception base class

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2014       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
