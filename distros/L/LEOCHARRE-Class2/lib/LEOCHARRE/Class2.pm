package LEOCHARRE::Class2;
use strict;
no strict 'refs';
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw(
make_constructor
make_constructor_init
make_conf
make_count_for
make_accessor_setget_aref
make_accessor_get
make_method_counter
make_accessor_setget
make_accessor_setget_pathondisk
make_accessor_setget_ondisk_file
make_accessor_setget_ondisk_dir
make_accessor_setget_unique_array
);
$VERSION = sprintf "%d.%02d", q$Revision: 1.19 $ =~ /(\d+)/g;
# use Smart::Comments '###';
use Carp;

sub make_constructor {
   my $class = shift;
   ### $class
   *{"$class\::new"} = sub {
      my ($class,$self) = @_;
      $self||={};

      (defined $self and ref $self and ref $self eq 'HASH')
         or confess("Argument to constructor must be a hash ref");

      bless $self, $class;
      return $self;
   };
}

sub make_constructor_init {
   my $class = shift;
   ### $class
   *{"$class\::new"} = sub {
      my ($class,$self) = @_;
      $self||={};
      
      (defined $self and ref $self and ref $self eq 'HASH')
         or confess("Argument to constructor must be a hash ref");


      bless $self, $class;
      if ($class->can('init')){
         $self->init;
      }
      return $self;
   };
}



sub make_accessor_setget {
   my $class = shift;
   defined $class or die;

   for ( ___resolve_args(@_) ){
      _make_setget($class,@$_);
   }  
}

sub make_accessor_get {
   my $class = shift;
   defined $class or die;

   for ( ___resolve_args(@_) ){
      _make_get($class,@$_);
   }  
}


sub make_accessor_setget_ondisk_file {
   my $class = shift;
   defined $class or die;

   for ( ___resolve_args(@_) ){
      _make_setget_ondisk_file($class,@$_);
   }  
}

sub make_accessor_setget_ondisk_dir {
   my $class = shift;
   defined $class or die;

   for ( ___resolve_args(@_) ){
      _make_setget_ondisk_dir($class,@$_);
   }  
}

sub make_accessor_setget_aref {
   my $class = shift;
   defined $class or die;
   for ( ___resolve_args(@_) ){
      _make_setget_aref($class,@$_);
   }  
}

sub make_accessor_setget_unique_array {
   my $class = shift;
   defined $class or die;
   for ( ___resolve_args(@_) ){
      _make_setget_unique_array($class,@$_);
   }  
}



sub make_method_counter {
   my $class = shift;
   defined $class or die;
   for( ___resolve_args(@_) ){
      _make_method_counter($class,@$_);
   }
}
sub make_count_for {
   my $class = shift;
   defined $class or die;
   for( ___resolve_args(@_) ){
      _make_count_for($class,@$_);
   }
}


# THE REST ARE PRIVATE METHODS

sub ___resolve_args {   

   my @resolved_args;
   
   # each one is
   #  accessor_name, accessor_default_value (can be undef)

   METHOD : while (scalar @_){
      my $arg = shift;      
      defined $arg 
         or die('1.arguments must be scalars, array refs, or hash refs, not undef or false');      
      ### ARG START -----------------------------------------------
      ### $arg
      if ( my $ref = ref $arg ){         # make_accessor__ ( {} [])
         
         if ( $ref eq 'ARRAY' ){
            ### arg is aref
            push @resolved_args, $arg; # keep as is..            
            next METHOD;
         }
         
         elsif ( $ref eq 'HASH' ){
            ### arg is hashref
            while( my ($name, $default_value) = each %$arg ){
               push @resolved_args, [ $name, $default_value];               
            }
            next METHOD;
         }
         
         die("2.arguments must be scalars, array refs, or hash refs, "
            ."not undef or false or '$ref'");         
      }

      ### arg is not ref
      
      push @resolved_args, [$arg, undef];
   }

   return @resolved_args;
}



# DEFAULT SETGET ACCESSOR
sub _make_setget {
   my($_class,$_name,$_default_value) = @_;
   my $namespace = "$_class\::$_name";      

   *{$namespace} = sub {
      my $self = shift;
      my ($val) = @_;
   
      if( defined $val ){ # store it in object instance only
         $self->{$_name} = $val;
      }

      # if the key does not exist and we DO have a default in the class...
      if( !exists $self->{$_name} and defined $_default_value ){ 

            # BUT, if it is a ref, COPY it
            # IS A REF:
            if ( my $ref = ref $_default_value ){
               if ($ref eq 'ARRAY'){
                  $self->{$_name} = [ @$_default_value ];
               }
               elsif( $ref eq 'HASH' ){
                  $self->{$_name} = { %$_default_value };
               }
               elsif ( $ref eq 'SCALAR' ){
                  $self->{$_name} = $$_default_value;                  
               }
               else {
                  die("dont know how to use '$ref' ref as a default");
               }
            }


            # IS NOT A REF:
            else {
               $self->{$_name} = $_default_value;
            }
         
         
      }
      return $self->{$_name}; # may still be undef, that's ok
   }; 
} 

# GET ACCESSOR

sub _make_get {
   my($_class,$_name,$_default_value) = @_;
   my $namespace = "$_class\::$_name";     

   *{$namespace} = sub {
      my $self = shift;
   
      Carp::croak("This method does not take arguments.") if @_ and scalar @_;

      # if the key does not exist and we DO have a default in the class...
      if( !exists $self->{$_name} and defined $_default_value ){ 

            # BUT, if it is a ref, COPY it
            # IS A REF:
            if ( my $ref = ref $_default_value ){
               if ($ref eq 'ARRAY'){
                  $self->{$_name} = [ @$_default_value ];
               }
               elsif( $ref eq 'HASH' ){
                  $self->{$_name} = { %$_default_value };
               }
               elsif ( $ref eq 'SCALAR' ){
                  $self->{$_name} = $$_default_value;                  
               }
               else {
                  die("dont know how to use '$ref' ref as a default");
               }
            }


            # IS NOT A REF:
            else {
               $self->{$_name} = $_default_value;
            }
         
         
      }
      return $self->{$_name}; # may still be undef, that's ok
   }; 

}



# counter
sub _make_method_counter {
   my ($class,$name) = @_;
   my $namespace = "$class\::$name";      
   my $datspace = "__$name\_counter__";

   *{$namespace} = sub {
      my($self,$val)=@_;
      
      $self->{$datspace} ||=0;
      
      if(defined $val){
         $val=~/^\d+$/ or die("value to $namespace() must be digits");
         if ($val) { #positive value
            $self->{$datspace} = ($self->{$datspace} + $val);
         }
         else { # arg is 0, reset
            $self->{$datspace} = 0;
         }
      }
      return  $self->{$datspace};
   };
}


sub _make_setget_ondisk_file {
   my($_class,$_name,$_default_value) = @_;
   my $namespace = "$_class\::$_name";      

   
   *{$namespace} = sub {
      my $self = shift;
      my ($val) = @_;
   
      if( defined $val ){ # store it in object instance only
         my $abs = __resolve_f($val) or return;
         $self->{$_name} = $abs;
      }

      # if the key does not exist and we DO have a default in the class...
      if( !exists $self->{$_name} and defined $_default_value ){ 
         $self->{$_name} = __resolve_f($_default_value) or die;
      }
      return $self->{$_name}; # may still be undef, that's ok
   };

   sub __resolve_f {
      my $val = shift;
      require Cwd;
      my $a = Cwd::abs_path($val)
         or warn("cant resolve $val")
         and return;
      -f $a or warn("not file on disk '$a'")
         and return;
      return $a;  
   }

} 

sub _make_setget_ondisk_dir {
   my($_class,$_name,$_default_value) = @_;
   my $namespace = "$_class\::$_name";      
   

   *{$namespace} = sub {
      my $self = shift;
      my ($val) = @_;
   
      if( defined $val ){ # store it in object instance only
        my $abs = __resolve_d($val) or return;
        $self->{$_name} = $abs;
      }

      # if the key does not exist and we DO have a default in the class...
      if( !exists $self->{$_name} and defined $_default_value ){ 
        $self->{$_name} = __resolve_d($_default_value) or die;
      }
      return $self->{$_name}; # may still be undef, that's ok
   }; 

   sub __resolve_d {
      my $val = shift;
      require Cwd;
      my $abs = Cwd::abs_path($val)
            or warn("cannot revolve '$val' with Cwd::abs_path()")
            and return;
      -d $abs
            or warn("'$abs' is not a directory")
            and return;
      return $abs;
   }
} 




#sub make_accessor_errstr {
#   my $class = shift;
#   my $namespace = "$class\::errstr";
#}


# validate ondisk file or dir

sub _make_method_validate_ondisk_dir {
   my ($class,$name)= @_;

   my $namespace = "$class\::$name";      
   *{$namespace} = sub {
      my ($self,$val) = @_;
      $val or return; # croak, die, warn ??

      require Cwd;
      my $abs = Cwd::abs_path($val) or return;
      -d $abs and return $abs;
      return 0;
   }
}
sub _make_method_validate_ondisk_file {
   my ($class,$name)= @_;

   my $namespace = "$class\::$name";      
   *{$namespace} = sub {
      my ($self,$val) = @_;
      $val or return; # croak, die, warn ??

      require Cwd;
      my $abs = Cwd::abs_path($val) or return;
      -f $abs and return $abs;
      return 0;
   }
}







# clear methods
sub _make_method_clear { 
   my ($class,$name)= @_;

   my $namespace = "$class\::$name";      
   *{$namespace} = sub {
      my $self = shift;
      $self->{$namespace} = undef;
      return 1;
   }
}
sub _make_method_clear_hashref { 
   my ($class,$name)= @_;

   my $namespace = "$class\::$name";      
   *{$namespace} = sub {
      my $self = shift;
      $self->{$namespace} = {};
      return 1;
   }
}
sub _make_method_clear_arrayref { 
   my ($class,$name)= @_;

   my $namespace = "$class\::$name";      
   *{$namespace} = sub {
      my $self = shift;
      $self->{$namespace} = [];
      return 1;
   }
}




#use Smart::Comments '####';

# _make_setget_unique_array()
sub _make_setget_unique_array {
   my($_class, $_name, $_default_value) = @_;

   #### $_default_value
   #### $_name

   if( defined $_default_value ){
      ref $_default_value 
         and ref $_default_value eq 'ARRAY'
         or confess("Default value to $_class '$_name' must be array ref");
   }

   my $namespace        = "$_class\::$_name";      
   
   no strict 'refs';

   # method name
   my $method_name_href    = "$_name\_href";
   my $method_name_aref    = "$_name\_aref";
   my $method_name_count   = "$_name\_count";
   my $method_name_delete  = "$_name\_delete";   
   my $method_name_add     = "$_name\_add";
   my $method_name_exists  = "$_name\_exists";
   my $method_name_clear   = "$_name\_clear";

   # return array   
   *{"$_class\::$_name"} = sub {
      my $self = shift;   

      map{ $self->$method_name_href->{$_}++ } grep { defined $_ } @_;

      my @a = sort keys %{$self->$method_name_href};
      wantarray ? @a : \@a;
   };

   # return array ref  
   *{"$_class\::$method_name_aref"} = sub {      
      [ sort keys %{$_[0]->$method_name_href} ]
   };

   # return count
   *{"$_class\::$method_name_count"} = sub {      
      scalar keys %{$_[0]->$method_name_href}
   };

   # add
   *{"$_class\::$method_name_add"} = sub {
      my $self = shift;
      map{ $self->$method_name_href->{$_}++ } grep { defined $_ } @_;      
      1;
   };

   # delete
   *{"$_class\::$method_name_delete"} = sub {
      my $self = shift;
      map{ delete $self->$method_name_href->{$_} } grep { defined $_ } @_;
      1;
   };

   # exists
   *{"$_class\::$method_name_exists"} = sub {
      my $self = shift;
      exists $self->$method_name_href->{$_[0]} ? 1 : 0
   };

   # clear
   *{"$_class\::$method_name_clear"} = sub {
      my $self = shift;
      $self->{$method_name_href} = {};
      1;
   };

   # actual data holder..... the href.....

   
   
   # if the key does not exist and we DO have a default in the class...
   *{"$_class\::$method_name_href"} = sub {
      my $self = shift;

      if ( ! exists $self->{$method_name_href} ){
         #### apparently not init yet
         
         if ( exists $self->{$_name} ){
            #### was in constructor
            ref $self->{$_name}
               and ref $self->{$_name} eq 'ARRAY'
               or confess("value for $_class $_name must be array ref");

            @{$self->{$method_name_href}}{ @{$self->{$_name}} } = ();
         }
         elsif ( defined $_default_value ){ # was already checked for ARRAY ref
            #### had default value               
            @{$self->{$method_name_href}}{ @$_default_value } = ();
         }
         
         else { 
            #### blank value
            $self->{$method_name_href} = {};
         }
      }
      $self->{$method_name_href}
   };

}


#





# TODO, check if subs exist alreaddy? can() 
# should we do this or not?


# setget arrayref
sub _make_setget_aref {
   my($_class, $_name, $_default_value) = @_;

   my $namespace = "$_class\::$_name";      
   my $namespace_count = "$_class\::$_name\_count";

   *{$namespace} = sub {
      my $self = shift;
      my ($val) = @_;
   
      if( defined $val ){ # store it in object instance only
         ### 343 VAL
         ref $val eq 'ARRAY' or die("must be array ref arg");
         $self->{$_name} = $val;
      }

      # if the key does not exist and we DO have a default in the class...
      if( !exists $self->{$_name}){ 

         if ( defined $_default_value ){
            ### 350 DEF
            $self->{$_name} = [ @$_default_value ];         
         }
         else {
            ### NON
            $self->{$_name} = [];
         }
      }

      wantarray ? return @{$self->{$_name}} : return $self->{$_name};
   }; 
   #TODO, right now if undef, we set to [], is this teh behaviour we want?

   _make_count_for($_class, $_name);
} 




sub _make_count_for {
   my($class, $methodorkey) = @_;

   my $namespace = "$class\::$methodorkey\_count";      

   *{$namespace} = sub {
      my $self = shift;

      my $thing;

      # object method?
      if ($self->can($methodorkey)){
         $thing = $self->$methodorkey;
      }
      # object key?
      elsif( exists $self->{$methodorkey}){
         $thing = $self->{$methodorkey};
      }
      
      # die???, NO NO.. we do want to return if nothing.. if we want a method that just counts
      # a value in the object instance, taht's all
      else {
         return 0; # ???
         #die;
      }


      # ok... now what..
      my $ref = ref $thing;
      if( $ref and $ref eq 'ARRAY'){
         return scalar @$thing;
      }
      elsif( $ref and $ref eq 'HASH'){
         return scalar keys %$thing;
      }
      # else ???
      # die??
      return 0; # ???
   };

}


# BEGIN  CONF

sub make_conf {
   my $class = shift;
   my $default_path = shift; # can be undef  

    _make_setget($class, 'abs_conf', $default_path);

   for my $name (qw(conf conf_load conf_save conf_keys)){
      #$class->can($name) and warn("Class $class can already '$name()'");
      *{"$class\::$name"} = \&$name;
   }


   sub conf { 
      $_[0]->{conf} or $_[0]->conf_load;
      $_[0]->{conf} ||= {};
   }
   sub conf_load { 
      require YAML; 
      my $a = $_[0]->abs_conf 
         or warn "Can't load conf, missing abs_conf path."
         and return;
      -f $a 
         or warn "Can't load conf, not on disk '$a'\n"
         and return;

      $_[0]->{conf} = YAML::LoadFile($a) 
   }
   sub conf_keys { my $c = $_[0]->conf or return; sort keys %$c }
   sub conf_save { require YAML; YAML::DumpFile($_[0]->abs_conf,$_[0]->{conf}) }

}






# END CONF


1;
