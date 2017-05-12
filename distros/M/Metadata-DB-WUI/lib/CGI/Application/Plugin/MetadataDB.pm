package CGI::Application::Plugin::MetadataDB;
use strict;
require Exporter;
require CGI::Application;
use LEOCHARRE::DEBUG;
use vars qw(@ISA $VERSION @EXPORT_OK @EXPORT);

# what modules does this code need
use HTML::Template::Default 'get_tmpl';
use CGI::Application::Plugin::Feedback;
use CGI::Application::Plugin::Session;


no strict 'refs';
# this sets default
__PACKAGE__->_set_class_defaults(
   mdw_per_page_limit => 100,
   mdw_result_code => '<hr />
   <div>
   <i><TMPL_VAR LIST_INDEX></i> 
   id <TMPL_VAR ID>
      <TMPL_VAR META_AS_UL_HTML>
   </div>',
   mdw_search_results_tmpl_name => 'mdw.search_results.html',
   mdw_search_tmpl_name => 'mdw.search.html',

);

# export...
@ISA = qw(Exporter);
@EXPORT_OK = qw(mds_object 
mdw_per_page_limit
mdw_process_search 
mdw_record_params 
mdw_records_loop 
mdw_result_code
mdw_results_loop_detailed 
mdw_search_args_submitted
mdw_search_results_tmpl 
mdw_search_results_tmpl_name
mdw_search_results_tmpl_code 
mdw_search_tmpl
mdw_search_tmpl_name);
@EXPORT = @EXPORT_OK;



sub _set_class_defaults {
   my $class = shift;
   my %arg = @_;
   while( my($k,$v) = each %arg ){
      ${"$class\::$k"} = $v;   
      _make_class_accessor_setget($class,$k);
   }
   return;
}

sub _make_class_accessor_setget {
   my($class,$name)= @_;
   defined $class or die;
   defined $name or die;

   *{"$class\::$name"} = 
   sub {
      my ($self,$val) = @_;
      
      if( defined $val ){
         # store it in object only
         $self->{$name} = $val;
      }

      unless( defined $self->{$name} ){
         
         # check if it's defined in the class default
         if( defined ${"$class\::$name"} ){
            $self->{$name} = ${"$class\::$name"};
         }
      }
      return $self->{$name};   
   };
}




sub mdw_search_tmpl {
   my ($self,$tmpl) = @_;

   if(defined $tmpl){
      $self->{_mdw_search_tmpl} =$tmpl;
   }
   
   unless( $self->{_mdw_search_tmpl} ){

      $ENV{HTML_TEMPLATE_ROOT} or die('$ENV{HTML_TEMPLATE_ROOT} is not set');
   
      my $filename = $self->mdw_search_tmpl_name;
      $self->feedback("trying for tmpl '$filename'") if DEBUG;
   
      my $abs  = "$ENV{HTML_TEMPLATE_ROOT}/$filename";
      -f $abs or die("$abs not on disk, missing $filename 
         in HTML_TEMPLATE_ROOT, please see Metadata::DB::WUI");
   
      debug("found '$abs'");
      require HTML::Template::Default;
      my $tmpl = HTML::Template::Default::get_tmpl($filename);
      $self->{_mdw_search_tmpl} = $tmpl;
   }
   return $self->{_mdw_search_tmpl};
}

sub mdw_search_results_tmpl {
   my($self,$tmpl) = @_;
   if(defined $tmpl){
      $self->{_mdw_search_results_tmpl} = $tmpl;
   }
   unless( $self->{_mdw_search_results_tmpl} ){
      
      my $filename      = $self->mdw_search_results_tmpl_name;
      my $default_code  = $self->mdw_search_results_tmpl_code;
      $self->feedback("trying for tmpl '$filename'") if DEBUG;

      require HTML::Template::Default;
      my $tmpl = HTML::Template::Default::get_tmpl($filename,\$default_code);
      $self->{_mdw_search_results_tmpl} = $tmpl;
   }
   return $self->{_mdw_search_results_tmpl};
}






# TEMPLATES ...............................



sub mdw_search_results_tmpl_code {
   my $self = shift;
   my $rc = $self->mdw_result_code;
   my $default_code =  qq{
   <TMPL_LOOP SEARCH_RESULTS_LOOP>$rc</TMPL_LOOP>
   
   };
   return $default_code;
}


# end templates --------------------------------------------------------------------










# START GET ARGS ////////////////////////////////////////// //////////////////////////
# the output of this is fed to Metadata::DB::Search::search()
sub mdw_search_args_submitted  {
   my $self = shift;
   my %h=();

   # the form needs to list what the attribute params are..
   # this means though, that we cannot reload a search without posting

   # DONT MESS WITH THIS
   require Metadata::DB::Search::InterfaceHTML;  
   my $PREPEND_FIELD_NAME = $Metadata::DB::Search::InterfaceHTML::PREPEND_FIELD_NAME;

   my $prepend = $self->query->param($PREPEND_FIELD_NAME);
   $prepend
      or warn("missing ($PREPEND_FIELD_NAME:$prepend) in post data")      
      and return;
   debug("prepend $PREPEND_FIELD_NAME = $prepend");


   my @a = $self->query->param( "$prepend\_attribute") 
      or debug("No search params requested. Missing [$prepend\_attribute] in form.")
      and return;

   unless ( defined @a and scalar @a ){
      debug('no search params requested');
      $self->feedback('No search params requested.');
      return;
   }

   my $message;

   ATT: for my $key (@a){
      my $val = $self->query->param("$prepend\_$key");
      defined $val and $val=~/\w/ or next ATT;

      my $type = $self->query->param("$prepend\_$key\_match_type");
      $type or warn("no type in $type");
      $type ||='like';
         #TODO this is not working

      $h{"$key:$type"} = $val;
      debug("search param: $key ($type) $val");

      $self->feedback("You searched for '$key' ($type) '$val'");
   }

   %h or $self->feedback('No search params requested and resolved.') and return;
   
   return \%h;
}


# END GeT ARGS ///////////////////////////////////////////// ///////////////

#*mdw_results_loop_detailed = \&mdw_results_loop;
sub mdw_results_loop_detailed {
   my ($self,$mds) = @_;
   $mds ||= $self->mds_object;

   my @ids = @{$mds->ids};
   my $count = $mds->ids_count;

   my $limit = $self->mdw_per_page_limit;

   $self->feedback("Found $count results.");
   
   if( $count > $limit ){
      $#ids = ($limit - 1);
      debug("results count $count is more then limit $limit, will prune down");          
      $self->feedback("Showing $limit results.");
   }

   my $loop = $self->mdw_records_loop( \@ids );
   return $loop;
}

# returns vars for html template in a hashref
sub mdw_record_params {
   my ($self,$id) = @_;

   my $mds = $self->mds_object;
   
   my $meta={
      id => $id,
   };

   my $hash = $mds->_record_entries_hashref($id);
   
   my $ul = "\t<ul>\n";
   for ( sort keys %$hash ){
      unless( $_=~/_path$/ ){ # maybe have a regex for this
         $ul.="\t\t<li>".$_ .' : '. $hash->{$_}->[0] ."</li>\n";
      }
      $meta->{'meta_'.$_} = $hash->{$_}->[0];
   }
   $ul.="\t</ul>\n";
   $meta->{meta_as_ul_html} = $ul;

   return $meta;
}


sub mdw_records_loop {
   my($self,$ids) = @_; #search object
   
   my $mds = $self->mds_object;

   my @results_loop = ();

   my $i;   
   for my $id ( @{$ids} ){
      my $record_meta = $self->mdw_record_params($id);
      $record_meta->{list_index} = ++$i;
      push @results_loop, $record_meta;
   }
   return \@results_loop;
}




# get a Metadata::DB::Search object, cached
sub mds_object {
   my ($self) = @_;

   

   unless( $self->{_mdsearch_object} ){
      require Metadata::DB::Search;
      my $dbh = $self->param('DBH');
      $dbh or die('missing DBH in param');
      debug('DBH has '. ref $dbh);

      $self->{_mdsearch_object} = Metadata::DB::Search->new({ DBH => $self->param('DBH') })
         or die;
   }
   return $self->{_mdsearch_object};
}


sub mdw_process_search {
   my $self = shift;

   # get search params
   my $search_args = $self->mdw_search_args_submitted
      or return 0;

   #get the search object
   my $mds = $self->mds_object
      or return;

   # feed it
   unless( $mds->search($search_args) ) {
      $self->feedback('Something went wrong with the search.');
      $self->feedback('Please wait and try again, or contact the system administrator.');
      return;
   }

   

   return 1;   
}




1;

__END__

=pod

=head1 NAME

CGI::Application::Plugin::MetadataDB

=head1 SYNOPSIS

   use CGI::Application::Plugin::MetadataDB;
   use CGI::Application::Plugin::Feedback;
   use CGI::Application::Plugin::Session;
   
   $ENV{HTML_TEMPLATE_ROOT} = '';
   
   sub mdw_search : Runmode {
      my $self = shift;
   }

   sub mdw_search_results : Runmode {
      my $self = shift;
   }

   

See Medatata::DB::WUI code for example usage.
   

=head1 DESCRIPTION

Methods to aid building search to use Metadata::DB
You will need to import the following plugins in your cgi app
   CGI::Application::Plugin::Session;
   CGI::Application::Plugin::Feedback;

Metadata::DB::Search makes use of a database.

=head1 CUSTOMIZING

the main things you want to customize are 

=head2 how each record displays

   my $default = q{
   <div>
   <i><TMPL_VAR LIST_INDEX></i> 
   id <TMPL_VAR ID>
      <TMPL_VAR META_AS_UL_HTML>
   </div>
   };


   $o->mdw_result_code($default);


=head2 the main template

=head2 the connection to the database




=head1 METHODS

These methods are meant to aid you in creating runmodes that interact with Metadata::DB

=head2 mds_object()

=head2 mdw_per_page_limit()

=head2 mdw_process_search()

=head2 mdw_record_params()

argument is id number, returns html template params in hashref

=head2 mdw_records_loop()

argument is a list of ids, (not array ref)

returns a loop suitable for html template, uses mdw_record_params()

=head2 mdw_result_code()

perl setget method, returns result code for one object
you can override this

=head2 mdw_results_loop_detailed()

=head2 mdw_search_args_submitted()

=head2 mdw_search_results_tmpl_code()



=head2 mdw_search_tmpl()

This is a setget method, opt arg is a HTML::Template object
returns HTML::Template object
by default we look for ENV HTML_TEMPLATE_ROOT / mdw_search.html
you can provide your own template by passing to the method before run

=head2 mdw_search_results_tmpl()

this is like mdw_search_results_tmpl()
by default looks for mdw_search_results.html
you can pass it another template to use

=head2 mdw_search_results_tmpl_name()

setget method, default is mdw_search_results.html

=head2 mdw_search_tmpl_name()

setget method, default is mdw_search.html




=head1 IF YOU WANT TO CHANGE THE TEMPLATES USED

Presently we require that the search template, generated by Metadata::DB::Search::InterfaceHTML
be present on disk, if you have various of these you may want to define which to use
before you run() your cgiapp

   $wui->mdw_search_tmpl_name('mdw_search.people.html');

And maybe change the output also for each record..

   $wui->mdw_search_results_tmpl_name('mdw_search_results.people.html');

   $wui->run;

Of course you can also provide template objects via mdw_search_results_tmpl() etc.




