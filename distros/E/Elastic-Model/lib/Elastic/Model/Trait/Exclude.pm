package Elastic::Model::Trait::Exclude;
$Elastic::Model::Trait::Exclude::VERSION = '0.52';
use Moose::Role;
use Moose::Exporter;
use MooseX::Types::Moose qw(Bool);
use namespace::autoclean;

Moose::Exporter->setup_import_methods(
    role_metaroles =>
        { applied_attribute => ['Elastic::Model::Trait::Exclude'], },
    class_metaroles => { attribute => ['Elastic::Model::Trait::Exclude'] },
);

has 'exclude' => ( isa => Bool, is => 'ro', default => 1 );

1;

=pod

=encoding UTF-8

=head1 NAME

Elastic::Model::Trait::Exclude - An internal use trait

=head1 VERSION

version 0.52

=head1 DESCRIPTION

This trait is used by Elastic::Model doc attributes which shouldn't be
stored in Elasticsearch. It implements just the
L<Elastic::Model::Trait::Field/"exclude"> keyword.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: An internal use trait

