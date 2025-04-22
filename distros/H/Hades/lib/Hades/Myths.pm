package Hades::Myths;
use strict;
use warnings;
use POSIX qw/locale_h/;
our $VERSION = 0.24;
our ($STASH);

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = bless {}, $cls;
	my %accessors = ();
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

sub import {
	my ( $self, $locales, @additional ) = @_;
	if ( defined $locales ) {
		if ( ( ref($locales) || "" ) ne "HASH" ) {
			die
			    qq{Optional[HashRef]: invalid value $locales for variable \$locales in method import};
		}
	}

	my $caller = caller();
	$STASH = delete $locales->{stash} || 'Hades::Myths::Object';
	eval "require $STASH";
	my ( $locale, $lang, $fb ) = $STASH->convert_locale(
		delete $locales->{locale} || setlocale(LC_CTYPE),
		delete $locales->{fb},
	);
	my $as_keyword = delete $locales->{as_keywords};
	$locales = undef if ( !ref $locales || !scalar keys %{$locales} );
	my ($new) = $STASH->new(
		( defined $fb      ? ( fb       => $fb )      : () ),
		( defined $lang    ? ( language => $lang )    : () ),
		( defined $locale  ? ( locale   => $locale )  : () ),
		( defined $locales ? ( locales  => $locales ) : () ),
		@additional
	);
	{
		no strict "refs";
		no warnings "redefine";
		*{"${caller}::locales"} = sub {$new};
		if ($as_keyword) {
			for my $key ( keys %{ $new->locales } ) {
				no strict "refs";
				no warnings "redefine";
				*{"${caller}::${key}"} = sub { $new->string( $key, @_ ); };
			}
		}
	};
}

sub new_object {
	my ( $self, %object ) = @_;

	return $STASH->new(%object);

}

1;

__END__

=head1 NAME

Hades::Myths - error handling for hades.

=head1 VERSION

Version 0.24

=cut

=head1 SYNOPSIS

use Hades::Myths;

	say stranger;
	die locales->stranger;

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Myths object.

	Hades::Myths->new

=head2 import

call import method. Expects param $locales to be a Optional[HashRef], param @additional to be any value including undef.

	$obj->import($locales, @additional)

=head2 new_object

Accepts a list of arguments that are used to build a new Hades::Myths::Object.
	

	Hades::Myths::Object->new_object(
		locale => $locale,
		locales => {
			%locales
		}
	);
	

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::myths at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Myths>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Myths

You can also look for information at:

=over 2

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Myths>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Myths>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
