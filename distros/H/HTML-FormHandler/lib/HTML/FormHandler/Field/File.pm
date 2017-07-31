package HTML::FormHandler::Field::File;
# ABSTRACT: simple file field; does no processing
$HTML::FormHandler::Field::File::VERSION = '0.40068';
use Moose;
extends 'HTML::FormHandler::Field';


has '+widget' => ( default => 'Upload' );
has '+type_attr' => ( default => 'file' );

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::File - simple file field; does no processing

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

This field does nothing and is here mainly for testing purposes. If you use this
field you'll have to handle the actual uploaded file yourself.

See L<HTML::FormHandler::Field::Upload>

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
