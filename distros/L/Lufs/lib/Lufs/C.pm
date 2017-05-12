package Lufs::C;

use vars qw/$AUTOLOAD/;
use base 'Lufs::Glue';

our $object;
our %config;

sub AUTOLOAD {
    my $method = (split/::/,$AUTOLOAD)[-1];
    $method eq 'DESTROY' && return;
	my $ret = $object->$method(@_);
	$object->TRACE($method, @_, $ret);
	$ret;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Lufs::C - C interface to perl

=head1 ABSTRACT

This interface is used by the C code to call the perl subs.

=head1 SEE ALSO

C<perlfs.c>

=head1 AUTHOR

Raoul Zwart, E<lt>rlzwart@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Raoul Zwart

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
