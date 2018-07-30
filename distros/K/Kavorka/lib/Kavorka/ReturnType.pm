use 5.014;
use strict;
use warnings;

package Kavorka::ReturnType;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';
our @CARP_NOT  = qw( Kavorka::Signature Kavorka::Sub Kavorka );

use Carp qw( croak );
use Parse::Keyword {};
use Parse::KeywordX qw(parse_trait);

use Moo;
use namespace::sweep;

has package         => (is => 'ro');
has type            => (is => 'ro');
has traits          => (is => 'ro', default => sub { +{} });

sub coerce  { !!shift->traits->{coerce} }
sub list    { !!shift->traits->{list} }
sub assumed { !!shift->traits->{assumed} }

sub BUILD
{
	my $self = shift;
	
	# traits handled natively
	state $native_traits = {
		coerce    => 1,
		list      => 1,
		scalar    => 1,
	};
	
	my @custom_traits =
		map  "Kavorka::TraitFor::ReturnType::$_",
		grep !exists($native_traits->{$_}),
		keys %{$self->traits};
	
	'Moo::Role'->apply_roles_to_object($self, @custom_traits) if @custom_traits;
}

sub parse
{
	my $class = shift;
	my %args = @_;
	
	lex_read_space;
	
	my %traits = ();
	
	my $type;
	my $peek = lex_peek(1000);
	if ($peek =~ /\A[^\W0-9]/)
	{
		my $reg = do {
			require Type::Registry;
			require Type::Utils;
			my $tmp = 'Type::Registry::DWIM'->new;
			$tmp->{'~~chained'} = $args{package};
			$tmp->{'~~assume'}  = 'Type::Tiny::Class';
			$tmp;
		};
		
		require Type::Parser;
		($type, my($remaining)) = Type::Parser::extract_type($peek, $reg);
		my $len = length($peek) - length($remaining);
		lex_read($len);
		lex_read_space;
	}
	elsif ($peek =~ /\A\(/)
	{
		lex_read(1);
		lex_read_space;
		my $expr = parse_listexpr
			or croak('Could not parse type constraint expression as listexpr');
		lex_read_space;
		lex_peek eq ')'
			or croak("Expected ')' after type constraint expression");
		lex_read(1);
		lex_read_space;
		
		require Types::TypeTiny;
		$type = Types::TypeTiny::to_TypeTiny( scalar $expr->() );
		$type->isa('Type::Tiny')
			or croak("Type constraint expression did not return a blessed type constraint object");
	}
	else
	{
		croak("Expected return type!");
	}
	
	undef($peek);
	
	while (lex_peek(5) =~ m{ \A (is|does|but) \s }xsm)
	{
		lex_read(length($1));
		lex_read_space;
		my ($name, undef, $args) = parse_trait;
		$traits{$name} = $args;
		lex_read_space;
	}
	
	return $class->new(
		%args,
		type           => $type,
		traits         => \%traits,
	);
}

sub sanity_check
{
	my $self = shift;
	
	croak("Return type cannot coerce and be assumed")
		if $self->assumed && $self->coerce;
	
	();
}

sub _effective_type
{
	my $self = shift;
	$self->type;
}

1;
