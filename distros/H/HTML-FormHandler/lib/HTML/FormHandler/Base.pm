package HTML::FormHandler::Base;
# ABSTRACT: stub
$HTML::FormHandler::Base::VERSION = '0.40068';
use Moose;

with 'HTML::FormHandler::Widget::Form::Simple';

# here to make it possible to combine the Blocks role with a role
# setting the render_list without an 'excludes'
sub has_render_list { }
sub build_render_list {[]}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Base - stub

=head1 VERSION

version 0.40068

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
