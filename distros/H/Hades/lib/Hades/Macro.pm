package Hades::Macro;
use strict;
use warnings;
our $VERSION = 0.23;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = bless {}, $cls;
	my %accessors = ( alias => {}, macro => { default => [], }, );
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

sub macro {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "ARRAY" ) {
			die qq{ArrayRef: invalid value $value for accessor macro};
		}
		$self->{macro} = $value;
	}
	return $self->{macro};
}

sub alias {
	my ( $self, $value ) = @_;
	if ( defined $value ) {
		if ( ( ref($value) || "" ) ne "HASH" ) {
			die
			    qq{HashRef[ArrayRef]: invalid value $value for accessor alias};
		}
		for my $item ( values %{$value} ) {
			if ( !defined($item) || ( ref($item) || "" ) ne "ARRAY" ) {
				$item = defined $item ? $item : 'undef';
				die
				    qq{HashRef[ArrayRef]: invalid value $item for accessor alias expected ArrayRef};
			}
		}
		$self->{alias} = $value;
	}
	return $self->{alias};
}

sub has_alias {
	my ($self) = @_;
	return exists $self->{alias};
}

sub meta {
	my ( $self, $meta ) = @_;
	$meta = defined $meta ? $meta : {};
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method meta};
	}

	my $cls = ref $self;
	for my $m ( @{ $self->macro } ) {
		$meta->{$m} = {
			meta => 'MACRO',
			code => \&{"${cls}::${m}"},
		};
	}
	if ( $self->has_alias ) {
		for my $key ( %{ $self->alias } ) {
			for my $alias ( @{ $self->alias()->{$key} } ) {
				$meta->{$alias} = $meta->{$key};
			}
		}
	}
	return $meta;

}

1;

__END__

=head1 NAME

Hades::Macro - Hades macro base class.

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	Hades::Macro::Kosmos base Hades::Macro {
		macro :t(ArrayRef) :d([qw/geras/])
		geras $mg :t(Object) { 
			return q|...|;
		}
	}

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Macro object.

	Hades::Macro->new

=head2 has_alias

has_alias will return true if alias accessor has a value.

	$obj->has_alias

=head2 meta

call meta method. Expects param $meta to be a HashRef.

	$obj->meta($meta)

=head1 ACCESSORS

=head2 macro

get or set macro.

	$obj->macro;

	$obj->macro($value);

=head2 alias

get or set alias.

	$obj->alias;

	$obj->alias($value);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::macro at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Macro>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Macro

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Macro>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Macro>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Macro>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Macro>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
