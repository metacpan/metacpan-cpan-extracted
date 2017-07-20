package Evo::Class::Base;
use Evo '/::Meta; -Internal::Util';

my $META = Evo::Class::Meta->register(__PACKAGE__);

Evo::Internal::Util::monkey_patch __PACKAGE__, new => $META->attrs->gen_new;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Class::Base

=head1 VERSION

version 0.0405

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
