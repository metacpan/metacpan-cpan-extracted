use 5.008;
use strict;
use warnings;
use if $] < 5.010, 'UNIVERSAL::DOES';

{
	package JSON::MultiValueOrdered;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.005';
	
	use base qw(JSON::Tiny::Subclassable);
	
	use Tie::Hash::MultiValueOrdered ();
	
	sub _new_hash { tie my %h, 'Tie::Hash::MultiValueOrdered'; return \%h }
	
	sub _encode_object {
		my $self = shift;
		my $object = shift;
		
		my $indent;
		if (exists $self->{_indent}) {
			$indent = $self->{_indent};
			$self->{_indent} .= "\t";
		}
		
		my @pairs;
		my $space = defined $indent ? q( ) : q();
		my $tied = tied(%$object);
		if ($tied and $tied->DOES('Tie::Hash::MultiValueOrdered')) {
			my @list = $tied->pairs;
			for (my $i = 0; $i < @list; $i+=2) {
				push @pairs, sprintf(
					'%s:%s%s',
					$self->_encode_string($list[$i]),
					$space,
					$self->_encode_values($list[$i + 1]),
				);
			}
		}
		else {
			while (my ($k, $v) = each %$object) {
				push @pairs, sprintf(
					'%s:%s%s',
					$self->_encode_string($k),
					$space,
					$self->_encode_values($v),
				);
			}
		}
		
		if (defined $indent)
		{
			$self->{_indent} =~ s/^.//;
			return "{}" unless @pairs;
			return "\{\n$indent\t" . join(",\n$indent\t", @pairs) . "\n$indent\}";
		}
		else
		{
			return '{' . join(',', @pairs) . '}';
		}
	}
	
	__PACKAGE__->import('j');
}

1;

__END__

=head1 NAME

JSON::MultiValueOrdered - handle JSON like {"a":1, "a":2}

=head1 SYNOPSIS

   use Test::More tests => 4;
   use JSON::MultiValueOrdered;
   
   my $j = JSON::MultiValueOrdered->new;
   isa_ok $j, 'JSON::Tiny';
   
   my $data = $j->decode(<<'JSON');
   {
      "a": 1,
      "b": 2,
      "a": 3,
      "b": 4
   }
   JSON
   
   # As you'd expect, for repeated values, the last value is used
   is_deeply(
      $data,
      { a => 3, b => 4 },
    );
   
   # But hashes within the structure are tied to Tie::Hash::MultiValueOrdered
   is_deeply(
      [ tied(%$data)->get('b') ],
      [ 2, 4 ],
    );
   
   # And the extra information from the tied hash is used when re-encoding
   is(
      $j->encode($data),
      q({"a":1,"b":2,"a":3,"b":4}),
   );
   
   done_testing;

=head1 DESCRIPTION

The JSON specification allows keys to be repeated within objects. It remains
silent on how repeated keys should be interpreted. Most JSON implementations
end up choosing just one of the values; sometimes the first, sometimes the
last.

JSON::MultiValueOrdered is a subclass of L<JSON::Tiny> which treats objects as
ordered lists of key-value pairs, with duplicate keys allowed. It achieves this
by returning all hashes as tied using L<Tie::Hash::MultiValueOrdered>. While
these hashes behave like standard Perl hashes (albeit while preserving the
original order of the keys), they provide a tied object interface allowing you
to retrieve additional values for each key.

JSON::MultiValueOrdered serialisation also serialises these additional values
and preserves order.

JSON::MultiValueOrdered is a subclass of L<JSON::Tiny::Subclassable> and
L<JSON::Tiny>, which is itself a fork of L<Mojo::JSON>. Except where noted,
the methods listed below behave identically to the methods of the same names
in the superclasses.

=head2 Constructor

=over

=item C<< new(%attributes) >>

=back

=head2 Attributes

=over

=item C<< pretty >>

=item C<< error >>

=back

=head2 Methods

=over

=item C<< decode($bytes) >>

=item C<< encode($ref) >>

=item C<< false >>

=item C<< true >>

=back

=head2 Functions

=over

=item C<< j(\@array) >> / C<< j(\%hash) >> / C<< j($bytes) >>

Encode or decode JSON as applicable.

This function may be exported, but is not exported by default. You may
request to import it with a different name:

   use JSON::MultiValueOrdered j => { -as => 'quick_json' };

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=JSON-MultiValueOrdered>.

=head1 SEE ALSO

L<JSON::Tiny::Subclassable>,
L<JSON::Tiny>,
L<Mojo::JSON>.

L<Tie::Hash::MultiValueOrdered>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

