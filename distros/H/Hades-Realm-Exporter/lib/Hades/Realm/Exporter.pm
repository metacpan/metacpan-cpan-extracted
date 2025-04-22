package Hades::Realm::Exporter;
use strict;
use warnings;
use base qw/Hades/;
our $VERSION = 0.05;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = $cls->SUPER::new(%args);
	my %accessors = ( export => { default => {}, }, );
	for my $accessor ( keys %accessors ) {
		my $param
		    = defined $args{$accessor}
		    ? $args{$accessor}
		    : $accessors{$accessor}->{default};
		my $value
		    = $self->$accessor( $accessors{$accessor}->{builder}
			? $accessors{$accessor}->{builder}->( $self, $param )
			: $param );
		unless ( !$accessors{$accessor}->{required} || defined $value ) {
			die "$accessor accessor is required";
		}
	}
	return $self;
}

sub export {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "HASH" ) {
			die qq{HashRef: invalid value $value for accessor export};
		}
		$self->{export} = $value;
	}
	return $self->{export};
}

sub build_self {
	my ( $self, $name ) = @_;
	if ( defined $name ) {
		if ( ref $name ) {
			die
			    qq{Optional[Str]: invalid value $name for variable \$name in method build_self};
		}
	}

	return qq|$name|;

}

sub default_export_hash {
	my ( $self, $mg, $class, $export ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method default_export_hash};
	}
	if ( ( ref($class) || "" ) ne "HASH" ) {
		$class = defined $class ? $class : 'undef';
		die
		    qq{HashRef: invalid value $class for variable \$class in method default_export_hash};
	}
	$export = defined $export ? $export : {};
	if ( ( ref($export) || "" ) ne "HASH" ) {
		$export = defined $export ? $export : 'undef';
		die
		    qq{HashRef: invalid value $export for variable \$export in method default_export_hash};
	}

	if ( $class->{CURRENT}->{BASE} || $class->{CURRENT}->{PARENT} ) {
		for my $cls (
			@{ $class->{CURRENT}->{BASE}   || [] },
			@{ $class->{CURRENT}->{PARENT} || [] }
		    )
		{
			if ( $self->export->{$cls} ) {
				my %unique;
				for ( keys %{ $self->export->{$cls} } ) {
					push @{ $export->{$_} },
					    map { $unique{$_}++; $_; }
					    @{ $self->export->{$cls}->{$_} };
				}
				for ( keys %unique ) {
					$self->build_sub_no_arguments( $mg,
						[ $_, "return ${cls}::$_(\@_)" ], {} );
				}
			}
			else { }
		}
	}
	return $export;

}

sub build_new {
	my ( $self, $mg, $meta, $our ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_new};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_new};
	}
	$our = defined $our ? $our : q|@EXPORT, @EXPORT_OK, %EXPORT_TAGS|;

	my %class  = %Module::Generate::CLASS;
	my $begin  = '';
	my $export = $self->default_export_hash( $mg, \%class );
	for ( keys %{$meta} ) {
		if ( $meta->{$_}->{meta} =~ m/^(ACCESSOR|METHOD)$/ ) {
			if ( $1 eq 'ACCESSOR' ) {
				$begin .= $_ . q| => | . $meta->{$_}->{default} . q|, |
				    if $meta->{$_}->{default};
			}
			my $import = $meta->{$_}->{import};
			my $now    = shift @{$import};
			$self->build_export_tags( $_, "${1}S", $export, $now, $import );
			$self->build_export_tags( "has_$_", 'PREDICATES', $export, $now,
				[] )
			    if $meta->{$_}->{predicate};
			$self->build_export_tags( "clear_$_", 'CLEARERS', $export, $now,
				[] )
			    if $meta->{$_}->{clearer};
		}
	}
	$self->export->{ $class{CURRENT}{NAME} } = { %{$export} };
	$mg->our( '(' . $our . ', %ACCESSORS)' );
	$begin = $self->build_exporter( '%ACCESSORS = (' . $begin . ')',
		$mg, $export, $meta );
	if ( $class{CURRENT}{BEGIN} ) {
		( my $code = $class{CURRENT}{BEGIN} ) =~ s/\s*\}\s*$//;
		$begin = $code . $begin . "\}";
	}
	else { $begin = qq|{ $begin }|; }
	$class{CURRENT}{BEGIN} = $begin;
	delete $class{CURRENT}{SUBS}{new};

}

sub build_exporter {
	my ( $self, $begin, $mg, $export, $meta ) = @_;
	if ( !defined($begin) || ref $begin ) {
		$begin = defined $begin ? $begin : 'undef';
		die
		    qq{Str: invalid value $begin for variable \$begin in method build_exporter};
	}
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_exporter};
	}
	if ( ( ref($export) || "" ) ne "HASH" ) {
		$export = defined $export ? $export : 'undef';
		die
		    qq{HashRef: invalid value $export for variable \$export in method build_exporter};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_exporter};
	}

	my $ex      = delete $export->{EXPORT};
	my $ex_ok   = delete $export->{EXPORT_OK};
	my $ex_tags = Module::Generate::_stringify_struct( 'undefined', $export );
	$ex_tags =~ s/^{/(/;
	$ex_tags =~ s/}$/);/;
	$begin
	    = '@EXPORT = ('
	    . join( ', ', map {qq|'$_'|} @{$ex} ) . ');'
	    . '@EXPORT_OK = ('
	    . join( ', ', map {qq|'$_'|} @{$ex_ok} ) . ');'
	    . '%EXPORT_TAGS = '
	    . $ex_tags
	    . $begin;
	return $begin;

}

sub build_export_tags {
	my ( $self, $name, $type, $export, $now, $import ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_export_tags};
	}
	if ( !defined($type) || ref $type ) {
		$type = defined $type ? $type : 'undef';
		die
		    qq{Str: invalid value $type for variable \$type in method build_export_tags};
	}
	if ( ( ref($export) || "" ) ne "HASH" ) {
		$export = defined $export ? $export : 'undef';
		die
		    qq{HashRef: invalid value $export for variable \$export in method build_export_tags};
	}
	if ( defined $now ) {
		if ( ref $now || $now !~ m/^[-+\d]\d*$/ ) {
			die
			    qq{Optional[Int]: invalid value $now for variable \$now in method build_export_tags};
		}
	}
	if ( !defined($import) || ( ref($import) || "" ) ne "ARRAY" ) {
		$import = defined $import ? $import : 'undef';
		die
		    qq{ArrayRef: invalid value $import for variable \$import in method build_export_tags};
	}

	push @{ $export->{$type} }, $name;
	push @{ $export->{EXPORT_OK} }, $name;
	push @{ $export->{EXPORT} },    $name if $now;
	for my $i ( @{$import} ) {
		$i =~ s/^\s*|\s*$//;
		push @{ $export->{$i} }, $name;
	}
	return $export;

}

sub after_class {
	my ( $self, $mg ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method after_class};
	}

	$mg->use(q|Exporter qw/import/|);

}

sub build_sub_or_accessor_attributes {
	my ( $orig, $self, @params )
	    = ( 'SUPER::build_sub_or_accessor_attributes', @_ );

	my @res = $self->$orig(@params);
	unshift @res, (
		qr/^(\:import|\:i$)/ => sub {
			$params[-1]->{ $params[-3] }->{import} = [0];
		},
		qr/^(\:import|\:i)\(/ => sub {
			my $value = shift;
			$value =~ s/(\:import|\:i)\((.*)\)$/$2/sg;
			$params[-1]->{ $params[-3] }->{import} = [ split /,/, $value ];
		}
	);

	return wantarray ? @res : $res[0];
}

sub build_accessor_no_arguments {
	my ( $self, $mg, $token, $meta ) = @_;

	$meta->{ $token->[0] }->{meta} = 'ACCESSOR';
	$mg->accessor( $token->[0] )
	    ->code( $self->build_accessor_code( $token->[0], '', '', '' ) )
	    ->clear_tests->test(
		$self->build_tests(
			$token->[0], $meta->{ $token->[0] },
			'', {%Module::Generate::CLASS}
		)
	)->pod(qq|call $token->[0] accessor function.|)
	    ->example(qq|$token->[0](\$value)|);
	return $meta;

}

sub build_accessor_code {
	my ( $self, $name, $private, $type, $trigger ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_accessor_code};
	}
	if ( !defined($private) || ref $private ) {
		$private = defined $private ? $private : 'undef';
		die
		    qq{Str: invalid value $private for variable \$private in method build_accessor_code};
	}
	if ( !defined($type) || ref $type ) {
		$type = defined $type ? $type : 'undef';
		die
		    qq{Str: invalid value $type for variable \$type in method build_accessor_code};
	}
	if ( !defined($trigger) || ref $trigger ) {
		$trigger = defined $trigger ? $trigger : 'undef';
		die
		    qq{Str: invalid value $trigger for variable \$trigger in method build_accessor_code};
	}

	return qq|{
			my ( \$value ) = \@_; $private
			if ( defined \$value ) { $type
				\$ACCESSORS{$name} = \$value; $trigger
			}
			return \$ACCESSORS{$name};
		}|;

}

sub build_accessor {
	my ( $orig, $self, @params ) = ( 'SUPER::build_accessor', @_ );

	my @res = $self->$orig(@params);
	$params[0]->clear_tests->test(
		$self->build_tests(
			$params[1], $params[2]->{ $params[1] },
			'', {%Module::Generate::CLASS}
		)
	);
	$params[0]->pod(
		sprintf
		    q|call %s accessor function. Expects a single param to be of type %s.|,
		$params[1],
		$params[2]->{ $params[1] }->{type}->[0] || 'Any'
	) unless $params[2]->{ $params[1] }->{pod};
	$params[0]->example(qq|$params[1]()|)
	    unless $params[2]->{ $params[1] }->{example};

	return wantarray ? @res : $res[0];
}

sub build_modify {
	my ($self) = @_;

}

sub build_sub_no_arguments {
	my ( $self, $mg, $token, $meta ) = @_;

	my $name = shift @{$token};
	$name =~ m/^(begin|unitcheck|check|init|end|new)$/
	    ? $mg->$name( join ' ', @{$token} )
	    : $mg->sub($name)
	    ->code( $self->build_sub_code( '', '', '', join( ' ', @{$token} ) ) )
	    ->pod(qq|call $name function. Expects no params.|)
	    ->example(qq|$name()|);
	return $meta;

}

sub build_sub_code {
	my ( $self, $name, $params, $subtype, $code ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_sub_code};
	}
	if ( !defined($params) || ref $params ) {
		$params = defined $params ? $params : 'undef';
		die
		    qq{Str: invalid value $params for variable \$params in method build_sub_code};
	}
	if ( !defined($subtype) || ref $subtype ) {
		$subtype = defined $subtype ? $subtype : 'undef';
		die
		    qq{Str: invalid value $subtype for variable \$subtype in method build_sub_code};
	}
	if ( !defined($code) || ref $code ) {
		$code = defined $code ? $code : 'undef';
		die
		    qq{Str: invalid value $code for variable \$code in method build_sub_code};
	}

	$params =~ s/^\s*,\s*//;
	$params = qq|my ($params) = \@_;| if $params;
	return qq|{
			$params $subtype
			$code;
		}|;

}

sub build_sub {
	my ( $orig, $self, @params ) = ( 'SUPER::build_sub', @_ );

	my @res = $self->$orig(@params);
	$params[0]->clear_tests->test(
		$self->build_tests(
			$params[1], $params[2]->{ $params[1] },
			'', {%Module::Generate::CLASS}
		)
	);
	$params[0]->pod(
		qq|call $params[1] function. Expects $params[2]->{$params[1]}->{params_explanation}|
	);

	return wantarray ? @res : $res[0];
}

sub build_clearer {
	my ( $self, $mg, $name, $meta ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_clearer};
	}
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_clearer};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_clearer};
	}

	my %class = %Module::Generate::CLASS;
	$mg->sub(qq|clear_$name|)->code(
		qq|{
			delete \$ACCESSORS{$name};
			return 1;
		}|
	)->pod(qq|clear $name accessor function.|)
	    ->example(qq|clear_$name()|)->clear_tests->test(
		[ 'ok', qq|$class{CURRENT}{NAME}::clear_$name| ],
		[ 'is', qq|$class{CURRENT}{NAME}::$name|, 'undef' ]
	    );

}

sub build_predicate {
	my ( $self, $mg, $name, $meta ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_predicate};
	}
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_predicate};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_predicate};
	}

	my %class = %Module::Generate::CLASS;
	$mg->sub(qq|has_$name|)->code(
		qq|{
			return exists \$ACCESSORS{$name};
		}|
	    )
	    ->pod(
		qq|has_$name accessor function will return trye if $name accessor has a value.|
	)->example(qq|has_$name()|)->clear_tests->test(
		(   $meta->{$name}->{required} || $meta->{$name}->{default}
			? ( [ 'is', qq|$class{CURRENT}{NAME}::has_$name|, 1 ], )
			: ( [ 'is', qq|$class{CURRENT}{NAME}::has_$name|, q|''| ], )
		),
		$self->build_tests( $name, $meta->{$name}, '', \%class ),
		[ 'is', qq|$class{CURRENT}{NAME}::has_$name|, 1 ],
	);

}

sub build_coerce {
	my ( $self, $name, $param, $code ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_coerce};
	}
	if ( !defined($param) || ref $param ) {
		$param = defined $param ? $param : 'undef';
		die
		    qq{Str: invalid value $param for variable \$param in method build_coerce};
	}
	if ( defined $code ) {
		if ( ref $code ) {
			die
			    qq{Optional[Str]: invalid value $code for variable \$code in method build_coerce};
		}
	}

	return
	      defined $code
	    ? $code =~ m/^\w+$/
		    ? qq|$param = $code($param);|
		    : $code
	    : q||;

}

sub build_trigger {
	my ( $self, $name, $param, $code ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_trigger};
	}
	if ( !defined($param) || ref $param ) {
		$param = defined $param ? $param : 'undef';
		die
		    qq{Str: invalid value $param for variable \$param in method build_trigger};
	}
	if ( defined $code ) {
		if ( ref $code ) {
			die
			    qq{Optional[Str]: invalid value $code for variable \$code in method build_trigger};
		}
	}

	return
	      defined $code
	    ? $code =~ m/^1$/
		    ? qq|_trigger_$name|
		    : $code =~ m/^\w+$/ ? qq|$code($param);|
		: $code
	    : q||;

}

sub build_tests {
	my ( $self, $name, $meta, $mod, $class ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_tests};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_tests};
	}
	if ( defined $mod ) {
		if ( ref $mod ) {
			die
			    qq{Optional[Str]: invalid value $mod for variable \$mod in method build_tests};
		}
	}
	if ( defined $class ) {
		if ( ( ref($class) || "" ) ne "HASH" ) {
			die
			    qq{Optional[HashRef]: invalid value $class for variable \$class in method build_tests};
		}
	}

	my @tests;
	if ($class) {
		my $cls = $class->{CURRENT}->{NAME};
		if ( $meta->{meta} eq 'ACCESSOR' ) {
			$meta->{private}
			    ? do {
				push @tests,
				    [
					'eval',
					qq|${cls}::${name}()|,
					'private method|private attribute'
				    ];
			    }
			    : do {
				push @tests, [ 'is', qq|${cls}::${name}()|, 'undef' ]
				    if !$meta->{required} && !$meta->{default};
				push @tests, [ 'eval', qq|${cls}::${name}()|, q|^$| ];
				my (@test_cases)
				    = $self->build_test_data( $meta->{type}->[0] || 'Any',
					$name );
				if ( scalar @test_cases > 1 ) {
					my $valid = shift @test_cases;
					push @tests,
					    [ 'deep', qq|${cls}::${name}($valid)|, $valid ];
					unless ( $meta->{coerce} ) {
						for (@test_cases) {
							push @tests,
							    [
								'eval', qq|${cls}::${name}($_)|,
								'invalid|value|type|constraint|greater|atleast'
							    ];
						}
					}
					push @tests, [ 'deep', qq|${cls}::${name}|, $valid ];
				}
			    };
		}
		elsif ( $meta->{meta} eq 'METHOD' ) {
			$meta->{private}
			    ? do {
				push @tests,
				    [ 'eval', qq|${cls}::${name}()|, 'private method' ];
			    }
			    : $meta->{param} && do {
				my %test_data = map {
					$_ => [
						$self->build_test_data(
							$meta->{params_map}->{$_}->{type} || 'Any', $name
						),
						( $meta->{params_map}->{$_}->{type} || 'Any' )
						    !~ m/^(|Optional|Any|Item)/ ? q|undef| : ()
					]
				} @{ $meta->{param} };
				for my $key ( @{ $meta->{param} } ) {
					for my $ah ( splice @{ $test_data{$key} }, 1 ) {
						push @tests,
						    [
							'eval',
							sprintf(
								q|%s::%s(%s)|,
								$cls, $name,
								join ', ',
								map { $key eq $_ ? $ah : $test_data{$_}->[0] }
								    @{ $meta->{param} }
							),
							'invalid|value|type|constraint|greater|atleast'
						    ];
					}
				}
			}
		}
	}
	push @tests, @{ $meta->{test} } if $meta->{test};
	return @tests;

}

1;

__END__

=head1 NAME

Hades::Realm::Exporter - Hades realm for Exporter

=head1 VERSION

Version 0.05

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	Hades->run({
		eval => 'Kosmos {
			[curae penthos] :t(Int) :d(2) :p :pr :c :r :i(1, GROUP)
			geras $nosoi :t(Int) :d(5) :i { if (penthos() == $nosoi) { return curae; } } 
		}',
		realm => 'Exporter',
	});

	... generates ...

	package Kosmos;
	use strict;
	use warnings;
	use Exporter qw/import/;
	our $VERSION = 0.01;
	our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS, %ACCESSORS );

	BEGIN {
		@EXPORT = (
			'curae',       'has_curae', 'clear_curae', 'penthos',
			'has_penthos', 'clear_penthos'
		);
		@EXPORT_OK = (
			'curae',       'has_curae',     'clear_curae', 'penthos',
			'has_penthos', 'clear_penthos', 'geras'
		);
		%EXPORT_TAGS = (
			'METHODS'    => ['geras'],
			'CLEARERS'   => [ 'clear_curae', 'clear_penthos' ],
			'GROUP'      => [ 'curae', 'penthos' ],
			'PREDICATES' => [ 'has_curae', 'has_penthos' ],
			'ACCESSORS'  => [ 'curae', 'penthos' ]
		);
		%ACCESSORS = ( curae => 2, penthos => 2, );
	}

	sub curae {
		my ($value) = @_;
		my $private_caller = caller();
		if ( $private_caller ne __PACKAGE__ ) {
			die "cannot call private method curae from $private_caller";
		}
		if ( defined $value ) {
			if ( ref $value || $value !~ m/^[-+\d]\d*$/ ) {
				die qq{Int: invalid value $value for accessor curae};
			}
			$ACCESSORS{curae} = $value;
		}
		return $ACCESSORS{curae};
	}

	sub has_curae {
		return exists $ACCESSORS{curae};
	}

	sub clear_curae {
		delete $ACCESSORS{curae};
		return 1;
	}

	sub penthos {
		my ($value) = @_;
		my $private_caller = caller();
		if ( $private_caller ne __PACKAGE__ ) {
			die "cannot call private method penthos from $private_caller";
		}
		if ( defined $value ) {
			if ( ref $value || $value !~ m/^[-+\d]\d*$/ ) {
				die qq{Int: invalid value $value for accessor penthos};
			}
			$ACCESSORS{penthos} = $value;
		}
		return $ACCESSORS{penthos};
	}

	sub has_penthos {
		return exists $ACCESSORS{penthos};
	}

	sub clear_penthos {
		delete $ACCESSORS{penthos};
		return 1;
	}

	sub geras {
		my ($nosoi) = @_;
		$nosoi = defined $nosoi ? $nosoi : 5;
		if ( !defined($nosoi) || ref $nosoi || $nosoi !~ m/^[-+\d]\d*$/ ) {
			$nosoi = defined $nosoi ? $nosoi : 'undef';
			die
			    qq{Int: invalid value $nosoi for variable \$nosoi in method geras};
		}
		if ( penthos() == $nosoi ) { return curae(); }
	}

	1;

	__END__

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Realm::Exporter object.

	Hades::Realm::Exporter->new

=head2 build_self

call build_self method. Expects param $name to be a Optional[Str].

	$obj->build_self($name)

=head2 default_export_hash

call default_export_hash method. Expects param $mg to be a Object, param $class to be a HashRef, param $export to be a HashRef.

	$obj->default_export_hash($mg, $class, $export)

=head2 build_new

call build_new method. Expects param $mg to be a Object, param $meta to be a HashRef, param $our to be any value including undef.

	$obj->build_new($mg, $meta, $our)

=head2 build_exporter

call build_exporter method. Expects param $begin to be a Str, param $mg to be a Object, param $export to be a HashRef, param $meta to be a HashRef.

	$obj->build_exporter($begin, $mg, $export, $meta)

=head2 build_export_tags

call build_export_tags method. Expects param $name to be a Str, param $type to be a Str, param $export to be a HashRef, param $now to be a Optional[Int], param $import to be a ArrayRef.

	$obj->build_export_tags($name, $type, $export, $now, $import)

=head2 after_class

call after_class method. Expects param $mg to be a Object.

	$obj->after_class($mg)

=head2 build_sub_or_accessor_attributes

call build_sub_or_accessor_attributes method.

=head2 build_accessor_no_arguments

call build_accessor_no_arguments method. Expects param $mg to be any value including undef, param $token to be any value including undef, param $meta to be any value including undef.

	$obj->build_accessor_no_arguments($mg, $token, $meta)

=head2 build_accessor_code

call build_accessor_code method. Expects param $name to be a Str, param $private to be a Str, param $type to be a Str, param $trigger to be a Str.

	$obj->build_accessor_code($name, $private, $type, $trigger)

=head2 build_accessor

call build_accessor method.

=head2 build_modify

call build_modify method. Expects no params.

	$obj->build_modify()

=head2 build_sub_no_arguments

call build_sub_no_arguments method. Expects param $mg to be any value including undef, param $token to be any value including undef, param $meta to be any value including undef.

	$obj->build_sub_no_arguments($mg, $token, $meta)

=head2 build_sub_code

call build_sub_code method. Expects param $name to be a Str, param $params to be a Str, param $subtype to be a Str, param $code to be a Str.

	$obj->build_sub_code($name, $params, $subtype, $code)

=head2 build_sub

call build_sub method.

=head2 build_clearer

call build_clearer method. Expects param $mg to be a Object, param $name to be a Str, param $meta to be a HashRef.

	$obj->build_clearer($mg, $name, $meta)

=head2 build_predicate

call build_predicate method. Expects param $mg to be a Object, param $name to be a Str, param $meta to be a HashRef.

	$obj->build_predicate($mg, $name, $meta)

=head2 build_coerce

call build_coerce method. Expects param $name to be a Str, param $param to be a Str, param $code to be a Optional[Str].

	$obj->build_coerce($name, $param, $code)

=head2 build_trigger

call build_trigger method. Expects param $name to be a Str, param $param to be a Str, param $code to be a Optional[Str].

	$obj->build_trigger($name, $param, $code)

=head2 build_tests

call build_tests method. Expects param $name to be a Str, param $meta to be a HashRef, param $mod to be a Optional[Str], param $class to be a Optional[HashRef].

	$obj->build_tests($name, $meta, $mod, $class)

=head1 ACCESSORS

=head2 export

get or set export.

	$obj->export;

	$obj->export($value);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::realm::exporter at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Realm-Exporter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Realm::Exporter

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Realm-Exporter>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Realm-Exporter>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
