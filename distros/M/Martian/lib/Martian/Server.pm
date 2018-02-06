package Martian::Server;

use strict;
use base 'Starman::Server';
use BSD::Resource;

sub done
{
    my $self = shift;
    return 1 if $self->SUPER::done(@_);
    my $rus = getrusage();
    my $memory_soft_cap = $self->{options}->{memory_limit} // 148680;
    if ( $rus->{maxrss} >= $memory_soft_cap ) {
        $self->log(2, "Maximum memory exceeded, this child will not serve more requests");
        return 1 ;
    }

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Martian::Server

=head1 VERSION

version 0.08

=head1 DESCRIPTION

=head1 NAME

Martian::Server

=head1 METHODS

=head2 done

=head1 ATTRIBUTES

=head1 LICENSE AND COPYRIGHT

Copyright 2013 OpusVL.

This software is licensed according to the "IP Assignment Schedule" provided with the development project.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
