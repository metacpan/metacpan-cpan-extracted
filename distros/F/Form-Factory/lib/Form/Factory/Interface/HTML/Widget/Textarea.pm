package Form::Factory::Interface::HTML::Widget::Textarea;
$Form::Factory::Interface::HTML::Widget::Textarea::VERSION = '0.022';
use Moose;

extends qw( Form::Factory::Interface::HTML::Widget::Element );

# ABSTRACT: HTML interface widget helper


has '+tag_name' => (
    default   => 'textarea',
);

has name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has rows => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_rows',
);

has cols => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_cols',
);

sub has_content { 1 }

override more_attributes => sub {
    my $self = shift;

    my %attributes = (
        name => $self->name,
    );

    $attributes{rows} = $self->rows if $self->has_rows;
    $attributes{cols} = $self->cols if $self->has_cols;

    return \%attributes;
};

sub consume_control {
    my ($self, %options) = @_;
    my $params = $options{params};
    my $name   = $self->name;

    return { $name => $params->{ $name } };
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Interface::HTML::Widget::Textarea - HTML interface widget helper

=head1 VERSION

version 0.022

=head1 DESCRIPTION

Move along. Nothing to see here.

=for Pod::Coverage   .*

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
