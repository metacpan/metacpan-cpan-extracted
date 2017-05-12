package Metadata::DB::Search::InterfaceHTML;
use strict;
use base 'Metadata::DB::Analizer';
use warnings;
use Carp;
use HTML::Entities;
no warnings 'redefine';
use HTML::Template::Default 'get_tmpl';





$Metadata::DB::Search::InterfaceHTML::PREPEND_FIELD_NAME ='search_interface_field_prepend';
$Metadata::DB::Search::InterfaceHTML::PREPEND_VALUE ='md';


*cgi_app_search_form_output = \&search_form_template_output;
*_html_tmpl_code_default    = \&search_form_template_code;
*tmpl                       = \&search_form_template_object;




#  OUTPUT ---------------------------------------

# feed the template and spit out output of object
sub search_form_template_output {
   my ($self) = @_;

   my $tmpl = $self->search_form_template_object;   
   
   my $param = $self->generate_search_form_template_params;   
   $tmpl->param( %{$param} );
   
   my $output = $tmpl->output;
   return $output;
}



# TEMPLATE OBJECT ------------------------------------------

sub search_form_template_object {
   my $self = shift;

   unless( $self->{_sfto} ){
      my $default_code = $self->search_form_template_code;
      $self->{_sfto} = get_tmpl(\$default_code) or die;      
   }
   return $self->{_sfto};
}

sub search_form_field_prepend {
   my($self,$val) = @_;

   $Metadata::DB::Search::InterfaceHTML::PREPEND_VALUE = $val if defined $val;
   return $Metadata::DB::Search::InterfaceHTML::PREPEND_VALUE;
}
   
sub search_form_template_code {
   my $self = shift;
   my $prepend =  $self->search_form_field_prepend;
   
   my $PREPEND_FIELD_NAME = $Metadata::DB::Search::InterfaceHTML::PREPEND_FIELD_NAME;
   

   my $tmpl_code  = qq|
<form name="$prepend\_search_form" 
   action="<TMPL_VAR NAME='SEARCH_INTERFACE_FORM_ACTION' DEFAULT='?rm=mdw_search_results'>"
   method="post">

<!--  THIS VALUE MUST MATCH THE FIELDS -->
<input type="hidden" name="$PREPEND_FIELD_NAME" value='$prepend'>
 
<TMPL_LOOP SEARCH_INTERFACE_LOOP>

<!--  // start attribute // -->
<div>
 <p><b><TMPL_VAR ATTRIBUTE_NAME></b> 
 <TMPL_IF INPUT_TYPE_SELECT> 
  <select name="$prepend\_<TMPL_VAR ATTRIBUTE_NAME>">
  <TMPL_LOOP SELECT_OPTIONS>
   <option value="<TMPL_VAR OPTION_VALUE>"><TMPL_VAR OPTION_NAME></option>
  </TMPL_LOOP>
  </select>
  
    <TMPL_IF ATTRIBUTE_TYPE_IS_NUMBER>
      <select name="$prepend\_<TMPL_VAR ATTRIBUTE_NAME>_match_type">
         <option value="exact" selected>exact</option>
         <option value="morethan">more than</option>
         <option value="lessthan">less than</option>
      </select>
    <TMPL_ELSE>
      <input type="hidden" name="$prepend\_<TMPL_VAR ATTRIBUTE_NAME>_match_type" value="exact">
    </TMPL_IF>
 <TMPL_ELSE>
   <input type="text" name="$prepend\_<TMPL_VAR ATTRIBUTE_NAME>">

   <select name="$prepend\_<TMPL_VAR ATTRIBUTE_NAME>_match_type">
      <option value="like" selected>like</option>
      <option value="exact">exact</option>
      <TMPL_IF ATTRIBUTE_TYPE_IS_NUMBER>      
      <option value="morethan">more than</option>
      <option value="lessthan">less than</option>
      </TMPL_IF>
   </select>
   <small><TMPL_VAR TOTAL_COUNT></small>   
 </TMPL_IF>

 <input type="hidden" name="$prepend\_attribute" value="<TMPL_VAR ATTRIBUTE_NAME>">
 </p>
</div>

</TMPL_LOOP>


<p><input type="submit" value="search"></p>
<input type="hidden" name="rm" value="<TMPL_VAR NAME='SEARCH_INTERFACE_NEXT_RUNMODE' DEFAULT='mdw_search_results'>">
<TMPL_IF SEARCH_INTERFACE_DATE><p>Updated <TMPL_VAR SEARCH_INTERFACE_DATE></p></TMPL_IF>
</form>|;


   return $tmpl_code;
}






# LOOPS & VARS --------------------------------------------

sub generate_search_form_template_params  {
   my $self = shift;

   require Time::Format;
   my $date = Time::Format::time_format('yy/mm/dd hh:mm',time());
   
   my %param = ( 
      # $prepend _FORM_ACTION => '',
      # $prepend _NEXT_RUNMODE => '',
      SEARCH_INTERFACE_LOOP => $self->generate_search_interface_loop,
      SEARCH_INTERFACE_DATE => $date,
   );

   return \%param;   
}




# this one is auto as far as the ammounts are concerned, the limits
sub generate_search_interface_loop {
   my $self = shift;      
   my @loop = ();   
   for my $attribute_name ( @{$self->search_attributes_selected} ){   
   
      my $hashref = $self->generate_search_attribute_params($attribute_name);      
      push @loop, $hashref;   
   }
   return \@loop;
}






# make hashref for ONE search attribute
# TODO, add that if we have only nums, we can select 'more than' etc
sub generate_search_attribute_params {
   my($self,$att,$limit) = @_;
   
   # see also Metadata::DB::Analizer for these methods

   if( $limit ){
      $self->attribute_option_list_limit( $att => $limit ); 
   }
   
   $self->_attributes_exists($att)
      or warn("attribute $att does NOT exist.") # die?
      and return;


   # approximately now many diff vals are there in db for this attr
   my $approx_count             = $self->attribute_all_unique_values_count($att);
   my $attribute_type_is_number = $self->attribute_type_is_number($att);
   

   my $param_hash = {};
   
   # is this a drop down ????
   if( my $opts = $self->attribute_option_list($att) ){ 
   
         # first should be blank
         my @opts_loop = ({ option_name => '----', option_value => '' });
                  

         map { 
            push @opts_loop, 
            { option_name => $_, option_value => encode_entities($_) }
         } @$opts;
      
         $param_hash = {         
            attribute_name => $att,
            #attribute_options => $opts,    
            select_options => \@opts_loop,
            input_type => 'select',
            input_type_select => 1,
            input_type_text => 0,
            total_count => $approx_count,
            attribute_type_is_number => $attribute_type_is_number,
         };
         
   }


   
   else {  #else there were too many results over the limit, so we show as text box
      $param_hash =  {
         attribute_name => $att,
         input_type => 'text',
         input_type_select => 0,
         input_type_text => 1,
         total_count => $approx_count,
         attribute_type_is_number => $attribute_type_is_number,         
      };      
   }

   return $param_hash;
}




1;

__END__

=pod

=head1 NAME

Metadata::DB::Search::InterfaceHTML - generate html search form

=head1 DESCRIPTION

This generates html output suitable for a web search interface to the metadata
this is not meant to specifially mean the metadata is about files, people, or anything
this JUST provides an interface to the stuff
this is NOT meant to be used live- this is meant to be used as an update tool only.

This code is separate from Metadata::DB::Analizer, because that code could be used to 
gen interface for tk, etc, any gui.
This module IS specifically for a HTML gui.

This module usea Metadata::DB::Analizer as base.

All relevant fields are prepended with 'search_interface' by default, to change

   $o->search_form_field_prepend('new_prepend_string');


=head1 METHODS





=head2 search_form_template_output()

output is html


=head2 search_form_template_code()

returns the HTML::Template code that will be used
to generate the static html output returns by search_form_template_output()

you can override this in various ways
see HTML::Template::Default


=head2 search_form_template_object()

returns HTML::Template object.


=head2 generate_search_form_template_params()

returns hash ref for params to load into template object





=head1 GENERATE A SEARCH INTERFACE

Generating the search form interface should be done offline.




You dont *have*to use these. 
These ouptut for HTML::Template loops, params, etc.
You generate a search interface and save it to a static file.




=head2 generate_search_attribute_params()

argument is attribute name, and optionally  a limit number
if the attribute does not exist in database, warns and returns undef

returns hash ref suitable for HTML::Template

if your tmpl is:
   
   <TMPL_LOOP SEARCH_OPTS_LOOP>
   
   <div>
    <b><TMPL_VAR ATTRIBUTE_NAME></b>
    
    <TMPL_IF INPUT_TYPE_SELECT>
    
    
         <select name="<TMPL_VAR ATTRIBUTE_NAME>">
          <TMPL_LOOP SELECT_OPTIONS>
           <option value="<TMPL_VAR OPTION_VALUE>"><TMPL_VAR OPTION_NAME></option>
          </TMPL_LOOP>
         </select>
         
    
    <TMPL_ELSE>
    
         <input type="text" name="<TMPL_VAR ATTRIBUTE_NAME>">
    
    </TMPL_IF> 
   </div>
   
   </TMPL_LOOP>
   <TMPL_VAR SEARCH_INTERFACE_HIDDEN_VARS>

The following means that if there are more then 40 name possible values, show a text field,
if less, show a drop down.
For cars, if there are less the 20 choices (possible metadata values for they key 'car'), show
dropdown, else, show text field.
(The default for all of these is 15.)
   

   my $i = Metadata::DB::Search::InterfaceHTML({ DBH => $dbh });
   
1) get the params for the attributes you want
   
   my $name_opt = $i->generate_search_attribute_params('name',40);   
   my $car_opt =  $i->generate_search_attribute_parmas('car',20);

2) build the main search options loop
   
   my @search_opts_loop = [ $name_opt, $age_opt ];

3) feed it to the template
   
   $i->search_form_template_object->param( SEARCH_OPTS_LOOP => \@search_opts_loop ):

4) now get the output, this is the interface you should show the user.
 

   my $output = $i->search_form_template_object->output;
   
   open(FILE,'>','/home/myself/public_html/search_meta.html');
   print FILE $output;
   close FILE;  



=head2 generate_search_interface_loop()

argument is dbh
returns array ref 
each element is a hash ref as returned by
   
   generate_search_attribute_params($attribute_name, $limit);
   
Usage:

   $tmpl->param( SEARCH_INTERFACE_LOOP => $self->generate_search_interface_loop($dbh) );

=head1 HOW TO CUSTOMIZE THE INTERFACE GENERATED

Please see Metadata::DB::Search::InterfaceHTML


If you alter limits for atts or change the atts selected, when you call
search_template_form_output() or search_template_form_code(), they will reflect the changes

   my @attribute_names = sort grep { !/path/ } @{ $self->get_search_attributes }; 
   
   $self->search_attributes_selected_clear;
   $self->search_attributes_selected_add( @attribute_names  );

   # change limit to 1000 for all atts matching 'client'

   for my $att ( grep { /client/ } @attribute_names ){
      $self->search_attribute_option_list_limit( $att, 1000 );
   }   

   # output the template code, or the template output

   $self->search_form_template_code;
   $self->search_form_template_output;

   


