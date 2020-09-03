package Hades::Realm::Import::Export;
use strict;
use warnings;
use base qw/Hades::Realm::Exporter/;
our $VERSION = 0.03;

sub new {
	my ( $cls, %args ) = ( shift(), scalar @_ == 1 ? %{ $_[0] } : @_ );
	my $self      = $cls->SUPER::new(%args);
	my %accessors = ();
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

sub build_new {
	my ( $orig, $self, @params ) = ( 'SUPER::build_new', @_ );

	my @res = $self->$orig( @params, q|%EX| );

	return wantarray ? @res : $res[0];
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

	my %ex = ();
	for my $k ( keys %{$export} ) {
		push @{ $ex{$_} }, $k for ( @{ $export->{$k} } );
	}
	my $ex_tags = Module::Generate::_stringify_struct( 'undefined', \%ex );
	$ex_tags =~ s/^{/(/;
	$ex_tags =~ s/}$/);/;
	$begin = '%EX = ' . $ex_tags . $begin;
	return $begin;

}

sub after_class {
	my ( $self, $mg ) = @_;
	if ( ( ref($mg) || "" ) =~ m/^(|HASH|ARRAY|SCALAR|CODE|GLOB)$/ ) {
		$mg = defined $mg ? $mg : 'undef';
		die
		    qq{Object: invalid value $mg for variable \$mg in method after_class};
	}

	$mg->base(q|Import::Export|);

}

1;

__END__

=head1 NAME

Hades::Realm::Import::Export - Hades realm for Import::Export

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does:

	Hades->run({
		eval => 'Kosmos {
			[curae penthos] :t(Int) :d(2) :p :pr :c :r :i(1, GROUP)
			geras $nosoi :t(Int) :d(5) :i { if (£penthos == $nosoi) { return £curae; } } 
		}',
		realm => 'Import::Export',
	});

	... generates ...

	package Kosmos;
	use strict;
	use warnings;
	use base qw/Import::Export/;
	our $VERSION = 0.01;
	our ( %EX, %ACCESSORS );

	BEGIN {
		%EX = (
		       'curae'	=> [ 'EXPORT',    'EXPORT_OK', 'ACCESSORS', 'GROUP' ],
		       'clear_penthos' => [ 'EXPORT',    'EXPORT_OK', 'CLEARERS' ],
		       'penthos'       => [ 'EXPORT',    'EXPORT_OK', 'ACCESSORS', 'GROUP' ],
		       'geras'	=> [ 'EXPORT_OK', 'METHODS' ],
		       'has_curae'     => [ 'EXPORT',    'EXPORT_OK', 'PREDICATES' ],
		       'has_penthos'   => [ 'EXPORT',    'EXPORT_OK', 'PREDICATES' ],
		       'clear_curae'   => [ 'EXPORT',    'EXPORT_OK', 'CLEARERS' ]
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

Instantiate a new Hades::Realm::Import::Export object.

	Hades::Realm::Import::Export->new

=head2 build_new

call build_new method.

=head2 build_exporter

call build_exporter method. Expects param $begin to be a Str, param $mg to be a Object, param $export to be a HashRef, param $meta to be a HashRef.

	$obj->build_exporter($begin, $mg, $export, $meta)

=head2 after_class

call after_class method. Expects param $mg to be a Object.

	$obj->after_class($mg)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hades::realm::import::export at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hades-Realm-Import-Export>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hades::Realm::Import::Export

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Hades-Realm-Import-Export>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hades-Realm-Import-Export>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Hades-Realm-Import-Export>

=item * Search CPAN

L<https://metacpan.org/release/Hades-Realm-Import-Export>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

 
