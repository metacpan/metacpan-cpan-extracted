package Keyword::Anonymous::Object;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';

use Anonymous::Object;

use base 'Import::Export';

our %EX = (
        object => [qw/all/]
);

our $ANON = Anonymous::Object->new({
        object_name => 'Keyword::Object::Anon'
});

sub object (\$@) {
        my (undef, $val, %spec) = @_;

        %spec = _build_spec(%spec);

        my $ref = ref $val;

        my $anon = $ref eq 'HASH' ? $ANON->hash_to_nested_object($val, %spec)
                : $ref eq 'ARRAY' ? $ANON->array_to_nested_object($val, %spec)
                : die "cannot create Anonymous::Object";

        ${$_[0]} = $anon;

        return $_[0];
}

sub _build_spec {
        return (
                clearer => 1,
                predicate => 1,
                get => 1,
                set => 1,
                ref => 1,
                reftype => 1,
                autotype => 1,
                @_
        );
}

1;

__END__

=head1 NAME

Keyword::Anonymous::Object - anonymous objects

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

	use Keyword::Anonymous::Object qw/object/;

	object my $obj => {
		a => {
			b  => {
				c => 1
			}
		}
		d => [1, 2, { e => 2 }],
	};
	
	$obj->a->b->c; # 1
	$obj->d->[2]->e; # 2 

	$obj->has_a;
	$obj->get_a;
	$obj->set_a({ ... });
	$obj->ref_a;
	$obj->reftype_a;
	$obj->clear_a;


=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 object

This module exports a single keyword object that expects a scalar variable as its first argument, followed by either an array reference or a hash reference as the value of that scalar. Additional optional parameters can be provided to disable certain functionality.


	object my $obj => {
		a => 1,
		b => 2,
		c => 3
	}, set => 0, autotype => 0;

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-keyword-anonymous-object at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Keyword-Anonymous-Object>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Keyword::Anonymous::Object


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Keyword-Anonymous-Object>

=item * Search CPAN

L<https://metacpan.org/release/Keyword-Anonymous-Object>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Keyword::Anonymous::Object
