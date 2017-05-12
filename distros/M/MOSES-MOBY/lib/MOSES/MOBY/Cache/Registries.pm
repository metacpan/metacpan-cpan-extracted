#-----------------------------------------------------------------
# MOSES::MOBY::Cache::Registries
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Registries.pm,v 1.6 2009/08/19 17:07:26 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Cache::Registries;
use MOSES::MOBY::Base;
use base qw ( MOSES::MOBY::Base);
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

use vars qw/ %REGISTRIES /;

BEGIN {
	our (%REGISTRIES);
	my $already_init = 0;

	sub is_init {
		return $already_init++;
	}

	sub init_reg {
		#-----------------------------------------------------------------
		# A hard-coded list of the known registries.
		#
		# Please fill all details if you are adding new registry here.
		#
		# Do not create synonyms starting with 'http://' (they are in the
		# roles of the hash keys) - this is how some methods distinguish
		# between synonym and endpoint.
		#
		#-----------------------------------------------------------------
		%REGISTRIES = (
			iCAPTURE => {
				  endpoint  => 'http://moby.ucalgary.ca/moby/MOBY-Central.pl',
				  namespace => 'http://moby.ucalgary.ca/MOBY/Central',
				  name      => 'Sun Centre of Excellence, Calgary',
				  contact   => 'Edward Kawas (edward.kawas@gmail.com)',
				  public    => 'yes',
				  text      => 'A curated public registry hosted at U of C, Calgary',
			},
			IRRI => {
				endpoint  => 'http://cropwiki.irri.org/cgi-bin/MOBY-Central.pl',
				namespace => 'http://cropwiki.irri.org/MOBY/Central',
				name      => 'IRRI, Philippines',
				contact   => 'Mylah Rystie Anacleto (m.anacleto@cgiar.org)',
				public    => 'yes',
				text      => 'The MOBY registry at the International Rice Research Institute (IRRI) is intended mostly for Generation Challenge Program (GCP) developers. It allows the registration of experimental moby entities within GCP.',
			},
			testing => {
				endpoint  => 'http://mobytest.biordf.net/MOBY-Central.pl',
				namespace => 'http://mobytest.biordf.net/MOBY/Central',
				name      => 'Testing BioMoby registry',
				contact   => 'Edward Kawas (edward.kawas+testregistry@gmail.com)',
				public    => 'yes',
			},
		);

		# create a default registry
		$REGISTRIES{default} = $REGISTRIES{iCAPTURE};

		# read from config file user registries
		# add user_registries
		eval {
			do {

				# is this the best way?
				use lib $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR
				  || "/make/believe";
				use vars qw( %USER_REGISTRIES );
				require $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_FILENAME
				  if defined $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_FILENAME;
				foreach my $key ( sort keys %USER_REGISTRIES ) {

					# script if key exists
					next if exists $REGISTRIES{$key};
					$REGISTRIES{$key} = $USER_REGISTRIES{$key};
				}
			  }
		};
		unshift @INC, "/make/believe" if $@;
	}
}

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
	my $self   = shift;
	init_reg() unless is_init(); 
	my %cloned = %REGISTRIES;
	$self->{registries} = \%cloned;
}

#-----------------------------------------------------------------
# list
#-----------------------------------------------------------------
sub list {
	my $self = shift;
	return sort keys %{ $self->{registries} } if ref $self;

	# do this so that we can get user defined registries
	return MOSES::MOBY::Cache::Registries->new()->list();
}

#-----------------------------------------------------------------
# get
#-----------------------------------------------------------------
sub get {
	my ( $self, $abbrev ) = @_;
	$abbrev ||= 'default';
	return $self->{registries}->{$abbrev} if ref $self;

	# do this so that we can get user defined registries
	return MOSES::MOBY::Cache::Registries->new()->get($abbrev);
}

#-----------------------------------------------------------------
# all
#-----------------------------------------------------------------
sub all {
	my $self = shift;
	return $self->{registries} if ref $self;

	# do this so that we can get user defined registries
	return MOSES::MOBY::Cache::Registries->new()->all;
}

#-----------------------------------------------------------------
# add
#-----------------------------------------------------------------
sub add {
	my ( $self, %reg ) = @_;

	# add using object methods ...
	return MOSES::MOBY::Cache::Registries->new()->add(%reg) unless ref $self;

	# check for force
	my $force = exists $reg{force};

	# check %reg hash for conformance and existance
	return -1
	  unless defined $reg{namespace}
		  and defined $reg{endpoint}
		  and defined $reg{synonym}
		  and defined $reg{text}
		  and defined $reg{name}
		  and defined $reg{contact}
		  and defined $reg{public};

	$reg{public} = 'yes'
	  unless $reg{public} eq 'yes' || $reg{public} eq 'no';

	return -1
	  if $reg{synonym} =~ m"^http://";

	return -2
	  unless ( ( not defined $self->{registries}->{ $reg{synonym} } )
			   or $force );

	# call update ...
	do {
		eval { $self->_update_user_registries(%reg); };
		$LOG->warn("Error updating user registries: $@")
		  if ( $LOG->is_warn )
		  and $@;

		# return 0 if $@; # removed because we should be able to

		#update $self->{registries}
		$self->{registries}->{ $reg{synonym} } = {
												   endpoint  => $reg{endpoint},
												   namespace => $reg{namespace},
												   name      => $reg{name},
												   contact   => $reg{contact},
												   public    => $reg{public},
												   text      => $reg{text},
		};

		# return success
		return 0 if $@;
		return 1;
	} if ref $self;
}

#-----------------------------------------------------------------
# remove
#-----------------------------------------------------------------
sub remove {
	my ( $self, $name ) = @_;

	# add using object methods ...
	return MOSES::MOBY::Cache::Registries->new()->remove($name)
	  unless ref $self;
	return 1 unless defined $self->{registries}->{$name};

	# do the remove
	do {
		eval {

			# remove from file
			my %args = (    # some default values
				user_reg_dir =>
				  ( $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR || '' ),
				user_reg_table => (
							  $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_FILENAME
								|| 'USER_REGISTRIES'
				),
			);
			die
"Couldn't find the location to 'USER_REGISTRIES' in the configuration file!"
			  if $args{user_reg_dir} eq '';

			# read the current user registry table
			unshift( @INC, $args{user_reg_dir} )
			  ;    # place where USER_REGISTRIES could be
			use vars qw ( %USER_REGISTRIES );
			eval { require $args{user_reg_table} };
			my $file_with_table;
			if ($@) {
				$LOG->warn(   "Cannot find table of USER_REGISTRIES '"
							. $args{user_reg_table}
							. "': $@" );
				$file_with_table = File::Spec->catfile( $args{user_reg_dir},
														$args{user_reg_table} );
			} else {
				$file_with_table = $INC{ $args{user_reg_table} };
			}

			# remove from user regs table
			delete $USER_REGISTRIES{$name};

			# ...and write it back to a disk
			require Data::Dumper;
			open DISPATCH, ">$file_with_table"
			  or
			  $self->throw("Cannot open for writing '$file_with_table': $!\n");
			print DISPATCH Data::Dumper->Dump( [ \%USER_REGISTRIES ],
											   ['*USER_REGISTRIES'] )
			  or $self->throw("cannot write to '$file_with_table': $!\n");
			close DISPATCH;
			$LOG->info(
				  "\nUpdated user reg table '$file_with_table'. New contents:\n"
					. $self->toString( \%USER_REGISTRIES ) );
		};
		$LOG->warn("Error removing user registries: $@")
		  if ( $LOG->is_warn )
		  and $@;

		#update $self->{registries}
		delete $self->{registries}->{$name};

		# could remove from persistent store
		return 0 if $@;

		# return success
		return 1;
	} if ref $self;
}

#-----------------------------------------------------------------
# _update_user_registries
#-----------------------------------------------------------------

sub _update_user_registries {
	my ( $self, @args ) = @_;
	my %args = (    # some default values
		user_reg_dir => ( $MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_DIR || '' ),
		user_reg_table => (
							$MOBYCFG::USER_REGISTRIES_USER_REGISTRIES_FILENAME
							  || 'USER_REGISTRIES'
		),

		# and the real parameters
		@args
	);
	die
"Couldn't find the location to 'USER_REGISTRIES' in the configuration file!"
	  if $args{user_reg_dir} eq '';

# check %args for the right parameters, endpoint, namespace, name, synonym, contact, text, public
	die "Arguments to update user registries are incomplete."
	  unless defined $args{namespace}
		  and defined $args{endpoint}
		  and defined $args{synonym}
		  and defined $args{text}
		  and defined $args{name}
		  and defined $args{contact}
		  and defined $args{public};

	die "Registry synonyms should not start with http ..."
	  if $args{synonym} =~ m"^http://";

	my $outdir = File::Spec->rel2abs( $args{user_reg_dir} );
	$LOG->debug( "Arguments for generating user registries table: "
				 . $self->toString( \%args ) )
	  if ( $LOG->is_debug );

	# read the current user registry table
	unshift( @INC, $args{user_reg_dir} ); # place where USER_REGISTRIES could be
	use vars qw ( %USER_REGISTRIES );
	eval { require $args{user_reg_table} };
	my $file_with_table;
	if ($@) {
		$LOG->warn(   "Cannot find table of USER_REGISTRIES '"
					. $args{user_reg_table}
					. "': $@" );
		$file_with_table =
		  File::Spec->catfile( $args{user_reg_dir}, $args{user_reg_table} );
	} else {
		$file_with_table = $INC{ $args{user_reg_table} };
	}

	# update user regs table
	$USER_REGISTRIES{ $args{synonym} } = {
										   endpoint  => $args{endpoint},
										   namespace => $args{namespace},
										   name      => $args{name},
										   contact   => $args{contact},
										   public    => $args{public},
										   text      => $args{text},
	};

	# ...and write it back to a disk
	require Data::Dumper;
	open DISPATCH, ">$file_with_table"
	  or $self->throw("Cannot open for writing '$file_with_table': $!\n");
	print DISPATCH Data::Dumper->Dump( [ \%USER_REGISTRIES ],
									   ['*USER_REGISTRIES'] )
	  or $self->throw("cannot write to '$file_with_table': $!\n");
	close DISPATCH;
	$LOG->info( "\nUpdated user reg table '$file_with_table'. New contents:\n"
				. $self->toString( \%USER_REGISTRIES ) );
}

1;
__END__

=head1 NAME

MOSES::MOBY::Cache::Registries - List of known BioMoby registries

=head1 SYNOPSIS

  use MOSES::MOBY::Cache::Registries;

  # print synonyms of all available registries
  print "Available registries: ",
        join (", ", MOSES::MOBY::Cache::Registries->list);

  # print all features of a selected registry
  my $regs = new MOSES::MOBY::Cache::Registries;
  my %reg = $regs->get ('IRRI');
  foreach $key (sort keys $reg) {
     print "$key: $reg{$key}\n";
  }
  
  # add a new user defined (localhost) registry
  my $success = MOSES::MOBY::Cache::Registries->add(
               endpoint  => 'http://localhost/cgi-bin/MOBY/MOBY-Central.pl',
               namespace => 'http://localhost/MOBY/Central',
               name      => 'My Localhost registry',
               contact   => 'Edward Kawas (edward.kawas@gmail.com)',
               public    => 'yes',
               text      => 'A curated private registry hosted right here on this cpu',
               synonym   => 'my_new_reg',);
  print "Registry added!" if $success == 1;
  print "Registry not added to persistent store! Unknown error. Please check the log file." if $success == 0;
  print "Registry not added! Please check the parameters." if $success == -1;
  print "Registry not added! It may be already defined or synonym is in use."
      if $success == -2;
  

=head1 DESCRIPTION

A list of known BioMoby registries is hard coded here, and their
characteristics (such as their endpoints) can be retrieved by a
user-friendly synonym.

There is not that many registries, so there is (at the moment) no
intention to retrieve details from a database. Hard-coded entries seem
to be sufficient (if you create a new BioMoby registry, then make sure
to add the registry to this list by either editing the list (persistent)
or by programatically using the C<add()> method).

=head1 SUBROUTINES

All subroutines can be called as object or class methods unless you plan 
on using the C<add()> method. In that case, make sure to use class methods.

=head2 list

   my @regs = MOSES::MOBY::Cache::Registries->list;

Return a list of synonyms (abbreviations) of all available
registries. At least a synonym C<default> is always present. The
synonyms can be used in the C<get> method.

=head2 add

   my $regs = new MOSES::MOBY::Cache::Registries;
   print "Success!" if $reg->add(%details) == 1;

Add a registry to the list. This method consumes a hash 
with the following keys:
    synonym   - a short name for the registry
	name      - a human readable textual name of the reg
	endpoint  - the endpoint to the registry
	namespace - the registry URI
	text      - a human readable textual description for the reg
	public    - is this a public registry? [yes | no]
	contact   - contact information for the registry
	force     - if the registry synonym is in use, overwrite it
 
Returns:
     1 on success (add to persistent store and in memory object)
	 0 failure to add persistent store, for other non life threatening reasons (like incomplete config file, etc)- check log file
	-1 failure if there are bad parameters
	-2 failure if the registry already exists or synonym in use 

The synonym can be used in the C<get> method to retrieve the registry.

=head2 remove

   my $regs = new MOSES::MOBY::Cache::Registries;
   print "Success!" if $reg->remove($name) == 1;

Removes a registry from the list. This method consumes a 
the name of a registry to remove
 
Returns:
     1 on success (remove from persistent store and in memory object)
	 0 failure to remove from persistent store, for other non life threatening reasons (like incomplete config file, etc)- check log file

=head2 get

   my %reg = MOSES::MOBY::Cache::Registries->get ('IRRI');
   my %reg = MOSES::MOBY::Cache::Registries->get;

Return a hash with details about a registry whose abbreviation was
given as an argument. No argument is the same as 'default'. The known
synonyms can be obtained by C<list> method.

Returned hash can contain the following keys:

=over

=item * endpoint

Value is an endpoint (a stringified URL) of this BioMoby registry.

=item * namespace

Value is a namespace (a URI) used by this registry.

=item * name

Value is a full-name of this registry. Often accompanied with the
geographical location.

=item * contact

Value is a contact person, perhaps with en email, who is in charge of
this registry.

=item * public

Indicate (by value 'yes') that this registry is publicly available.

=item * text

A human-readable description explaining reasons, sometimes policies,
of this registry.

=back

=head2 all

   my $regs = MOSES::MOBY::Cache::Registries->all;

Return a hash reference with details about all registries. It is the
same as calling C<get> for all individual entries.

=head1 AUTHORS

 Martin Senger (martin.senger [at] gmail [dot] com)
 Edward Kawas (edward.kawas [at] gmail [dot] com)

=cut

