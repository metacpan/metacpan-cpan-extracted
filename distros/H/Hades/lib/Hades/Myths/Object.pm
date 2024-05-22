package Hades::Myths::Object;
use strict;
use warnings;
use POSIX qw/locale_h/;
our $VERSION = 0.22;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self = bless {}, $cls;
	my %accessors = (
		locales => {
			builder => sub {
				my ( $self, $value ) = @_;
				$value = $self->_build_locales($value);
				return $value;
			}
		},
		fb     => { default => 'en', },
		locale => {
			builder => sub {
				my ( $self, $value ) = @_;
				$value = $self->_build_locale($value);
				return $value;
			}
		},
		language => {},
	);
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

sub fb {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ref $value ) {
			die qq{Str: invalid value $value for accessor fb};
		}
		$self->{fb} = $value;
	}
	return $self->{fb};
}

sub locale {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ref $value ) {
			die qq{Str: invalid value $value for accessor locale};
		}
		$self->{locale} = $value;
		$self->_set_language_from_locale($value);
	}
	return $self->{locale};
}

sub _build_locale {
	my ( $self, $locale ) = @_;
	if ( defined $locale ) {
		if ( ref $locale ) {
			die
			    qq{Optional[Str]: invalid value $locale for variable \$locale in method _build_locale};
		}
	}

	return $locale || setlocale(LC_CTYPE);

}

sub _set_language_from_locale {
	my ( $self, $value ) = @_;
	if ( !defined($value) || ref $value ) {
		$value = defined $value ? $value : 'undef';
		die
		    qq{Str: invalid value $value for variable \$value in method _set_language_from_locale};
	}

	unless ( $self->has_language ) {
		my ( $locale, $lang ) = $self->convert_locale($value);
		if ($lang) { $self->language($lang); }
	}

}

sub language {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ref $value ) {
			die qq{Str: invalid value $value for accessor language};
		}
		$self->{language} = $value;
	}
	return $self->{language};
}

sub has_language {
	my ($self) = @_;
	return exists $self->{language};
}

sub locales {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "HASH" ) {
			die
			    qq{Map[Str, HashRef]: invalid value $value for accessor locales};
		}
		for my $key ( keys %{$value} ) {
			my $val = $value->{$key};
			if ( ref $key ) {
				die
				    qq{Map[Str, HashRef]: invalid value $key for accessor locales expected Str};
			}
			if ( ( ref($val) || "" ) ne "HASH" ) {
				$val = defined $val ? $val : 'undef';
				die
				    qq{Map[Str, HashRef]: invalid value $val for accessor locales expected HashRef};
			}
		}
		$self->{locales} = $value;
	}
	return $self->{locales};
}

sub _build_locales {
	my ( $self, $values ) = @_;
	$values = defined $values ? $values : {};
	if ( ( ref($values) || "" ) ne "HASH" ) {
		$values = defined $values ? $values : 'undef';
		die
		    qq{HashRef: invalid value $values for variable \$values in method _build_locales};
	}

	my ($debug_steps) = debug_steps();
	return {
		%{$values}, %{$debug_steps},
		( $self->locales ? ( %{ $self->locales } ) : () )
	};

}

sub convert_locale {
	my ( $self, $locale, $fb ) = @_;
	if ( !defined($locale) || ref $locale ) {
		$locale = defined $locale ? $locale : 'undef';
		die
		    qq{Str: invalid value $locale for variable \$locale in method convert_locale};
	}
	$fb = defined $fb ? $fb : "en";
	if ( !defined($fb) || ref $fb ) {
		$fb = defined $fb ? $fb : 'undef';
		die
		    qq{Str: invalid value $fb for variable \$fb in method convert_locale};
	}

	$locale =~ m/^(\w\w)_(\w\w).*/;
	return $1 && $2 ? ( $1 . '_' . $2, $1, $fb ) : ( $locale, $fb, $fb );

}

sub add {
	my ( $self, $key, $locales ) = @_;
	if ( !defined($key) || ref $key ) {
		$key = defined $key ? $key : 'undef';
		die qq{Str: invalid value $key for variable \$key in method add};
	}
	if ( ( ref($locales) || "" ) ne "HASH" ) {
		$locales = defined $locales ? $locales : 'undef';
		die
		    qq{Map[Str, HashRef]: invalid value $locales for variable \$locales in method add};
	}
	for my $key ( keys %{$locales} ) {
		my $val = $locales->{$key};
		if ( ref $key ) {
			die
			    qq{Map[Str, HashRef]: invalid value $key for variable \$locales in method add expected Str};
		}
		if ( ( ref($val) || "" ) ne "HASH" ) {
			$val = defined $val ? $val : 'undef';
			die
			    qq{Map[Str, HashRef]: invalid value $val for variable \$locales in method add expected HashRef};
		}
	}

	$self->locales->{$key} = { %{ $self->locales->{$key} }, %{$locales} };

}

sub string {
	my ( $self, $key, $locale, $lang, $fb ) = @_;
	if ( !defined($key) || ref $key ) {
		$key = defined $key ? $key : 'undef';
		die qq{Str: invalid value $key for variable \$key in method string};
	}
	$locale = defined $locale ? $locale : $self->locale;
	if ( !defined($locale) || ref $locale ) {
		$locale = defined $locale ? $locale : 'undef';
		die
		    qq{Str: invalid value $locale for variable \$locale in method string};
	}
	$lang = defined $lang ? $lang : $self->language;
	if ( !defined($lang) || ref $lang ) {
		$lang = defined $lang ? $lang : 'undef';
		die qq{Str: invalid value $lang for variable \$lang in method string};
	}
	$fb = defined $fb ? $fb : $self->fb;
	if ( !defined($fb) || ref $fb ) {
		$fb = defined $fb ? $fb : 'undef';
		die qq{Str: invalid value $fb for variable \$fb in method string};
	}

	die "string $key is empty"
	    if ( !ref $self->locales->{$key}
		|| !scalar keys %{ $self->locales->{$key} } );
	$_ && exists $self->locales->{$key}->{$_}
	    and return $self->locales->{$key}->{$_}
	    for ( $locale, $lang, $fb );
	return $self->locales->{$key}
	    ->{ [ keys %{ $self->locales->{$key} } ]->[0] };

}

sub debug_steps {
	my ( $self, $steps ) = @_;

	$steps = {
		debug_step_1 => { en => 'About to run hades with %s.', },
		debug_step_2 =>
		    { en => 'Parsing the eval string of length %s into classes.', },
		debug_step_3 =>
		    { en => 'Parsed the eval string into %s number of classes.', },
		debug_step_4 => {
			en => 'Set the Module::Generate %s accessor with the value %s.'
		},
		debug_step_5 => { en => 'Start building macros' },
		debug_step_6 => { en => 'Build macro' },
		debug_step_7 => { en => 'Attempt to import %s macro object.' },
		debug_step_8 => { en => 'Successfully imported %s macro object.', },
		debug_step_9 =>
		    { en => 'Attempt to import %s macro from the hades file.' },
		debug_step_10 =>
		    { en => 'Successfully imported %s macro from the hades file.' },
		debug_step_11   => { en => 'Successfully built macros.' },
		debug_step_12   => { en => 'Building Module::Generate class %s.' },
		debug_step_13   => { en => 'Parsing class token.' },
		debug_step_14   => { en => 'Setting last inheritance token: %s.' },
		debug_step_14_b => { en => 'The last token was: %s.' },
		debug_step_15 =>
		    { en => 'Call Module::Generate\'s %s method with the value %s.' },
		debug_step_16 =>
		    { en => 'Build a accessor named %s with no arguments.' },
		debug_step_17 => { en => 'Build the classes %s.' },
		debug_step_18 => { en => 'Build a sub named %s with no arguments.' },
		debug_step_19 =>
		    { en => 'Declare the classes global our variables', },
		debug_step_20 => {
			en => 'Found a group of attributes or subs so will iterrate each.'
		},
		debug_step_21 =>
		    { en => 'Building attributes for a sub or accessor named %s.' },
		debug_step_22 => { en => 'Built attributes for %s.' },
		debug_step_23 => { en => 'Constructing accessor named %s.' },
		debug_step_24 => { en => 'Built private code for %s.' },
		debug_step_25 => { en => 'Built coerce code for %s.' },
		debug_step_26 => { en => 'Built type code for %s.' },
		debug_step_27 => { en => 'Built trigger for %s.' },
		debug_step_28 => { en => 'Constructed accessor named %s.' },
		debug_step_29 => { en => 'Construct a modify sub routine named %s.' },
		debug_step_30 =>
		    { en => 'Constructed a modify sub routine named %s.' },
		debug_step_31 => { en => 'Construct a sub routine named %s.' },
		debug_step_32 => { en => 'Constructed a sub routine named %s.' },
		debug_step_33 =>
		    { en => 'Construct the new sub routine for class %s.' },
		debug_step_34 =>
		    { en => 'Constructed the new sub routine for class %s.' },
		debug_step_35 => { en => 'Finished Compiling the class.' },
		debug_step_36 => { en => 'Finished Compiling all classes.' },
		debug_step_37 => {
			en =>
			    'Calling Module::Generates generate method which will write the files to disk.'
		},
		debug_step_38 => { en => 'Constructing code for %s.', },
		debug_step_39 => { en => 'Build macro for: %s.' },
		debug_step_40 => { en => 'Matched macro %s that has parameters.' },
		debug_step_41 => { en => 'Macro %s has a code callback.' },
		debug_step_42 => { en => 'Generated code for macro %s.' },
		debug_step_43 => { en => 'Match macro %s that has no parameters.' },
		debug_step_44 => { en => 'Constructed code for %s.', },
		debug_step_45 => { en => 'Constructing predicate named has_%s.' },
		debug_step_46 => { en => 'Constructed predicate named has_%s.' },
		debug_step_47 => { en => 'Constructing clearer named clearer_%s.' },
		debug_step_48 => { en => 'Constructed clearer named clearer_%s.' },
		press_enter_to_continue => { en => 'Press enter to continue' },
	};
	return $steps;

}

sub DESTROY {
	my ($self) = @_;

}

sub AUTOLOAD {
	my ($self) = @_;

	my ( $cls, $vn ) = ( ref $_[0], q{[^:'[:cntrl:]]{0,1024}} );
	our $AUTOLOAD =~ /^${cls}::($vn)$/;
	return $self->string($1) if $1;

}

1;

__END__

=head1 NAME

Hades::Myths::Object - display text locally.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	use Hades::Myths::Object;

	my $locales = Hades::Myths::Object->new({
		locale => 'ja_JP',
		locales => {
			stranger => {
				en_GB => 'Hello stranger',
				en_US => 'Howdy stranger',
				ja_JP => 'こんにちは見知らぬ人'
			},
		}
	});

	say $locales->stranger;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Myths::Object object.

	Hades::Myths::Object->new

=head2 _build_locale

call _build_locale method. Expects param $locale to be a Optional[Str].

	$obj->_build_locale($locale)

=head2 _set_language_from_locale

call _set_language_from_locale method. Expects param $value to be a Str.

	$obj->_set_language_from_locale($value)

=head2 has_language

has_language will return true if language accessor has a value.

	$obj->has_language

=head2 _build_locales

call _build_locales method. Expects param $values to be a HashRef.

	$obj->_build_locales($values)

=head2 convert_locale

Split a locale into locale and language.

	$obj->convert_locale($locale, $fb)

=head2 add

Add an item into the locales. This method expects a reference $key that should be a Str and a locales HashRef where the keys are locales and the values are the text string.

	locales->add('stranger', {
		en_US => 'Howdy stranger!'
	});
	

=head2 string

call string method. Expects param $key to be a Str, param $locale to be a Str, param $lang to be a Str, param $fb to be a Str.

	$obj->string($key, $locale, $lang, $fb)

=head2 debug_steps

call debug_steps method. Expects param $steps to be any value including undef.

	$obj->debug_steps($steps)

=head2 DESTROY

call DESTROY method. Expects no params.

	$obj->DESTROY()

=head2 AUTOLOAD

call AUTOLOAD method. Expects no params.

	$obj->AUTOLOAD()

=head1 ACCESSORS

=head2 fb

The fallback locale/language that is used when no value in the locales hash matches the objects locale or language. You can get or set this attribute and it expects a Str value. This attribute will default to be 'en'.

	$obj->fb;

	$obj->fb($value);

=head2 locale

The locale that will be checked for first when stringiying. You can get or set this attribute and it expects a Str value. This attribute will default to use Posix::setlocale

	$obj->locale;

	$obj->locale($value);

=head2 language

The language that will be checked for second when stringifying. You can get or set this attribute and it expects a Str value. This attribute will be defaulted to be the first part of a locale.

	$obj->language;

	$obj->language($value);

=head2 locales

The hash reference of strings that map to each locale.

	$obj->locales({ 
		stranger => {
			en_US => 'Howdy stranger!'
		}
	})
	

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::myths::object at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Myths-Object>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Myths::Object

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Myths-Object>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Myths-Object>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Myths-Object>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Myths-Object>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
