package Maypole::Model::CDBI::FromCGI;
use strict;
use warnings;

=head1 NAME

Maypole::Model:CDBI::FromCGI - Validate form input and populate Model objects

=head1 SYNOPSIS

  $obj = $class->create_from_cgi($r);
  $obj = $class->create_from_cgi($r, { params => {data1=>...}, required => [..],
		 ignore => [...], all => [...]);
  $obj = $class->create_from_cgi($h, $options); # CDBI::FromCGI style, see docs

  $obj->update_from_cgi($r);
  $obj->update_from_cgi($h, $options);

  $obj = $obj->add_to_from_cgi($r);
  $obj = $obj->add_to_from_cgi($r, { params => {...} } );

  # This does not work like in CDBI::FromCGI and probably never will :
  # $class->update_from_cgi($h, @columns);


=head1 DESCRIPTION

Provides a way to validate form input and populate Model Objects, based
on Class::DBI::FromCGI.

=cut


# The base base model class for apps 
# provides good search and create functions

use base qw(Exporter); 
use CGI::Untaint;
use Maypole::Constants;
use CGI::Untaint::Maypole;
our $Untainter = 'CGI::Untaint::Maypole';

our @EXPORT = qw/update_from_cgi create_from_cgi untaint_columns add_to_from_cgi
    cgi_update_errors untaint_type validate_inputs validate_all _do_update_all 
    _do_create_all _create_related classify_form_inputs/;



use Data::Dumper; # for debugging

=head1 METHODS

=head2 untaint_columns

Replicates Class::DBI::FromCGI method of same name :

  __PACKAGE__->untaint_columns(
    printable => [qw/Title Director/],
    integer   => [qw/DomesticGross NumExplodingSheep],
    date      => [qw/OpeningDate/],
  );

=cut

sub untaint_columns {
    die "untaint_columns() needs a hash" unless @_ % 2;
    my ($class, %args) = @_;
    $class->mk_classdata('__untaint_types')
        unless $class->can('__untaint_types');
    my %types = %{ $class->__untaint_types || {} };
    while (my ($type, $ref) = each(%args)) {
        $types{$type} = $ref;
    }
    $class->__untaint_types(\%types);
}

=head2 untaint_type

  gets the  untaint type for a column as set in "untaint_types"

=cut

# get/set untaint_type for a column
sub untaint_type {
    my ($class, $field, $new_type) = @_;
    my %handler = __PACKAGE__->_untaint_handlers($class);
    return $handler{$field} if $handler{$field};
    my $handler = eval {
        local $SIG{__WARN__} = sub { };
        my $type = $class->column_type($field) or die;
        _column_type_for($type);
    };
    return $handler || undef;
}

=head2 cgi_update_errors

Returns errors that ocurred during an operation.

=cut

sub cgi_update_errors { %{ shift->{_cgi_update_error} || {} } }

=head2 create_from_cgi

Based on the same method in Class::DBI::FromCGI.

Creates  multiple objects  from a  cgi form. 
Errors are returned in cgi_update_errors

It can be called Maypole style passing the Maypole request object as the
first arg, or Class::DBI::FromCGI style passing the Untaint Handler ($h)
as the first arg. 

A hashref of options can be passed as the second argument. Unlike 
in the CDBI equivalent, you can *not* pass a list as the second argument.
Options can be :
 params -- hashref of cgi data to use instead of $r->params,
 required -- list of fields that are required
 ignore   -- list of fields to ignore
 all      -- list of all fields (defaults to $class->columns)

=cut

sub create_from_cgi {
  my ($self, $r, $opts) = @_;
  $self->_croak( "create_from_cgi can only be called as a class method")
    if ref $self;
  my ($errors, $validated);
  
  
  if ($r->isa('CGI::Untaint')) { # FromCGI interface compatibility
    ($validated, $errors) = $self->validate_inputs($r,$opts); 
  } else {
    my $params = $opts->{params} || $r->params;
    $opts->{params} = $self->classify_form_inputs($params);
    ($validated, $errors) = $self->validate_all($r, $opts);
  }

  if (keys %$errors) {
    return bless { _cgi_update_error => $errors }, $self;
  }

  # Insert all the data
  my ($obj, $err ) = $self->_do_create_all($validated); 
  if ($err) {
    return bless { _cgi_update_error => $err }, $self;
  }
  return $obj;
}


=head2 update_from_cgi

Replicates the Class::DBI::FromCGI method of same name. It updates an object and
returns 1 upon success. It can take the same arguments as create_form_cgi. 
If errors, it sets the cgi_update_errors.

=cut

sub update_from_cgi {
  my ($self, $r, $opts) = @_;
  $self->_croak( "update_from_cgi can only be called as an object method") unless ref $self;
  my ($errors, $validated);
  $self->{_cgi_update_error} = {};
  $opts->{updating} = 1;

  # FromCGI interface compatibility 
  if ($r->isa('CGI::Untaint')) {
    # REHASH the $opts for updating:
    # 1: we ignore any fields we dont have parmeter for. (safe ?)
    # 2: we dont want to update fields unless they change

    my @ignore = @{$opts->{ignore} || []};
    push @ignore, $self->primary_column->name;
    my $raw = $r->raw_data;
    #print "*** raw data ****" . Dumper($raw);
    foreach my $field ($self->columns) {
      #print "*** field is $field ***\n";
      	if (not defined $raw->{$field}) {
			push @ignore, $field->name; 
			#print "*** ignoring $field because it is not present ***\n";
			next;
      	}
      	# stupid inflation , cant get at raw db value easy, must call
      	# deflate ***FIXME****
      	my $cur_val = ref $self->$field ? $self->$field->id : $self->$field;
      	if ($raw->{$field} eq $cur_val) {
			#print "*** ignoring $field because unchanged ***\n";
			push @ignore, "$field"; 
      	}
    }
    $opts->{ignore} = \@ignore;
    ($validated, $errors) = $self->validate_inputs($r,$opts); 
  } else {
    my $params = $opts->{params} || $r->params;
    $opts->{params} = $self->classify_form_inputs($params);
    ($validated, $errors) = $self->validate_all($r, $opts);
    #print "*** errors for validate all   ****" . Dumper($errors);
  }

  if (keys %$errors) {
    #print "*** we have errors   ****" . Dumper($errors);
    $self->{_cgi_update_error} = $errors;
    return;
  }

  # Update all the data
  my ($obj, $err ) = $self->_do_update_all($validated); 
  if ($err) {
    $self->{_cgi_update_error} = $err;
    return; 
  }
  return 1;
}

=head2 add_to_from_cgi

$obj->add_to_from_cgi($r[, $opts]); 

Like add_to_* for has_many relationships but will add nay objects it can 
figure out from the data.  It returns a list of objects it creates or nothing
on error. Call cgi_update_errors with the calling object to get errors.
Fatal errors are in the respective "FATAL" key.

=cut

sub add_to_from_cgi {
  my ($self, $r, $opts) = @_;
  $self->_croak( "add_to_from_cgi can only be called as an object method")
    unless ref $self;
  my ($errors, $validated, @created);
   
  my $params = $opts->{params} || $r->params;
  $opts->{params} = $self->classify_form_inputs($params);
  ($validated, $errors) = $self->validate_all($r, $opts);

  
  if (keys %$errors) {
    $self->{_cgi_update_error} = $errors;
	return;
  }

  # Insert all the data
  foreach my $hm (keys %$validated) { 
	my ($obj, $errs) = $self->_create_related($hm, $validated->{$hm}); 
	if (not $errs) {
		push @created, $obj;
	}else {
		$errors->{$hm} = $errs;
	}
  }
  
  if (keys %$errors) {
    $self->{_cgi_update_error} = $errors;
	return;
  }

  return @created;
}

 


=head2 validate_all

Validates (untaints) a hash of possibly mixed table data. 
Returns validated and errors ($validated, $errors).
If no errors then undef in that spot.

=cut

sub validate_all {
  my ($self, $r, $opts) = @_;
  my $class = ref $self || $self;
  my $classified = $opts->{params};
  my $updating   = $opts->{updating};

  # Base case - validate this classes data
  $opts->{all}   ||= eval{ $r->config->{$self->table}{all_cols} } || [$self->columns('All')];
  $opts->{required} ||= eval { $r->config->{$self->table}{required_cols} || $self->required_columns } || [];
  my $ignore = $opts->{ignore} || eval{ $r->config->{$self->table}{ignore_cols} } || [];
  push @$ignore, $self->primary_column->name if $updating;
  
  # Ignore hashes of foreign inputs. This takes care of required has_a's 
  # for main object that we have foreign inputs for. 
  foreach (keys %$classified) {
    push @$ignore, $_ if  ref $classified->{$_} eq 'HASH'; 
  }
  $opts->{ignore} = $ignore;
  my $h = $Untainter->new($classified);
  my ($validated, $errs) = $self->validate_inputs($h, $opts);

  # Validate all foreign input
	
  #warn "Classified data is " . Dumper($classified); 
  foreach my $field (keys %$classified) {
    if (ref $classified->{$field} eq "HASH") {
      my $data = $classified->{$field};
  	  my $ignore = [];
      my @usr_entered_vals = ();
      foreach ( values %$data ) {
		push @usr_entered_vals, $_  if $_  ne '';
      }

      # filled in values
      # IF we have some inputs for the related
      if ( @usr_entered_vals ) {
		# We need to ignore us if we are a required has_a in this foreign class
		my $rel_meta = $self->related_meta($r, $field);
	    my $fclass   = $rel_meta->{foreign_class};
		my $fmeta    = $fclass->meta_info('has_a');
		for (keys %$fmeta) {
			if ($fmeta->{$_}{foreign_class} eq $class) {
				push @$ignore, $_;
			}
		}
		my ($valid, $ferrs) = $fclass->validate_all($r,
		{params => $data, updating => $updating, ignore => $ignore } ); 	

		$errs->{$field} = $ferrs if $ferrs;
		$validated->{$field} = $valid;

      } else { 
		# Check this foreign object is not requeired
		my %req = map { $_ => 1 } $opts->{required};
		if ($req{$field}) {
	  		$errs->{$field}{FATAL} = "This is required. Please enter the required fields in this section." 
			}
		}
  	}
  }
  #warn "Validated inputs are " . Dumper($validated);
  undef $errs unless keys %$errs;
  return ($validated, $errs);	
}



=head2 validate_inputs

$self->validate_inputs($h, $opts);

This is the main validation method to validate inputs for a single class.
Most of the time you use validate_all.

Returns validated and errors.

If no errors then undef in that slot.

Note: This method is currently experimental (in 2.11) and may be subject to change
without notice.

=cut

sub validate_inputs {
  my ($self, $h, $opts) = @_;
  my $updating = $opts->{updating};
  my %required = map { $_ => 1 } @{$opts->{required}};
  my %seen;
  $seen{$_}++ foreach @{$opts->{ignore}};
  my $errors 	= {}; 
  my $fields 	= {};
  $opts->{all} = [ $self->columns ] unless @{$opts->{all} || [] } ;
  foreach my $field (@{$opts->{required}}, @{$opts->{all}}) {
    next if $seen{$field}++;
    my $type = $self->untaint_type($field) or 
      do { warn "No untaint type for $self 's field $field. Ignoring.";
	   next;
	 };
    my $value = $h->extract("-as_$type" => $field);
    my $err = $h->error;

    # Required field error 
    if ($required{$field} and !ref($value) and $err =~ /^No input for/) {
      $errors->{$field} = "You must supply '$field'" 
    } elsif ($err) {

      # 1: No inupt entered
      if ($err =~ /^No input for/) {
				# A : Updating -- set the field to undef or '' 
	if ($updating) { 
	  $fields->{$field} = eval{$self->column_nullable($field)} ? 
	    undef : ''; 
	}
				# B : Creating -- dont set a value and RDMS will put default
      }

      # 2: A real untaint error -- just set the error 
      elsif ($err !~ /^No parameter for/) {
	$errors->{$field} =  $err;
      }
    } else {
      $fields->{$field} = $value
    }
  }
  undef $errors unless keys %$errors;
  return ($fields, $errors);
}


##################
# _do_create_all #
##################

# Untaints and Creates objects from hashed params.
# Returns parent object and errors ($obj, $errors).  
# If no errors, then undef in that slot.
sub _do_create_all {
  my ($self, $validated) = @_;
  my $class = ref $self  || $self;
  my ($errors, $accssr); 

  # Separate out related objects' data from main hash 
  my %related;
  foreach (keys %$validated) {
    $related{$_}= delete $validated->{$_} if ref $validated->{$_} eq 'HASH';
  }

  # Make main object -- base case
  #warn "\n*** validated data is " . Dumper($validated). "***\n";
  my $me_obj  = eval { $self->create($validated) };
  if ($@) { 
    warn "Just failed making a " . $self. " FATAL Error is $@"
      if (eval{$self->model_debug});  
    $errors->{FATAL} = $@; 
    return (undef, $errors);
  }

  if (eval{$self->model_debug}) {
    if ($me_obj) {
      warn "Just made a $self : $me_obj ( " . $me_obj->id . ")";
    } else {
      warn "Just failed making a " . $self. " FATAL Error is $@" if not $me_obj;
    }
  }

  # Make other related (must_have, might_have, has_many  etc )
  foreach $accssr ( keys %related ) {
    my ($rel_obj, $errs) = 
      $me_obj->_create_related($accssr, $related{$accssr});
    $errors->{$accssr} = $errs if $errs;

  }
  #warn "Errors are " . Dumper($errors);

  undef $errors unless keys %$errors;
  return ($me_obj, $errors);
}


##################
# _do_update_all #
##################

#  Updates objects from hashed untainted data 
# Returns 1 

sub _do_update_all {
	my ($self, $validated) = @_;
	my ($errors, $accssr); 

	#  Separate out related objects' data from main hash 
	my %related;
	foreach (keys %$validated) {
		$related{$_}= delete $validated->{$_} if ref $validated->{$_} eq 'HASH';
	}
	# Update main obj 
	# set does not work with IsA right now so we set each col individually
	#$self->set(%$validated);
	my $old = $self->autoupdate(0); 
	for (keys %$validated) {
		$self->$_($validated->{$_});
	}
	$self->update;
	$self->autoupdate($old);

	# Update related
	foreach $accssr (keys %related) {
		my $fobj = $self->$accssr;
		my $validated = $related{$accssr};
		if ($fobj) {
			my $old = $fobj->autoupdate(0); 
			for (keys %$validated) {
				$fobj->$_($validated->{$_});
			}
			$fobj->update;
			$fobj->autoupdate($old);
		}
		else { 
			$fobj = $self->_create_related($accssr, $related{$accssr});
		}	
	}
	return 1;
}
	

###################
# _create_related #
###################

# Creates and automatically relates newly created object to calling object 
# Returns related object and errors ($obj, $errors).  
# If no errors, then undef in that slot.

sub _create_related {
    # self is object or class, accssr is accssr to relationship, params are 
    # data for relobject, and created is the array ref to store objs we 
    # create (optional).
    my ( $self, $accssr, $params, $created )  = @_;
    $self->_croak ("Can't make related object without a parent $self object") 
	unless ref $self;
    $created      ||= [];
    my  $rel_meta = $self->related_meta('r',$accssr);
    if (!$rel_meta) {
	$self->_carp("[_create_related] No relationship for $accssr in " . ref($self));
	return;
    }
    my $rel_type  = $rel_meta->{name};
    my $fclass    = $rel_meta->{foreign_class};
    #warn " Dumper of meta is " . Dumper($rel_meta);


    my ($rel, $errs); 

    # Set up params for might_have, has_many, etc
    if ($rel_type ne 'has_own' and $rel_type ne 'has_a') {

	# Foreign Key meta data not very standardized in CDBI
	my $fkey= $rel_meta->{args}{foreign_key} || $rel_meta->{foreign_column};
	unless ($fkey) { die " Could not determine foreign key for $fclass"; }
	my %data = (%$params, $fkey => $self->id);
	%data = ( %data, %{$rel_meta->{args}->{constraint} || {}} );
	#warn "Data is " . Dumper(\%data);
	($rel, $errs) =  $fclass->_do_create_all(\%data, $created);
    }
    else { 
	($rel, $errs) =  $fclass->_do_create_all($params, $created);
	unless ($errs) {
	    $self->$accssr($rel->id);
	    $self->update;
	}
    }
    return ($rel, $errs);
}



		
=head2  classify_form_inputs

$self->classify_form_inputs($params[, $delimiter]);

Foreign inputs are inputs that have data for a related table.
They come named so we can tell which related class they belong to.
This assumes the form : $accessor . $delimeter . $column recursively 
classifies them into hashes. It returns a hashref.

=cut

sub classify_form_inputs {
	my ($self, $params, $delimiter) = @_;
	my %hashed = ();
	my $bottom_level;
	$delimiter ||= $self->foreign_input_delimiter;
	foreach my $input_name (keys %$params) {
		my @accssrs  = split /$delimiter/, $input_name;
		my $col_name = pop @accssrs;	
		$bottom_level = \%hashed;
		while ( my $a  = shift @accssrs ) {
			$bottom_level->{$a} ||= {};
			$bottom_level = $bottom_level->{$a};  # point to bottom level
		}
		# now insert parameter at bottom level keyed on col name
		$bottom_level->{$col_name} = $params->{$input_name};
	}
	return  \%hashed;
}

sub _untaint_handlers {
    my ($me, $them) = @_;
    return () unless $them->can('__untaint_types');
    my %type = %{ $them->__untaint_types || {} };
    my %h;
    @h{ @{ $type{$_} } } = ($_) x @{ $type{$_} } foreach keys %type;
    return %h;
}

sub _column_type_for {
    my $type = lc shift;
    $type =~ s/\(.*//;
    my %map = (
        varchar   => 'printable',
        char      => 'printable',
        text      => 'printable',
        tinyint   => 'integer',
        smallint  => 'integer',
        mediumint => 'integer',
        int       => 'integer',
        integer   => 'integer',
        bigint    => 'integer',
        year      => 'integer',
        date      => 'date',
    );
    return $map{$type} || "";
}

=head1 MAINTAINER 

Maypole Developers

=head1 AUTHORS

Peter Speltz, Aaron Trevena 

=head1 AUTHORS EMERITUS

Tony Bowden

=head1 TODO

* Tests
* add_to_from_cgi, search_from_cgi
* complete documentation
* ensure full backward compatibility with Class::DBI::FromCGI

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
 Maypole list.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 by Peter Speltz 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::FromCGI>

=cut

1;


