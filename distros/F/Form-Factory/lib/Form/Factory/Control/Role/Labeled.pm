package Form::Factory::Control::Role::Labeled;
$Form::Factory::Control::Role::Labeled::VERSION = '0.022';
use Moose::Role;

# ABSTRACT: labeled controls


has label => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    builder   => '_build_label',
    lazy      => 1,
);

sub _build_label {
    my $self = shift;
    my $label = $self->name;
    $label =~ s/_/ /g;
    $label =~ s/\b(\w)/\U$1\E/g;
    return $label;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Control::Role::Labeled - labeled controls

=head1 VERSION

version 0.022

=head1 DESCRIPTION

Implemented by any control with a label.

=head1 ATTRIBUTES

=head2 label

The label. By default it is created from the control's name.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
