BEGIN { print "1..1\n"; }
use Inline C => <<'END', FILTERS => [Strip_POD => 'Preprocess'];

=head1 FOO

This code must be preprocessed before parsing.

=cut

void foo(int a
#ifdef FOO_GETS_B
	, int b
#endif
	) { printf("ok %i\n", a); }

END

foo(1);
