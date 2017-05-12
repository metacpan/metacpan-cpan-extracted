package Hash::DefaultValue;

use 5.006;
use strict;
use warnings;
use utf8;

use Tie::Hash qw();
use Carp qw(croak);

use constant {
	IDX_HASH   => 0,
	IDX_CODE   => 1,
	NEXT_IDX   => 2,
};
use constant _default => undef;

BEGIN {
	no warnings 'once';
	$Hash::DefaultValue::AUTHORITY = 'cpan:TOBYINK';
	$Hash::DefaultValue::VERSION   = '0.007';
	@Hash::DefaultValue::ISA       = qw(Tie::ExtraHash);
}

sub TIEHASH
{
	my $class    = shift;
	my $coderef  = @_ ? shift : $class->_default;

	unless (ref $coderef)
	{
		my $value = $coderef;
		$coderef = sub { $value };
	}
	
	unless (ref $coderef eq 'CODE')
	{
		croak "must provide a coderef or non-reference scalar value for $class";
	}
	
	$class->SUPER::TIEHASH($coderef)
}

sub FETCH
{
	my ($this, $key)  = @_;
	$key = '' unless defined $key;
	
	unless (exists $this->[IDX_HASH]{$key})
	{
		local $_ = $key;
		return scalar $this->[IDX_CODE]($this->[IDX_HASH], $key);
	}
	
	$this->[IDX_HASH]{$key}
}

__PACKAGE__
__END__

=head1 NAME

Hash::DefaultValue - create a hash where the default value ain't undef

=head1 SYNOPSIS

  use 5.010;
  use Hash::DefaultValue;
  
  tie my %hash, 'Hash::DefaultValue', 42;
  say $hash{the_answer};  # says 42

=head1 DESCRIPTION

Normally, if you try fetching a value from a hash where the key does
not exist, you get undef.

  my %hash;
  if (defined $hash{foobar}) {
    say "this will not happen!";
  }

Hash::DefaultValue allows you to choose another value instead of
undef. It tried to avoid changing any other part of the hash's
behaviour. For example, it doesn't automatically create any hash
keys that Perl wouldn't normally autovivify.

  tie my %hash, 'Hash::DefaultValue', 42;
  say $hash{the_answer};                    # says 42
  my $exists = exists $hash{the_answer};    # false
  say keys %hash;                           # says nothing

And of course you can still store explicit values in the hash, as
you'd expect:

  tie my %hash, 'Hash::DefaultValue', 42;
  $hash{monkey} = 'Bobo';
  say $hash{the_answer};     # says 42
  say $hash{monkey};         # says "Bobo"

Delete operations on the hash are vaguely interesting:

  tie my %hash, 'Hash::DefaultValue', 42;
  $hash{monkey} = 'Bobo';
  my $the_answer = delete $hash{the_answer};  # undef
  my $monkey     = delete $hash{monkey};      # "Bobo"

=head2 Allowed Default Values

Any non-reference scalar can be used as a default value.

Coderefs can be used too, in which case when a default value is being
fetched the coderef will be evaluated (in scalar context) and the return
value used as the default. The coderef will have a reference to the tied
hash, and the key being fetched passed as arguments. Additionally, the
key will be available in C<< $_ >> which often makes for nicer looking
code.

  tie my %hash, 'Hash::DefaultValue', sub { $_ + 10 };
  say $hash{32};     # says 42
  say $hash{monkey}; # says 10

Other references are disallowed, which provides a handy extensibility
point in the future. If you want to use some other reference, then wrap
it in a coderef.

  tie my %hash, 'Hash::DefaultValue', sub { \@foo };

=head2 Alias

The L<aliased> module allows you to define aliases for class names, and
works great for tie implementations.

  use aliased 'Hash::DefaultValue' => 'HDV';
  tie my %hash, HDV, 42;

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Hash-DefaultValue>.

=head1 SEE ALSO

L<Hash::Missing> is a subclass of this module.

L<Hash::WithDefaults> allows you to default particular keys by
providing a template hashref.

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

