package Kwiki::Zipcode;
use Kwiki::Plugin -Base;
our $VERSION = '0.12';

const class_id => 'zipcode';

sub register {
    my $registry = shift;
    $registry->add(preference => $self->zipcode);
    $registry->add(prerequisite => 'user_preferences');
}

sub zipcode {
    my $p = $self->new_preference('zipcode');
    $p->query('Enter your zipcode.');
    $p->type('input');
    $p->size(5);
    $p->edit('check_zipcode');
    $p->default('');
    return $p;
}

sub check_zipcode {
    my $preference = shift;
    my $value = $preference->new_value;
    return unless length $value;
    $preference->error('Invalid. Must be 5 digits.')
      unless $value =~ /^\d{5}$/;
}

__DATA__

=head1 NAME 

Kwiki::Zipcode - Kwiki Zipcode Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
