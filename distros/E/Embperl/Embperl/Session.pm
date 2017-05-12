#############################################################################
#
# HTML::Embperl::Session
# A bridge between Apache::Session and Embperl's %udat hash
# Copyright(c) 1999 Gerald Richter (richter@ecos.de)
# Copyright(c) 1998, 1999 Jeffrey William Baker (jeffrey@kathyandjeffrey.net)
# Distribute under the Artistic License
#
#############################################################################

=head1 NAME

HTML::Embperl::Session - adaptation of Apache::Session to work with HTML::Embperl

=head1 DESCRIPTION

An adaptation of Apache::Session to work with HTML::Embperl

=head1 SYNOPSIS

=head2 Addtional Attributes for TIE

=over 4

=item lazy

By Specifyng this attribute, you tell Apache::Session to not do any
access to the object store, until the first read or write access to
the tied hash. Otherwise the B<tie> function will make sure the hash
exist or creates a new one.

=item create_unknown

Setting this to one causes Apache::Session to create a new session
with the given id (or a new id, depending on C<recreate_id>)
when the specified session id does not exists. Otherwise it will die.

=item recreate_id

Setting this to one causes Apache::Session to create a new session id
when the specified session id does not exists. 

=item object_store

Specify the class for the object store. (The Apache::Session:: prefix is
optional) Only for Apache::Session 1.00.

=item lock_manager

Specify the class for the lock manager. (The Apache::Session:: prefix is
optional) Only for Apache::Session 1.00.

=item Store

Specify the class for the object store. (The Apache::Session::Store prefix is
optional) Only for Apache::Session 1.5x.

=item Lock

Specify the class for the lock manager. (The Apache::Session::Lock prefix is
optional) Only for Apache::Session 1.5x.

=item Generate

Specify the class for the id generator. (The Apache::Session::Generate prefix is
optional) Only for Apache::Session 1.5x.

=item Serialize

Specify the class for the data serializer. (The Apache::Session::Serialize prefix is
optional) Only for Apache::Session 1.5x.


=back

Example using attrubtes to specfiy store and object classes instead of
a derived class:

 use HTML::Embperl::Session;

 tie %session, 'HTML::Embperl::Session', undef,
    { 
    object_store => 'DBIStore',
    lock_manager => 'SysVSemaphoreLocker',
    DataSource => 'dbi:Oracle:db' 
    };

NOTE: HTML::Embperl::Session will require the nessecary additional perl modules for you.


=head2 Addtional Methods

=over 4

=item setid

Set the session id for futher accesses.

=item getid

Get the session id. The difference to using $session{_session_id} is,
that in lazy mode, getid will B<not> create a new session id, if it
doesn't exists.

=item cleanup

Writes any pending data, releases all locks and deletes all data from memory.

=back

=head1 AUTHORS

Gerald Richter <richter at embperl dot org> is the current maintainer.

This class was written by Jeffrey Baker (jeffrey@kathyandjeffrey.net)
but it is taken wholesale from a patch that Gerald Richter
(richter@ecos.de) sent me against Apache::Session.


=cut 

package HTML::Embperl::Session;

use strict;
use vars qw(@ISA $VERSION);

$VERSION = '2.0.0';
@ISA = qw(Apache::Session);

use Apache::Session;

use constant NEW      => Apache::Session::NEW () ;
use constant MODIFIED => Apache::Session::MODIFIED () ;
use constant DELETED  => Apache::Session::DELETED () ;
use constant SYNCED   => Apache::Session::SYNCED () ;


sub TIEHASH {
    my $class = shift;
    
    my $session_id = shift;
    my $args       = shift || {};

    if(ref $args ne "HASH") 
        {
        die "Additional arguments should be in the form of a hash reference";
        }

    #Set-up the data structure and make it an object
    #of our class


    #$args -> {IDLength} ||= 32 ;
    my $self = 
        {
        args         => $args,
        data         => { _session_id => $session_id },
        initial_session_id => $session_id,
        lock         => 0,
        lock_manager => undef,
        object_store => undef,
        status       => 0,
        serialized   => undef,
        };
    
    bless $self, $class;

    $self -> require_modules ($args) ;

    $self -> init if (!$args -> {'lazy'}) ;


    return $self ;
    }


sub require_modules
    {
    my $self = shift ;
    my $args = shift ;

    # check object_store and lock_manager classes (Apache::Session 1.00)
    
    if ($args -> {'object_store'})
        {
        $args -> {'object_store'} = "Apache::Session::$args->{'object_store'}" if (!($args -> {'object_store'} =~ /::/)) ;
        eval "require $args->{'object_store'}" ;
        die "Cannot require $args->{'object_store'}" if ($@) ;
        }

    if ($args -> {'lock_manager'})
        {
        $args -> {'lock_manager'} = "Apache::Session::$args->{'lock_manager'}" if (!($args -> {'lock_manager'} =~ /::/)) ;
        eval "require $args->{'lock_manager'}" ;
        die "Cannot require $args->{'lock_manager'}" if ($@) ;
        }

    # check Store, Lock, Generate, Serialize classes (Apache::Session 1.5x)
    
    if ($args -> {'Store'})
        {
        $args -> {'Store'} = "Apache::Session::Store::$args->{'Store'}" if (!($args -> {'Store'} =~ /::/)) ;
        eval "require $args->{'Store'}" ;
        die "Cannot require $args->{'Store'}" if ($@) ;
        }

    if ($args -> {'Lock'})
        {
        $args -> {'Lock'} = "Apache::Session::Lock::$args->{'Lock'}" if (!($args -> {'Lock'} =~ /::/)) ;
        eval "require $args->{'Lock'}" ;
        die "Cannot require $args->{'Lock'}" if ($@) ;
        }

    if ($args -> {'Generate'})
        {
        $args -> {'Generate'} = "Apache::Session::Generate::$args->{'Generate'}" if (!($args -> {'Generate'} =~ /::/)) ;
        eval "require $args->{'Generate'}" ;
        die "Cannot require $args->{'Generate'}" if ($@) ;
        }

    if ($args -> {'Serialize'})
        {
        $args -> {'Serialize'} = "Apache::Session::Serialize::$args->{'Serialize'}" if (!($args -> {'Serialize'} =~ /::/)) ;
        eval "require $args->{'Serialize'}" ;
        die "Cannot require $args->{'Serialize'}" if ($@) ;
        }
    }





sub init
    {
    my $self = shift ;

    #If a session ID was passed in, this is an old hash.
    #If not, it is a fresh one.

    my $session_id = $self->{data}->{_session_id} ;

    if (!$session_id && $self -> {idfrom})
        {
        $session_id = $self->{data}->{_session_id} = &{$self->{generate}}($self, $self -> {idfrom})  ;
        }

    $self->{initial_session_id} ||= $session_id ;

    $self->populate;

    if (defined $session_id  && $session_id) 
        {
        #check the session ID for remote exploitation attempts
        #this will die() on suspicious session IDs.        

        eval { &{$self->{validate}}($self); } ;
        if (!$@)
            { # session id is ok        
            if (exists $self -> {'args'}->{Transaction} && $self -> {'args'}->{Transaction}) 
                {
                $self->acquire_write_lock;
                }

            $self->{status} &= ($self->{status} ^ NEW);

	    if ($self -> {'args'}{'create_unknown'})
	        {
                eval { $self -> restore } ;
	        #warn "Try to load session: $@" if ($@) ;
	        $@ = "" ;
	        $session_id = $self->{data}->{_session_id} ;
	        }
	    else
	        {
	        $self->restore;
	        }
            }
        }

    $@ = '' ;

    if (!($self->{status} & SYNCED))
        {
        $self->{status} |= NEW();
        if (!$self->{data}->{_session_id} || $self -> {'args'}{'recreate_id'})
            {
            if (exists ($self->{generate}))
                { # Apache::Session >= 1.50
	        $self->{data}->{_session_id} = &{$self->{generate}}($self)  ;
                }
            else
                {
	        $self->{data}->{_session_id} = $self -> generate_id() ;
                }
            }
        $self->save;
        }
    
    #warn "Session INIT $self->{initial_session_id};$self->{data}->{_session_id};" ;

    return $self;
    }

sub FETCH {
    my $self = shift;
    my $key  = shift;

    $self -> init if (!$self -> {'status'}) ;

    return $self->{data}->{$key};
}

sub STORE {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    $self->{data}->{$key} = $value;
    
    $self->{status} |= MODIFIED;
    
    return $self->{data}->{$key};
}

sub DELETE {
    my $self = shift;
    my $key  = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    $self->{status} |= MODIFIED;
    
    delete $self->{data}->{$key};
}

sub CLEAR {
    my $self = shift;

    $self -> init if (!$self -> {'status'}) ;

    $self->{status} |= MODIFIED;
    
    $self->{data} = {};
}

sub EXISTS {
    my $self = shift;
    my $key  = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    return exists $self->{data}->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    my $reset = keys %{$self->{data}};
    return each %{$self->{data}};
}

sub NEXTKEY {
    my $self = shift;
    
    $self -> init if (!$self -> {'status'}) ;

    return each %{$self->{data}};
}

sub DESTROY {
    my $self = shift;
    
    return if (!$self -> {'status'}) ;

    $self->save;
    $self->release_all_locks;
}

sub cleanup 
    {
    my $self = shift;
    
    $self->{initial_session_id} = undef ;
    if (!$self -> {'status'})
	{
	$self->{data} = {} ;
        $self->{serialized} = undef ;
	return ;
	}

    $self->save;
    {
    local $SIG{__WARN__} = 'IGNORE' ;
    local $SIG{__DIE__}  = 'IGNORE' ; 
    eval { $self -> {object_store} -> close } ; # Try to close file storage 
    $@ = "" ;
    }
    $self->release_all_locks;

    $self->{'status'} = 0 ;
    $self->{data} = {} ;
    $self->{serialized} = undef ;
    }


sub setid {
    my $self = shift;

    $self->{'status'} = 0 ;
    $self->{data}->{_session_id} = $self->{initial_session_id} = shift ;

}

sub setidfrom {
    my $self = shift;

    $self->{'status'} = 0 ;
    $self->{data}->{_session_id} = $self->{initial_session_id} = undef ;
    $self->{idfrom} = shift ;

}


sub getid {
    my $self = shift;

    return $self->{data}->{_session_id} || $self->{'ID'} ;
}

sub getids {
    my $self = shift;

    return ($self->{initial_session_id}, $self->{data}->{_session_id} || $self->{'ID'},  $self->{status} & MODIFIED) ;
}

sub delete {
    my $self = shift;
    
    return if ($self->{status} & NEW);
    
    $self->{initial_session_id} = "!DELETE" ;

    $self -> init if (!$self -> {'status'}) ;

    $self->{status} |= DELETED;
    $self->save;
    $self->{data} = {} ; # Throw away the data
}    


#
# For Apache::Session 1.00
#

sub get_object_store {
    my $self = shift;

    return new {$self -> {'args'}{'object_store'}} $self;
}

sub get_lock_manager {
    my $self = shift;
    
    return new {$self -> {'args'}{'lock_manager'}} $self;
}

#
# Default validate for Apache::Session < 1.53
#

sub validate {
    #This routine checks to ensure that the session ID is in the form
    #we expect.  This must be called before we start diddling around
    #in the database or the disk.

    my $session = shift;
    
    if ($session->{data}->{_session_id} !~ /^[a-fA-F0-9]+$/) {
        die;
    }
}

#
# For Apache::Session >= 1.50
#

sub populate 
    {
    my $self = shift;

    my $store = $self->{args}->{Store};
    my $lock  = $self->{args}->{Lock};
    my $gen   = $self->{args}->{Generate};
    my $ser   = $self->{args}->{Serialize};


    $self->{object_store} = new $store $self if ($store) ;
    $self->{lock_manager} = new $lock $self if ($lock);
    $self->{generate}     = \&{$gen . '::generate'} if ($gen);
    $self->{'validate'}     = \&{$gen . '::validate'} if ($gen && defined (&{$gen . '::validate'}));
    $self->{serialize}    = \&{$ser . '::serialize'} if ($ser);
    $self->{unserialize}  = \&{$ser . '::unserialize'} if ($ser) ;

    if (!defined ($self->{'validate'}))
        {
        $self->{'validate'} = \&validate ;
        }

    return $self;
    }



1 ;
