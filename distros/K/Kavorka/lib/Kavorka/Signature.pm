use 5.014;
use strict;
use utf8;
use warnings;

use Kavorka::Parameter ();
use Kavorka::ReturnType ();

package Kavorka::Signature;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';
our @CARP_NOT  = qw( Kavorka::Sub Kavorka );

use Carp qw( croak );
use Parse::Keyword {};
use Parse::KeywordX;

use Moo;
use namespace::sweep;

has package           => (is => 'ro');
has _is_dummy         => (is => 'ro');
has params            => (is => 'ro',  default => sub { +[] });
has return_types      => (is => 'ro',  default => sub { +[] });
has has_invocants     => (is => 'rwp', default => sub { +undef });
has has_named         => (is => 'rwp', default => sub { +undef });
has has_slurpy        => (is => 'rwp', default => sub { +undef });
has yadayada          => (is => 'rwp', default => sub { 0 });
has parameter_class   => (is => 'ro',  default => sub { 'Kavorka::Parameter' });
has return_type_class => (is => 'ro',  default => sub { 'Kavorka::ReturnType' });
has last_position     => (is => 'lazy');
has args_min          => (is => 'lazy');
has args_max          => (is => 'lazy');
has checker           => (is => 'lazy');
has nobble_checks     => (is => 'rwp', default => sub { 0 });

sub parse
{
	my $class = shift;
	my $self = $class->new(@_);
	
	lex_read_space;
	
	my $found_colon = 0;
	my $arr    = $self->params;
	my $_class = 'parameter_class';
	
	if (lex_peek(4) =~ /\A(\xE2\x86\x92|-->)/)
	{
		lex_read(length $1);
		$arr    = $self->return_types;
		$_class = 'return_type_class';
		lex_read_space;
	}
	
	my $skip = 0;
	while (lex_peek ne ')')
	{
		if (lex_peek(3) eq '...')
		{
			$self->_set_yadayada(1);
			lex_read(3);
			lex_read_space;
			++$skip && next if lex_peek(4) =~ /\A(\xE2\x86\x92|-->)/;
			croak("After yada-yada, expected right parenthesis") unless lex_peek eq ")";
			next;
		}
		
		$skip
			? ($skip = 0)
			: push(@$arr, $self->$_class->parse(package => $self->package));
		lex_read_space;
		
		my $peek = lex_peek;
		if ($found_colon and $peek eq ':')
		{
			croak("Cannot have two sets of invocants - unexpected colon!");
		}
		elsif ($peek eq ':')
		{
			$_->traits->{invocant} = 1 for @{$self->params};
			$self->_set_has_invocants( scalar @{$self->params} );
			lex_read(1);
		}
		elsif ($peek eq ',')
		{
			lex_read(1);
		}
		elsif ($peek eq ')')
		{
			last;
		}
		elsif (lex_peek(4) =~ /\A(\xE2\x86\x92|-->)/)
		{
			lex_read(length $1);
			$arr    = $self->return_types;
			$_class = 'return_type_class';
		}
		else
		{
			use Data::Dumper;
			print Dumper($self);
			croak("Unexpected characters in signature (${\ lex_peek(8) })");
		}
		
		lex_read_space;
	}
	
	$self->sanity_check;
	
	return $self;
}

# XXX - check not allowed optional parameters and named parameters in same sig
sub sanity_check
{
	my $self = shift;
	
	my $has_invocants = 0;
	my $has_slurpy = 0;
	my $has_named = 0;
	for my $p (reverse @{ $self->params or croak("Huh?") })
	{
		$has_named++ if $p->named;
		$has_slurpy++ if $p->slurpy;
		
		if ($p->invocant) {
			$has_invocants++;
			next;
		}
		elsif ($has_invocants) {
			$has_invocants++;
			$p->traits->{invocant} = 1;  # anything prior to an invocant is also an invocant!
		}
	}
	$self->_set_has_invocants($has_invocants);
	$self->_set_has_named($has_named);
	$self->_set_has_slurpy($has_slurpy);
	
	croak("Cannot have more than one slurpy parameter") if $has_slurpy > 1;
	
	my $i    = 0;
	my $zone = 'invocant';
	my %already;
	for my $p (@{ $self->params })
	{
		my $p_type =
			$p->invocant ? 'invocant' :
			$p->named    ? 'named'    :
			$p->slurpy   ? 'slurpy'   :
			$p->optional ? 'optional' : 'positional';
		
		$p->sanity_check($self);
		$p->_set_position($i++) unless $p->invocant || $p->slurpy || $p->named;
		
		my $name = $p->name;
		croak("Parameter $name occurs twice in signature")
			if length($name) > 1 && $already{$name}++;
		
		if ($name eq '@_')
		{
			croak("Cannot have slurpy named \@_ after positional parameters") if $self->positional_params;
			croak("Cannot have slurpy named \@_ after named parameters")      if $self->named_params;
		}
		
		next if $p_type eq $zone;
		
		# Zone transitions
		if ($zone eq 'invocant' || $zone eq 'positional'
		and $p_type eq 'positional' || $p_type eq 'named' || $p_type eq 'slurpy' || $p_type eq 'optional')
		{
			$zone = $p_type;
			next;
		}
		elsif ($zone eq 'optional' || $zone eq 'named'
		and    $p_type eq 'slurpy')
		{
			$zone = $p_type;
			next;
		}
		
		croak("Found $p_type parameter ($name) after $zone; forbidden");
	}
	
	$_->sanity_check for @{ $self->return_types };
	
	();
}

sub _build_last_position
{
	my $self = shift;
	my ($last) = reverse( $self->positional_params );
	return -1 unless $last;
	return $last->position;
}

sub injection
{
	my $self = shift;
	join q[] => (
		$self->_injection_nobble,
		$self->_injection_invocants,
		$self->_injection_parameter_count,
		$self->_injection_positional_params,
		$self->_injection_hash_underscore,
		$self->_injection_named_params,
		$self->_injection_slurpy_param,
		'();',
	);
}

our $NOBBLE = bless(do { my $x = 1; \$x }, 'Kavorka::Signature::NOBBLE');
sub _injection_nobble
{
	my $self = shift;
	return unless $self->nobble_checks;
	
	sprintf('my $____nobble_checks = (ref($_[0]) eq "Kavorka::Signature::NOBBLE") ? ${+shift} : 0;');
}

sub _injection_parameter_count
{
	my $self = shift;
	
	my $min = $self->args_min;
	my $max = $self->args_max;
	
	my @lines;
	
	return sprintf(
		'Carp::croak("Expected %d parameter%s") if @_ != %d;',
		$min,
		$min==1 ? '' : 's',
		$min,
	) if defined($min) && defined($max) && $min==$max;
	
	push @lines, sprintf(
		'Carp::croak("Expected at least %d parameter%s") if @_ < %d;',
		$min,
		$min==1 ? '' : 's',
		$min,
	) if defined $min && $min > 0;
	
	push @lines, sprintf(
		'Carp::croak("Expected at most %d parameter%s") if @_ > %d;',
		$max,
		$max==1 ? '' : 's',
		$max,
	) if defined $max;
	
	return @lines;
}

sub _build_args_min
{
	my $self = shift;
	0 + scalar grep !$_->optional, $self->positional_params;
}

sub _build_args_max
{
	my $self = shift;
	return if $self->has_named || $self->has_slurpy || $self->yadayada;
	0 + scalar $self->positional_params;
}

sub _injection_hash_underscore
{
	my $self = shift;
	
	my $slurpy = $self->slurpy_param;
	
	if ($self->has_named
	or $slurpy && $slurpy->name =~ /\A\%/
	or $slurpy && $slurpy->name =~ /\A\$/ && $slurpy->type->is_a_type_of(Types::Standard::HashRef()))
	{
		my $ix  = 1 + $self->last_position;
		my $str;
		if ($] >= 5.022)
		{
			my $pragma = "use warnings FATAL => qw(all);use experimental 'refaliasing';no warnings 'experimental::refaliasing';";
			$str = sprintf(
				'local %%_;'
				.'{ %s '
					.'if ($#_==%d && ref($_[%d]) eq q(HASH)) { '
						.'\\%%_ = $_[%d]; '
					.'} else { '
						.'my $i = %d; '
						.'my $slice_length = ($#_ + 1 - $i); '
						.'if ($slice_length %% 2 != 0) { '
							.'Carp::croak("Odd number of elements in anonymous hash");'
						.'} '
						.'while ($i <= $#_) { '
							.'my $key = $_[$i]; '
							.'\\$_{$key} = \\$_[$i+1]; '
							.'$i += 2; '
						.'} '
					.'} '
				.'};',
				$pragma,
				($ix) x 4,
			);
		}
		else
		{
			require Data::Alias;
			$str = sprintf(
				'local %%_; { use warnings FATAL => qw(all); Data::Alias::alias(%%_ = ($#_==%d && ref($_[%d]) eq q(HASH)) ? %%{$_[%d]} : @_[ %d .. $#_ ]) };',
				($ix) x 4,
			);
		}
		
		unless ($slurpy or $self->yadayada)
		{
			my @allowed_names = map +($_=>1), map @{$_->named_names}, $self->named_params;
			$str .= sprintf(
				'{ my %%OK = (%s); ',
				join(q[,], map(sprintf('%s=>1,', B::perlstring $_), @allowed_names)),
			);
			$str .= '$OK{$_}||Carp::croak("Unknown named parameter: $_") for sort keys %_ };';
		}
		
		return $str;
	}
	
	return;
}

sub _injection_invocants
{
	my $self = shift;
	map($_->injection($self), $self->invocants);
}

sub _injection_positional_params
{
	my $self = shift;
	map($_->injection($self), $self->positional_params);
}

sub _injection_named_params
{
	my $self = shift;
	map($_->injection($self), $self->named_params);
}

sub _injection_slurpy_param
{
	my $self = shift;
	map($_->injection($self), grep defined, $self->slurpy_param);
}

sub named_params
{
	my $self = shift;
	grep $_->named, @{$self->params};
}

sub positional_params
{
	my $self = shift;
	grep !$_->named && !$_->invocant && !$_->slurpy, @{$self->params};
}

sub slurpy_param
{
	my $self = shift;
	my ($s) = grep $_->slurpy, @{$self->params};
	$s;
}

sub invocants
{
	my $self = shift;
	grep $_->invocant, @{$self->params};
}

sub check
{
	my $checker = shift->checker;
	goto $checker;
}

sub _build_checker
{
	my $self = shift;
	eval sprintf(
		'sub { eval { %s; 1 } }',
		$self->injection,
	);
}

sub inline_check
{
	my $self = shift;
	my ($arr) = @_;
	
	my $tmp = $self->nobble_checks;
	$self->_set_nobble_checks(0);
	
	my $inline = sprintf(
		'do { local @_ = %s; eval { %s; 1 } }',
		$arr,
		$self->injection,
	);
	
	$self->_set_nobble_checks($tmp) if $tmp;
	
	return $inline;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords invocant invocants lexicals unintuitive yadayada

=head1 NAME

Kavorka::Signature - a function signature

=head1 DESCRIPTION

Kavorka::Signature is a class where each instance represents a function
signature. This class is used to parse the function signature, and also
to inject Perl code into the final function.

Instances of this class are also returned by Kavorka's function
introspection API.

=head2 Introspection API

A signature instance has the following methods. Each method
which returns parameters, returns an instance of
L<Kavorka::Parameter>.

=over

=item C<package>

Returns the package name the parameter was declared in.

=item C<params>

Returns an arrayref of parameters.

=item C<return_types>

Returns an arrayref of declared return types.

=item C<has_invocants>, C<invocants>

Returns a boolean/list of invocant parameters.

=item C<positional_params>

Returns a list of positional parameters.

=item C<has_named>, C<named_params>

Returns a boolean/list of named parameters.

=item C<has_slurpy>, C<slurpy>

Returns a boolean indicating whether there is a slurpy parameter
in this signature / returns the slurpy parameter.

=item C<yadayada>

Indicates whether the yadayada operator was encountered in the
signature.

=item C<last_position>

The numeric index of the last positional parameter.

=item C<args_min>, C<args_max>

The minimum/maximum number of arguments expected by the function.
Invocants are not counted. If there are any named or slurpy arguments,
of the yada yada operator was used in the signature, then C<args_max>
will be undef.

=item C<< check(@args) >>

Check whether C<< @args >> (which should include any invocants) would
satisfy the signature.

=item C<< checker >>

Returns a coderef which acts like C<< check(@args) >>.

=item C<< inline_check($varname) >>

Returns a string of Perl code that acts like an inline check, given the
name of an array variable, such as C<< '@foo' >>.

=back

=head2 Other Methods

=over

=item C<parse>

An internal method used to parse a signature. Only makes sense to use
within a L<Parse::Keyword> parser.

=item C<parameter_class>

A class to use for parameters when parsing the signature.

=item C<return_type_class>

A class to use for return types when parsing the signature.

=item C<injection>

The string of Perl code to inject for this signature.

=item C<sanity_check>

Tests that the signature is sane. (For example it would not be sane to
have a slurpy parameter prior to a positional one.)

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Kavorka>.

=head1 SEE ALSO

L<Kavorka::Manual::API>,
L<Kavorka::Sub>,
L<Kavorka::Parameter>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

