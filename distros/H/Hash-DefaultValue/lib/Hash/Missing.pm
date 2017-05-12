package Hash::Missing;

use 5.006;
use strict;
use warnings;
use utf8;

use Carp qw(carp);

use constant _default => sub {
	carp "missing hash key: $_";
	return undef;
};

BEGIN {
	require Hash::DefaultValue;
	no warnings 'once';
	$Hash::Missing::AUTHORITY = 'cpan:TOBYINK';
	$Hash::Missing::VERSION   = '0.007';
	@Hash::Missing::ISA       = qw(Hash::DefaultValue);
}

__PACKAGE__
__END__

=head1 NAME

Hash::Missing - a hash that warns when retrieving non-existent keys

=head1 SYNOPSIS

  use 5.010;
  use Hash::Missing;
  
  tie my %hash, 'Hash::Missing';
  my $foo = $hash{foo};  # warns

=head1 DESCRIPTION

This is a trivial subclass of Hash::DefaultValue. The example in the
SYNOPSIS could be written:

  use 5.010;
  use Hash::DefaultValue;
  
  tie my %hash, 'Hash::DefaultValue', sub {
     carp "missing hash key: $_";
     return undef;
  };
  my $foo = $hash{foo};  # warns

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Hash-DefaultValue>.

=head1 SEE ALSO

L<Hash::DefaultValue>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

