package Plack::Handler::Martian;

use strict;
use Martian::Server;

sub new
{
    my $class = shift;
    bless { @_ }, $class;
}

sub run
{
    my ($self, $app) = @_;
    Martian::Server->new->run($app, {%$self});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Handler::Martian

=head1 VERSION

version 0.08

=head1 DESCRIPTION

=head1 NAME

Plack::Handler::Martian

=head1 METHODS

=head2 new

=head2 run

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
