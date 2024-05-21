package Hades::Realm::Moose;
use strict;
use warnings;
use base qw/Hades::Realm::OO/;
our $VERSION = 0.07;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = $cls->SUPER::new(%args);
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

sub build_as_role {
	my ( $orig, $self, @params ) = ( 'SUPER::build_as_role', @_ );
	my @res = $self->$orig(@params);
	$res[0]->use(q|Moose::Role|);
	$res[0]->use(
		sprintf q|Types::Standard qw/%s/|,
		join( ' ', keys %{ $self->meta->{ $self->current_class }->{types} } )
	);

	return wantarray ? @res : $res[0];
}

sub build_as_class {
	my ( $orig, $self, @params ) = ( 'SUPER::build_as_class', @_ );
	my @res = $self->$orig(@params);
	$res[0]->use(q|Moose|);
	$res[0]->use(q|MooseX::Privacy|);
	$res[0]->use(
		sprintf q|Types::Standard qw/%s/|,
		join( ' ', keys %{ $self->meta->{ $self->current_class }->{types} } )
	);

	return wantarray ? @res : $res[0];
}

sub build_has {
	my ( $self, $meta ) = @_;
	if ( ( ref($meta) || "" ) ne "HASH" ) {
		$meta = defined $meta ? $meta : 'undef';
		die
		    qq{HashRef: invalid value $meta for variable \$meta in method build_has};
	}

	$meta->{is} ||= '"rw"';
	my $attributes = join ', ',
	    map { ( $meta->{$_} ? ( sprintf "%s => %s", $_, $meta->{$_} ) : () ) }
	    qw/is required clearer predicate isa default trigger builder/;
	$attributes .= ', traits => [qw/Private/]' if ( $meta->{private} );
	my $name = $meta->{has};
	my $code = qq{
			has $name => ( $attributes );};
	return $code;

}

sub build_accessor_predicate {
	my ( $self, $name, $content ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_accessor_predicate};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method build_accessor_predicate};
	}

	return qq|"has_$name"|;

}

sub build_accessor_clearer {
	my ( $self, $name, $content ) = @_;
	if ( !defined($name) || ref $name ) {
		$name = defined $name ? $name : 'undef';
		die
		    qq{Str: invalid value $name for variable \$name in method build_accessor_clearer};
	}
	if ( !defined($content) || ref $content ) {
		$content = defined $content ? $content : 'undef';
		die
		    qq{Str: invalid value $content for variable \$content in method build_accessor_clearer};
	}

	return qq|"clear_$name"|;

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

	return $content =~ m/^\w\w+$/ ? $content : qq|"_build_$name"|;

}

1;

__END__

=head1 NAME

Hades::Realm::Moose - Hades realm for Moose

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	Hades->run({
		eval => q|
			Kosmos { 
				[curae penthos] :t(Int) :d(2) :p :pr :c :r 
				geras $nosoi :t(Int) :d(5) { 
					if (£penthos == $nosoi) {
						return £curae;
					}
				} 
			}
		|,
		realm => 'Moose',
	});

	... generates ...

	package Kosmos;
	use strict;
	use warnings;
	use Moose;
	use MooseX::Privacy;
	use Types::Standard qw/Int/;
	our $VERSION = 0.01;

	has curae => (
		is        => "rw",
		required  => 1,
		clearer   => "clear_curae",
		predicate => "has_curae",
		isa       => Int,
		default   => sub {2},
		traits    => [qw/Private/]
	);

	has penthos => (
		is        => "rw",
		required  => 1,
		clearer   => "clear_penthos",
		predicate => "has_penthos",
		isa       => Int,
		default   => sub {2},
		traits    => [qw/Private/]
	);

	sub geras {
		my ( $self, $nosoi ) = @_;
		$nosoi = defined $nosoi ? $nosoi : 5;
		if ( !defined($nosoi) || ref $nosoi || $nosoi !~ m/^[-+\d]\d*$/ ) {
			$nosoi = defined $nosoi ? $nosoi : 'undef';
			die qq{Int: invalid value $nosoi for variable \$nosoi in method geras};
		}
		if ( £penthos == $nosoi ) { return £curae; }
	}

	1;

	__END__

NOTE: coerce attributes currently do not work with Moose

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Realm::Moose object.

	Hades::Realm::Moose->new

=head2 build_as_role

call build_as_role method.

=head2 build_as_class

call build_as_class method.

=head2 build_has

call build_has method. Expects param $meta to be a HashRef.

	$obj->build_has($meta)

=head2 build_accessor_predicate

call build_accessor_predicate method. Expects param $name to be a Str, param $content to be a Str.

	$obj->build_accessor_predicate($name, $content)

=head2 build_accessor_clearer

call build_accessor_clearer method. Expects param $name to be a Str, param $content to be a Str.

	$obj->build_accessor_clearer($name, $content)

=head2 build_accessor_builder

call build_accessor_builder method. Expects param $name to be a Str, param $content to be a Str.

	$obj->build_accessor_builder($name, $content)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::realm::moose at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Realm-Moose>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Realm::Moose

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Realm-Moose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Realm-Moose>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Realm-Moose>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Realm-Moose>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
