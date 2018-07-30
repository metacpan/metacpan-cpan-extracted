use 5.014;
use strict;
use warnings;

use Kavorka::Parameter ();
use Role::Tiny ();

my $DETECT_OO = do {
	my %_detect_oo; # memoize
	sub {
		my $pkg = $_[0];
		
		return $_detect_oo{$pkg} if exists $_detect_oo{$pkg};
		
		if ($pkg->can("meta"))
		{
			my $meta = $pkg->meta;
			
			return $_detect_oo{$pkg} = "Moo::Role"
				if 'Role::Tiny'->is_role($pkg)
				&& ref($meta) eq "Moo::HandleMoose::FakeMetaClass";
			return $_detect_oo{$pkg} = "Moo"
				if ref($meta) eq "Moo::HandleMoose::FakeMetaClass";
			return $_detect_oo{$pkg} = "Mouse"
				if $meta->isa("Mouse::Meta::Module");
			return $_detect_oo{$pkg} = "Moose"
				if $meta->isa("Moose::Meta::Class");
			return $_detect_oo{$pkg} = "Moose"
				if $meta->isa("Moose::Meta::Role");
		}
		
		return $_detect_oo{$pkg} = "Role::Tiny"
			if 'Role::Tiny'->is_role($pkg);
		
		return $_detect_oo{$pkg} = "";
	}
};

my $INSTALL_MM = sub {
	my ($modification, $names, $code) = @_;
	
	for my $name (@$names)
	{
		my ($package, $method) = ($name =~ /\A(.+)::(\w+)\z/);
		my $OO = $package->$DETECT_OO;
		
		if ($OO eq 'Moose')
		{
			require Moose::Util;
			my $installer = sprintf('add_%s_method_modifier', $modification);
			Moose::Util::find_meta($package)->$installer($method, $code);
		}
		
		elsif ($OO eq 'Mouse')
		{
			require Mouse::Util;
			my $installer = sprintf('add_%s_method_modifier', $modification);
			Mouse::Util::find_meta($package)->$installer($method, $code);
		}
		
		elsif ($OO eq 'Role::Tiny')
		{
			require Class::Method::Modifiers;
			push @{$Role::Tiny::INFO{$package}{modifiers}||=[]}, [ $modification, $method, $code ];
		}
		
		elsif ($OO eq 'Moo::Role')
		{
			require Class::Method::Modifiers;
			push @{$Role::Tiny::INFO{$package}{modifiers}||=[]}, [ $modification, $method, $code ];
			$OO->_maybe_reset_handlemoose($package);
		}
		
		elsif ($OO eq 'Moo')
		{
			require Class::Method::Modifiers;
			require Moo::_Utils;
			Moo::_Utils::_install_modifier($package, $modification, $method, $code);
		}
		
		else
		{
			require Class::Method::Modifiers;
			Class::Method::Modifiers::install_modifier($package, $modification, $method, $code);
		}
	}
};

package Kavorka::MethodModifier;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Parse::Keyword {};
use Parse::KeywordX;
use Scalar::Util qw(reftype);

use Moo::Role;
with 'Kavorka::Sub';
use namespace::sweep;

requires 'method_modifier';

has more_names => (is => 'ro', default => sub { [] });

sub bypass_custom_parsing
{
	my $class = shift;
	my ($keyword, $caller, $args) = @_;
	
	my $coderef = pop @$args;
	
	reftype($coderef) eq reftype(sub {})
		or croak('Not a valid coderef');
	
	my @qnames =
		map { /::/ ? $_ : sprintf('%s::%s', $caller, $_) }
		map { !ref($_) ? $_ : reftype($_) eq reftype([]) ? @$_ : croak("Not an array or string: $_") }
		@$args;
	
	$INSTALL_MM->(
		$class->method_modifier,
		\@qnames,
		$coderef,
	);
}

after parse_subname => sub
{
	my $self = shift;
	lex_read_space;
	while (lex_peek eq ',')
	{
		lex_read(1);
		lex_read_space;
		push @{$self->more_names}, scalar Kavorka::_fqname(parse_name('method', 1));
		lex_read_space;
	}
};

sub allow_anonymous { 0 }
sub allow_lexical   { 0 }

sub default_invocant
{
	my $self = shift;
	return (
		'Kavorka::Parameter'->new(
			name      => '$self',
			traits    => { invocant => 1 },
		),
	);
}

sub install_sub
{
	my $self = shift;
	my $code = $self->body;
	
	my $modification = $self->method_modifier;
	
	my @names = $self->qualified_name or die;
	push @names, @{$self->more_names};
	
	$INSTALL_MM->($modification, \@names, $code);
}

1;
