package FarmBalance;
use Mouse;
our $VERSION = '0.03';

#- Input
has 'farms' => (
	is=>'rw', 
	isa=>'Int', 
	required=>1
);
has 'stats' => (
	is=>'rw', 
	isa=>'HashRef[ArrayRef[Num]]', 
	required=>1,
);
has 'input' => (
	is=>'rw', 
	isa=>'HashRef[Num]'
);

has 'debug' => (
	is=>'rw', 
	isa=>'Bool', 
	default=>0
);
#- Output
has 'effective_farm' => (
	is=>'rw', 
	isa=>'Int'
);
has 'effect_in_farm_max' => (
	is=>'rw', 
	isa=>'Int'
);

#- Other
has 'percent' => (
	is=>'rw',
	isa=>'Int',
	required=>1, 
	default=>100
);

__PACKAGE__->meta->make_immutable;
no Mouse;


#- if parameter 'input' is empty, fill average values in balance keys.
sub input_fill_avg {
	my $self = shift;
	foreach my $bkey ( keys %{ $self->{stats} } ) {
		my $arrayref = $self->{stats}->{$bkey};
		my $avg = $self->average($arrayref);
		$self->{input}->{$bkey} = $avg;
	}
}

#- check parameters.
sub check_param {
	my $self = shift;
	if ( $self->{farms}  < 1 ) {
		die "Error: farms must be larger than 0\n";
	} elsif ( $self->{farms} > 10000000 ) {
		die "Error: farms must be less than 10000000. Is it real system??\n";
	}
	foreach my $bkey ( keys %{ $self->{stats} } ) {
		if ( $#{$self->{stats}->{$bkey}} != ($self->{farms} - 1) ) {
			die "Error: numbers of stats differ from farm number\n";
		}
	}
	if ( defined $self->{input} ) {
		my @input_array = keys %{$self->{input}};
		my @bkey_array = keys %{$self->{stats}};
		if ( $#input_array != $#bkey_array ) {
			die "Error: numbers of input differ from stats blance key number\n";
		}
	}
	return 0;
}

#- Define Farm Number
sub define_farm {
	my $self = shift;
	#- init, regarding bulk operation.
	$self->{effective_farm} = undef;
	$self->{effect_in_farm_max} = undef;
	#- check stats and input parameters.
	$self->check_param;
	#- if traffic and data unknown, fill average values.
	if ( ! defined $self->{input} ) {
		$self->input_fill_avg;
	}
	#-  effect calculation for each nodes.
	my $second_farm;	#- looser
	for ( my $farm = 0; $farm < $self->{farms}; $farm++ ) {
		my $farm_str = $farm + 1;
		my $effect_in_farm = 0;
		print "NODE: $farm_str\n" if ( $self->{debug} );
		foreach my $b_key ( keys %{$self->{input}} ) {
			#- standard deviation : before insert.
			my ( $sd_before ) = sprintf("%.2f",$self->sd_percent($self->{stats}->{$b_key}));
			if ( $self->{debug} ) {
 				print "$b_key\n";
				print "  before:\t$self->{stats}->{$b_key}->[$farm]\tsd:\t$sd_before\n";
			}
			#- if added to this node.
			$self->{stats}->{$b_key}->[$farm] += $self->{input}->{$b_key};
			#- statndard deviation : after insert.
			my ( $sd_after ) = sprintf("%.2f",$self->sd_percent($self->{stats}->{$b_key}));
			#- if effect is large number, it's better farming.
			my $effect = $sd_before - $sd_after; 
			if ( $self->{debug} ) {
   				print "  after:\t$self->{stats}->{$b_key}->[$farm]\tsd:\t$sd_after\n"; 
				print "  effect:\t" . sprintf("%.2f", $effect) . "\n";
			}
			$effect_in_farm += $effect;;
		}
		print "\t->TotalEffect:\t" . sprintf("%.2f", $effect_in_farm) . "\n" if ( $self->{debug} );
		#- chose most effective farm.
		if ( ! defined $self->{effect_in_farm_max} ) {
			$self->change_effective_farm($farm_str, $effect_in_farm);
		} elsif ( $effect_in_farm > $self->{effect_in_farm_max} ) {
			#- consider looser.
			$second_farm = $self->{effective_farm} - 1;
			$self->change_effective_farm($farm_str, $effect_in_farm, $second_farm);
		}  else {
			#- rollback 
			$self->rollback_stat($farm);
		}
	}

}

sub change_effective_farm {
	my ( $self, $farm_str, $effect_in_farm, $second_farm ) = @_;
	$self->{effect_in_farm_max} = $effect_in_farm;
	$self->{effective_farm} = $farm_str;
	$self->rollback_stat($second_farm) if ( defined $second_farm);
}

sub rollback_stat {
	my ( $self, $farm ) = @_;
	foreach my $bkey ( keys %{ $self->{input} } ) {
		$self->{stats}->{$bkey}->[$farm] -= $self->{input}->{$bkey};
	}
}

sub report {
	my $self = shift;
	$self->check_param;
	my $stats = $self->{stats};
	print "-----------------------------\n";
	print "farm";
	foreach my $key ( keys %$stats ) {
		print "\t$key";
	}
	print "\n";
	for ( my $farm = 0; $farm < $self->{farms}; $farm++ ) {
		print  $farm + 1 . ':';
		foreach my $key ( keys %$stats ) {
			print "\t", $stats->{$key}->[$farm];
		}
		print "\n";
	}
	print "sd";
	my $total_sd = 0;
	foreach my $key ( keys %$stats ) {
		print "\t" , sprintf("%.2f", $self->sd_percent($stats->{$key}));
		$total_sd += $self->sd_percent($stats->{$key});
	}
	print "\n";
	print "SD_Total:\t" . sprintf("%.2f",$total_sd) . "\n";
	print "-----------------------------\n";
	
}

#- return standard deviation, if all summ is 100(%).
sub sd_percent {
	my ( $self, $a_ref ) = @_;
	$a_ref = $self->arrange_array($a_ref);
	return $self->sd($a_ref);
}

#- return array that has sum = 100.
sub arrange_array {
	my ( $self, $arrayref)  = @_;
	my $sum = $self->array_val_sum($arrayref);
	my $kei = $self->{'percent'} / $sum;
	my @nums_new = map { $_ * $kei } @{$arrayref};
	return \@nums_new;
}

#- return standard deviation
sub sd {
	my ( $self, $arrayref )  = @_;
	my $avg = $self->average($arrayref);
	my $ret = 0;
	for  (@{$arrayref}) {
		$ret += ($_ - $avg)**2;
	}
	return ( $ret/($#$arrayref + 1));
}
sub average {	
	my ( $self, $arrayref)  = @_;
	my $sum = $self->array_val_sum($arrayref);
	return ( $sum / ( $#$arrayref + 1)  );
}
#- summarize array values 
sub array_val_sum {
	my ( $self, $arrayref)  = @_;
	my $sum = 0;
	for (@{$arrayref}) {
		$sum += $_;
	}
	return $sum;
}

1;
__END__

=head1 NAME

FarmBalance - make nice balance in Farming System regarding data, traffics, etc..

=head1 SYNOPSIS

  #- use OLTP to determine new user's farm 
  use FarmBalance;
  my $farms = 4;      #- write farm number of systems
  my $stats = {	      #- give system stats.
        'a_table_rows' => [1000, 700, 629, 800],
        'b_table_rows' => [300, 70, 26, 200],
        'server_tps'   => [1000, 300, 5, 200],
  };
  my $input = {	      #- give new commer's data and traffic, estimated. 
                      #- if undefined, filled by average values of stats.
        'a_table_rows' => 20,
        'b_table_rows' => 33,
        'server_tps' => 10,
  };
  my $df = FarmBalance->new(
        farms => $farms,
        stats => $stats,
        input => $input,
  );
  $df->report($df->{stats});	#- report before adding new user
  $df->define_farm;
  print "DefineNode:" , $df->{effective_farm} , "\n"; #- best farm to insert.
  $df->report($df->{stats});    #- report after adding user.

 
  #- when use in data migration.
  use FarmBalance;
  my $farms = 4;
  my $src = 'migration.tsv'; #- like "uid100\t20\t22\t5..."
  my $stats = {	      #- give new system stats.
        'a_table_rows' => [0, 0, 0, 0],
        'b_table_rows' => [0, 0, 0, 0],
        'server_tps'   => [0, 0, 0, 0],
  };
  my $df = FarmBalance->new(
        farms => $farms,
        stats => $stats,
  );
  open (IN, $file );
  while ( <IN> ) {
        chomp;
        my ( $row, $keyA, $keyB, $keyC ) = split (/\t/, $_);
        my $input = +{
                'a_table_rows' => $keyA,
                'b_table_rows' => $keyB,
                'server_tps' => $keyC,
        };
        $df->{input} = $input;
        $df->define_farm;
        print "Row: $row => DefineNode:" , $df->{effective_farm} , "\n";
        #- Insert data to above node.
  }
  close(IN);



=head1 DESCRIPTION

FarmBalance is useful tool to reduce variability in Web Farming System.
In many web sites, engineers uses many application-servers and database-servers
to handle too much transacions and too may data.
Deciding farm to insert new user and new data, often Hashing logic or residual calculation 
is used.
But it often results in variability of data rows in DB and server traffic.

Using FarmBalance and giving it 
  Server Stats ( ex. data rows, transactions, server resources  from system infromations),
your farming system will be in nice balance.

FarmBalance calculates effect to reduce standard deviation, supposing new user added to each nodes in estimated values.
And, chose most effective farm.
  

=head1 AUTHOR

DUKKIE(Masataka Koduka) E<lt>dukkie@cpan.orgE<gt>

with helps from H.Fujimiya, K.Moriyama and Y.Kanda.

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
