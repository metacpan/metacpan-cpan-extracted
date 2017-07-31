package HTML::FormHandler::Field::NonEditable;
# ABSTRACT: reset field
$HTML::FormHandler::Field::NonEditable::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field::NoValue';


has '+widget' => ( default => 'Span' );

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::NonEditable - reset field

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Another flavor of a display field, but unlike L<HTML::FormHandler::Field::Display>
it's intended to be rendered somewhat more like a "real" field, like the
'non-editable' "fields" in Bootstrap.

   has_field 'source' => ( type => 'NonEditable', value => 'Outsourced' );

By default uses the 'Span' widget.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
