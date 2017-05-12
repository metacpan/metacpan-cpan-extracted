package Evo::Internal::Exception;
use Evo;

sub import($class) {
  my $caller = caller;
  no strict 'refs';    ## no critic
  *{"${caller}::exception"} = \&exception;
}

sub exception($sub) : prototype(&) {
  local $@;
  eval { $sub->() };
  $@;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Evo::Internal::Exception

=head1 VERSION

version 0.0403

=head1 AUTHOR

alexbyk.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by alexbyk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
