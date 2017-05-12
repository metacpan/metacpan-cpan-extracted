package Kephra::Config::Tree;
our $VERSION = '0.02';
=head1 NAME

Kephra::Config::Tree - manipulation of config data

=head1 DESCRIPTION

=cut
use strict;
use warnings;
#
# single node manipulation
#
sub _convert_node_2_AoH {
	my $node = shift;
	if (ref $$node eq 'ARRAY') {
		return $$node if ref $$node->[0] eq 'HASH';
	} elsif (ref $$node eq 'HASH') {
		my %temp_hash = %{$$node};
		push( my @temp_array, \%temp_hash );
		return $$node = \@temp_array;
	} elsif (not ref $$node) {
		my @temp_array = ();
		return $$node = \@temp_array;
	}
}

sub _convert_node_2_AoS {
	my $node = shift;
	if (ref $$node eq 'ARRAY') {
		return $$node;
	} elsif ( 'SCALAR' eq ref $node )  {
		if ($$node) {
			push( my @temp_array, $$node );
			return $$node = \@temp_array;
		} else {
			my @temp_array = ();
			return $$node = \@temp_array;
		}
	}
}
#
# single node manipulation
#
sub get_subtree { &subtree }
sub subtree {
	my $config = shift;
	return unless ref $config;
	my $path = shift;
	for (split '/', $path) {
		$config = $config->{$_} if defined $config->{$_};
	}
	return $config;
}

sub flat_keys {
	my $config = shift;
	return unless ref $config eq 'HASH';
	my %flathash;
	for ( keys %$config ){
		
	}
}
#sub _parse_and_copy_node {
	#my ($parent_node, $parent_id) = @_;
	#no strict;
	#for ( keys %$parent_node ){
		#$cmd_id = $parent_id . $_;
		#$leaf_type = ref $parent_node->{$_};
		#if (not $leaf_type) {
			#$list{$cmd_id}{$target_leafe} = $parent_node->{$_}
				#if $parent_node->{$_};
		#} elsif ($leaf_type eq 'HASH'){
			#_parse_and_copy_node($parent_node->{$_}, $cmd_id . '-')
		#}

#
# tree operations
#
my %copy = (
	''     => sub {          $_[0]    },
	SCALAR => sub {       \${$_[0]}   },
	REF    => sub { \copy( ${$_[0]} ) },
	ARRAY  => sub { [map {copy($_)} @{$_[0]} ] },
	HASH   => sub { my %copy = map { copy($_) } %{$_[0]}; \%copy; },
);
my %merge = (
	''     => sub { $_[0] },
	SCALAR => sub { \${$_[0]} },
	REF    => sub { \merge( ${$_[0]}, ${$_[1]} ) },
	ARRAY  => sub { [map { copy($_) } ( @{$_[0]}, @{$_[1]} ) ] },
	HASH   => sub {
			my %copy = map 
				{ $_, merge( $_[0]{$_}, $_[1]{$_} ) } 
				(keys %{$_[0]}, keys %{$_[1]} );
			\%copy;
	},
);
my %update = (
	''     => sub { $_[1] },
	SCALAR => sub { \${$_[1]} },
	REF    => sub { \update( ${$_[0]}, ${$_[1]} ) },
	ARRAY  => sub { [map { copy($_) } ( @{$_[1]} ) ] },
	HASH   => sub {
			my %copy = map {
				$_, exists $_[1]{$_}
					? update( $_[0]{$_}, $_[1]{$_} )
					: copy( $_[0]{$_} ) 
				} keys %{$_[0]} ;
			\%copy;
	},
);
my %diff = (
	''     => sub { $_[0] ne $_[1] ? $_[0] : undef },
	SCALAR => sub { ${$_[0]} ne ${$_[1]} ? \${$_[0]} : undef },
 	REF    => sub { 
			my $diff = diff( ${$_[0]}, ${$_[1]} ); 
			defined $diff ? \$diff : undef 
	},
	ARRAY  => sub { [map { copy($_) }  @{$_[0]}  ] },
	HASH   => sub { 
			my %diff;
			for ( keys %{$_[0]} ) {
				my $diff = exists $_[1]{$_}
							? diff( $_[0]{$_}, $_[1]{$_} )
							: copy( $_[0]{$_} )
				;
				$diff{$_} = $diff if defined $diff;
			}
			return scalar keys %diff > 0 ? \%diff : undef;
	},
);
sub copy { $copy{ ref $_[0] }( $_[0] ) }
sub merge {
	my ($lref, $rref) = (ref $_[0], ref $_[1]);
	$lref eq $rref
		? $merge{ $lref }( $_[0], $_[1] )
		: defined $_[0]
			? $copy{ $lref }( $_[0] )
			: $copy{ $rref }( $_[1] )
	;
}
sub update { # left dictates the content, right the structure
	my ($lref, $rref) = (ref $_[0], ref $_[1]);
	$lref eq $rref
		? $update{ $lref }( $_[0], $_[1] )
		: $copy{ $rref }( $_[0] )
	;
}
sub diff {
	my ($lref, $rref) = (ref $_[0], ref $_[1]);
	$lref eq $rref
		? $diff{ $lref }( $_[0], $_[1] )
		: $copy{ $lref }( $_[0] ) # undef
	;
}

1;
