package HTML::WidgetValidator::Widget;
use base qw(Class::Data::Inheritable);
use warnings;
use strict;

__PACKAGE__->mk_classdata('models'      => [] );
__PACKAGE__->mk_classdata('name'        => undef );
__PACKAGE__->mk_classdata('url'         => undef );
__PACKAGE__->mk_classdata('description' => '' );

1;
__END__

=head1 NAME

HTML::WidgetValidator::Widget


=head1 DESCRIPTION

Base class for objects which describe widget pattern.


=head1 SEE ALSO

L<HTML::WidgetDetector>
L<Class::Data::Inheritable>


=head1 AUTHOR

Takaaki Mizuno  C<< <mizuno_takaaki@hatena.ne.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) Hatena Inc. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
