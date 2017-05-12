package List::AssignRef;

use 5.006;
use strict;
use warnings;
use LV qw( lvalue );
use Carp qw( confess );
use Scalar::Util qw( reftype );

use constant {
	SCALAR   => 'SCALAR',
	ARRAY    => 'ARRAY',
	HASH     => 'HASH',
};

use constant {
	ERR_UNSUPPORTED => "Unsupported reference type: %s",
	ERR_MISMATCH    => "Reference type mismatch: %s vs %s",
};

BEGIN {
	$List::AssignRef::AUTHORITY = 'cpan:TOBYINK';
	$List::AssignRef::VERSION   = '0.004';
}

use Exporter::Shiny our @EXPORT = qw( deref );

sub _confessf
{
	my $fmt = shift;
	confess sprintf $fmt, @_;
}

sub deref (\[$@%]) :lvalue
{
	my $given = shift;
	lvalue get => sub {
		reftype($given) eq SCALAR ? $$given :
		reftype($given) eq ARRAY  ? @$given :
		reftype($given) eq HASH   ? %$given :
		_confessf(ERR_UNSUPPORTED, reftype($given));
	},
	set => sub {
		my $assign = shift;
		reftype($given) eq reftype($assign)
			or _confessf(ERR_MISMATCH, reftype($given), reftype($assign));
		reftype($given) eq SCALAR ? ($$given = $$assign):
		reftype($given) eq ARRAY  ? (@$given = @$assign):
		reftype($given) eq HASH   ? (%$given = %$assign):
		_confessf(ERR_UNSUPPORTED, reftype($given));
	}
}

1;

__END__

=head1 NAME

List::AssignRef - assign an arrayref to an array sensibly

=head1 SYNOPSIS

	# You can't do this in Perl...
	
	my \@array = $arrayref;
	
	# But you can do this...
	
	use List::AssignRef;
	deref my @array = $arrayref;

=head1 DESCRIPTION

OK, so you might ask yourself, why would you want to do this:

	my \@array = $arrayref;

When you can just do this:

	my @array = @{ $arrayref };

Well, in that simple case List::AssignRef is overkill.

However, what about cases when you have a function that returns a list of
arrayrefs, such as C<part> from L<List::MoreUtils>. For example:

	my ($staff, $managers) = part { $_->title =~ /Manager/ } @employees;

If you want C<< @staff >> and C<< @managers >> arrays (as against arrayrefs),
you need to dereference each separately. Something like:

	my @parted = part { $_->title =~ /Manager/ } @employees;
	my @staff    = @{$parted[0]};
	my @managers = @{$parted[1]};

List::AssignRef makes this slightly prettier:

	(deref my @staff, deref my @managers)
		= part { $_->title =~ /Manager/ } @employees;

List::AssignRef exports exactly one function...

=over

=item C<< deref ARRAY|HASH|SCALAR >>

C<deref> must be given a (non-reference) array, hash or scalar. It acts as
an lvalue, allowing a reference array, hash or scalar respectively to be
assigned to it.

=back

This module uses L<Exporter::Shiny> which means that you can rename the
exported function easily:

	use List::AssignRef deref => { -as => 'dereference' };

=head1 LEGACY PERL SUPPORT

The examples above rely on a parsing improvement in Perl 5.14. Although this
module does support earlier versions of Perl (5.6 and above), prior to 5.14
you may need to add additional parentheses:

	(deref(my @staff), deref(my @managers))
		= part { $_->title =~ /Manager/ } @employees;

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=List-AssignRef>.

=head1 SEE ALSO

L<List::Util>,
L<List::MoreUtils>.

L<Ref::List> is not dissimilar but without the prototype trickery and lvalue
stuff, so doesn't satisfy this module's use case.

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

