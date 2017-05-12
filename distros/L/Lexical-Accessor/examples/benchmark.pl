use v5.14;
use Benchmark qw( cmpthese );

package Using_LexicalAccessor {
	use Moose;
	use Types::Standard 'Int';
	use Lexical::Accessor;
	
	my $foo;
	lexical_has foo => (
		isa      => Int,
		accessor => \$foo,
	);
	
	sub go {
		my $self = shift;
		$self->$foo(0);
		for (1..1000) {
			$self->$foo( $self->$foo + 1 );
		}
	}
	
	__PACKAGE__->meta->make_immutable;
}

package Using_PrivateAttributes {
	use Moose;
	use Types::Standard 'Int';
	use MooX::PrivateAttributes;
	
	private_has foo => (
		isa      => Int,
		accessor => 'foo',
	);
	
	sub go {
		my $self = shift;
		$self->foo(0);
		for (1..1000) {
			$self->foo( $self->foo + 1 );
		}
	}
	
	__PACKAGE__->meta->make_immutable;
}

package Using_Moose {
	use Moose;
	use Types::Standard 'Int';
	
	has foo => (
		isa      => Int,
		accessor => '_foo',
	);
	
	sub go {
		my $self = shift;
		$self->_foo(0);
		for (1..1000) {
			$self->_foo( $self->_foo + 1 );
		}
	}
	
	__PACKAGE__->meta->make_immutable;
}

package Using_MooseXPrivacy {
	use Moose;
	use MooseX::Privacy;
	use Types::Standard 'Int';
	
	has foo => (
		isa      => Int,
		accessor => 'foo',
		traits   => ['Private'],
	);
	
	sub go {
		my $self = shift;
		$self->foo(0);
		for (1..1000) {
			$self->foo( $self->foo + 1 );
		}
	}
	
	__PACKAGE__->meta->make_immutable;
}

my @implementations = qw( LexicalAccessor PrivateAttributes Moose MooseXPrivacy );
my $horror = 0;

for (@implementations)
{
	my $obj = "Using_$_"->new;
	do { $horror++; say "Something went horribly wrong with $obj!" } if eval { $obj->foo; 1 };
}

exit(1) if $horror;

cmpthese(-3, +{
	map { my $class = "Using_$_"; $_ => qq[ $class\->new->go ] } @implementations
});

__END__
                    Rate MooseXPrivacy PrivateAttributes LexicalAccessor   Moose
MooseXPrivacy     4.47/s            --              -86%            -95%    -95%
PrivateAttributes 31.4/s          601%                --            -63%    -63%
LexicalAccessor   85.1/s         1803%              171%              --     -0%
Moose             85.4/s         1809%              172%              0%      --
