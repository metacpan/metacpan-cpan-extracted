package Gideon::Plugin;
{
  $Gideon::Plugin::VERSION = '0.0.3';
}
use Moose;

#ABSTRACT: Plugin base class

has next => ( is => 'rw', required => 1 );

sub find_one {
    my $self = shift;
    $self->next->find_one(@_);
}

sub find {
    my $self = shift;
    $self->next->find(@_);
}

sub update {
    my $self = shift;
    $self->next->update(@_);
}

sub save {
    my $self = shift;
    $self->next->save(@_);
}

sub remove {
    my $self = shift;
    $self->next->remove(@_);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Gideon::Plugin - Plugin base class

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

This is the base class all plugins inherit from

=head1 NAME

Gideon::Plugin - Base class for all Plugins

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
