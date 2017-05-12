package HTML::TurboForm;

use strict;
use warnings;
use UNIVERSAL::require;
use YAML::Syck;
our $VERSION='0.75';
use Try::Tiny;
use File::Copy;

sub new{
  my ($class, $r,$prefix)=@_;
  my $self = {};
  $r={} if (!$r);  
  $self->{request}= $r;
  $self->{submitted} = 0;
  $self->{after_upload}='';
  $self->{submit_value} = '';
  $self->{count}=0;
  $self->{submit_id} = -1;
  $self->{addition_modules}='';
  $self->{prefix}='';
  $self->{row_wrapper}='';
  $self->{prefix}=$prefix if ($prefix);
  
  
  bless( $self, $class );
  $self->add_element({type => 'Hidden', name => 'forminit1122013', value => '45B68E73A'});
  return $self;
}

sub set_row_wrapper{
  my ($self, $wrapper) = @_;
   $self->{row_wrapper}=$wrapper;
}

sub add_modules{
  my ($self, $mods) = @_;
   $self->{addition_modules}=$mods;
}

sub add_constraint{
  my ($self, $params) = @_;
  my $name= $self->{prefix}.$params->{name};
  $params->{request}=$self->{request};
  my $class_name = "HTML::TurboForm::Constraint::" . $params->{ type };
  $class_name->require() or die "Constraint Class '" . $class_name . "' does not exist: $@";
  push(@ { $self->{constraints} }, $class_name->new($params));
}

sub add_uploads{
  my ($self, $uploads) = @_;
  $self->{uploads} = $uploads;
}

sub build_form{
    my ($self, $data, $resultsource, $options)=@_;
    
    my @columns=$resultsource->columns;
        
    foreach (@columns){
        my $forbidden=0;
        my $info=$resultsource->column_info($_);
        
        my $label=$_;        
        $label=$info->{label} if $info->{label};        
        my $type='Text';
        $type=$info->{fieldtype} if $info->{fieldtype};        
        my $args={ type=>$type, name=> $_, label=> $label };        
        if ($data->{$_}) {
           while(my($key, $value) = each(%{$data->{$_}})){
               $args->{$key}=$value if ($key ne 'name');
           }
        }        
        my $k=$_;
        if ($options->{definedonly}){
        if ($options->{definedonly} eq '1'){
        } else{
           my $number =    keys %$info;    
           $forbidden=1  if ($number==0);
        }
        } else{
          my $number =    keys %$info;    
           $forbidden=1  if ($number==0);          
        }
        
        if (($data->{forbidden})&&($forbidden==0)){
        #if ($data->{forbidden}){
            foreach (@{$data->{forbidden}}){ $forbidden=1 if ($_ eq $k); }
        }
        $self->add_element($args) if $forbidden == 0;      
    }
}

sub load{
    my ($self,$fn)=@_;
    my $data = LoadFile($fn);

    foreach my $item( @{ $data->{elements} }) {
        $self->add_element($item);
    }
    foreach my $item( @{ $data->{constraints} }) {
        if ($item->{params}->{compvalue}){
           my $tmp=$item->{params}->{compvalue};
           $item->{params}->{comp}=$self->get_value($tmp);
        }
        $self->add_constraint($item);
    }
}

sub unignore_all{
  my ($self ) = @_;
  my $k;
  my $v;
  foreach $k(keys %{ $self->{element_index} } ){
    $self->{element_index}->{$k}->{ignore}='false';
  }
}

sub ignore_all{
  my ($self ) = @_;

  my $k;
  my $v;
  foreach $k(keys %{ $self->{element_index} } ){
    $self->{element_index}->{$k}->{ignore}='true';
  }
}

sub remove_all{
  my ($self ) = @_;

  $self->{element_index}={};
  $self->{element}=();
}

sub ignore_element{
  my ($self, $name ) = @_;
  $name=$self->{prefix}.$name;
  $self->{element_index}->{$name}->{ignore}='true';
}

sub unignore_element{
  my ($self, $name ) = @_;
  $name=$self->{prefix}.$name;
  $self->{element_index}->{$name}->{ignore}='false';
}

sub add_element{
  my( $self, $params ) = @_;
  my $class='';
  my $options='';
  if (!$params->{name}){
    $params->{name}='html'.$self->{count};
    $self->{count}++;
  }
  $params->{request}=$self->{request};
  my $namew= $params->{name};
  my $name= $self->{prefix}.$params->{name};
  $params->{name}=$name;
  #print $name."\n";

  my $class_name = "HTML::TurboForm::Element::" . $params->{ type };
  $class_name->require() or die "Class '" . $class_name . "' does not exist: $@";
  
  if (!$params->{wrapper}){  
      $params->{wrapper}=$self->{row_wrapper} if ($self->{row_wrapper} ne '');
  }
  
  my $element= $class_name->new($params,$self->{uploads}->{$name.'_upload'});

  my $new_len =  push(@ { $self->{element} },  $element);

  $self->{element_index}->{$name}->{index}=$new_len-1;
  $self->{element_index}->{$name}->{frozen}=0;
  $self->{element_index}->{$name}->{ignore}='false';
  $self->{element_index}->{$name}->{error_message}='';
  
  if ($params->{type} eq 'Imageupload') {    
    if ( exists $self->{uploads}->{$name."_upload"} ){   
        $self->{after_upload}=$name;        
        $element->do_img();   
    }
  }     

  if ($params->{type} eq 'Submit') {
    if (( exists $self->{request}->{$name.".x"} )or(exists $self->{request}->{$name})){
      $self->{submitted}=1 ;
      $self->{submit_value} = $namew;
    }
  }

  if ($params->{submit}){
    if ( $self->{request}->{$name} ){
      $self->{submitted}=1 ;
      $self->{submit_value} = $namew;
    }
  }

  if (($params->{type} eq 'Image')||($params->{type} eq 'Upload')) {
    if ( exists $self->{request}->{$name.'_submit' } ){
      $self->{submitted}=1 ;
      $self->{submit_value} = $namew.'_uploaded';
    }
  }

  if ($params->{type} eq 'Imagegalerie') {
    my $f='';
    $f = $self->find_action($name.'_delete_');
    $self->{submit_value} = $namew.'_delete' if ($f ne '');
    if ($f eq ''){
      $f = $self->find_action($name.'_next_');
      $self->{submit_value} = $namew.'_next' if ($f ne '');
    }
    if ($f eq ''){
      $f = $self->find_action($name.'_prev_');
      $self->{submit_value} = $namew.'_prev' if ($f ne '');
    }
    if ($f ne ''){
      $self->{submitted}=1 ;
      $self->{submit_id} = $f;
    }
  }

  if ($params->{type} eq 'Imageslider') {
    my $f='';
    $f = $self->find_action($name.'_delete_');
    if ($f ne ''){
      $self->{submitted}=1 ;
      $self->{submit_value} = $name.'_delete';
      $self->{submit_id} = $f;
    }
  }

  if ($params->{type} eq 'Captcha') {      
      my $tlabel=$params->{label1};
      my $tlabel2=$params->{label2};
      my $tname=$name."_input";
      my $tname2=$name."_input2";
      $self->add_element({ type => 'Text',  name => $tname, label=> $tlabel } );
      $self->add_element({ type => 'Text',  name => $tname2, class=>"form_input2", label=> $tlabel2 } );
      my $c_val = $self->get_value($tname2);
      
      #use Data::Dumper;
      #print STDERR Dumper($params);
      $self->add_constraint({ type=> 'Equation', operator=>'eq', name=>$tname, comp=>$c_val, text=>$params->{message} });
      #$self->add_constraint({ type=> 'Equation', operator=>'eq', name=>$tname2, comp=>'', text=>$params->{message} });      
      $self->add_constraint({ type=> 'Mintime', name=>$tname, keyname=> $params->{keyname}."2", keyphrase=>$params->{keyphrase} ,session=> $params->{session} , text=>'Error, please wait 5 Seconds and resubmit the form.' });                      
  }
}

sub find_action{
  my ($self, $action_part)=@_;

  foreach (%{$self->{request}}){
     if (length($_)>length($action_part)){
        if (index($_,$action_part) > -1){
            my $tmp = substr($_,length($action_part));
            return $tmp if (length($tmp)>0);
        }
     }
  }
  return '';
}

sub do{
  my ($self, $name, $fn,@args)=@_;
  $self->{element}[$self->{element_index}->{$self->{prefix}.$name}->{index}]->$fn(@args);
}

sub get_javascript{
  my ($self, $url)=@_;
  my $js='';
  my $result='';
  my $usejquery = 0;
  foreach my $item(@{$self->{element}}) {
    if ($item->{js}){
      $usejquery = 1;
      $js.=$item->{js}."\n";
    }
  }
  if ($usejquery==1){
      $js='<script>'."\n".'$(document).ready(function(){ '.$js.' });'."\n".'</script>';
  }
  return $js;
}

sub get_jquery_modules{
  my ($self, $url)=@_;
  my @modules;
  my @stylefiles;
  my $js='';
  my $result='';
  my $css_r = '';
  my $usejquery = 0;
  foreach my $item(@{$self->{element}}) {
    if ($item->{modules}){
       foreach (@{ $item->{modules} }){
          my $f = 0; foreach my $t(@modules){ if ($t eq $_) { $f = 1; }}
          push(@modules, $_) if ($f==0) ;
       }
    }
    if ($item->{stylefiles}){
       foreach (@{ $item->{stylefiles} }){
          my $f = 0; foreach my $t(@stylefiles){ if ($t eq $_) { $f = 1; }}
          push(@stylefiles, $_) if ($f==0) ;
       }
    }
    if ($item->{js}){
      $usejquery = 1;
      $js.=$item->{js}."\n";
    }
  }

  if ($usejquery==1){
      $js='<script>'."\n".'$(document).ready(function(){ '.$js.' });'."\n".'</script>';
  }

  foreach (@modules){
    $result .='<script type="text/javascript" src="/'.$url.'/'.$_.'.js" ></script>'."\n";
  }
  foreach (@stylefiles){
    $css_r.='<link href="/'.$url.'/'.$_.'.css" rel="stylesheet" type="text/css" />'."\n";
  }

  return $css_r.$result.$js.$self->{addition_modules};
}

sub set_table_class{
  my ($self, $classname)=@_;
  $self->{table_class}=$classname;
}

sub set_table_attributes{
  my ($self, $attributes)=@_;

  my $attr='';
  while ( my ($key, $value) = each(%$attributes) ) {
      $attr.=$key.'="'.$value.'" ';
  }
  $self->{table_attibutes}=$attr;
}

sub render{
  my ($self, $view, $action)=@_;

  my $table=-1;
  my $count=0;
  $view='' if (!$view);
  $action=' action="'.$action.'" ' if ($action);
  $action='' if (!$action);
  my $table_class='class="form_table"';
  $table_class= 'class="'.$self->{table_class}.'"' if ($self->{table_class});
  $table_class=$self->{table_attibutes} if ($self->{table_attibutes});

    my $result='<form method=post '.$action.'enctype="multipart/form-data">';
    
    if ($view eq 'table'){ $result.='<table '.$table_class.'>'; }

    foreach my $item(@{$self->{element}}) {
    my $name = $item->name;

    if ($self->{element_index}->{$name}->{ignore} ne 'true'){
        $item->{table}=-1;
       
        if ($view eq 'flat'){
            if ($item->type ne 'Submit'){
                my $label = $item->get_label();
                my $value = $item->get_value();
                $result.='<span class="form_label">'.$label."</span>: ".$value."<br />";
            }
        } else {
            if ($item->type eq "TableEnd") {
                $item->{table}=-1;
                $table=-1;
            }
            if ($item->type eq "Table") {
                $item->{table}=$item->columns;
                $item->{colcount}=-1;
                $count=-1;
                $table=$item->columns;
            }
            if ($table>-1) {
                $count++;
                $count=1 if ($count>$table);
                $item->{colcount}=$count;
                $item->{table}=$table;
            }
            $result .= $item->render($self->{element_index}->{$name}, $view);
         }
      } else {
     $result.="<input type='hidden' name='$name' value='".$item->get_value()."'>";
  }
}

  if ($view eq 'table'){ $result.='</table>'; }
  #if ($view eq 'clean'){ }
  return $result.'</form>';
}


sub uploaded{
  my ($self) = @_;
  
  return $self->{after_upload} if ($self->{after_upload} ne '');    
  return '';
}

sub submit{
  my ($self) = @_;
  my $result='';
  if ($self->{submit_value} ne '') {
    $result=$self->{submit_value};
  }
  return $result;
}

sub submitted{
  my ($self) = @_;
  my $result='';
  my $set=0;
  if ($self->{submit_value} ne '') {
    $result=$self->{submit_value};
    #$result=substr($result,length($self->{prefix})) if ($self->{prefix} ne'');
    foreach my $item(@{$self->{constraints}}) {
      my $name=$item->{name};
      if ($item->check() == 0){
        $self->{element_index}->{$name}->{error_message}= $item->message();
        $set=1;
      }
    }
    $result='' if ($set==1);
  }
  return $result;
}

sub get_single_dbix{
  my ($self,$name)=@_;
  my $result = $self->{element}[$self->{element_index}->{$self->{prefix}.$name}->{index}]->get_dbix();
  return $result;
}

sub get_dbix{
  my ($self)=@_;
  my $result;

  foreach (@{$self->{element}}) {
    my $tmp = $_->get_dbix();
    if ($tmp){
      while ( my ($key, $value) = each(%$tmp) ) {
        $result->{$key} = $value;
      }
    }
  }
  return $result;
}

sub add_options{
  my ($self,$name,$options)=@_;
  $self->{prefix}='' if (!$self->{prefix});
  if ($name && $name ne ''){
     if ($self->{element_index}->{$self->{prefix}.$name }){      
        $self->{element}[$self->{element_index}->{$self->{prefix}.$name}->{index}]->add_options($options);
     }
  }
}

sub reset_options{
  my ($self,$name,$options,$label,$id)=@_;
  
  $self->{prefix}='' if (!$self->{prefix});
  if ($name && $name ne ''){
     if ($self->{element_index}->{$self->{prefix}.$name }){      
        my $element=$self->{element}[ $self->{element_index}->{ $self->{prefix}.$name }->{index}
        ];      
      $element->reset_options($options,$label,$id) if ($element && $options && $label && $id);
      }
  }  
}

sub freeze{
  my ($self, $name)=@_;
  $self->{element_index}->{$self->{prefix}.$name}->{frozen}=1;
  $self->{element}[$self->{element_index}->{$self->{prefix}.$name}->{index}]->freeze();
}

sub get_r{
  my ($self, $name)=@_;
  $self->{element}[$self->{element_index}->{$self->{prefix}.$name}->{index}]->pure(1) if (!$self->{element}[$self->{element_index}->{$self->{prefix}.$name}->{index}]->pure);
  return $self->{element}[$self->{element_index}->{$self->{prefix}.$name}->{index}]->render();
}
sub get_e{
  my ($self, $name)=@_;
  
  return '' if (!$self->{element_index}->{$self->{prefix}.$name}->{error_message});
  return $self->{element_index}->{$self->{prefix}.$name}->{error_message};
}

sub get_errors{
  my ($self)=@_;
  my $k;
  my $result='';
  foreach $k(keys %{ $self->{element_index} } ){
    $result.=$self->{element_index}->{$k}->{error_message}.'<br />' if ( $self->{element_index}->{$k}->{error_message});
  }
  return $result;
}

sub freeze_all{
  my ($self)=@_;
  my $k;
  my $v;
  foreach $k(keys %{ $self->{element_index} } ){
    $self->{element_index}->{$k}->{frozen}=1;
  }
}

sub unfreeze{
  my ($self, $name)=@_;
  $self->{element_index}->{$self->{prefix}.$name}->{frozen}=0;
}

sub get_value{
  my ($self, $name)=@_;
  my $result='';
  
  my $id='';
   try{
       $id=$self->{element_index}->{$self->{prefix}.$name}->{index};
   };   
   $result=$self->{element}[$id]->get_value() if ($id);
   
  return $result;
}

sub populate{
  my ($self, $data, $anyway)=@_;
  
  $self->{submit_value}='' unless ($self->{submit_value});
  
  if (($self->{submit_value} eq '') or ($anyway ne '')) {
    if (ref($data) eq 'HASH') {
      while (my ($key, $value) = each %{ $data }){
             $self->{request}->{$self->{prefix}.$key}=$value;
      }
    } else {
      my @columns= $data->result_source->columns;

      foreach my $item(keys %{$self->{element_index}}) {
        $item=substr($item,length($self->{prefix})) if ($self->{prefix} ne'');
        if ( grep { $item eq $_ } @columns ) {
           if (!$self->{request}->{$self->{prefix}.$item}) {
            $self->{request}->{$self->{prefix}.$item}=$data->get_column($item);
           }
        }
      }
    }
  }
}

sub serial_populate{
  my ($self, $data)=@_;
  my $result = {};
  my @arr_data = split('&',$data);
  foreach (@arr_data) {
     my @tmp = split('=',$_);
     $self->{request}->{$self->{prefix}.$tmp[0]} = $tmp[1] if ($tmp[1]);
  }
}

sub map_value{
  my ($self, @columns)=@_;
  my $result;
  foreach my $item(keys %{$self->{element_index}}) {
    $item=substr($item,length($self->{prefix})) if ($self->{prefix} ne'');
    my $type=$self->{element}[$self->{element_index}->{$self->{prefix}.$item}->{index}]->type;
    if (($type ne 'Upload')&&($type ne 'Image')){
      if ( grep { $item eq $_ } @columns ) {    
          $result->{$item}=$self->get_value($item);
      }
    }
  }
 return $result;
}

sub get_values{
  my ($self)=@_;
  my $result;

  foreach my $item(keys %{$self->{element_index}}) {
    $item=substr($item,length($self->{prefix})) if ($self->{prefix} ne'');
    $result->{$item}=$self->get_value($item);
  }
 return $result;
}


1;

__END__

=head1 HTML::TurboForm

HTML::TurboForm - fast and compact HTML Form Class

=head1 SYNOPSIS

to start with, two simple examples of how to use turboform. I am still working on both the classes and the docs so please be patient.

=head2 Usage variant 1 : via objects and methods

 my $options;
    $options->{ 'label1' }='1';
    $options->{ 'label2' }='2';
    $options->{ 'label3' }='3';
    $form->add_element({ type => 'Html', text =>'<center>'  });
    $form->add_element({ type => 'Text',     name => 'texttest',     label => 'element1' } );
    $form->add_element({ type => 'Text',     name => 'texttest2',     label => 'vergleichselement' } );
    $form->add_element({ type => 'Textarea', name => 'textareatest', label => 'Areahalt:' } );
    $form->add_element({ type => 'Submit',   name => 'freeze',       label => ' ',            value=>'einfrieren' } );
    $form->add_element({ type => 'Submit',   name => 'unfreeze',     label => ' ',            value=>'normal' } );
    $form->add_element({ type => 'Checkbox', name => 'boxtest',      label => 'auswählen',   options =>  $options, params =>{ 'listmode'=>'' } } );
    $form->add_element({ type => 'Html', text =>'<hr>'  });
    $form->add_element({ type => 'Select',   name => 'selecttest',   label => 'selectieren', options =>  $options } );
    $form->add_element({ type => 'Select',   name => 'selecttest2',  label => 'selectieren', options => $options,  attributes => { 'multiple'=>'' , 'size'=>'3' } } );
    $form->add_element({ type => 'Text',     name => 'mailtest',    label => 'E-Mail' } );
    $form->add_element({ type => 'Radio',    name => 'tadiotest',    label => 'radioteile', options => $options, params =>{ 'listmode', 'norow'} } );
    $form->add_element({ type => 'Date',     name => 'datetest',    label => 'Datum', params=>{ startyear=> '2000' , endyear => '2020' } } );
    $form->add_element({ type => 'Image',     name => 'imagetest',    label => 'Bild', width=>'400', height=>'300',
                       thumbnail => { width => '60', height=>'80' },
                       savedir=>'/home/whocares/catalyst/formproject/root/static/images/temp',
                       loadurl=>'/static/images/temp' } );
    $form->add_constraint({ type=> 'Equation', name=> 'texttest', text=> 'kein Vergleich', params=>{ operator => 'eq', comp=>$form->get_value('texttest2') } });
    $form->add_constraint({ type=> 'Required', name=> 'boxtest', text=> 'du musst schon was auswählen' });
    $form->add_constraint({ type=> 'Date',     name=> 'datetest', text=> 'das ist doch kein datum' });
    $form->add_constraint({ type=> 'Email',    name=> 'mailtest', text=> 'ungültige Mailadresse' });
    $form->add_element({ type => 'Html', text =>'</center>'  });
    $form->freeze_all() if ($form->submitted() eq 'freeze');
    $c->stash->{form} = $form->render();
    $c->stash->{template}='formtest/formtest.tt';
    if ($form->submitted() eq 'freeze') {
       my @cols= ('txt1','date','txt2','checkboxtest');
       my $data=$form->map_value(@cols);
    }



=head2 Usage Variant 2 : via yml file:

 my $form= new HTML::TurboForm($c->req->params);
 $form->load('test.yml');
 my $text=$form->render();

 if ($form->submitted eq 'freeze') {}

 Sample yml-file:

---
languages:
  - de
elements:
  - type: Html
    text: <center>

  - type: Text
    name: messageausyml
    label: ausyml

  - type: Text
    name: txt1
    label: sampleinput

  - type: Text
    name: txt2
    label: whatever to compare

  - type: Checkbox
    label: chooser
    name: checkboxtest
    options:
        label1: 1
        label2: 2

  - type: Html
    text: <div class="form_row"><hr></div>

  - type: Radio
    label: radiochooser
    options:
        radio1: 1
        radio2: 2

  - type: Submit
    name: freeze
    value: einfrieren

  - type: Submit
    name: defreeze
    value: normal

  - type: Date
    label: Datum
    name: date
    params:
      startyear: 2000
      endyear: 2010

  - type: Html
    text: </center>

constraints:

  - type: Required
    name: messageausyml
    text: <font size=2><b>mandatory field</b></font>

  - type: Date
    name: date
    text: <font size=2><b>must be a correct date</b></font>

  - type: Equation
    name: txt1
    text: <font size=2><b>must be higher</b></font>
    params:
      operator: <
      compvalue: txt2


=head1 DESCRIPTION

HTML::TurboForm was designed as a small, fast and compact Form Class to use with catalyst in order to easily create any needed Form.
I know there a quite a lot of classes out there which do the same but i wasn't quite content with what i found.
They were either too slow or complicated or both.

=head1 METHODS

=head2 new

Arguments: $request

Creates new Form Object, needs Request Arguments to fill out Form Elements. To do so it's very important that the form elements
have the same names as the request parameters.

=head2 add_constraint

Arguments: $params

Adds a new Contraint to the Form. Constraints can be date, required or any other constraint class object.
Only if they successfully match the given constraint rule the form will return valid.

=head2 load

Arguments: $fn

Loads a form from a given YML File.

=head2 unignore_element

Arguments: $name

will unIgnore an element so it will be rendered normally

=head2 ignore_element

Arguments: $name

will Ignore an element so it won't be rendered and in effect invisible, it's value will be given to the form as hidden value

=head2 add_element

Arguments: $params

Will add a new Form Element, for example a new text element or select box or whatever.

=head2 render

Arguments: none

Renders the form. Will retrun the HTML Code for the form including error messages.

=head2 submitted

Arguments: none

Will be true if the form is correctly filled out by user, otherwise it returns false and shows the corresponding error message(s).

=head2 add_options

Arguments: $name, $option

Adds option to HTML elements that needs them, for example select boxes.

=head2 freeze

Arguments: $name

Will disable the HTML Element identified by name for viewing purposes only.

=head2 freeze_all

Arguments: none

Freezes the whole form.

=head2 unfreeze

Arguments: $name

Unfreezes certain Element.

=head2 get_value

Arguments: $name

Returns Value of Eelement by name

=head2 populate

Arguments: $data

fills form with values form hash.

=head2 map_value

Arguments: @columns

Expects an array with column names. This method is used to map the request and form elements to the columns of a database table.

=head1 AUTHOR

Thorsten Drobnik, camelcase@hotmail.com

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
