package Hades::Realm::Rope;
use strict;
use warnings;
use base qw/Hades::Realm::OO/;
our $VERSION = 0.04;

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
	$res[0]->use(q|Rope::Role|);
	$res[0]->use(
		sprintf q|Types::Standard qw/%s/|,
		join( ' ', keys %{ $self->meta->{ $self->current_class }->{types} } )
	);

	return wantarray ? @res : $res[0];
}

sub build_as_class {
	my ( $orig, $self, @params ) = ( 'SUPER::build_as_class', @_ );
	my @res = $self->$orig(@params);
	$res[0]->use(q|Rope|);
	$res[0]->use(q|Rope::Autoload|);
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
	my $attributes = sprintf "initable => 1, writeable => %s,",
	    $meta->{is} =~ m/^ro$/ ? 0 : 1;
	$attributes .= sprintf "type => %s,", $meta->{isa} if $meta->{isa};
	$attributes .= join ', ',
	    map { ( $meta->{$_} ? ( sprintf "%s => %s", $_, $meta->{$_} ) : () ) }
	    qw/required clearer predicate trigger builder private/;
	$attributes .= sprintf ", value => %s", $meta->{default}
	    if $meta->{default};
	my $name = $meta->{has};
	my $code = qq{
			property $name => ( $attributes );
		};
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

	return $content;

}

sub has_function_keyword {
	my ($self) = @_;

	return 1;

}

1;

__END__

=head1 NAME

Hades::Realm::Rope - Hades realm for Rope

=head1 VERSION

Version 0.04

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
		realm => 'Rope',
	});

	... generates ...

	package Kosmos;
	use strict;
	use warnings;
	use Rope;
	use Rope::Autoload;
	use Types::Standard qw/Int/;
	our $VERSION = 0.01;

	property curae => (
		initable  => 1,
		writeable => 1,
		type      => Int,
		required  => 1,
		clearer   => "clear_curae",
		predicate => "has_curae",
		private   => 1,
		value     => 2
	);

	property penthos => (
		initable  => 1,
		writeable => 1,
		type      => Int,
		required  => 1,
		clearer   => "clear_penthos",
		predicate => "has_penthos",
		private   => 1,
		value     => 2
	);

	function geras => sub {
		my ( $self, $nosoi ) = @_;
		$nosoi = defined $nosoi ? $nosoi : 5;
		if ( !defined($nosoi) || ref $nosoi || $nosoi !~ m/^[-+\d]\d*$/ ) {
			$nosoi = defined $nosoi ? $nosoi : 'undef';
			die
			    qq{Int: invalid value $nosoi for variable \$nosoi in method geras};
		}
		if ( $self->penthos == $nosoi ) { return $self->curae; }
	};

	1;

	__END__

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Hades::Realm::Rope object.

	Hades::Realm::Rope->new

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

=head2 build_accessor_default

call build_accessor_default method. Expects param $name to be a Str, param $content to be a Str.

	$obj->build_accessor_default($name, $content)

=head2 has_function_keyword

call has_function_keyword method. Expects no params.

	$obj->has_function_keyword()

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::realm::rope at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Realm-Rope>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Realm::Rope

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Realm-Rope>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Realm-Rope>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Realm-Rope>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Realm-Rope>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
