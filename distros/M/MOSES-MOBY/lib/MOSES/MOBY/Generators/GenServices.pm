#-----------------------------------------------------------------
# MOSES::MOBY::Generators::GenServices
# Author: Martin Senger <martin.senger@gmail.com>,
#         Edward Kawas <edward.kawas@gmail.com>
#
# For copyright and disclaimer see below.
#
# $Id: GenServices.pm,v 1.9 2009/03/30 13:15:03 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Generators::GenServices;
use MOSES::MOBY::Base;
use base qw( MOSES::MOBY::Base );
use Template;
use FindBin qw( $Bin );
use lib $Bin;
use File::Spec;
use MOSES::MOBY::Cache::Central;
use MOSES::MOBY::Generators::Utils;
use MOSES::MOBY::Generators::GenTypes;
use MOSES::MOBY::Def::Relationship;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.9 $ =~ /: (\d+)\.(\d+)/;

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------
{
    my %_allowed =
	(
	 outdir   => undef,
	 cachedir => undef,
	 registry => undef,
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->cachedir ($MOBYCFG::CACHEDIR);
    $self->registry ($MOBYCFG::REGISTRY);
    $self->outdir ( $MOBYCFG::GENERATORS_OUTDIR ||
		    MOSES::MOBY::Generators::Utils->find_file ($Bin, 'generated') );
}

#-----------------------------------------------------------------
# generate_base
#-----------------------------------------------------------------
sub generate_base {
    my ($self, @args) = @_;
    my %args =
	( # some default values
	  outdir        => $self->outdir,
	  cachedir      => $self->cachedir,
	  registry      => $self->registry,
	  service_names => [],

	  # other args, with no default values
	  # authority     => 'authority'
	  # outcode       => ref SCALAR

	  # and the real parameters
	  @args );
    $self->_check_outcode (%args);

    my $outdir = File::Spec->rel2abs ($args{outdir});
    $LOG->debug ("Arguments for generating service bases: " . $self->toString (\%args))
	if ($LOG->is_debug);
    $LOG->info ("Services will be generated into: '$outdir'")
	unless $args{outcode};

    # get objects from a local cache
    my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $args{cachedir},
					   registry => $args{registry});
    my @names = ();
    push (@names, $args{authority}, @{ $args{service_names} })
	if $args{authority};
    my @services = $cache->get_services (@names);

    # generate from template
    my $tt = Template->new ( ABSOLUTE => 1 );
    my $input = File::Spec->rel2abs ( MOSES::MOBY::Generators::Utils->find_file
				      ($Bin,
				       'MOSES', 'MOBY', 'Generators', 'templates',
				       'service-base.tt') );
    my $ref_sub_ref = sub {
	# return ref ($entry)
	return ref (shift);
    };

    foreach my $obj (@services) {
	my $name = $obj->name;
	$LOG->debug ("$name\n");
	if ($args{outcode}) {
	    # check if the same service is already loaded
	    # (it can happen when this subroutine is called several times)
	    next if eval '%' . $obj->module_name . '::';
	    $tt->process ( $input, { obj         => $obj,
				     ref         => $ref_sub_ref,
				 },
			   $args{outcode} ) || $LOG->logdie ($tt->error());
	} else {
	    # we cannot easily check whether the same file was already
	    # generated - so we don't
	    my $outfile =
		File::Spec->catfile ( $outdir, split (/::/, $obj->module_name) )
		. '.pm';
	    $tt->process ( $input, { obj         => $obj,
				     ref         => $ref_sub_ref,
				 },
			   $outfile ) || $LOG->logdie ($tt->error());
	}
    }
}

#-----------------------------------------------------------------
# load
#    load (cachedir      => dir,
#          authority     => 'authority',
#          service_names => [..], ... )
#-----------------------------------------------------------------
sub load {
    my ($self, @args) = @_;

    my $code = '';
    $self->generate_base (@args, outcode => \$code);
    eval $code;
    $LOG->logdie ("$@") if $@;

}

#-----------------------------------------------------------------
# generate_impl
#-----------------------------------------------------------------
sub generate_impl {
    my ($self, @args) = @_;
    my %args =
	( # some default values
	  impl_outdir   => ( $MOBYCFG::GENERATORS_IMPL_OUTDIR ||
			     MOSES::MOBY::Generators::Utils->find_file ($Bin, 'services') ),
	  impl_prefix   => $MOBYCFG::GENERATORS_IMPL_PACKAGE_PREFIX,
	  cachedir      => $self->cachedir,
	  registry      => $self->registry,
	  service_names => [],
      force_over    => 0,
	  static_impl   => 0,

	  # other args, with no default values
	  # authority     => 'authority'
	  # outcode       => ref SCALAR

	  # and the real parameters
	  @args );
    $self->_check_outcode (%args);

    my $outdir = File::Spec->rel2abs ($args{impl_outdir});
    $LOG->debug ("Arguments for generating service implementation: " . $self->toString (\%args))
	if ($LOG->is_debug);

    # get objects from a local cache
    my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $args{cachedir},
					   registry => $args{registry});
    my @names = ();
    push (@names, $args{authority}, @{ $args{service_names} })
	if $args{authority};
    my @services = $cache->get_services (@names);

    # generate from template
    my $tt = Template->new ( ABSOLUTE => 1 );
    my $input = MOSES::MOBY::Generators::Utils->find_file
	($Bin,
	 'MOSES', 'MOBY', 'Generators', 'templates',
	 'service.tt');

    my $ref_sub_get_children = sub {
	# $entry is a data type name whose all children have to be returned
	my $entry = shift;
	[ $cache->get_all_children ($entry) ];
    };

    my $ref_sub_ref = sub {
	# return ref ($entry)
	return ref (shift);
    };

    foreach my $obj (@services) {
	my $name = $obj->name;

	# create paths with all children for each input
	my %input_paths = ();
	foreach my $input (@{ $obj->inputs }) {
	    my $main_name = $input->name;
	    my $simple = (ref ($input) eq 'MOSES::MOBY::Def::PrimaryDataSimple' ?
			  $input :
			  $input->elements->[0]);
	    my $tree = {};
	    my $node_id = $self->_add_node ($tree, $main_name, undef, undef);
	    $self->_fill_tree ($cache, $tree, $node_id, $simple->datatype->name);
	    $input_paths{$main_name} = $self->_tree2paths ($tree);
	}
#	print MOSES::MOBY::Base->toString (\%input_paths);
	# create implementation specific object
	my $impl = {
	    package => ($args{impl_prefix} || 'Service') . '::' . $name,
	};
	my @input_ns = ();
        foreach my $in (@{ $obj->inputs }) {
		    if (ref ($in) eq 'MOSES::MOBY::Def::PrimaryDataSimple') {
	                foreach my $ns ( @{$in->namespaces} ) {
	                    push @input_ns, $ns->name;
	                }
	        } else {
	        	foreach my $sim (@{ $in->elements }) {
	            	foreach my $ns ( @{$sim->namespaces} ) {
	                	push @input_ns, $ns->name;
					}
				}
			}
        }
	if ($args{outcode}) {
	    $tt->process ( $input, { base         => $obj,
				     impl         => $impl,
				     static_impl  => $args{static_impl},
				     get_children => $ref_sub_get_children,
				     ref          => $ref_sub_ref,
                                     input_paths  => \%input_paths,
				     input_ns     =>,\@input_ns,
				 },
			   $args{outcode} ) || $LOG->logdie ($tt->error());
	} else {
	    my $outfile =
		File::Spec->catfile ( $outdir, split (/::/, $impl->{package}) )
		. '.pm';

	    # do not overwrite an existing file (there may be already
	    # a real implementation code)
	    if (-f $outfile and ! $args{force_over}) {
		$LOG->logwarn ("Implementation '$outfile' already exists. " .
			       "It will *not* be re-generated. Safety reasons.\n");
		next;
	    }
	    $tt->process ( $input, { base         => $obj,
				     impl         => $impl,
				     static_impl  => $args{static_impl},
				     get_children => $ref_sub_get_children,
				     ref          => $ref_sub_ref,
                                     input_paths  => \%input_paths,
                                     input_ns     => \@input_ns,
				 },
			   $outfile ) || $LOG->logdie ($tt->error());
	    $LOG->info ("Created $outfile\n");
	}
    }
}

#-----------------------------------------------------------------
# generate_cgi
#-----------------------------------------------------------------
sub generate_cgi {
    my ($self, @args) = @_;
    my %args =
	( # some default values
	  outdir        => $MOBYCFG::GENERATORS_IMPL_OUTDIR ||
			     	   MOSES::MOBY::Generators::Utils->find_file ($Bin, 'services'),
	  cachedir      => $self->cachedir,
	  registry      => $self->registry,
	  service_names => [],

	  # other args, with no default values
	  # authority     => 'authority'
	  # outcode       => ref SCALAR
	  
	  # and the real parameters
	  @args );
    $self->_check_outcode (%args);
    
    my $outdir = File::Spec->rel2abs ($args{outdir} . "/../cgi" );
    $LOG->debug ("Arguments for generating cgi services: " . $self->toString (\%args))
	if ($LOG->is_debug);
    $LOG->info ("CGI Services will be generated into: '$outdir'")
	unless $args{outcode};

    # get objects from a local cache
    my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $args{cachedir}, registry => $args{registry});
    my @names = ();
    push (@names, $args{authority}, @{ $args{service_names} })
	if $args{authority};
    my @services = $cache->get_services (@names);

    # generate from template
    my $tt = Template->new ( ABSOLUTE => 1 );
    my $input = File::Spec->rel2abs ( MOSES::MOBY::Generators::Utils->find_file
				      ($Bin,
				       'MOSES', 'MOBY', 'Generators', 'templates',
				       'service-cgi.tt') );

    foreach my $obj (@services) {
		my $name = $obj->name;
		$LOG->debug ("$name\n");
		if ($args{outcode}) {
		    # check if the same service is already loaded
		    # (it can happen when this subroutine is called several times)
		    next if eval '%' . $obj->module_name . '::';
		    $tt->process ( 
		    	$input, 
		    	{ 
		    		obj 		  => $obj, 
		    	  	pmoses_home   => $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR,
		    	  	generated_dir => $MOBYCFG::GENERATORS_OUTDIR,
		    	  	services_dir  => $MOBYCFG::GENERATORS_IMPL_OUTDIR,
		    	},
				$args{outcode} )
			 || $LOG->logdie ($tt->error());
		} else {
		    # we cannot easily check whether the same file was already
		    # generated - so we don't
		    my $outfile =
			File::Spec->catfile ( $outdir, split (/\./, $obj->authority), $obj->name ) . '.cgi';
		    $tt->process ( $input, 
		    	{ 
		    		obj 		  => $obj, 
		    	  	pmoses_home   => $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR,
		    	  	generated_dir => $MOBYCFG::GENERATORS_OUTDIR,
		    	  	services_dir  => $MOBYCFG::GENERATORS_IMPL_OUTDIR,
		    	},
				   $outfile ) || $LOG->logdie ($tt->error());
			chmod (0755, $outfile);
			$LOG->info ("\tCGI service created at '$outfile'\n");
			 
		}
    }
}

#-----------------------------------------------------------------
# generate_async_cgi
#-----------------------------------------------------------------
sub generate_async_cgi {
    my ($self, @args) = @_;
    my %args =
	( # some default values
	  outdir        => $MOBYCFG::GENERATORS_IMPL_OUTDIR ||
			     	   MOSES::MOBY::Generators::Utils->find_file ($Bin, 'services'),
	  cachedir      => $self->cachedir,
	  registry      => $self->registry,
	  service_names => [],

	  # other args, with no default values
	  # authority     => 'authority'
	  # outcode       => ref SCALAR
	  
	  # and the real parameters
	  @args );
    $self->_check_outcode (%args);
    
    my $outdir = File::Spec->rel2abs ($args{outdir} . "/../cgi" );
    $LOG->debug ("Arguments for generating async cgi services: " . $self->toString (\%args))
	if ($LOG->is_debug);
    $LOG->info ("Async CGI Services will be generated into: '$outdir'")
	unless $args{outcode};

    # get objects from a local cache
    my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $args{cachedir}, registry => $args{registry});
    my @names = ();
    push (@names, $args{authority}, @{ $args{service_names} })
	if $args{authority};
    my @services = $cache->get_services (@names);

    # generate from template
    my $tt = Template->new ( ABSOLUTE => 1 );
    my $input = File::Spec->rel2abs ( MOSES::MOBY::Generators::Utils->find_file
				      ($Bin,
				       'MOSES', 'MOBY', 'Generators', 'templates',
				       'service-cgi-async.tt') );

    foreach my $obj (@services) {
		my $name = $obj->name;
		$LOG->debug ("$name\n");
		if ($args{outcode}) {
		    # check if the same service is already loaded
		    # (it can happen when this subroutine is called several times)
		    next if eval '%' . $obj->module_name . '::';
		    $tt->process ( 
		    	$input, 
		    	{ 
		    		obj 		  => $obj, 
		    	  	pmoses_home   => $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR,
		    	  	generated_dir => $MOBYCFG::GENERATORS_OUTDIR,
		    	  	services_dir  => $MOBYCFG::GENERATORS_IMPL_OUTDIR,
		    	},
				$args{outcode} )
			 || $LOG->logdie ($tt->error());
		} else {
		    # we cannot easily check whether the same file was already
		    # generated - so we don't
		    my $outfile =
			File::Spec->catfile ( $outdir, split (/\./, $obj->authority), $obj->name ) . '.cgi';
		    $tt->process ( $input, 
		    	{ 
		    		obj 		  => $obj, 
		    	  	pmoses_home   => $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR,
		    	  	generated_dir => $MOBYCFG::GENERATORS_OUTDIR,
		    	  	services_dir  => $MOBYCFG::GENERATORS_IMPL_OUTDIR,
		    	},
				   $outfile ) || $LOG->logdie ($tt->error());
			chmod (0755, $outfile);
			$LOG->info ("\tAsync CGI service created at '$outfile'\n");
			 
		}
    }
}


#-----------------------------------------------------------------
# generate_async
#-----------------------------------------------------------------
sub generate_async {
    my ($self, @args) = @_;
    my %args =
	( # some default values
	  impl_outdir   => ( $MOBYCFG::GENERATORS_IMPL_OUTDIR ||
			     MOSES::MOBY::Generators::Utils->find_file ($Bin, 'services') ),
	  impl_prefix   => $MOBYCFG::GENERATORS_IMPL_PACKAGE_PREFIX,
	  cachedir      => $self->cachedir,
	  registry      => $self->registry,
	  service_names => [],
      force_over    => 0,
	  static_impl   => 0,

	  # and the real parameters
	  @args );
    $self->_check_outcode (%args);
    
    my $outdir = File::Spec->rel2abs ($args{impl_outdir});
    $LOG->debug ("Arguments for generating async services: " . $self->toString (\%args))
	if ($LOG->is_debug);
    $LOG->info ("ASYNC Services will be generated into: '$outdir'")
	unless $args{outcode};

    # get objects from a local cache
    my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $args{cachedir}, registry => $args{registry});
    my @names = ();
    push (@names, $args{authority}, @{ $args{service_names} })
	if $args{authority};
    my @services = $cache->get_services (@names);

    # generate from template
    my $tt = Template->new ( ABSOLUTE => 1 );
    my $input = MOSES::MOBY::Generators::Utils->find_file
	($Bin,
	 'MOSES', 'MOBY', 'Generators', 'templates',
	 'service-async.tt');

    foreach my $obj (@services) {
	my $name = $obj->name;
	my $impl = {
	    package => ($args{impl_prefix} || 'Service') . '::' . $name,
	};
	$LOG->debug ("$name\n");
	if ($args{outcode}) {
	    # check if the same service is already loaded
	    # (it can happen when this subroutine is called several times)
	    next if eval '%' . $obj->module_name . '::';
	    $tt->process ( 
	    	$input, 
	    	{ 
	    		impl   => $impl,
	    		obj 		  => $obj, 
	    	  	pmoses_home   => $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR,
	    	  	generated_dir => $MOBYCFG::GENERATORS_OUTDIR,
	    	  	services_dir  => $MOBYCFG::GENERATORS_IMPL_OUTDIR,
	    	},
			$args{outcode} )
		 || $LOG->logdie ($tt->error());
	} else {
	    # we cannot easily check whether the same file was already
	    # generated - so we don't
	    my $outfile =
		File::Spec->catfile ( $outdir, split (/::/, $impl->{package}) )
		. 'Async.pm';
	    $tt->process ( $input, 
	    	{
	    		impl		  => $impl, 
	    		obj 		  => $obj, 
	    	  	pmoses_home   => $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR,
	    	  	generated_dir => $MOBYCFG::GENERATORS_OUTDIR,
	    	  	services_dir  => $MOBYCFG::GENERATORS_IMPL_OUTDIR,
	    	},
			   $outfile ) || $LOG->logdie ($tt->error());
		chmod (0755, $outfile);
		$LOG->info ("\tAsync service created at '$outfile'\n");
		 
	}
    }
}


#-----------------------------------------------------------------
# update_table
#-----------------------------------------------------------------
sub update_table {
    my ($self, @args) = @_;
    my %args =
	( # some default values
	  impl_outdir    => ( $MOBYCFG::GENERATORS_IMPL_OUTDIR ||
			      MOSES::MOBY::Generators::Utils->find_file ($Bin, 'services') ),
	  services_table => ($MOBYCFG::GENERATORS_IMPL_SERVICES_TABLE || 'SERVICES_TABLE'),
	  impl_prefix    => ($MOBYCFG::GENERATORS_IMPL_PACKAGE_PREFIX || 'Service'),
	  cachedir       => $self->cachedir,
	  registry       => $self->registry,
	  service_names  => [],

	  # other args, with no default values
	  # authority     => 'authority'
	  # outcode       => ref SCALAR

	  # and the real parameters
	  @args );
    $self->_check_outcode (%args);

    my $outdir = File::Spec->rel2abs ($args{impl_outdir});
    $LOG->debug ("Arguments for generating services table: " . $self->toString (\%args))
	if ($LOG->is_debug);

    # read the current service table
    unshift (@INC, $args{impl_outdir});   # place where SERVICES_TABLE could be
    use vars qw ( $DISPATCH_TABLE );
    eval { require $args{services_table} };
    my $file_with_table;
    if ($@) {
	$LOG->warn ("Cannot find table of services '" . $args{services_table} . "': $@");
	$file_with_table = File::Spec->catfile ($args{impl_outdir}, $args{services_table});
    } else {
	$file_with_table = $INC{ $args{services_table} };
    }

    # get names of services that should be added to the service table:
    my @names = ();
    if ($args{service_names} and @{ $args{service_names} } > 0) {
	# 1) if there are service_names given, take them, and that's it
	#    (TBD?: should I checked names against the cache?)
	@names = @{ $args{service_names} };
    } else {
	# 2) otherwise we need to get names from the cache
	my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $args{cachedir},
					       registry => $args{registry});
	my %by_authorities = $cache->get_service_names;
	if ($args{authority}) {
	    my $authority = $by_authorities{ $args{authority} };
	    $self->throw ("Unknown authority '$args{authority}'.")
		unless $authority;
	    @names = @{ $authority };
	} else {
	    foreach my $authority (keys %by_authorities) {
		push (@names, @{ $by_authorities{$authority} });
	    }
	}
    }

    # update dispatch table
    foreach my $service_name (@names) {
	$DISPATCH_TABLE->{"http://biomoby.org/#$service_name"} =
	    $args{impl_prefix} . '::' . $service_name;
    }
    # ...and write it back to a disk
    require Data::Dumper;
    open DISPATCH, ">$file_with_table"
	or $self->throw ("Cannot open for writing '$file_with_table': $!\n");
    print DISPATCH Data::Dumper->Dump ( [$DISPATCH_TABLE], ['DISPATCH_TABLE'] )
	or $self->throw ("cannot write to '$file_with_table': $!\n");
    close DISPATCH;
    $LOG->info ("Updated services table '$file_with_table'. New contents: " .
		$self->toString ($DISPATCH_TABLE));
}

#-----------------------------------------------------------------
# update_async_table
#-----------------------------------------------------------------
sub update_async_table {
    my ($self, @args) = @_;
    my %args =
	( # some default values
	  impl_outdir    => ( $MOBYCFG::GENERATORS_IMPL_OUTDIR ||
			      MOSES::MOBY::Generators::Utils->find_file ($Bin, 'services') ),
	  services_table => ($MOBYCFG::GENERATORS_IMPL_ASYNC_SERVICES_TABLE || 'ASYNC_SERVICES_TABLE'),
	  impl_prefix    => ($MOBYCFG::GENERATORS_IMPL_PACKAGE_PREFIX || 'Service'),
	  cachedir       => $self->cachedir,
	  registry       => $self->registry,
	  service_names  => [],

	  # other args, with no default values
	  # authority     => 'authority'
	  # outcode       => ref SCALAR

	  # and the real parameters
	  @args );
    $self->_check_outcode (%args);

    my $outdir = File::Spec->rel2abs ($args{impl_outdir});
    $LOG->debug ("Arguments for generating async services table: " . $self->toString (\%args))
	if ($LOG->is_debug);

    # read the current service table
    unshift (@INC, $args{impl_outdir});   # place where ASYNC_SERVICES_TABLE could be
    use vars qw ( $DISPATCH_TABLE );
    eval { require $args{services_table} };
    my $file_with_table;
    if ($@) {
	$LOG->warn ("Cannot find table of async services '" . $args{services_table} . "': $@");
	$file_with_table = File::Spec->catfile ($args{impl_outdir}, $args{services_table});
    } else {
	$file_with_table = $INC{ $args{services_table} };
    }

    # get names of services that should be added to the service table:
    my @names = ();
    if ($args{service_names} and @{ $args{service_names} } > 0) {
	# 1) if there are service_names given, take them, and that's it
	#    (TBD?: should I checked names against the cache?)
	@names = @{ $args{service_names} };
    } else {
	# 2) otherwise we need to get names from the cache
	my $cache = MOSES::MOBY::Cache::Central->new (cachedir => $args{cachedir},
					       registry => $args{registry});
	my %by_authorities = $cache->get_service_names;
	if ($args{authority}) {
	    my $authority = $by_authorities{ $args{authority} };
	    $self->throw ("Unknown authority '$args{authority}'.")
		unless $authority;
	    @names = @{ $authority };
	} else {
	    foreach my $authority (keys %by_authorities) {
		push (@names, @{ $by_authorities{$authority} });
	    }
	}
    }
    # dont want the redefined errors in Async to discourage service developer
    no warnings qw(redefine);
	require MOBY::Async::WSRF;

    # update dispatch table
    foreach my $service_name (@names) {
	$DISPATCH_TABLE->{$WSRF::Constants::MOBY."#$service_name"} 
		= $args{impl_prefix} . '::' . $service_name . 'Async';
    $DISPATCH_TABLE->{$WSRF::Constants::MOBY."#$service_name".'_submit'} 
    	= $args{impl_prefix} . '::' . $service_name . 'Async';
    $DISPATCH_TABLE->{$WSRF::Constants::WSRPW .'/GetResourceProperty/GetResourcePropertyRequest'} 
    	= "MOBY::Async::SimpleServer";
    $DISPATCH_TABLE->{$WSRF::Constants::WSRPW.'/GetMultipleResourceProperties/GetMultipleResourcePropertiesRequest'} 
    	= "MOBY::Async::SimpleServer";
    $DISPATCH_TABLE->{$WSRF::Constants::WSRLW.'/ImmediateResourceTermination/DestroyRequest'} 
    	= "MOBY::Async::SimpleServer";
	
#	$DISPATCH_TABLE->{"http://biomoby.org/#$service_name"} =
#	    $args{impl_prefix} . '::' . $service_name;
	}
    # ...and write it back to a disk
    require Data::Dumper;
    open DISPATCH, ">$file_with_table"
	or $self->throw ("Cannot open for writing '$file_with_table': $!\n");
    print DISPATCH Data::Dumper->Dump ( [$DISPATCH_TABLE], ['DISPATCH_TABLE'] )
	or $self->throw ("cannot write to '$file_with_table': $!\n");
    close DISPATCH;
    $LOG->info ("Updated async services table '$file_with_table'. New contents: " .
		$self->toString ($DISPATCH_TABLE));
}


#-----------------------------------------------------------------
# _check_outcode
#    throws an exception if %args has an 'outcode' of a wrong type
#-----------------------------------------------------------------
sub _check_outcode {
    my ($self, %args) = @_;
    $self->throw ("Parameter 'outcode' should be a reference to a SCALAR.")
	if $args{outcode} and ref ($args{outcode}) ne 'SCALAR';
}


#-----------------------------------------------------------------
# Support for creating code showing how to read inputs.
#
# For each input, a tree of all children is created first (_fill_tree,
# recursively). Each branch of the tree represents a path from this
# input's name to a real value (or to an Id, if the last child is an
# Object and not a primitive type). Nodes are created by _add_node,
# each node has a pointer to its parent, an indication if it is
# already a leaf node, and a value. The value is either a data type
# name, or - for HAS members - another tree (with the same structure
# as the main tree). The leaf nodes have (in 'is_leaf') name of the
# last child (the name will be used as my $xxxx, but may be suffixed
# by a number if not unique - _select_name).
#
# Next, the tree is converted to pathes - each path for one child
# (_tree2paths). The resulting structure is understood by the template
# service.tt. An example of such structure is shown there.
#
#-----------------------------------------------------------------

{
    my $node_count = 0;
    sub _node_id {
	return ++$node_count;
    }
}

sub _select_name {
    my ($member_name, $members) = @_;
    return $member_name unless exists $members->{$member_name};
    foreach my $i (2..1000) {
	my $numbered_name = $member_name . "_$i";
	return $numbered_name unless exists $members->{$numbered_name};
    }
    return $member_name . "_$$";   # :-)
}

sub _add_node {
    my ($self, $tree, $node_value, $node_parent, $leaf_name) = @_;
    my $node_id = &_node_id;
    $tree->{$node_id} = { value => $node_value,
			  parent => $node_parent,
			  is_leaf => $leaf_name,
		      };
    return $node_id;
}

sub is_primitive_type {
    my ($self, $datatype_name) = @_;
    return exists $MOSES::MOBY::Generators::GenTypes::PRIMITIVE_TYPES{$datatype_name};
}

sub _fill_tree {
    my ($self, $cache, $tree, $parent_id, $datatype_name) = @_;
    my @children = $cache->get_all_children ($datatype_name);
    if (@children == 0) {
	$self->_add_node ($tree, 'id', $parent_id, 'id');
	$self->_add_node ($tree, 'namespace', $parent_id, 'namespace');
	return;
    }
    foreach my $child (@children) {
	# $child is of type MOSES::MOBY::Def::Relationship
	my $node_id = $self->_add_node ($tree, $child->memberName, $parent_id, undef);
	if ($child->relationship eq HAS) {
	    my $subtree = {};
	    my $subtree_node_id = $self->_add_node ($subtree, $child->memberName . '_element', undef, undef);
	    if ($self->is_primitive_type ($child->datatype)) {
		$self->_add_node ($subtree, 'value', $subtree_node_id, $child->memberName);
	    } else {
		$self->_fill_tree ($cache, $subtree, $subtree_node_id, $child->datatype);
	    }
	    $self->_add_node ($tree, $subtree, $node_id, $child->memberName);
	} else {
	    if ($self->is_primitive_type ($child->datatype)) {
		$self->_add_node ($tree, 'value', $node_id, $child->memberName);
	    } else {
		$self->_fill_tree ($cache, $tree, $node_id, $child->datatype);
	    }
	}
    }

#    my $subtree = {};
#    my $subtree_node_id = $self->_add_node ($subtree, $child->memberName . '_element', undef, undef);
#    $self->_add_node ($subtree, 'data', $subtree_node_id, $child->memberName);
}

sub _tree2paths {
    my ($self, $tree) = @_;
    my %members = ();
    my ($id, $node);
    while (($id, $node) = each %$tree) {
	next unless $node->{is_leaf};
	my $member_name = _select_name ($node->{is_leaf}, \%members);
	my $node_value = $node->{value};
	my @path;
	if (ref ($node_value) eq 'HASH') {
	    @path = ($self->_tree2paths ($node_value));
	} else {
	    @path = ($node_value);
	}
	while ($node->{parent}) {
	    $node = $tree->{ $node->{parent} };
	    unshift (@path, $node->{value});
	}
	$members {$member_name} = \@path;
    }
    return \%members;
}


1;
__END__

=head1 NAME

MOSES::MOBY::Generators::GenServices - generator of Moby services

=head1 SYNOPSIS

 use MOSES::MOBY::Generators::GenServices;
 
=head1 DESCRIPTION

=head1 AUTHORS, COPYRIGHT, DISCLAIMER

 Martin Senger (martin.senger [at] gmail [dot] com)
 Edward Kawas (edward.kawas [at] gmail [dot] com)

Copyright (c) 2006 Martin Senger, Edward Kawas. All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided "as is" without warranty of any kind.

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<outdir>

A directory where to create generated code.

=item B<cachedir>

=item B<registry>

=back

=head1 SUBROUTINES

#-----------------------------------------------------------------
# load
#    load (cachedir      => dir,
#          authority     => 'authority',
#          service_names => [..], ... )
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# generate_base
#-----------------------------------------------------------------

#-----------------------------------------------------------------
# generate_impl
#-----------------------------------------------------------------

=cut

