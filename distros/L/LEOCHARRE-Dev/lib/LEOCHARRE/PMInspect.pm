package LEOCHARRE::PMInspect;
use strict;
use warnings;
use Carp;
# use Smart::Comments '###';


sub new {
   my($class,$self) = @_;
   $self||={};
   bless $self,$class;
   return $self;
}

sub pm_class {
   my($self,$val) = @_;
   if(defined $val){
      $self->{pm_class} = $val;
   }

   if ((!defined $self->{pm_class} and !defined $self->{pm_instance}) and defined $self->{pm_path}){

         my @pkg = $self->minfo->packages_inside;
         my $class = shift @pkg if @pkg;
         
         $self->{pm_class} = $class;

   }

   
   if( ! defined $self->{pm_class}) {
      if ( my $ref = $self->pm_instance ){
         my $class = ref $ref or die("not ref");
         $self->{pm_class} = $class;
      }
   }
   
   return $self->{pm_class};
}

sub pm_instance {
   my($self,$val) = @_;
   if(defined $val){
      $self->{pm_instance} = $val;
   }

   if( !defined $self->{pm_instance} ){
   
   
      my $class = $self->pm_class or die("pm_instance not passed and pm_class  not set");
      
      
      eval  "use $class;" ;
      my $instance = $class->new() or die;
      $self->{pm_instance} = $instance;
   }
      
   return $self->{pm_instance};

}

sub pm_path {
   my($self,$val) = @_;
   $self->{pm_path} = $val if defined $val;

   unless( defined $self->{pm_path} ){
      $self->minfo;
      $self->{pm_path} =  $self->minfo->file ;   
   }
   return $self->{pm_path};
}






# INSPECTOR OBJECTS

sub _symdump {
   my $self = shift;
   unless( $self->{devel_symdump} ){
      require Devel::Symdump;   
      my $obj = Devel::Symdump->new( $self->pm_class );
      $self->{devel_symdump} = $obj;
   }
   return $self->{devel_symdump};
}





# OUTPUT METHODS

sub dump {
   my $self = shift;
   require Data::Dumper;
   my $string = Data::Dumper::Dumper($self->pm_instance);
   return $string;
}

sub symdump {
   my $self = shift;
   return $self->_symdump->as_string;
}




# ALL OUTPUTS

sub output {
   my $self = shift;

   my $output = sprintf "class: %s, ref: %s\n", $self->pm_class, $self->pm_instance;
   $output   .= sprintf "symdump:\n%s\n", $self->symdump;
   $output   .= sprintf "dump:\n%s\n", $self->dump();
   

   return $output;   
}





sub minfo {
   my $self = shift;

   unless( defined $self->{module_info} ){ 
      require Module::Info;
   
      if ( $self->{pm_path} ){ # if we call via method, will go into endless loop
      
         print STDERR " fromfile \n";
         
         $self->{module_info} = Module::Info->new_from_file( $self->pm_path );
      }

      elsif ( $self->pm_class ){
      
         print STDERR " romclass \n";

         $self->{module_info} = Module::Info->new_from_module( $self->pm_class );         
      }     

      else {
         die("no pm_path or pm_class can be set");
      }
   
   }

   
   return $self->{module_info};
}



1;


__END__









=head1 SYNOPSIS


example 1

   my $i = new LEOCHARRE::PMInspect({
      pm_instance => $instance,
   });


   print $i->output;

example 2

   my $i = new LEOCHARRE::PMInspect({
      pm_class => 'Name::Space',
   });


   print $i->output;

exmaple 3

   my $i = new LEOCHARRE::PMInspect({
      pm_path => './lib/Module.pm',
   });

   print $i->output;


=head2 pm_class()

get name of module

=head2 pm_instance()

retrieve instance

=head2 pm_path()

abs path to file


=head2 _symdump()

returns Devel::Symdump object
no arg

=head2 minfo()

returns Module::Info object
takes no arg

=head2 symdump()

returns symdump output as string

=head2 dump()

returns Data::Dumper output



=head2 output()

returns string for output to STDERR, includes all outputs

=cut
