package Exobrain::JSONify;
use Moose::Role;
use Storable qw(dclone);
use Data::Structure::Util qw(unbless);

# Basic role that allows converting self object into JSON.
# Really we should use MooseX::Storage instead.

sub TO_JSON {
    my ($self) = @_;

    return unbless dclone $self;   # Yuck!
}


1;

__END__

=pod

=head1 NAME

Exobrain::JSONify

=head1 VERSION

version 1.08

=for Pod::Coverage TO_JSON

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
