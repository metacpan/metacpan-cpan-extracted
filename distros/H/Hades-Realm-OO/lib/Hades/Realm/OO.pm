package Hades::Realm::OO;
use strict;
use warnings;
use base qw/Hades/;
our $VERSION = 0.06;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = $cls->SUPER::new(%args);
	my %accessors = ( is_role => {}, meta => {}, current_class => {}, );
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

sub current_class {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ref $value ) {
			die qq{Str: invalid value $value for accessor current_class};
		}
		$self->{current_class} = $value;
	}
	return $self->{current_class};
}

sub meta {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "HASH" ) {
			die
			    qq{Map[Str, Dict[types => HashRef, attributes => HashRef]]: invalid value $value for accessor meta};
		}
		for my $key ( keys %{$value} ) {
			my $val = $value->{$key};
			if ( ref $key ) {
				die
				    qq{Map[Str, Dict[types => HashRef, attributes => HashRef]]: invalid value $key for accessor meta expected Str};
			}
			if ( ( ref($val) || "" ) ne "HASH" ) {
				$val = defined $val ? $val : 'undef';
				die
				    qq{Map[Str, Dict[types => HashRef, attributes => HashRef]]: invalid value $val for accessor meta expected Dict[types=>HashRef,attributes=>HashRef]};
			}
			if ( ( ref( $val->{types} ) || "" ) ne "HASH" ) {
				$val->{types}
				    = defined $val->{types} ? $val->{types} : 'undef';
				die
				    qq{Map[Str, Dict[types => HashRef, attributes => HashRef]]: invalid value $val->{types} for accessor meta expected Dict[types=>HashRef,attributes=>HashRef] expected HashRef for types};
			}
			if ( ( ref( $val->{attributes} ) || "" ) ne "HASH" ) {
				$val->{attributes}
				    = defined $val->{attributes}
				    ? $val->{attributes}
				    : 'undef';
				die
				    qq{Map[Str, Dict[types => HashRef, attributes => HashRef]]: invalid value $val->{attributes} for accessor meta expected Dict[types=>HashRef,attributes=>HashRef] expected HashRef for attributes};
			}
		}
		$self->{meta} = $value;
	}
	return $self->{meta};
}

sub is_role {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		my $ref = ref $value;
		if (   ( $ref || 'SCALAR' ) ne 'SCALAR'
			|| ( $ref ? $$value : $value ) !~ m/^(1|0)$/ )
		{
			die qq{Bool: invalid value $value for accessor is_role};
		}
		$value = !!( $ref ? $$value : $value ) ? 1 : 0;
		$self->{is_role} = $value;
	}
	return $self->{is_role};
}

sub clear_is_role {
	my ($self) = @_;
	delete $self->{is_role};
	return $self;
}

sub module_generate {
	my ( $self, $mg ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method module_generate};
	}

	$mg->keyword(
		'has',
		CODE        => sub { $self->build_has(@_) },
		KEYWORDS    => $self->build_has_keywords,
		POD_TITLE   => 'ATTRIBUTES',
		POD_POD     => 'Get or set $keyword',
		POD_EXAMPLE => "\$obj->\$keyword;\n\n\t\$obj->\$keyword(\$value)"
	);
	$mg->keyword(
		'extends',
		CODE        => sub { $self->build_extends(@_) },
		KEYWORDS    => $self->build_extends_keywords,
		POD_TITLE   => 'EXTENDS',
		POD_POD     => 'This class extends the following classes',
		POD_EXAMPLE => "\$keyword"
	);
	$mg->keyword(
		'with',
		CODE        => sub { $self->build_with(@_) },
		KEYWORDS    => $self->build_with_keywords,
		POD_TITLE   => 'WITH',
		POD_POD     => 'This class includes the following roles',
		POD_EXAMPLE => "\$keyword"
	);
	$mg->keyword(
		'requires',
		CODE        => sub { $self->build_requires(@_) },
		KEYWORDS    => $self->build_requires_keywords,
		POD_TITLE   => 'REQUIRES',
		POD_POD     => 'This class requires:',
		POD_EXAMPLE => "\$keyword"
	);
	$mg->keyword(
		'before',
		CODE        => sub { $self->build_before(@_) },
		KEYWORDS    => $self->build_before_keywords,
		POD_TITLE   => 'BEFORE',
		POD_POD     => 'Call $keyword method',
		POD_EXAMPLE => "\$obj->\$keyword"
	);
	$mg->keyword(
		'around',
		CODE        => sub { $self->build_around(@_) },
		KEYWORDS    => $self->build_around_keywords,
		POD_TITLE   => 'AROUND',
		POD_POD     => 'Call $keyword method',
		POD_EXAMPLE => "\$obj->\$keyword"
	);
	$mg->keyword(
		'after',
		CODE        => sub { $self->build_after(@_) },
		KEYWORDS    => $self->build_after_keywords,
		POD_TITLE   => 'AFTER',
		POD_POD     => 'Call $keyword method',
		POD_EXAMPLE => "\$obj->\$keyword"
	);

}

sub build_class_inheritance {
	my ( $orig, $self, @params ) = ( 'SUPER::build_class_inheritance', @_ );

	if ( $params[-1] =~ m/^(role)$/i ) {
		$self->is_role(1);
		return $params[-2];
	}
	elsif ( $params[-1] =~ m/^(with|extends|parent|base)$/ ) {
		return 'extends' if $1 =~ m/parent|base/;
		return $params[-1];
	}
	elsif ( $params[-2] && $params[-2] =~ m/^(with|extends)$/ ) {
		my ( $mg, $last, $ident ) = splice @params, -3;
		$mg->$last($ident);
		return $last;
	}
	my @res = $self->$orig(@params);
	return wantarray ? @res : $res[0];
}

sub build_new {
	my ( $self, $mg, $meta, $types ) = @_;
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
	$types = defined $types ? $types : {};
	if ( ( ref($types) || "" ) ne "HASH" ) {
		$types = defined $types ? $types : 'undef';
		die
		    qq{HashRef: invalid value $types for variable \$types in method build_new};
	}

	my %class     = %Module::Generate::CLASS;
	my %accessors = ();
	map {
		my $key = $_;
		exists $meta->{$key}->{$_}
		    && do { $accessors{$key}->{$_} = $meta->{$key}->{$_} }
		    for ( @{ $self->build_has_keywords } );
	} grep {
		$self->unique_types( $meta->{$_}->{type}, $types )
		    if $meta->{$_}->{type};
		$meta->{$_}->{meta} eq 'ACCESSOR';
	} keys %{$meta};
	my $class_meta = $self->meta;
	$class_meta->{ $class{CURRENT}{NAME} } = {
		types      => $types,
		attributes => \%accessors
	};
	$self->meta($class_meta);
	$self->current_class( $class{CURRENT}{NAME} );
	$class{CURRENT}{SUBS}{new}{NO_CODE} = 1;
	$class{CURRENT}{SUBS}{new}{TEST}
	    = [ $self->build_tests( 'new', $meta, 'new', \%class ) ];

}

sub build_clearer {
	my ( $orig, $self, @params ) = ( 'SUPER::build_clearer', @_ );
	my @res = $self->$orig(@params);
	$res[0]->no_code(1);

	return wantarray ? @res : $res[0];
}

sub build_predicate {
	my ( $orig, $self, @params ) = ( 'SUPER::build_predicate', @_ );
	my @res = $self->$orig(@params);
	$res[0]->no_code(1);

	return wantarray ? @res : $res[0];
}

sub build_accessor_no_arguments {
	my ( $self, $mg, $token, $meta ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_accessor_no_arguments};
	}
	if ( !defined($token) || ( ref($token) || "" ) ne "ARRAY" ) {
		$token = defined $token ? $token : 'undef';
		die
		    qq{ArrayRef: invalid value $token for variable \$token in method build_accessor_no_arguments};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_accessor_no_arguments};
	}

	$meta->{ $token->[0] }->{meta} = 'ACCESSOR';
	$mg->has( $token->[0] );
	return $meta;

}

sub build_accessor {
	my ( $self, $mg, $name, $meta ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_accessor};
	}
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_accessor};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_accessor};
	}

	$mg->has($name);
	$meta->{$name}->{$_} and $mg->$_(
		$self->build_code(
			$mg,
			$name,
			$self->can("build_accessor_${_}")
			? $self->can("build_accessor_${_}")
			    ->( $self, $name, $meta->{$name}->{$_} )
			: $meta->{$name}->{$_}
		)
	) for ( @{ $self->build_has_keywords } );
	$mg->isa(
		  $self->can("build_accessor_isa")
		? $self->can("build_accessor_isa")
		    ->( $self, $name, $meta->{$name}->{type}->[0] )
		: $meta->{$name}->{type}->[0]
	) if !$meta->{$name}->{isa};
	$mg->clear_tests->test( $self->build_tests( $name, $meta->{$name} ) );
	$meta->{$name}->{$_}
	    && $mg->$_( $self->replace_pe_string( $meta->{$name}->{$_}, $name ) )
	    for qw/pod example/;

}

sub build_modify {
	my ( $self, $mg, $name, $meta ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_modify};
	}
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_modify};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_modify};
	}

	$meta->{$name}->{$_}
	    && $mg->$_($name)
	    ->code( $self->build_code( $mg, $name, delete $meta->{$name}->{$_} ) )
	    ->test( $self->build_tests( $name, $meta->{$name} ) )
	    for qw/before around after/;
	$meta->{$name}->{$_}
	    && $mg->$_(
		$self->replace_pe_string( delete $meta->{$name}->{$_}, $name ) )
	    for qw/pod example/;

}

sub after_class {
	my ( $self, $mg, $meta ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method after_class};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method after_class};
	}

	$self->is_role && $self->clear_is_role
	    ? $self->build_as_role( $mg, $meta )
	    : $self->build_as_class( $mg, $meta );

}

sub unique_types {
	my ( $self, $type, $unique ) = @_;
	if ( ref $type eq 'ARRAY' ) {
		$self->unique_types( $_, $unique ) for @{$type};
		return;
	}
	if ( !defined($type) || ref $type ) {
		$type = defined $type ? $type : 'undef';
		die
		    qq{Str: invalid value $type for variable \$type in method unique_types};
	}
	if ( ( ref($unique) || "" ) ne "HASH" ) {
		$unique = defined $unique ? $unique : 'undef';
		die
		    qq{HashRef: invalid value $unique for variable \$unique in method unique_types};
	}

	if ( $type =~ s/^([^\[ ]+)\[(.*)\]$/$2/ ) {
		my ( $t, $v ) = ( $1, $2 );
		$unique->{$t}++ if ( $t =~ m/^\w+$/ );
		$v =~ s/,\s*\d+,\s*\d+$//g;
		$self->unique_types( $v, $unique );
	}
	elsif ( $type =~ m/^\s*\w+\s*\=\>\s*/ || $type =~ m/^([^,]+),\s*(.*)$/ ) {
		my @matches = split ',', $type;
		while (@matches) {
			my ($match) = ( shift @matches );
			if ( @matches && $match =~ m/(Map|Tuple|ArrayRef|Dict)\[/ ) {
				my $cb = sub {
					my $copy = shift;
					1 while ( $copy =~ s/\[[^\[\]]+\]//g );
					return ( $copy =~ m/\[|\]/ ) ? 1 : 0;
				};
				1 while ( $cb->( $match .= ', ' . shift @matches ) );
			}
			my ( $k, $v )
			    = map { my $h = $_; $h =~ s/^\s*|\s*$//g; $h; }
			    $match =~ m/\s+\w*\s*\=\>/
			    ? split( '=>', $match, 2 )
			    : $match;
			$self->unique_types( $v || $k, $unique );
		}
	}
	else {
		$unique->{$type}++;
	}

}

sub build_as_class {
	my ( $self, $mg, $meta ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_as_class};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_as_class};
	}
	return ( $mg, $meta );
}

sub build_as_role {
	my ( $self, $mg, $meta ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method build_as_role};
	}
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_as_role};
	}
	return ( $mg, $meta );
}

sub build_has_keywords {
	my ( $self, $keywords ) = @_;
	$keywords
	    = defined $keywords
	    ? $keywords
	    : [
		qw/is isa required default clearer coerce predicate trigger private builder/
	    ];
	if ( !defined($keywords) || ( ref($keywords) || "" ) ne "ARRAY" ) {
		$keywords = defined $keywords ? $keywords : 'undef';
		die
		    qq{ArrayRef: invalid value $keywords for variable \$keywords in method build_has_keywords};
	}
	return $keywords;
}

sub build_has {
	my ( $self, $meta ) = @_;
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_has};
	}

	my $name    = $meta->{has};
	my $private = $self->SUPER::build_private( $name, $meta->{private} );
	my $type = $self->SUPER::build_coerce( $name, '$value', $meta->{coerce} )
	    . $self->build_type( $name, $meta->{type}[0] );
	my $trigger
	    = $self->SUPER::build_trigger( $name, '$value', $meta->{trigger} );
	return qq|{
			my ( \$self, \$value ) = \@_; $private
			if ( defined \$value ) { $type
				$self->{$name} = \$value; $trigger
			}
			return $self->{$name};
		}|;

}

sub build_extends_keywords {
	my ( $self, $keywords ) = @_;
	$keywords = defined $keywords ? $keywords : [];
	if ( !defined($keywords) || ( ref($keywords) || "" ) ne "ARRAY" ) {
		$keywords = defined $keywords ? $keywords : 'undef';
		die
		    qq{ArrayRef: invalid value $keywords for variable \$keywords in method build_extends_keywords};
	}
	return $keywords;
}

sub build_extends {
	my ( $self, $meta ) = @_;
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_extends};
	}

	$meta->{extends} = '"' . $meta->{extends} . '"'
	    if $meta->{extends} !~ m/^["'q]/;
	return qq(extends $meta->{extends};);

}

sub build_with_keywords {
	my ( $self, $keywords ) = @_;
	$keywords = defined $keywords ? $keywords : [];
	if ( !defined($keywords) || ( ref($keywords) || "" ) ne "ARRAY" ) {
		$keywords = defined $keywords ? $keywords : 'undef';
		die
		    qq{ArrayRef: invalid value $keywords for variable \$keywords in method build_with_keywords};
	}
	return $keywords;
}

sub build_with {
	my ( $self, $meta ) = @_;
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_with};
	}

	$meta->{with} = '"' . $meta->{with} . '"' if $meta->{with} !~ m/^["'q]/;
	return qq(with $meta->{with};);

}

sub build_requires_keywords {
	my ( $self, $keywords ) = @_;
	$keywords = defined $keywords ? $keywords : [];
	if ( !defined($keywords) || ( ref($keywords) || "" ) ne "ARRAY" ) {
		$keywords = defined $keywords ? $keywords : 'undef';
		die
		    qq{ArrayRef: invalid value $keywords for variable \$keywords in method build_requires_keywords};
	}
	return $keywords;
}

sub build_requires {
	my ( $self, $meta ) = @_;
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_requires};
	}

	$meta->{requires} = '"' . $meta->{requires} . '"'
	    if $meta->{requires} !~ m/^["'q]/;
	return qq(requires $meta->{requires};);

}

sub build_before_keywords {
	my ( $self, $keywords ) = @_;
	$keywords = defined $keywords ? $keywords : [];
	if ( !defined($keywords) || ( ref($keywords) || "" ) ne "ARRAY" ) {
		$keywords = defined $keywords ? $keywords : 'undef';
		die
		    qq{ArrayRef: invalid value $keywords for variable \$keywords in method build_before_keywords};
	}
	return $keywords;
}

sub build_before {
	my ( $self, $meta ) = @_;
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_before};
	}

	return
	    qq(before $meta->{before} => sub { my (\$orig, \$self, \@params) = \@_; $meta->{CODE} };);

}

sub build_around_keywords {
	my ( $self, $keywords ) = @_;
	$keywords = defined $keywords ? $keywords : [];
	if ( !defined($keywords) || ( ref($keywords) || "" ) ne "ARRAY" ) {
		$keywords = defined $keywords ? $keywords : 'undef';
		die
		    qq{ArrayRef: invalid value $keywords for variable \$keywords in method build_around_keywords};
	}
	return $keywords;
}

sub build_around {
	my ( $self, $meta ) = @_;
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_around};
	}

	return
	    qq(around $meta->{around} => sub { my (\$orig, \$self, \@params) = \@_; $meta->{CODE} };);

}

sub build_after_keywords {
	my ( $self, $keywords ) = @_;
	$keywords = defined $keywords ? $keywords : [];
	if ( !defined($keywords) || ( ref($keywords) || "" ) ne "ARRAY" ) {
		$keywords = defined $keywords ? $keywords : 'undef';
		die
		    qq{ArrayRef: invalid value $keywords for variable \$keywords in method build_after_keywords};
	}
	return $keywords;
}

sub build_after {
	my ( $self, $meta ) = @_;
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_after};
	}

	return
	    qq(after $meta->{after} => sub { my (\$orig, \@params) = \@_; $meta->{CODE} };);

}

sub build_accessor_builder {
	my ( $self, $name, $content ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_accessor_builder};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method build_accessor_builder};
	}

	return (
		$content =~ m/^(\w+|1)$/
		? qq|$content|
		: qq|sub {
					my (\$self, \$value) = \@_; 
					$content
					return \$value;
				}|
	);

}

sub build_accessor_coerce {
	my ( $self, $name, $content ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_accessor_coerce};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method build_accessor_coerce};
	}

	return q|sub { my ($value) = @_;|
	    . (
		$content =~ m/^\w+$/
		? qq|\$value = __PACKAGE__->$content(\$value);|
		: $content
	    ) . q|return $value; }|;

}

sub build_accessor_trigger {
	my ( $self, $name, $content ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_accessor_trigger};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method build_accessor_trigger};
	}

	return q|sub { my ($self, $value) = @_;|
	    . (
		$content =~ m/^\w+$/
		? qq|\$value = \$self->$content(\$value);|
		: $content
	    ) . q|return $value; }|;

}

sub build_accessor_default {
	my ( $self, $name, $content ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_accessor_default};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method build_accessor_default};
	}

	return q|sub {| . $content . q|}|;

}

1;

__END__

=head1 NAME

Hades::Realm::OO - Hades realm for object orientation

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	Hades::Realm::Kosmos base Hades::Realm::OO {
                ...
        }

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Realm::OO object.

	Hades::Realm::OO->new

=head2 clear_is_role

clear is_role accessor

	$obj->clear_is_role

=head2 module_generate

call module_generate method. Expects param $mg to be a Object.

	$obj->module_generate($mg)

=head2 build_class_inheritance

call build_class_inheritance method.

=head2 build_new

call build_new method. Expects param $mg to be a Object, param $meta to be a HashRef, param $types to be a HashRef.

	$obj->build_new($mg, $meta, $types)

=head2 build_clearer

call build_clearer method.

=head2 build_predicate

call build_predicate method.

=head2 build_accessor_no_arguments

call build_accessor_no_arguments method. Expects param $mg to be a Object, param $token to be a ArrayRef, param $meta to be a HashRef.

	$obj->build_accessor_no_arguments($mg, $token, $meta)

=head2 build_accessor

call build_accessor method. Expects param $mg to be a Object, param $name to be a Str, param $meta to be a HashRef.

	$obj->build_accessor($mg, $name, $meta)

=head2 build_modify

call build_modify method. Expects param $mg to be a Object, param $name to be a Str, param $meta to be a HashRef.

	$obj->build_modify($mg, $name, $meta)

=head2 after_class

call after_class method. Expects param $mg to be a Object, param $meta to be a HashRef.

	$obj->after_class($mg, $meta)

=head2 unique_types

call unique_types method. Expects param $type to be a Str, param $unique to be a HashRef.

	$obj->unique_types($type, $unique)

=head2 build_as_class

call build_as_class method. Expects param $mg to be a Object, param $meta to be a HashRef.

	$obj->build_as_class($mg, $meta)

=head2 build_as_role

call build_as_role method. Expects param $mg to be a Object, param $meta to be a HashRef.

	$obj->build_as_role($mg, $meta)

=head2 build_has_keywords

call build_has_keywords method. Expects param $keywords to be a ArrayRef.

	$obj->build_has_keywords($keywords)

=head2 build_has

call build_has method. Expects param $meta to be a HashRef.

	$obj->build_has($meta)

=head2 build_extends_keywords

call build_extends_keywords method. Expects param $keywords to be a ArrayRef.

	$obj->build_extends_keywords($keywords)

=head2 build_extends

call build_extends method. Expects param $meta to be a HashRef.

	$obj->build_extends($meta)

=head2 build_with_keywords

call build_with_keywords method. Expects param $keywords to be a ArrayRef.

	$obj->build_with_keywords($keywords)

=head2 build_with

call build_with method. Expects param $meta to be a HashRef.

	$obj->build_with($meta)

=head2 build_requires_keywords

call build_requires_keywords method. Expects param $keywords to be a ArrayRef.

	$obj->build_requires_keywords($keywords)

=head2 build_requires

call build_requires method. Expects param $meta to be a HashRef.

	$obj->build_requires($meta)

=head2 build_before_keywords

call build_before_keywords method. Expects param $keywords to be a ArrayRef.

	$obj->build_before_keywords($keywords)

=head2 build_before

call build_before method. Expects param $meta to be a HashRef.

	$obj->build_before($meta)

=head2 build_around_keywords

call build_around_keywords method. Expects param $keywords to be a ArrayRef.

	$obj->build_around_keywords($keywords)

=head2 build_around

call build_around method. Expects param $meta to be a HashRef.

	$obj->build_around($meta)

=head2 build_after_keywords

call build_after_keywords method. Expects param $keywords to be a ArrayRef.

	$obj->build_after_keywords($keywords)

=head2 build_after

call build_after method. Expects param $meta to be a HashRef.

	$obj->build_after($meta)

=head2 build_accessor_builder

call build_accessor_builder method. Expects param $name to be a Str, param $content to be a Str.

	$obj->build_accessor_builder($name, $content)

=head2 build_accessor_coerce

call build_accessor_coerce method. Expects param $name to be a Str, param $content to be a Str.

	$obj->build_accessor_coerce($name, $content)

=head2 build_accessor_trigger

call build_accessor_trigger method. Expects param $name to be a Str, param $content to be a Str.

	$obj->build_accessor_trigger($name, $content)

=head2 build_accessor_default

call build_accessor_default method. Expects param $name to be a Str, param $content to be a Str.

	$obj->build_accessor_default($name, $content)

=head1 ACCESSORS

=head2 current_class

get or set current_class.

	$obj->current_class;

	$obj->current_class($value);

=head2 meta

get or set meta.

	$obj->meta;

	$obj->meta($value);

=head2 is_role

get or set is_role.

	$obj->is_role;

	$obj->is_role($value);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::realm::oo at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Realm-OO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Realm::OO

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Realm-OO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Realm-OO>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Realm-OO>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Realm-OO>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
