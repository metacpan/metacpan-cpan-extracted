package JSONSchema::Validator::Constraints::Draft7;

# ABSTRACT: JSON Schema Draft7 specification constraints

use strict;
use warnings;

use JSONSchema::Validator::JSONPointer 'json_pointer';
use JSONSchema::Validator::Error 'error';
use JSONSchema::Validator::Util qw(is_type serialize unbool);

use parent 'JSONSchema::Validator::Constraints::Draft6';

sub if {
    my ($self, $instance, $if, $schema, $instance_path, $schema_path, $data) = @_;

    my $errors = $data->{errors};
    $data->{errors} = [];

    my $result = $self->validator->_validate_schema($instance, $if, $instance_path, $schema_path, $data);
    $data->{errors} = $errors;
    if ($result) {
        return 1 unless exists $schema->{then};
        my $then = $schema->{then};
        my $spath = json_pointer->append($schema_path, 'then');
        return $self->validator->_validate_schema($instance, $then, $instance_path, $spath, $data);
    }

    return 1 unless exists $schema->{else};
    my $else = $schema->{else};
    my $spath = json_pointer->append($schema_path, 'else');
    return $self->validator->_validate_schema($instance, $else, $instance_path, $spath, $data);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JSONSchema::Validator::Constraints::Draft7 - JSON Schema Draft7 specification constraints

=head1 VERSION

version 0.006

=head1 AUTHORS

=over 4

=item *

Alexey Stavrov <logioniz@ya.ru>

=item *

Ivan Putintsev <uid@rydlab.ru>

=item *

Anton Fedotov <tosha.fedotov.2000@gmail.com>

=item *

Denis Ibaev <dionys@gmail.com>

=item *

Andrey Khozov <andrey@rydlab.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
