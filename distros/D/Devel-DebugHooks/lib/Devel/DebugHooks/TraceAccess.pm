package Devel::DebugHooks::TraceAccess;

# use Log::Log4perl;

sub TIESCALAR {
	my $class =  shift;

	my $obj = { data => ${ shift }, @_ };

	return bless $obj, 'ScalarHistory';
}

sub TIEHASH {
	my $class =  shift;
	my $data  =  shift;
	my %arg   =  @_;

	my $obj;
	@{ $obj->{ data } }{ keys %$data } =  values %$data;
	@$obj{ keys %arg }                 =  values %arg;

	return bless $obj, 'HashHistory';
}

sub TIEARRAY {
	my $class =  shift;
	my $data  =  shift;
	my %arg   =  @_;

	my $obj;
	@{ $obj->{ data } }[ keys @$data ] =  values @$data;
	@$obj{ keys %arg }                 =  values %arg;

	return bless $obj, 'ArrayHistory';
}


{ package Logger; sub info{ shift; warn @_, "\n" } }

{
	package             # hide the package from the PAUSE indexer
		ScalarHistory;
	# my $logger =  Log::Log4perl::get_logger( "LogVars" );
	my $logger = bless {}, 'Logger';


	sub FETCH {
		my $self =  shift;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( $self->{ data } ."<< $name    at $file:$line" );

		return $self->{ data };
	}


	sub STORE {
		my( $self, $value ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "$name =  '$value'    at $file:$line" );

		$self->{ data } =  $value;
	}


	sub DESTROY {
		my $self =  shift;
	}


	sub UNTIE {
		my $self =  shift;
	}
}

{
	package             # hide the package from the PAUSE indexer
		HashHistory;
	# my $logger =  Log::Log4perl::get_logger( "LogVars" );
	my $logger = bless {}, 'Logger';


	sub FETCH {
		my( $self, $key ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( $self->{ data }{ $key } ."<< $name\{ $key }    at $file:$line" );

		return $self->{ data }{ $key };
	}


	sub STORE {
		my( $self, $key, $value ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "$name\{ $key } =  '$value'    at $file:$line" );

		$self->{ data }{ $key } =  $value;
	}


	sub DELETE {
		my( $self, $key ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "delete $name\{ $key }'    at $file:$line" );
		delete $self->{ data }{ $key };
	}


	sub CLEAR {
		my( $self ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "$name =  ()    at $file:$line" );
		%{ $self->{ data } } =  ();
	}


	sub EXISTS {
		my( $self, $key ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		my $exists =  exists $self->{ data }{ $key };
		$logger->info( ($exists?'':'NOT ') ."EXISTS $name\{ $key }    at $file:$line" );
		$exists;
	}


	sub FIRSTKEY {
		my( $self ) =  @_;

		keys %{ $self->{ data } };    # reset each() iterator
		each %{ $self->{ data } };
	}


	sub NEXTKEY {
		my( $self, $lastkey ) =  @_;

		each %{ $self->{ data } };
	}


	sub SCALAR {
		my $self =  shift;

		scalar %{ $self->{ data } };
	}


	sub DESTROY {
		my $self =  shift;
	}


	sub UNTIE {
		my $self =  shift;
	}
}


{
	package             # hide the package from the PAUSE indexer
		ArrayHistory;
	# my $logger =  Log::Log4perl::get_logger( "LogVars" );
	my $logger = bless {}, 'Logger';


	sub FETCH {
		my( $self, $index ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( $self->{ data }[ $index ] ."<< $name\[ $index ]    at $file:$line" );

		return $self->{ data }[ $index ];
	}


	sub STORE {
		my( $self, $index, $value ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "$name\[ $index ] =  '$value'    at $file:$line" );

		$self->{ data }[ $index ] =  $value;
	}


	sub DELETE {
		my( $self, $index ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "delete $name\[ $index ]'    at $file:$line" );
		delete $self->{ data }[ $index ];
	}


	sub CLEAR {
		my( $self ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "$name =  ()    at $file:$line" );
		@{ $self->{ data } } =  ();
	}


	sub EXISTS {
		my( $self, $index ) =  @_;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		my $exists =  exists $self->{ data }[ $index ];
		$logger->info( ($exists?'':'NOT ') ."EXISTS $name\[ $index ]    at $file:$line" );
		$exists;
	}


	sub FETCHSIZE {
		my $self =  shift;

		scalar @{ $self->{ data } };
	}


	sub STORESIZE {
		my( $self, $count ) =  @_;

		$#{ $self->{ data } } =  $count;
	}


	sub PUSH {
		my $self =  shift;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "PUSH $name'    at $file:$line" );
		push @{ $self->{ data } }, @_;
	}


	sub POP {
		my $self =  shift;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "POP $name'    at $file:$line" );
		pop @{ $self->{ data } };
	}


	sub SHIFT {
		my $self =  shift;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "SHIFT $name'    at $file:$line" );
		shift @{ $self->{ data } };
	}


	sub UNSHIFT {
		my $self =  shift;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "UNSHIFT $name'    at $file:$line" );
		unshift @{ $self->{ data } }, @_;
	}


	sub SPLICE {
		my $self =  shift;

		my $name =  $self->{ desc };
		my( undef, $file, $line ) =  caller(0);
		$logger->info( "SPLICE $name'    at $file:$line" );
		splice @{ $self->{ data } }, @_;
	}


	sub EXTEND {
		# Do nothing
		return;
	}


	sub DESTROY {
		my $self =  shift;
	}


	sub UNTIE {
		my $self =  shift;
	}
}

1;
