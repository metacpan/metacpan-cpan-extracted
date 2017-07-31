package HTML::FormHandler::Widget::Wrapper::None;
# ABSTRACT: wrapper that doesn't wrap
$HTML::FormHandler::Widget::Wrapper::None::VERSION = '0.40068';

use Moose::Role;

sub wrap_field { "\n" . $_[2] }

use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Wrapper::None - wrapper that doesn't wrap

=head1 VERSION

version 0.40068

=head1 DESCRIPTION

This wrapper does nothing except return the 'bare' rendered form element,
as returned by the 'widget'. It does not add errors or anything else.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
