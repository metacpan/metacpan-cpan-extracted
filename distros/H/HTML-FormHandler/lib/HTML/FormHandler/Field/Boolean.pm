package HTML::FormHandler::Field::Boolean;
# ABSTRACT: a true or false field
$HTML::FormHandler::Field::Boolean::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::Checkbox';


sub value {
    my $self = shift;

    my $v = $self->next::method(@_);

    return $v ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Boolean - a true or false field

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

This field returns 1 if true, 0 if false.  The widget type is 'Checkbox'.
Similar to Checkbox, except only returns values of 1 or 0.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
