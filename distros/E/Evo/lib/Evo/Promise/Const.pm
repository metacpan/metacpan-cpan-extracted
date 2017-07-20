package Evo::Promise::Const;
use Evo '-Export *';

use constant {PENDING => 'PENDING', REJECTED => 'REJECTED', FULFILLED => 'FULFILLED'};

export qw(PENDING REJECTED FULFILLED);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Promise::Const

=head1 VERSION

version 0.0405

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
