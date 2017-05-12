package Form::Factory::Interface::HTML::Widget::Element;
$Form::Factory::Interface::HTML::Widget::Element::VERSION = '0.022';
use Moose;

with qw( Form::Factory::Interface::HTML::Widget );

# ABSTRACT: HTML interface widget helper


has tag_name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has id => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_id',
);

has classes => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    required  => 1,
    default   => sub { [] },
);

has attributes => (
    is        => 'ro',
    isa       => 'HashRef[Str]',
    required  => 1,
    default   => sub { {} },
);

has content => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_content',
);

sub has_content {
    my $self = shift;
    return $self->_has_content;
}

sub render_control {
    my ($self, %options) = @_;

    my $html = '<' . $self->tag_name;
    $html .= $self->render_id(%options);
    $html .= $self->render_class(%options);
    $html .= $self->render_attributes(%options);

    if ($self->has_content) {
        $html .= '>';
        $html .= $self->render_content(%options);
        $html .= '</' . $self->tag_name . '>';
    }

    else {
        $html .= '/>';
    }

    return $html;
}

sub render_content {
    my $self = shift;
    my $content = $self->content;
    return $self->content || '';
}

sub render_id {
    my $self = shift;
    return '' unless $self->has_id;
    return ' id="' . $self->id . '"';
}

sub render_class {
    my $self = shift;

    my @classes = ('form', @{ $self->classes });
    return ' class="' . join(' ', @classes) . '"';
}

sub render_attributes {
    my $self = shift;
    my @attributes;

    my %attributes = (
        %{ $self->attributes },
        %{ $self->more_attributes },
    );

    while (my ($name, $value) = each %attributes) {
        push @attributes, $name . '="' . $value . '"';
    }

    return join ' ', @attributes;
}

sub more_attributes { {} }

sub consume_control { }


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Interface::HTML::Widget::Element - HTML interface widget helper

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
