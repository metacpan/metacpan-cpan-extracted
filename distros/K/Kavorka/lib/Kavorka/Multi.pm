use 5.014;
use strict;
use warnings;

use Sub::Util ();

package Kavorka::Multi;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Parse::Keyword {};
use Parse::KeywordX;

use Moo;
with 'Kavorka::Sub';
use namespace::sweep;

has multi_type          => (is => 'ro', required => 1);
has declared_long_name  => (is => 'rwp');
has qualified_long_name => (is => 'rwp');

around parse => sub
{
	my $next  = shift;
	my $class = shift;
	
	lex_read_space;
	my $type = parse_name('keyword', 0);
	lex_read_space;
	
	$class->multi_parse($next, $type, @_);
};

sub multi_parse
{
	my $class = shift;
	my ($parse_method, $keyword, @args) = @_;
	
	my $implementation;
	if ($^H{Kavorka} =~ /\b$keyword=(\S+)/)
	{
		$implementation = $1;
	}
	else
	{
		Carp::croak("Could not resolve keyword '$keyword'");
	}
	
	return $class->$parse_method(@args, multi_type => $implementation);
}

after parse_attributes => sub
{
	my $self = shift;
	
	my @attr = @{$self->attributes};
	
	my @filtered;

	$_->[0] eq 'long'
		? ($self->_set_declared_long_name($_->[1]), $self->_set_qualified_long_name(scalar Kavorka::_fqname $_->[1]))
		: push(@filtered, $_)
		for @attr;
	
	@{$self->attributes} = @filtered;
};

after parse_signature => sub
{
	my $self = shift;
	my $sig  = $self->signature;
	
	for my $param (@{$sig->params})
	{
		Carp::croak("Type constraints for parameters cannot be 'assumed' in a multi sub")
			if $param->traits->{assumed};
	}
	
	$self->signature->_set_nobble_checks(1);
};

sub allow_anonymous { 0 }
sub allow_lexical   { 0 }

sub default_attributes
{
	my $code = $_[0]->multi_type->can('default_attributes');
	goto $code;
}

sub default_invocant
{
	my $code = $_[0]->multi_type->can('default_invocant');
	goto $code;
}

sub forward_declare
{
	my $code = $_[0]->multi_type->can('forward_declare');
	goto $code;
}

sub invocation_style
{
	$_[0]->multi_type->invocation_style
		or Carp::croak("No invocation style defined");
}

our %DISPATCH_TABLE;
our %DISPATCH_STYLE;
our %INVALIDATION;

sub __gather_candidates
{
	my ($pkg, $subname, $args) = @_;
	
	if ($DISPATCH_STYLE{$pkg}{$subname} eq 'fun')
	{
		return @{$DISPATCH_TABLE{$pkg}{$subname}};
	}
	
	require mro;
	my $invocant = ref($args->[0]) || $args->[0];
	return map @{$DISPATCH_TABLE{$_}{$subname} || [] }, @{ $invocant->mro::get_linear_isa };
}

sub __dispatch
{
	my ($pkg, $subname) = @{ +shift };
	
	for my $c ( __gather_candidates($pkg, $subname, \@_) )
	{
		my @copy = @_;
		next unless $c->signature->check(@copy);
		my $body = $c->body;
		goto $body;
	}
	
	Carp::croak("Arguments to $pkg\::$subname did not match any known signature for multi sub");
}

sub __compile
{
	my ($pkg, $subname) = @_;
	
	my @candidates = __gather_candidates($pkg, $subname, [$pkg]);
	my @coderefs   = map $_->body, @candidates;
	
	my $slowpath = '';
	if ($DISPATCH_STYLE{$pkg}{$subname} ne 'fun')
	{
		my $this = [$pkg, $subname];
		push @{ $INVALIDATION{"$_\::$subname"} ||= [] }, $this for @{ $pkg->mro::get_linear_isa };
		
		$slowpath = sprintf(
			'if ((ref($_[0]) || $_[0]) ne %s) { unshift @_, [%s, %s]; goto \\&Kavorka::Multi::__dispatch }',
			B::perlstring($pkg),
			B::perlstring($pkg),
			B::perlstring($subname),
		);
	}
	
	my $compiled = join q[] => (
		map {
			my $sig = $candidates[$_]->signature;
			$sig && $sig->nobble_checks ? sprintf(
				"\@tmp = \@_; if (%s) { unshift \@_, \$Kavorka::Signature::NOBBLE; goto \$coderefs[%d] }\n",
				$candidates[$_]->signature->inline_check('@tmp'),
				$_,
			) :
			$sig ? sprintf(
				"\@tmp = \@_; if (%s) { goto \$coderefs[%d] }\n",
				$candidates[$_]->signature->inline_check('@tmp'),
				$_,
			) : sprintf('goto \$coderefs[%d];', $_);
		} 0 .. $#candidates,
	);
	
	my $error = "Carp::croak(qq/Arguments to $pkg\::$subname did not match any known signature for multi sub/);";
	
	Sub::Util::set_subname(
		"$pkg\::$subname",
		eval("package $pkg; sub { $slowpath; my \@tmp; $compiled; $error }"),
	);
}

sub __defer_compile
{
	my ($pkg, $subname) = @_;
	return Sub::Util::set_subname(
		"$pkg\::$subname" => sub {
			no strict "refs";
			no warnings "redefine";
			*{"$pkg\::$subname"} = (my $compiled = __compile($pkg, $subname));
			goto $compiled;
		},
	);
}

sub install_sub
{
	my $self = shift;
	my ($pkg, $subname) = ($self->qualified_name =~ /^(.+)::(\w+)$/);
	
	unless ($DISPATCH_TABLE{$pkg}{$subname})
	{
		$DISPATCH_TABLE{$pkg}{$subname} = [];
		$DISPATCH_STYLE{$pkg}{$subname} = $self->invocation_style;
	}
	
	$DISPATCH_STYLE{$pkg}{$subname} eq $self->invocation_style
		or Carp::croak("Two different invocation styles used for $subname");
	
	{
		# A placeholder dispatcher that will replace itself with a more
		# efficient optimized (compiled) dispatcher.
		no strict "refs";
		no warnings "redefine";
		*{"$pkg\::$subname"} = __defer_compile($pkg, $subname);
		
		# Invalidate previously optimized dispatchers in subclasses of $pkg
		*{join '::', @$_} = __defer_compile(@$_)
			for @{ delete($INVALIDATION{"$pkg\::$subname"}) || [] };
	}
	
	my $long = $self->qualified_long_name;
	if (defined $long)
	{
		no strict 'refs';
		*$long = $self->body;
	}
	
	push @{ $DISPATCH_TABLE{$pkg}{$subname} }, $self;
}

1;
