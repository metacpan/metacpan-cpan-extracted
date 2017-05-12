package HTML::TurboForm::Element::Fileupload;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
use File::Copy;
use File::Path;
__PACKAGE__->mk_accessors( qw/ prev upload maxsize keeporiginal savedir loadurl filedir caption overwrite errormessage / );

sub new{
    my ($class, $request, $upload) = @_;
    my $self = $class->SUPER::new( $request );    

    my $pic='';
    $pic = $self->request->{$self->name} if ($self->request->{$self->name} );
    if (!$self->filedir){
        $self->filedir('');
    } else {        
        mkpath($self->savedir.'/'.$self->filedir);        
        $self->filedir($self->filedir.'/') if ($self->filedir!~/(.*)\/$/);
    }    
    if ($self->request->{ $self->name.'_upload' }) {
        if ((-e $self->savedir.'/'.$self->filedir.$self->upload->basename)&&(!$self->overwrite)){
            $pic='ERROR';
        } else {            
            move($self->upload->tempname,$self->savedir.'/'.$self->filedir.$self->upload->basename);
            $pic = $self->savedir.'/'.$self->upload->basename;
        }
    }
    $self->{pic}=$pic;

    return $self;
}

sub get_value{
    my ($self) = @_;
    my $result='';
     my $request=$self->request;
    $result=$self->{pic} if ($self->{pic});
   if (!$self->{pic}){
         $result=$request->{$self->name} if ($request->{$self->name});
    }
    return $result;
}

sub render{
    my ($self, $options, $view)=@_;
    if ($view) { $self->{view}=$view; }
    my $request=$self->request;
    my $result='';
    my $disabled='';
    my $class='form_upload_select';
    $self->label('&nbsp;') if ($self->label eq '');
    $class=$self->{class}  if exists($self->{class});
    my $name=' name="'.$self->name.'_upload" ';
    my $checked='';

    $disabled=' disabled ' if ($options->{frozen} == 1);
    if ($options->{frozen} != 1 ){
        $result.= $self->errormessage if ($self->{sizeerror} && $self->errormessage);
        $result.='<input type="file" class="'.$class.'" '.$self->get_attr().$disabled.$name.'>';        
    }
    
    if ($self->get_value() ne ''){
         my @parts=split('/',$self->get_value());
         my $f= pop(@parts);
        $result.='<input type="hidden" name="'.$self->name.'" value="'.$self->get_value().'">File: '.$f;
    }
  return $self->vor($options).$result.$self->nach;
}

1;


__END__

=head1 HTML::TurboForm::Element::Fileuploa

Representation class for HTMl SelectBox element.

=head1 DESCRIPTION

Straight forward so no need for much documentation.
See HTML::TurboForm doku for mopre details.

=head1 METHODS

=head2 render

Arguments: $options

returns HTML Code for select element.

=head1 AUTHOR

Thorsten Domsch, tdomsch@gmx.de

=cut
