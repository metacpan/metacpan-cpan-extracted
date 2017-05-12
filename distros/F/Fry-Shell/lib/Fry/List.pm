package Fry::List;
use strict;
#use Data::Dumper;
#public
	my $list = {};
	our $Warn = 1;
	sub new ($%) {
		my ($class,%arg) = @_;
		#print Dumper \%arg;
		if (! exists $arg{id}) { warn "id attribute not set, didn't create object";return 0 }
		$class->setHashDefault(\%arg);
		bless \%arg,$class;

		$class->_indexObj($arg{id}=>\%arg);
	}
	sub _indexObj {
		my ($cls,$id,$obj,$opt) = @_;
		if (exists $cls->list->{$id} && $opt->{force} != 1) {
			warn "id $id already exists in list, not put in list"; return
		}	
		else { $cls->list->{$id} = $obj }
	}
	sub list { die "This is an abstract method which shouldn't be called"; }
	#sub list {$list}
	sub _hash_default {return {} }
	#both
	*defaultNew = \&manyNew;
	sub manyNew ($%) {
		my ($class,%arg) = @_; 
		$class->setId(%arg);
		for (values %arg) { $class->new(%$_) }
	}
	sub manyNewScalar ($$%) {
		my ($cls,$defaultAttr,%arg) = @_;
		$cls->convertScalarToHash(\%arg,$defaultAttr);
		$cls->manyNew(%arg);
	}
	sub defaultSet { shift->_obj(@_) }
	sub setOrMake ($%) {
		#my ($cls,$arg,$createsub,$defaultAttr) = @_;
		#slow: in order, fast, out of order setting
		my %opt = (ref $_[-1] eq "ARRAY") ? @{pop(@_)} : ();
		#print Dumper \%opt;
		my ($cls,%arg) = @_;
		
		while (my ($id,$value) = each %arg) {
			if ($cls->objExists($id)) {
				$cls->defaultSet($id=>delete $arg{$id});
			}
		}

		$cls->defaultNew(%arg);
	}
#inter-core class int
#Fry::Shell interface
	#get/set obj
	#sub objExists ($$) { (exists $_[0]->list->{$_[1]})?1 :0}
	#private to Fry::List subclasses
	#allows changing of &list call
	sub _obj ($$;$) {
		$_[0]->list->{$_[1]} = $_[2] if (@_ > 2); 
		return $_[0]->list->{$_[1]} 
	}
	#public
	sub objExists ($$) { 
		if (exists $_[0]->list->{$_[1]}) { return  1}
		else {
			#is 'or' working to handle objExists being called directly
			#w: assumes that objExists usually called by another fn which needs reporting
			warn("nonexistent object $_[1] specified from ".((caller(1))[3] or '')."\n",2);return 0 
		}
	}
	#unlike &get doesn't assume attr exists
	sub attrExists ($$$) {(exists $_[0]->Obj($_[1])->{$_[2]}) ? 1 : 0 } 

	#?: should I return undef on failing,causes errors later
	sub Obj { ($_[0]->objExists($_[1])) ? $_[0]->_obj($_[1]) : {} }
	sub unloadObj ($@) {
		my ($cls,@ids) = @_;
		for my $id (@ids) {
			delete $cls->list->{$id};
		}
	}
	sub setObj ($%) {
		my ($cls,%arg) = @_;
		while (my ($id,$obj) = each %arg){
			#e:new obj not created
			$cls->list->{$id} = $obj if ($cls->objExists($id));
		}
	}
	sub getObj ($%) {
		my ($cls,@ids) = @_;
		my @valid;
		for (@ids) { 
			push(@valid,$cls->list->{$_}) if ($cls->objExists($_)) 
		}
		return @valid;
	}
	#get/set attr
	sub get ($$$) { #return ($_[0]->objExists($_[1])) ?  
			(exists $_[0]->Obj($_[1])->{$_[2]}) ? $_[0]->list->{$_[1]}{$_[2]} 
		: do {warn("Attribute $_[2] of $_[1] doesn't exist",1); return undef } 
	}
	sub set ($$$$) { 
		if (@_ <4) {
			warn ('not enough arguments given'); return 0
		}
		else { return $_[0]->list->{$_[1]}{$_[2]} = $_[3] if ($_[0]->objExists($_[1])) } 
	}
	sub getMany ($$@) { 
		#only one to one mapping if attributes are scalar 
		my ($cls,$attr,@ids) = @_; 
		my @valid;
		for (@ids) { 
			my $arg = ($cls->objExists($_)) ?  $cls->list->{$_}{$attr} 
				: do { warn('passed undef to &getMany return',2);  undef };
			(ref $arg eq "ARRAY") ? push(@valid,@$arg) : push(@valid,$arg);
		}
		return @valid;
	}
	sub setMany ($$%) {
		my ($cls,$attr,%arg) = @_;

		while (my ($id,$value) = each %arg) {
			#to catch unbalanced %arg
			warn("$id\'s value is undef",1) if (! defined $value);  

			if (! $cls->objExists($id)) {
				warn("Didn't set attribute $attr of '$id' with $value",1);
				next;
			}
			$cls->list->{$id}{$attr} = $value
		}
	}
	sub allAttr {
		my ($cls,$attr) = @_;
		return ($cls->getMany($attr,$cls->listIds))
	}
#misc	
	sub callSubAttr {
		my ($cls,%arg) = @_;
		my @args = @{$arg{args}};
		my $caller = $arg{caller} || $cls;
		my $id = $cls->anyAlias($arg{id});

		if ($cls->attrExists($id,$arg{attr})) {
			my $sub = $cls->get($id,$arg{attr});
			#coderef
			if (ref $sub eq "CODE") {
				return $sub->($caller,@args);
			}
			#text 
			elsif ($caller->can($sub)) { return $caller->$sub(@args)}
			#td?: exact method in fn format
		}
		#elsif ($cls->sub->can(

		#default
		#works for cmd obj
		return $caller->$id(@args) if ($caller->can($id));
	}
	sub findIds ($$$$) {
		my ($cls,$attr,$comparison_type,$value) = @_;
		if (@_ < 4) { warn('not enough arguments'); return undef }
		my @found;

		for my $id ($cls->listIds) {
			if ($comparison_type eq "=") {
				push (@found,$id) if ($cls->attrExists($id,$attr) &&
					$cls->get($id,$attr) eq $value);
			}
			elsif ($comparison_type eq '~') {
				push (@found,$id) if ($cls->attrExists($id,$attr) &&
					$cls->get($id,$attr) =~ /$value/);
			}
			elsif ($comparison_type eq '>') {
				push (@found,$id) if ($cls->attrExists($id,$attr) &&
					$cls->get($id,$attr) > $value);
			}
			elsif ($comparison_type eq '<') {
				push (@found,$id) if ($cls->attrExists($id,$attr) &&
					$cls->get($id,$attr) < $value);
			}
		}
		return @found;
	}
	sub listIds ($){ return keys %{$_[0]->list} }
	sub listAlias ($) { return map { $_[0]->list->{$_}{a} } keys %{$_[0]->list} }
	sub listAliasAndIds ($) { return ($_[0]->listIds,$_[0]->listAlias) }
	sub findAlias ($$) {
		#d: returns alias if alias is an id,returns alias if found,returns undef if not found
		#tests if obj exists with either id or alias passed
		my ($cls,$alias) = @_;
		return $alias if (exists $cls->list->{$alias});
		for my $id ($cls->listIds) {
			#return $id if ($cls->list->{$id}{a} eq $alias)
			return $id if ($cls->attrExists($id,'a') && $cls->get($id,'a') eq $alias)
		}	
		warn("No alias found for object '$alias'",2);
		return undef;
		#to delete autovivified delete $o->{cmd}{$cmd};
		#$cls->objExists($alias);
	}
	sub anyAlias ($$) {
		#d: returns alias if not found
		return $_[0]->findAlias($_[1]) || $_[1];
	}
	sub pushArray($$$@) {
		my ($cls,$id,$attr) = splice(@_,0,3);

		if  (ref ($cls->Obj($id)->{$attr}) eq "ARRAY" or ! exists $cls->Obj($id)->{$attr}) {
			push(@{$cls->_obj($id)->{$attr}},@_);
		}
		else { warn("Didn't push array onto attribute $attr of $id",2) }

	}
#private	
	sub convertScalarToHash ($$$) {
		#d: sets all
		my ($cls,$hash,$attr) = @_;
		while (my ($k,$v)= each %$hash) {
			$hash->{$k} = {$attr=>$v};
		}
	}
	sub setHashDefault ($\%) {
		my $cls = shift; my $arg = shift;
		my %default = %{shift() || $cls->_hash_default ||{}};
		while (my ($k,$v)= each %default) {
			$arg->{$k} ||= $v;
		}
	}
	sub setId ($%){
		#d: sets hash's id by given key
		my ($class,%arg) = @_; 
		while (my ($id,$obj) = each %arg) {
			$obj->{id} = $id;
		}
	}
1;
__END__	

	sub setOrMake ($%) {
		my ($cls,$arg,$createsub,$defaultAttr) = @_;
		while (my ($id,$value) = each %$arg) {
			if (! $cls->objExists($id)) {
				$cls->$createsub($defaultAttr,$id=>$value);
			}
			else { $cls->setMany($defaultAttr,$id=>$value) }
		}
	}

	#old
	sub setHashDefaults ($$\%) {
		#handles multiple hashes	
		my ($o,$hashes,$default) = @_;
		my @hashes = (ref $hashes eq "ARRAY") ? @$hashes : $hashes; 
		for my $hash (@hashes) {
			while (my ($k,$v) = each %$default) {
				$hash->{$k} ||= $v;
			}
		}
	}	
=head1 NAME

Fry::List - Base class serving as a container for its subclass's objects.

=head1 DESCRIPTION 

This base class provides to its sub classes class methods for storing and accessing its objects.
It also comes with a &new constructor which creates a hash-based object and stores it in the
container or list.  

Here are a few key points you should know:

	- All objects must have a unique 'id' in the list.
	- For now only one list of objects can be created per class.
	This list is stored in &list. You must create a &list in the subclass
	namespace to have a unique list. 
	- One alias to an object's id is supported via an 'a' attribute in an
	object. Use &findAlias to get the aliased id.
	- Default values for required attributes can be set via
	&_hash_default.They will only be made and set if the attribute isn't
	defined.
	- Warnings in this class can be turned on and off by the variable $Fry::List::Warn

=head1 PUBLIC METHODS

	new(%attr_to_value): Given hash is blessed as an object after setting defaults. 
	manyNew(%id_to_obj): Makes several objects.
	manyNewScalar($attr,%id_to_value): Converts each hash value to a hash using $attr and
		&convertScalarToHash and then makes objects from modified hash.

	Get and Set methods
		_obj($id,$object): Get and set an obj by id.
		Obj($id): Gets an obj if it exists, otherwise returns {}
		setObj(%id_to_obj): Set multiple objects with a hash of id to object pairs.
		getObj(@ids): Gets several objects by id.
		unloadObj(@ids): Unload/delete objects from list.
		get($id,$attr): Gets an attribute value of the object specified by id.
		set($id,$attr,$value): Sets an attribute value of the object specified by id.
		getMany($attr,@ids): Gets same attribute of several objects
		setMany($attr,%id_to_values): Sets same attribute of objects via a hash of object to attribute-value pairs.
		setOrMake(%id_to_values): If the object id exists then it passes the hash pair to
			&defaultSet, otherwise a new object is created via &defaultNew.

	Other methods
		listIds(): Returns list of all object id's.
		listAlias (): Returns list of all aliases of all objects.
		listAliasAndIds (): Returns list of all aliases and all ids.
		findAlias($alias): Returns id that alias points to. Returns undef if no id found.
		anyAlias($alias): Wrapper around &findAlias which returns $alias instead.
		pushArray($id,$attr,@values): Pushes values onto array stored in object's attribute.
		objExists($id): Returns boolean indicating if object exists. Throws warning if it doesn't.
		attrExists($id): Returns boolean indicating if attribute exists.
		allAttr(): Returns all possible values of a given attribute for the class.
		findIds($attr,$comparison_type,$value): Returns all object of a class that whose
			attribute matches a value for a given comparison type. Possible comparison
			types are =,~,> and < .
		callSubAttr(%arg): Calls an attribute that is a subroutine. Attribute can be a
			coderef or the sub's name. This should be moved to Fry::Sub.

	Subclassable subs
		defaultSet(): Method used to set a variable's values by &setOrMake, usually a
			wrapper around &setMany
		defaultNew(): Interface method used by subclasses to initialize a hash of objects.
		list: Returns a hash reference for holding all objects.
		_hash_default: Returns a hash reference with default attributes and values.

	Utility subs
		setHashDefault($hash,($default_hash)?): Sets defaults to a hash, uses &_hash_default if
			no default hash given
		convertScalarToHash($hash,$key): Sets a hash value to a hashref of $key and its former value
		setId(%id_to_hash): Sets keys of arguments as ids of values which are hashes


=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
