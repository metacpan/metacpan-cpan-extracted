package Object::WithIntAndString;
use 5.006001;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Object::WithIntAndString', $VERSION);

1;
__END__

=head1 NAME

Object::WithIntAndString - A tiny C++ class example that holds a string and an int

=head1 SYNOPSIS

  use Object::WithIntAndString;
  my $o = Object::WithIntAndString->new;
  $o->SetString("foo");
  print $o->GetString(), "\n";
  $o->SetInt(5);
  print $o->GetInt(), "\n";

=head1 DESCRIPTION

Simply an XS++ example!

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
