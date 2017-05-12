package Kwiki::Email;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Email::Valid;
our $VERSION = '0.02';

const class_id => 'email';

sub register {
    my $registry = shift;
    $registry->add(
		preference => 'email',
        object => $self->email,
    );
}

sub email {
    my $p = $self->new_preference('email');
    $p->query('Enter your email address.');
    $p->type('input');
    $p->size(30);
    $p->edit('check_email');
    $p->default('');
    return $p;
}

sub check_email {
    my $preference = shift;
    my $value      = $preference->new_value;
    return unless length $value;
    $preference->error('Invalid Email Adress.')
      unless Email::Valid->address($value);
}

1;

__DATA__

=head1 NAME 

Kwiki::Email - Kwiki Email Plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

This module adds a email address preference for the current user.

=head1 AUTHOR

Alexander Goller <decay@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Alexander Goller. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
