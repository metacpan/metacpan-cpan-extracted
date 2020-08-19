package Hades::Realm::Compiled::Params;
use strict;
use warnings;
use base qw/Hades/;
our $VERSION = 0.01;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = $cls->SUPER::new(%args);
	my %accessors = ( cpo => { required => 1, default => [], }, );
	for my $accessor ( keys %accessors ) {
		my $value
		    = $self->$accessor(
			defined $args{$accessor}
			? $args{$accessor}
			: $accessors{$accessor}->{default} );
		unless ( !$accessors{$accessor}->{required} || defined $value ) {
			die "$accessor accessor is required";
		}
	}
	return $self;
}

sub cpo {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "ARRAY" ) {
			die qq{ArrayRef: invalid value $value for accessor cpo};
		}
		$self->{cpo} = $value;
	}
	return $self->{cpo};
}

sub push_cpo {
	my ( $self, $key, $value ) = @_;
	if ( !defined($key) || ref $key ) {
		$key = defined $key ? $key : 'undef';
		die qq{Str: invalid value $key for variable \$key in method push_cpo};
	}
	if ( !defined($value) || ref $value ) {
		$value = defined $value ? $value : 'undef';
		die
		    qq{Str: invalid value $value for variable \$value in method push_cpo};
	}
	push @{ $self->{cpo} }, qq|$key => $value|;
}

sub build_accessor {
	my ( $orig, $self, @params ) = ( 'SUPER::build_accessor', @_ );
	$params[2]->{ $params[1] }->{type}->[0] =~ s/\s*\[/[/g
	    if $params[2]->{ $params[1] }->{type}->[0];
	$self->push_cpo( $params[1],
		'[' . ( $params[2]->{ $params[1] }->{type}->[0] || 'Any' ) . ']' );
	my @res = $self->$orig(@params);
	return wantarray ? @res : $res[0];
}

sub build_sub {
	my ( $self, $mg, $name, $meta ) = @_;
	if ( !ref $mg ) {
		$mg = defined $mg ? $mg : 'undef';
		die qq{Ref: invalid value $mg for variable \$mg in method build_};
	}
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_sub};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_sub};
	}
	my $code = $meta->{$name}->{code};
	my ( $params, $types, $params_explanation, $private );
	$private = $self->build_private($name) if $meta->{$name}->{private};
	if ( $meta->{$name}->{param} ) {
		for my $param ( @{ $meta->{$name}->{param} } ) {
			$params_explanation .= ', ' if $params_explanation;
			$params             .= ', ' . $param;
			my $pm = $meta->{$name}->{params_map}->{$param};
			$pm->{type} ||= q|Any|;
			$types              .= $types ? ', ' . $pm->{type} : $pm->{type};
			$params_explanation .= qq|param $param to be a $pm-> { type } |;
		}
		my $type = $self->build_type( $name, $types, $types );
		$self->push_cpo( $name, '[' . $types . ']' );
		$code = qq| { my (\$self $params) = (shift$type); $code;  } |;
		$params =~ s/^\,\s*//;
		my $example = qq|\$obj->$name($params)|;
		$mg->sub($name)->code($code)
		    ->pod(qq|call $name method. Expects $params_explanation.|)
		    ->example($example)
		    ->test( $self->build_tests( $name, $meta->{$name} ) );
	}
}

sub build_type {
	my ( $self, $name, $type, $value ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_type};
	}
	if ( defined $type ) {
		if ( ref $type ) {
			die
			    qq{Optional[Str]: invalid value $type for variable \$type in method build_type};
		}
	}
	if ( defined $value ) {
		if ( ref $value ) {
			die
			    qq{Optional[Str]: invalid value $value for variable \$value in method build_type};
		}
	}
	my $code = '';
	if ($type) {
		$code
		    .= $value
		    ? qq|, \$VALIDATE->$name->(\@_)|
		    : qq|(\$value) = \$VALIDATE->$name->(\$value);|;
	}
	return $code;
}

sub after_class {
	my ( $self, $mg ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method after_class};
	}
	my $cpo = join ', ', @{ $self->cpo };
	$mg->use(q|Types::Standard qw/Str Optional HashRef Tuple Map Dict ArrayRef Int Any/|);
	$mg->use(q|Compiled::Params::OO|);
	$mg->our(q|$VALIDATE|);
	my $code  = qq|\$VALIDATE = Compiled::Params::OO::cpo( $cpo );|;
	my %class = %Module::Generate::CLASS;
	if ( $class{CURRENT}{BEGIN} ) {
		( my $begin = $class{CURRENT}{BEGIN} ) =~ s/\s*\}\s*$//;
		$code = $begin . $code . "\}";
	}
	else {  $code = qq|{ $code }|; }
	$class{CURRENT}{BEGIN} = $code;
}

1;

__END__

=head1 NAME

Hades::Realm::Compiled::Params - The great new Hades::Realm::Compiled::Params!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Hades::Realm::Compiled::Params;

	Hades::Realm::Compiled::Params->run({
		eval => 'Kosmos { penthos :d(2) :p :pr :c :t(Int) curae :r :t(Any) geras $nosoi :t(Int) { if ($self->penthos == $nosoi) { return $self->curae; } } }',
		lib => 't/lib'
	});

	... generates ...

	package Kosmos;
	use strict;
	use warnings;
	use Types::Standard qw/Str Optional HashRef Tuple Map Dict ArrayRef Int Any/;
	use Compiled::Params::OO;
	our $VERSION = 0.01;
	our $VALIDATE;

	BEGIN {
		$VALIDATE = Compiled::Params::OO::cpo(
			penthos => [Int],
			curae   => [Any],
			geras   => [Int]
		);
	}

	sub new {
		my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
		my $self = bless {}, $cls;
		my %accessors
		    = ( curae => { required => 1, }, penthos => { default => 2, }, );
		for my $accessor ( keys %accessors ) {
			my $value
			    = $self->$accessor(
				defined $args{$accessor}
				? $args{$accessor}
				: $accessors{$accessor}->{default} );
			unless ( !$accessors{$accessor}->{required} || defined $value ) {
				die "$accessor accessor is required";
			}
		}
		return $self;
	}

	sub penthos {
		my ( $self, $value ) = @_;
		my $private_caller = caller();
		if ( $private_caller ne __PACKAGE__ ) {
			die "cannot call private method penthos from $private_caller";
		}
		if ( defined $value ) {
			($value) = $VALIDATE->penthos->($value);
			$self->{penthos} = $value;
		}
		return $self->{penthos};
	}

	sub clear_penthos {
		my ($self) = @_;
		delete $self->{penthos};
		return $self;
	}

	sub has_penthos {
		my ($self) = @_;
		return !!$self->{penthos};
	}

	sub curae {
		my ( $self, $value ) = @_;
		if ( defined $value ) {
			($value) = $VALIDATE->curae->($value);
			$self->{curae} = $value;
		}
		return $self->{curae};
	}

	sub geras {
		my ( $self, $nosoi ) = ( shift, $VALIDATE->geras->(@_) );
		if ( $self->penthos == $nosoi ) { return $self->curae; }
	}

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Realm::Compiled::Params object.

	Hades::Realm::Compiled::Params->new

=head2 push_cpo

call push_cpo method. Expects param $key to be a Str, param $value to be a Str.

	$obj->push_cpo($key, $value)

=head2 build_accessor

call build_accessor method.

=head2 build_sub

call build_sub method. Expects param $mg to be a Ref, param $name to be a Str, param $meta to be a HashRef.

	$obj->build_sub($mg, $name, $meta)

=head2 build_type

call build_type method. Expects param $name to be a Str, param $type to be a Optional[Str], param $value to be a Optional[Str].

	$obj->build_type($name, $type, $value)

=head2 after_class

call after_class method. Expects param $mg to be a Object.

	$obj->after_class($mg)

=head1 ACCESSORS

=head2 cpo

get or set cpo.

	$obj->cpo;

	$obj->cpo($value);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hadesrealmcompiledparams at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Realm-Compiled-Params>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Realm::Compiled::Params

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Realm-Compiled-Params>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Realm-Compiled-Params>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Realm-Compiled-Params>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Realm-Compiled-Params>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


