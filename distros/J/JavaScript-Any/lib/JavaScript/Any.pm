use 5.008003;
use strict;
use warnings;

package JavaScript::Any;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Exporter::Shiny qw( jseval );

sub _generate_jseval {
	my $me = shift;
	my ($name, $args) = @_;
	return sub {
		my $code = shift;
		my $ctx  = $me->new_context($args or {});
		$ctx->eval($code);
	};
}

my $IMPLEMENTATION;
my @IMPLEMENTATIONS = qw(
	JavaScript::Any::Context::V8
	JavaScript::Any::Context::Duktape
	JavaScript::Any::Context::JE
);

sub new_context {
	my $me   = shift;
	my $args = ref($_[0]) eq 'HASH' ? $_[0] : +{ @_ };
	
	my $impl = delete($args->{implementation})
		|| ($IMPLEMENTATION ||= $me->implementation);
	
	# ehhh, should probably load $impl.
	
	$impl->new($args);
}

sub implementation {
	return $IMPLEMENTATION if defined $IMPLEMENTATION;
	
	for my $try (@IMPLEMENTATIONS) {
		eval "require $try" or next;
		return $try;
	}
	
	require Carp;
	Carp::croak("No Javascript implementation available. Please install JavaScript::Duktape or JE");
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

JavaScript::Any - evaluate some javascript using the best available Javascript implementation

=head1 SYNOPSIS

  use JavaScript::Any qw( jseval );
  
  my $sum = jseval('1 + 2');   # 3

Or:

  use JavaScript::Any;
  
  my $context = JavaScript::Any->new_context;
  $context->define( say => sub { print @_, "\n" } );
  $context->eval('say(1 + 2)');

=head1 DESCRIPTION

This module is a thin wrapper around L<JavaScript::V8>,
L<JavaScript::Duktape>, and L<JE>, allowing you to evaluate strings of
Javascript code from Perl.

=head2 Status

This is a very early alpha version. The API still needs documenting and
cleaning up a lot.

In particular, the API for defining custom Javascript functions exposes
differences between the alternative Javascript implementations. Future
versions of JavaScript::Any will smooth some of these out.

=head2 Functional Interface

This module can export one function. It is not exported by default.

=over

=item C<< jseval($str) >>

Evaluates the string of Javascript in a fresh context and returns
the result.

=back

=head2 Object-Oriented Interface

For more advanced features, use the object-oriented interface.

=over

=item C<< JavaScript::Any->new_context(%opts) >>

Factory method returning an object which implements the
L<JavaScript::Any::Context> API.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=JavaScript-Any>.

=head1 SEE ALSO

L<JavaScript::Any::Context>.

L<JavaScript::V8>,
L<JavaScript::Duktape>,
L<JE>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

