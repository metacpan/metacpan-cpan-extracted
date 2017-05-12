package LEOCHARRE::Code::Perl::Method;
use strict;



sub new {
   my($class,$self) = shift;
   $self ||= {};
   bless $self, $class;
   return $self;
}

sub name {
   my($self,$val) = @_;
   $self->{name} = $val if defined $val;
   return $self->{name};
}


# output code
sub output_code {
  my $self = shift;

   my $name = $self->name;


   my $code = 
"sub $name {
   my \$self = shift;
$args
   $self->{$name} = 
}
";
   $self->name, $self->args_count;

   my @podarg;
   for my $argname ($self->args_list) {
      my $type = $self->args_type($argname);
      push @podarg, "$argname ($type)";
   }
   
   $code.= join(', ',@podarg).".\n";

   $code.="\n";

   return $code;




}



# output pod
sub output_pod {
   my $self = shift;

   my $code = sprintf 
"=head2 %s

Takes %s arguments.
";
   $self->name, $self->args_count;

   my @podarg;
   for my $argname ($self->args_list) {
      my $type = $self->args_type($argname);
      push @podarg, "$argname ($type)";
   }
   
   $code.= join(', ',@podarg).".\n";

   $code.="\n";

   return $code;
}


# output settings

# name is_private arg_count arg_type returns  

sub args_count {
   my $self = shift;
   return (scalar @{$self->args});
}
sub args { # returns array ref
   my $self = shift;
   $self->{args} ||=[];
   return $self->{args};
}

sub args_list { # returns array list of args in order
   my $self = shift;
   my @list;
   for( @{$self->args} ){
      push @list, $_->[0];
   }
   return @list;
}

sub args_hashref {
   my $self = shift;
   
   my $hash={};
   
   for ($self->args){
      my($k,$v) = @$_;
      $hash->{$k} = $v;  
   }
   return $hash;  
}

sub args_type {
   my($self,$argname) = @_;

   my $val = $self->args_hashref->{$val} or die("no arg '$argname'");

   if( my $r = ref $val){
      return lc ($r) .' ref';
   }
   if( $val =~/^[01]$/ ){
      return 'boolean';
   }
   if( $val =~/^\d+$/ ){
      return 'number';
   }
   
   return 'string';
}

sub args_add {
   my $self = shift;
   TUPLE: while(1){
      my ($name,$val) = (shift,shift);
      defined $name or last TUPLE;
      #defined $val or last TUPLE;
      push @{$self->{args}}, [$name,$val];
   }
   return 1;      
}








1;

__END__

the idea if you can feed a POD description, a chunk of perl CODE, or variables
and from those, we create all the rest.




   $m->arg_add( 'jimmy' => {} );
   $m->arg_add( 'heads' => [] );
   $m->arg_add( 'sitting' => 0 );
   $m->arg_add( 'age' => undef );
   $m->arg_add( 'age' => undef );

   $m->arg_type('heads'); # returns 'array ref'
   $m->arg_type('jimmy'); # returns 'hash ref'
   $m->arg_type('sitting'); # returns 'boolean'
   $m->arg_type('age'); # returns 'string'


=head1 METHODS

=head2 name()

setget, returns name of method
   
=head2 args_list()

returns list of args in order, just the names

=head2 args_hashref()

returns hash ref of args/values

=head2 args_type()

arg is name of argument, returns type, one of:
   boolean, array ref, hash ref, string, number

=head2 args_add()

args are arg name and arg value
value can be undef, hash ref {}, array ref [], bool 0|1
