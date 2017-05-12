package HTML::Template::Default;
use strict;
use Carp;
use base 'HTML::Template';
use LEOCHARRE::Debug;
use vars qw(@EXPORT_OK @ISA %EXPORT_TAGS $VERSION);
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_tmpl);
%EXPORT_TAGS = ( 
	all => \@EXPORT_OK,
);
$VERSION = sprintf "%d.%02d", q$Revision: 1.10 $ =~ /(\d+)/g;


sub _get_abs_tmpl {
   my $filename = shift;
   $filename or debug('no filename provided') and return;
   #$filename or die('missing filename argument to get_tmpl');

   my @possible_abs;

   for my $envar ( $ENV{HTML_TEMPLATE_ROOT}, $ENV{TMPL_PATH}, $ENV{HTML_TEMPLATE_ROOT} ){
      defined $envar or next;
      push @possible_abs, "$envar/$filename";
   }

   # lastly try the filename
   push @possible_abs, $filename;


   for my $abs ( @possible_abs ){
      if( -f $abs ){
         debug("file found: $abs");
         return $abs;
      }
      else {
         debug("file not found: $abs");
      }
   }

   debug("$filename : not found on disk.\n");
   return;
}





sub get_tmpl {
   if( scalar @_ > 3 ){ 
      debug('over');
      return tmpl(@_);
   } 
   else {
      debug('under');
      my %arg;
      for (@_){
         defined $_ or next;
         if( ref $_ eq 'SCALAR' ){
            $arg{scalarref} = $_;
            next;
         }
         $arg{filename} = $_;
      }
      
      # insert my default params
      $arg{die_on_bad_params} = 0;
      
      return tmpl(%arg);
   }

}

sub tmpl {
   my %a = @_;
   defined %a or confess('missing argument');

   ### %a

   my $debug = sprintf 'using filename: %s, using scalarref: %s',
      ( $a{filename} ? $a{filename} : 'undef' ),
      ( $a{scalarref} ? 1 : 0 ),
      ;
   
   $a{filename} or $a{scalarref} or confess("no filename or scalarref provided");


   if( my $abs = _get_abs_tmpl($a{filename})){
      
      my %_a = %a;      
      #if there is a scalarref, delete it
      delete $_a{scalarref};

      #replace filename with what we resolved..
      $_a{filename} = $abs;

      if ( my $tmpl = HTML::Template->new(%_a) ){
         debug("filename, $debug");
         return $tmpl;
      }
   }

   if( $a{scalarref} ){
   
      my %_a = %a;
      #if there is a filename, delete it
      delete $_a{filename};

      if ( my $tmpl = HTML::Template->new(%_a) ){
         debug("scalarref - $debug");
         return $tmpl;
      }
   }

   carp(__PACKAGE__ ."::tmpl() can't instance a template - $debug");
   return;
}




# NEW VERSION... by overriding new in HTML::Template....





sub new {
   my $class = shift;
   my %opt = @_;

   # for this to be of any use there must be
   $opt{filename} # at least a filename source
      and ( $opt{filehandle} or $opt{arrayref} or $opt{scalarref} ) # and at least a default source passed as argument
      #or return $class->SUPER::new( %opt ); # otherwise we add nothing, and revert to regular HTML::Template
      or return HTML::Template->new( %opt ); # otherwise we add nothing, and revert to regular HTML::Template
   

   # ok, at this point we know we have a filename source and some other source

   # we need to test the filename source, if it is valid, remove the other source(s)
   if (
      HTML::Template::_find_file( # in HTML::Template
         { options => { path => ($opt{path} || []) } }, # pseudo 'self'
         $opt{filename},
      )
   ){
      $DEBUG and Carp::cluck('# found file, deleting other sources');   
      delete $opt{filehandle};
      delete $opt{arrayref};
      delete $opt{scalarref};
   }

   else {      
      $DEBUG and Carp::cluck('# did not find file, deleting filename source');
      delete $opt{filename};
   }
  
   #$class->SUPER::new( %opt );
   HTML::Template->new( %opt );
}



1;
