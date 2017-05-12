
package Devel::StrictObjectHash;

use strict;
use warnings;

our $VERSION = '0.01';

## ----------------------------------------------------------------------------
## Debugging functions
## ----------------------------------------------------------------------------

# make a sub
sub DEBUG { 0 }

{
    # this should not be accessable 
    # to anyone but the debug function    
    my $debug_line_number = 1;
    # debuggin'
    sub debug { 
        # otherwise debug
        my $formatted_debug_line_number = sprintf("%03d", $debug_line_number);
        print STDERR "debug=($formatted_debug_line_number) ", @_, "\n";
        $debug_line_number++;
    }
}

## ----------------------------------------------------------------------------
## package variables
## ----------------------------------------------------------------------------

my $KEY_CREATION_ACCESS_REGEX  = qr/^new$/;
my $PRIVATE_FIELD_ACCESS_REGEX = qr/^new$/;

my $PUBLIC_FIELD_IDENTIFIER    = undef;
my $PROTECTED_FIELD_IDENTIFIER = qr/^[a-zA-Z][a-zA-Z0-9_]+/;
my $PRIVATE_FIELD_IDENTIFIER   = qr/^_/;

my $INC_FILTER_REG_EX = undef;
my $INC_filter = sub {
        my ($code, $file_name) = @_;
        # we dont handle anything other than
        # .pm files for now
        return undef unless $file_name =~ /\.pm$/;
        # get the package name
        my $package_name = $file_name;        
        $package_name =~ s/\.pm$//;
        $package_name =~ s/\//\:\:/g;
        # now create the package now, but
        # also create a bless routine in it
        if ($package_name =~ /$INC_FILTER_REG_EX/ || $file_name =~ /$INC_FILTER_REG_EX/) {
            debug("+ creating bless routine in ${file_name}") if DEBUG;
            no strict 'refs';
            *{"${package_name}::bless"} = \&Devel::StrictObjectHash::strict_bless;
        }
        # tell the world
        debug("^ loading $file_name package through INC filter") if DEBUG;                        
        # and let it be loaded normally
        return undef;
    };

my $ERROR_TYPE = 'die';
my %ERROR_HANDLERS = (
    "warn" => sub { warn "* ", __PACKAGE__, " [", (scalar localtime), "] ", @_ },
    "die"  => sub { die  @_ }
);
    
sub handleError {
    $ERROR_HANDLERS{$ERROR_TYPE}->(@_)    
}    

## ----------------------------------------------------------------------------
## import interface
## ----------------------------------------------------------------------------

sub import {
    shift;
    ((scalar(@_) % 2) == 0) || die "uneven parameter assignment for Devel::StrictObjectHash";
    my %params = @_;
    # change bless as nessecary
    if (exists $params{"strict_bless"}) {
        my $how_to_bless = $params{"strict_bless"};
        if (ref($how_to_bless) eq "ARRAY") {
            my @packages = @{$how_to_bless};
            no strict 'refs';
            *{"${_}::bless"} = \&Devel::StrictObjectHash::strict_bless foreach @packages;
        }
        elsif (ref($how_to_bless) eq "Regexp") {
            $INC_FILTER_REG_EX = $how_to_bless;
            unshift @INC => $INC_filter;
        }
        elsif ($how_to_bless eq "global") {
            *CORE::GLOBAL::bless = \&Devel::StrictObjectHash::strict_bless;
        }
        else {
            die "unrecognized parameter ($how_to_bless) for 'strict_bless'";
        }
    }
    # turn on debugging
    if (exists $params{"debug"}) {
        no warnings 'redefine';    
        *Devel::StrictObjectHash::DEBUG = sub { 1 } if $params{"debug"};
    } 
    # change $KEY_CREATION_ACCESS_REGEX
    if (exists $params{"allow_autovivification_in"}) {
        # if is this param is a reg-ex, we need to add 'new' to it
        # so we can handle strings and qr// stuff the same way
        $KEY_CREATION_ACCESS_REGEX = qr/$params{"allow_autovivification_in"}|new/;
    }
    # change $PUBLIC, $PROTECTED, $PRIVATE
    if (exists $params{"field_access_identifiers"}) {
        my %field_identifiers = %{$params{"field_access_identifiers"}};
        $PUBLIC_FIELD_IDENTIFIER    = $field_identifiers{"public"} if exists $field_identifiers{"public"};	
        $PROTECTED_FIELD_IDENTIFIER = $field_identifiers{"protected"} if exists $field_identifiers{"protected"};
        $PRIVATE_FIELD_IDENTIFIER   = $field_identifiers{"private"} if exists $field_identifiers{"private"};        
    }    
    # change $ERROR_TYPE
    if (exists $params{"error_handling"}) {
        (exists $ERROR_HANDLERS{$params{"error_handling"}}) 
            || die "error handling style (" . $params{"error_handling"}. ") not available";
        $ERROR_TYPE = $params{"error_handling"};
    }       
}

## ----------------------------------------------------------------------------
## bless function
## ----------------------------------------------------------------------------

# you can use this to replace bless
# it is best done by importing this 
# method into the module you wish to
# use Devel::StrictObjectHash in. 
# NOTE:
# this explicity disallows it to tie
# itself so it will not create any
# deep-recusion.
sub strict_bless {
	my ($hash, $class) = @_;
	debug("* tying hash ($hash) with Devel::StictObjectHash for $class") if DEBUG;
	# do not allow it to tie itself
	tie(%{$_[0]}, "Devel::StrictObjectHash", $class, %{$hash}) unless ($class eq "Devel::StrictObjectHash");
	# since this may be used to override the 
	# actual bless function, then we should
	# be explict here and use CORE::bless
	return CORE::bless($_[0], $class);
}

## ----------------------------------------------------------------------------
## class methods
## ----------------------------------------------------------------------------

use Data::Dumper ();

sub Dump {
    my ($object) = @_;
    my $tied_hash = tied(%{$object}) || die "not a Devel::StrictObjectHash object";
    if ($tied_hash->isa("Devel::StrictObjectHash")) {
        return "dumping: $tied_hash\n" . Data::Dumper::Dumper($tied_hash);
    }
}


## ----------------------------------------------------------------------------
## tie functions
## ----------------------------------------------------------------------------

sub TIEHASH { 
	my ($class, $blessed_class, %_hash) = @_;
    debug("class=($class) blessed_class($blessed_class) hash-keys=(" . (join ", " => keys %_hash) . ")") if DEBUG;
	# we need to get the name of the class that
	# actually called us (it should be at least
	# one away since you should be using strict_bless)
	# this will tell is what class is doing the 
	# actual initialization
	my ($actual_calling_class) = caller(1);	
	my $hash = { 
		# store the class this has is going to 
		# be blessed into
		blessed_class => $blessed_class,
		# store the initial hash fields
		fields => \%_hash,
		# this stores a reference to what class
		# the fields were actually initialized int
		# this is important for private fields
		# and being able to check if they are being
		# stepped upon or not
		fields_init_in => { map { $_ => $actual_calling_class } keys %_hash }
		};
	bless($hash, $class); 
	return $hash;
}

## HASH tie routines

sub STORE { 
	my ($self, $key, $value) = @_;
    debug("^ calling STORE on key=($key) for object=($self) ") if DEBUG;    
	# first we need to check to see if 
	# the user has the right to access 
	# this field
	$self->_check_access($key);
	# and log this activity    
	debug("> storing value=(" . 
            # this avoids unnessecary warnings 
            ((defined($value)) ? $value : "undef") . 
            ") at key=($key) in subroutine=(" . 
            # this is the name of the subroutine 
            # that called this function
            (caller(1))[3] . ")") if DEBUG;		
    $self->{fields}->{$key} = $value;
}

sub FETCH { 
	my ($self, $key) = @_;
    debug("^ calling FETCH on key=($key) for object=($self) ") if DEBUG;
	# first we need to check to see if 
	# the user has the right to access 
	# this field	
	$self->_check_access($key);
	# and log the activity
	debug("< fetching value=(" . 
            # this avoids unnessecary warnings
            # NOTE:
            # we say defined here, not exists because
            # we know the field exists, otherwise the
            # _check_access method would have failed
            # we just need to see if the value is not
            # undef, to avoid the warnings.
            ((defined($self->{fields}->{$key})) ?
                $self->{fields}->{$key} 
                : 
                "undef") . 
            ") at key=($key) in subroutine=(" . 
            # this is the name of the subroutine 
            # that called this function			
            (caller(1))[3] . ")") if DEBUG;    		
	return $self->{fields}->{$key};
}

# NOTE:
# the following 2 methods are rarely used, but 
# in the interest in providing a complete interface
# to the object, we will implement.

# checking existence is rare, since an
# object should know its fields (its protected 
# ones anyway). Good encapsulation dictates that
# the private fields should be hidden though, so
# we use _check_access. 
# NOTE:
# it might make sense to catch the exception
# thrown by _check_access here and return something
# but then again, I would not want to give the
# false impression that the field is NOT there.
sub EXISTS { 
	my ($self, $key) = @_; 
    debug("^ calling EXISTS on key=($key) for object=($self) ") if DEBUG;    
	# first we need to check to see if 
	# the user has the right to access 
	# this field		
	$self->_check_access($key);		
	return exists $self->{fields}->{$key}; 
}

# deletion too is something done rarely, usually
# only in the destructor method (DESTROY), so
# we will enforce access control here as usual
sub DELETE {
	my ($self, $key) = @_;
    debug("^ calling DELETE on key=($key) for object=($self) ") if DEBUG;    
	# first we need to check to see if 
	# the user has the right to access 
	# this field		
	$self->_check_access($key);	
	delete $self->{fields}->{$key};
}


# NOTE:
# the following 2 methods (FIRSTKEY and NEXTKEY) are
# for supporting the keys, values and each functions
# on hashes. These are not common things done with 
# the hashes used to form the basis of objects. 

sub FIRSTKEY { 
    my ($calling_package) = caller(0);
    handleError "Illegal Operation : calling FIRSTKEY not supported from $calling_package";
}

sub NEXTKEY { 
    my ($calling_package) = caller(0);
    handleError "Illegal Operation : calling NEXTKEY not supported from $calling_package";
}

# NOTE:
# the following 2 methods are not allowed at all.
# a user should never clear all the fields of an 
# object, that just doesnt make sense. And untie-ing
# of this object would violate the intent of this
# module (to provide a drop in bless replacement
# for debugging object field access issues)

sub CLEAR { 
	handleError "Illegal Operation : Clearing of this hash is strictly forbidden";
}

sub UNTIE {
	handleError "Illegal Operation : Un-tie-ing of this hash is strictly forbidden";
}

## Private subroutine

# to check the access of our hash
sub _check_access {
	my ($self, $key) = @_;
    debug("  ? checking access for key=($key)") if DEBUG;
	my ($calling_package, undef, undef, $hash_action) = caller(1); 
    ($calling_package ne "main") || handleError "Illegal Operation : hashes cannot be accessed directly";
	my (undef, undef, undef, $_calling_subroutine) = caller(2);	
    my ($calling_subroutine) = ($_calling_subroutine =~ /\:\:([a-zA-Z0-9_]+)$/);
    # we do not handle DESTROY methods, they get funky
    return if $calling_subroutine =~ /DESTROY/;
	# check if our key ever exists ...
	unless (exists $self->{fields}->{$key}) {
		# if our field does not exist, then we should throw an exception
		# we want to do this to protect ourselves against mis-spellings
		# of field names. This means that we are only allowed to create
		# fields before the hash is blessed. We do however allow one repreise
		# which is for a field to be created inside of the "new" method.
		#
		# here we check to see if they are in a methos allowed by the   
		# $KEY_CREATION_ACCESS_REGEX and if not throw an 
		# IllegalOperation exception...
        debug("    ? attempting to autovivify key=($key) in method=($calling_subroutine) from package=($calling_package)") if DEBUG;
		($calling_subroutine =~ /$KEY_CREATION_ACCESS_REGEX/) 
            || handleError "Illegal Operation : attempt to create non-existant key ($key) in method '$calling_subroutine'";
		# however, if they are in method allowed by $KEY_CREATION_ACCESS_REGEX
        # the then we allow the field to be created (this happens in STORE) and 
        # we note which package asked for it to be created.
        debug("    + autovivified key=($key) in hash in method=($calling_subroutine) from package=($calling_package)") if DEBUG;
		$self->{fields_init_in}->{$key} = $calling_package;
	}
	# if our key does exist then, 
	# check who is asking for it
	else {
		# first lets check the private fields ...
		if ($key =~ /$PRIVATE_FIELD_IDENTIFIER/) {	
			# we need to check to see if this is 
			# being called from an $KEY_CREATION_ACCESS_REGEX method and ...
			if ($calling_subroutine =~ /$KEY_CREATION_ACCESS_REGEX/ && 
				# if it is being asked to STORE a value
				$hash_action =~ /\:\:STORE$/ && 
				# and that the calling package is
				# not the same package who initialized 
				# the field
				$calling_package ne $self->{fields_init_in}->{$key}) {
				# if all these conditions meet then we 
				# have a problem ...
				
				# first lets check if the package which
				# initialized the field is actually a 
				# descendant of the calling package.
				# Meaning that the child package may
				# have intialized a private field that
				# the parent had reserved, but not yet
				# intialized (this can happen if you 
				# run your _init routines before you 
				# run the parents).
				if ($self->{fields_init_in}->{$key}->isa($calling_package)) {
					handleError "Illegal Operation : It seems that " . 
                            $self->{fields_init_in}->{$key} . 
                            " maybe stepping on one of ${calling_package}'s private fields ($key)";
				}
				# next we check to see if maybe the 
				# calling package is a descendent of the
				# package the field was intialized in.
				# Meaning that the child package is 
				# stepping on a private field from the
				# parent.
				elsif ($calling_package->isa($self->{fields_init_in}->{$key})) {
					handleError "Illegal Operation : $calling_package is stepping on a private field ($key) that belongs to " . $self->{fields_init_in}->{$key};
				}
				# and lastly our fall through case, since
				# no-one should be doing this anyway. 
				else {
					handleError "Illegal Operation : attempting to set a private field ($key) in $calling_subroutine, field was already set by " . $self->{fields_init_in}->{$key};
				}
			}
			# okay now we know that is all set
			#
			# For a private field we need to check 
			# if the calling package is the same as
			# the package the field was intialized in.
			# If it is, then all is fine.
			# However, if it is not we need to check 
			# on some things ...
            debug(">>> calling package=($calling_package) package init in=($self->{fields_init_in}->{$key})") if DEBUG;
			unless ($calling_package eq $self->{fields_init_in}->{$key}) { 
				# ocasionally the calling package is 
				# actually the derived class (because
				# its a dynamic method call), in which case
				# the call may actually still be valid,
				# so we check the calling subroutine. 
				# That subroutine name will contain the 
				# name of the package from where it originated,
				# and therefore tell us if the privacy is being
				# violated or not.
				($calling_subroutine =~ /^$self->{fields_init_in}->{$key}\:\:/) 
					|| handleError "Illegal Operation : $calling_package ($calling_subroutine) attempted to access private field ($key) for " . $self->{fields_init_in}->{$key}; 
			}
		}
		# now we check the protected fields ....
		elsif ($key =~ /$PROTECTED_FIELD_IDENTIFIER/) {	        
			# a protected field is one that can only be accessed
			# if the calling package is a descendent of the 
			# orginal class it was blessed into, or the actual
			# class itself
			($self->{blessed_class}->isa($calling_package)) 
				|| handleError "Illegal Operation : $calling_package attempted to access protected field ($key) for " . $self->{blessed_class}; 
		} 
        elsif (defined($PUBLIC_FIELD_IDENTIFIER) && $key =~ /$PUBLIC_FIELD_IDENTIFIER/) {
            # if the field is public, then we dont
            # need to do anything, access is granted.
            # we do though, check to see if the public
            # reg-ex is even defined, as it may not be
            ;
        }
	}
	# if we return normally from this 
	# subtroutine, meaning no exceptions
	# were thrown, then all is well in our
	# hash accessing world.
    debug("  + access granted for key=($key)") if DEBUG;
}


1;

__END__

=head1 NAME

Devel::StrictObjectHash - A strict access-controlled hash for debugging objects

=head1 SYNOPSIS

    use Devel::StrictObjectHash (
            # replace bless in the modules that match this reg-ex
            strict_bless => qr/.*?Module$/,
                                                                       
            # allow hash autovivification in routines other than 'new'
            allow_autovivification_in => qr/create_.*|_init/,
            
            # set the field access identifiers
            field_access_identifiers => {
                # no public access allowed
                public => undef
                # first char is an underscore followed by alpha
                protected => /^_[a-zA-Z]/  
                # the word 'private' followed by an underscores 
                # followed by an alpha character
                private => /^private_[a-zA-Z]/ 
            },
            
            # turn on debugging
            debug => 1           
        );

=head1 DESCRIPTION

The goal of this module is to provide a drop in C<bless> replacement for debugging object field access issues during development. It should never be used in production, as it has performance costs. 

=head2 What does this module do?

This module implements a tied hash which has OO style access control. By default, it provides protected style access control for regular hash keys, and private style access control for hash keys that are prefixed with a underscore (_), and does not allow any form of public access. However, if this is too strict a setting, it is possible to configure the key-style for public, protected and private access using regular expressions (see L<INTERFACE>).

=head2 How do I use this module?

The idea is that you configure this module at the top of your script (or in your mod_perl startup.pl file) to turn it on. Your application will then raise an error (the default is to C<die>) if you try to access your object fields incorrectly. It will quickly help you to find where someone (possibly you) is doing bad things with your objects. 

=head2 Do I need to change my code to use this module?

Yes and No. 

I<No> - If your code is well written OO code, then you should not have to make any other changes then to load and configure Devel::StrictObjectHash. I have tried (and am trying) to make this object as configurable as possible to cover many styles of hash-based OO code. However, if I am not accomadating your style (and you would like me too), let me know.

I<Yes> - If your OO is not so good and you do things like allow private fields to be accessed by subclasses, or access fields outside of object methods or other such nastiness. Then you will likely either not want to use this module at all, or you will need to recode. 

However, if your goal is to recode/refactor "bad-style" OO, then you actually may find this module I<very> useful.

=head1 INTERFACE

=over 4

=item B<strict_bless>

The C<strict_bless> option tells Devel::StrictObjectHash which packages in which to override C<bless>. The result of this is that the classes contained in those packages will be under the watch of Devel::StrictObjectHash. This parameter accepts three different types of arguments. The first is an array reference of package names:

    use Devel::StrictObjectHash (
                        strict_bless => [ qw(MyModule HisModule HerModule) ]
                        );

The second option is a regular expression reference, which is used to decide which modules to place under the control of Devel::StrictObjectHash. This option actually uses the little known trick of pushing a subroutine onto the C<@INC> array, which means that it will only work for modules loaded I<after> this line:

    use Devel::StrictObjectHash (
                        strict_bless => qr/.*?Module$/
                        ); 

The third option, is not usually recommended, but may be handy at times. This option will override C<bless> for B<everything>, through C<CORE::bless>. 

    use Devel::StrictObjectHash strict_bless => 'global';

Be careful with this option, since it will override C<bless> not only for your modules, but for any other you happen to load as well. However, if your program only uses your modules, then by all means, use this.

=item B<allow_autovivification_in>

Allowing autovivification of the object's internal hash to happen in routines other than just C<new> (the default). This option exists because at times it makes sense for the creation of an object's instance (the constructor) to be seperate from the initialization of that instance. 

The argument can either be a string

    use Devel::StrictObjectHash (
                        allow_autovivification_in => "_init"
                        );   

or a regular expression reference

    use Devel::StrictObjectHash (
                        allow_autovivification_in => qr/create_.*|_init/
                        ); 
                        
It is recommended that your regular expression be a strict as possible, so as to not match unintended routines.

=item B<field_access_identifiers>

As mentioned above, by default, Devel::StrictObjectHash provides protected style access control for 'regular' hash keys, and private style access control for hash keys that are prefixed with a underscore (_), and does not allow any form of public access. I realize this is a very strict, OO-purist style, and not for everyone, so I have made it possible to configure your hash-key access as you see fit. 

This option sets the field access identifiers for the three categories; I<public, protected, private>. The I<public> option can be set to C<undef>, which will result in disallowing I<public> access.

    use Devel::StrictObjectHash (
                        field_access_identifiers => {
                                # first char is alpha
                                public => /^[a-zA-Z]/, 
                                # first char is an underscore followed by alpha
                                protected => /^_[a-zA-Z]/  
                                # first 2 chars are underscores followed by alpha
                                private => /^__[a-zA-Z]/ 
                                }
                        );

=item B<error_handling>

By default, Devel::StrictObejctHash will C<die> if it encounters an incorrect field access. This may not be acceptable to your application, so an option to send the error to C<warn> is provided. 

    use Devel::StrictObjectHash (
                error_handling => "warn"
            );

Currently the only available options are C<warn> and C<die>, although there are plans for allowing custom error handlers to be written. 
            
=item B<debug>

Devel::StrictObjectHash has a number of embedded debug statements, which can be used essentially to 'watch' your code with. These statements are sent to C<STDERR> and prepended with a debug line number for easy reference. Turning this feature on is as simple as this:

    use Devel::StrictObjectHash debug => 1;  

There are future plans for allowing a custom debug handler to be used.

=back

=head1 METHODS

=over 4

=item B<strict_bless>

This is the method that B<Devel::StrictObjectHash> uses to replace C<bless> with. It can also be used on its own if you like, although it kind of defeats the whole purpose of the module.

=item B<Dump>

Since this module doesn't play to well with Data::Dumper's Dump method, we supply a replacement method here. This will essentially dump the underlying tied hash that B<Devel::StrictObjectHash> uses. 

=item B<handleError>

Handles the error based upon the value of the C<error_handling> import parameter. Defaults to C<die>.

=back

=head1 CAVEATS

Does not work well with Data::Dumper, as it gets caught in the tied hash access routines. Use our C<Dump> instead to see the tied hash that B<Devel::StrictObjectHash> uses.

Currently, checking access within C<DESTORY> methods appears a little wonky, so we just dont go there.

Currently you are not allowed use C<each>, C<keys> or C<values> on an object's internal hash and doing so will result in an error being thrown. To me, this makes since, as that it really an operation that you should not be doing with your internal hash. If you disagree with me, and can explain to my why it does make sense, email me, and I will add this ability.

Currently you are not allowed to clear or C<untie> the hash. I cannot see a reason to where it would ever make sense to do this, so errors are thrown if it is attempted.

=head1 TO DO

=over 4

=item Tests and Code Coverage

Currently we have 141 tests in the test-suite, but there are 2 test files which are yet to be written. I have included stub test files, and there are comments detailing the test plans, but I just don't have the time currently to write them. I want to get this 0.01 release up to CPAN to replace the I<very> incomplete 0.01a that is up there currently.

Also for some reason Devel::Cover chokes on the tests, even though they run fine under Test::Harness. Again, I don't have time currently to investigate this, so I will leave it be for now.

=item Custom error handlers

Ideally you could write your own error handler, it would look something like this.

    use Devel::StrictObjectHash (
                error_handling => sub {
                    MyErrorHandler::HandleError("MyApplication::Error [", @_, "]")
                }
            ); 

=item Using exceptions for C<die> errors

I would like to eventually use exceptions when the error handling is set to C<die>, this way we can include stack trace information in the errors.

=item Custom debug handlers

The same for debug handlers as well.

    use Devel::StrictObjectHash (
                debug => sub {
                    MyDebugger::debug("DEBUG [", @_, "]");
                }
            ); 
            
=item More debug statements

There are a number of debug statements embedded in the code, but I am sure that they are not enough, nor are the 100% descriptive enough. They can/should be improved.

=item Fix command-line interface

Ideally you wouldn't even touch your own code at all. But instead, just do something like this:

  perl -MDevel::StrictObjectHash=strict_bless,global,debug,1 my_script.pl
  
And the module would do its magic. But for some reason, that doesn't work, and I have no clue why.

=item Configuration file

It would be nice to have the CLI be able to check for a configuration file, most likely stored in the local directory.

=back

=head1 BUGS

So far, so good, but if you find a bug, let me know, and I will be sure to fix it. 

=head1 SEE ALSO

Clearly this module was inspired by B<Tie::StrictHash>. The difference is that B<Tie::StrictHash> is a general purpose hash with access controls, while this module is meant for debugging object field access issues only. 

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
