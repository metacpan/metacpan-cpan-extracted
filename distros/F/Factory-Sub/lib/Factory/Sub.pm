package Factory::Sub;
use 5.006; use strict; use warnings;
use Import::Into; use Carp qw/croak/; use Coerce::Types::Standard qw//;
our $VERSION = '0.07';

use overload 
	"&{}" => sub {my $self = shift; sub { $self->call(@_) }},
	fallback => 1;  

sub import {
	my ($pkg, @import) = @_;
	if (@import) {
		my $target = caller;
		Coerce::Types::Standard->import::into($target, @import)
	}
}

sub new {
	my $self = shift;
	my $fallback;
	for (my $i = 0; $i < scalar @_; $i++) {
		if ( scalar @{$_[$i]} == 1 ) {
			$fallback = splice @_, $i, 1;
			$i--;
		}
	}
	bless { factory => [ @_ ], ($fallback ? (fallback => $fallback->[0]) : ()) }, $self;
}

sub add {
	my ($self, @args) = @_;
	if (scalar @args == 1) {
		$self->{fallback} = $args[0];
	} else {
		push @{ $self->{factory} }, \@args;
	}
}

sub call {
	my ($self, @params) = @_;
	FACTORY:
	for my $factory ( @{ $self->{factory} } ) {
		if ( scalar @{$factory} - 1 == scalar @params) {	
			my @factory_params = @{clone(\@params)};
			for (my $i = 0; $i < scalar @factory_params; $i++) {
				eval { $factory_params[$i] = $factory->[$i]->(
					ref $factory->[$i] eq 'Type::Tiny' 
						&& scalar @{$factory->[$i]->{coercion}->{type_coercion_map}} 
							? $factory->[$i]->coerce($factory_params[$i])
							: $factory_params[$i]
				); 1; } or next FACTORY;
			}
			return $factory->[-1]->(@factory_params);
		}
	}
	if ($self->{fallback}) {
		return $self->{fallback}->(@params);
	}
	croak "No matching factory sub for given params " . join " ", map { ! defined $_ ? 'undef' : $_ } @params;
}

sub clone {
	my ($clone) = @_;
	my $ref = ref $clone;
	if ($ref eq 'ARRAY') { return [ map { clone($_) } @{$clone} ]; }
	elsif ($ref eq 'HASH') { return { map +( $_ => clone($clone->{$_}) ), keys %{$clone} }; }
	elsif ($ref eq 'SCALAR') { my $r = clone($$clone); return \$r; }
	return $clone;
}

1;

__END__;

=head1 NAME

Factory::Sub - Generate a factory of subs

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Factory::Sub qw/Str HashRef ArrayRef StrToArray StrToHash HashToArray/;

	my $factory = Factory::Sub->new();

	$factory->add(sub { return 'fallback' });

	$factory->add(Str, Str, sub { 
		return 1;
	});

	$factory->add(Str, HashRef, sub { 
		return 2;
	});

	$factory->add(ArrayRef, HashRef, sub { 
		return 3;
	});

	$factory->add(StrToArray->by(', '), StrToHash->by(' '), HashToArray->by('keys'), sub { 
		return 4;
	});
	
	$factory->('hello', 'world'); # 1
	$factory->('hello', { one => 1 }); # 2
	$factory->([qw/h e l l o/], { one => 1 }); # 3
	$factory->('h, e, l, l, o', 'world', { one => 1 }); # 4 

=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new Factory::Sub object. This does not accept any argurments.

	my $factory = Factory::Sub->new(
		[Str, Str, sub { return 1 }],
		[Str, HashRef, sub { return 2 }],
		[ArrayRef, HashRef, sub { return 3 }]
	);

=head2 add

Add a new condition to the factory. 

	$factory->add(StrToArray->by(', '), StrToHash->by(' '), HashToArray->by('keys'), sub { 
		return 4;
	});

=cut

=head2 call

Call the factory. If o matching factory sub is not found for the given params then the code currently croaks with an error.

	$factory->call('h, e, l, l, o', 'world', { one => 1 });
...
	$factory->('h, e, l, l, o', 'world', { one => 1 });	

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-factory-sub at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Factory-Sub>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Factory::Sub

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Factory-Sub>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Factory-Sub>

=item * Search CPAN

L<https://metacpan.org/release/Factory-Sub>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Factory::Sub
