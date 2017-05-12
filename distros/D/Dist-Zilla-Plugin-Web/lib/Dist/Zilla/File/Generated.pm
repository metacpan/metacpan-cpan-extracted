package Dist::Zilla::File::Generated;
$Dist::Zilla::File::Generated::VERSION = '0.0.10';
# ABSTRACT: a file whose content is built on demand and changed later
use Moose;

use namespace::autoclean;

extends 'Dist::Zilla::File::FromCode';

has 'content' => (
    is        => 'rw',
    isa       => 'Str',
    lazy      => 1,
  
    builder   => '_build_content',
);


sub _build_content {
    my ($self) = @_;

    my $code = $self->code;
    
    return $self->$code;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::File::Generated - a file whose content is built on demand and changed later

=head1 VERSION

version 0.0.10

=head1 AUTHOR

Nickolay Platonov <nplatonov@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nickolay Platonov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
