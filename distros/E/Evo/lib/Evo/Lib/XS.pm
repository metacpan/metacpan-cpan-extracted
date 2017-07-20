package Evo::Lib::XS;
use Evo 'XSLoader; -Export';

our $VERSION = '0.0405';    # VERSION

# to be able to run with and without dzil
my $version = eval '$VERSION';    ## no critic
$version ? XSLoader::load(__PACKAGE__, $version) : XSLoader::load(__PACKAGE__);

export('try');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Lib::XS

=head1 VERSION

version 0.0405

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
