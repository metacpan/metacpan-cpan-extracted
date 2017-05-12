#!perl -w
# fix "panic: malloc" error in fieldhash_key_free()
use strict;
use constant HAS_WEAKEN => eval {
    require Scalar::Util;
    Scalar::Util->import('weaken');
    return 1;
};
use if !HAS_WEAKEN, 'Test::More' => 'skip_all', 'missing weaken()';
use Test::More tests => 2;

BEGIN{
	package Hook::Finalizer;
	use Hash::FieldHash qw(:all);
	use Scalar::Util qw(weaken);

	fieldhash my %finalizers_of;

	sub add_finalizer{

		my $ref  = shift;
		my $code = shift;

		my $finalizers_ref = $finalizers_of{$ref} ||= bless [];

		unshift @_, $code, $ref;

		unshift @{$finalizers_ref}, \@_; # $code, $ref, @args
		weaken $_[1]; # $ref

		return $ref;
	}

	sub DESTROY{
		my($finalizers_ref) = @_;

		foreach my $finalizer (@{$finalizers_ref}){
			my $code = shift @{$finalizer};

			$code->(@{$finalizer});
		}
	}
}
use Scalar::Util qw(weaken);
{
	my $a = [42];
	my $b = $a;
	weaken $b;
	Hook::Finalizer::add_finalizer $a => sub{ my @a = @_;  pass 'in finalizer'; };
}
pass 'scope out';
