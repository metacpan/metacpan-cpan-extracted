package HTML::TurboForm::Element::Imageupload;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
use Imager;
use File::Finder;

__PACKAGE__->mk_accessors( qw/ prev upload keeporiginal scaletype filename width height savedir thumbnail loadurl caption maxsize errormessage / );

sub new{
    my ($class, $request, $upload) = @_;
    my $self = $class->SUPER::new( $request );
    $self->upload( $upload );
    $self->{pic}='';
    $self->do_img(); 
    return $self;
}

sub ren{
    my ($self, $newfilename)=@_;
    my $file='';
    my $request=$self->request;
    $file=$self->{pic};
    if (!$self->{pic}){
         $file=$request->{$self->name} if ($request->{$self->name});
    }    
    rename($self->savedir.'/med_'.$file, $self->savedir.'/'.$newfilename.'.jpg');    
}

sub ren_thumb{
    my ($self, $newfilename)=@_;
    my $file='';
    my $request=$self->request;
    $file=$self->{pic};
    if (!$self->{pic}){
         $file=$request->{$self->name} if ($request->{$self->name});
    }       
    rename($self->thumbnail->{savedir}.'/thumb_'.$file, $self->thumbnail->{savedir}.'/'.$newfilename.'.jpg');    
}


sub do_img{
    my ($self)=@_;
    my $request=$self->request;
    my $pic='';
    $pic = $self->request->{$self->name} if ($self->request->{$self->name} );
   if ($request->{ $self->name.'_upload' }) {

        if( $self->upload->type !~ /^image\/(jpeg|jpg|gif|png|pjpeg)$/ ) {
                #$c->stash->{ 'error' } = 'Filetype not supported!';
        } else {
            # read image
            my $image = Imager->new;
            $self->{sizeerror}=0;
            if ($self->maxsize) {
                if (($self->upload->size/1024) > $self->maxsize){
                    $self->{sizeerror}=1;
                }
            }
            if (!$self->{sizeerror}){
                if( $image->read( file => $self->upload->tempname ) ) {
                    # remove alpha channels because jpg does not support it  # and its not used anyways
                    $image = $image->convert( preset => 'noalpha' );
                    #attribute keeporignal isparams local path for storing orig sized images

                    my $tmp = File::Temp->new( DIR => $self->savedir.'', UNLINK => 0, SUFFIX => '.jpg' );
                    $pic = substr( $tmp, length( $self->savedir )+1 );
                    $self->{pic}=$pic;                    

                    if ($self->keeporiginal){
                        $self->upload->copy_to($self->keeporiginal.'/orig_'.$pic);
                    }
                
                    # if there is a save dir, resize. depending if width and/or height is given, scale to dimensions
                    if ($self->savedir){
                         my $continueflag=1;
                         if ($self->scaletype eq 'smart'){                            
                            if ($self->width && $self->height){
                                $continueflag = 0;
                                my $container_dir='v';
                                if ($self->width > $self->height){
                                    my $container_dir='h';
                                }
                                
                                my $dir='v';
                                if ($image->getwidth() > $image->getheight()){
                                    $dir='h';
                                }
                                                        
                                if ($container_dir ne $dir ){
                                    my $tmp=$self->width;
                                    $self->width=$self->height;
                                    $self->height=$tmp;
                                }                                
                                $image = $image->scale(ypixels=>$self->height,xpixels=>$self->width);
                            }
                        }
                        if ($continueflag==1){  
                            if  (($self->width) and ($self->height) and ($self->scaletype)) {
                                # Resize height, scale width
                                $image = $image->scale(ypixels=>$self->height,xpixels=>$self->width,type=>$self->scaletype);
                            } elsif (($self->width) and ($self->height)) {
                                # No scale. Resize to given dimensions
                                $image = $image->scaleX(pixels=>$self->width)->scaleY(pixels=>$self->height);
                            } elsif ($self->width) {
                                # Resize width, scale height
                                $image = $image->scale(xpixels=>$self->width);
                            } elsif ($self->height) {
                                # Resize height, scale width
                                $image = $image->scale(ypixels=>$self->height);
                            } 
                        }
                            $image->write(
                                file        => $self->savedir.'/med_'.$pic,
                                type        => 'jpeg',
                                jpegquality => 90
                            );
                            unlink($self->upload->tempname);
                

                        if ($self->thumbnail) {
                            if ($self->thumbnail->{width} || $self->thumbnail->{height} ) {
                                if (($self->thumbnail->{width}) and ($self->thumbnail->{height})) {
                                    # No scale. Resize to given dimensions
                                    $image = $image->scaleX(pixels=>$self->thumbnail->{width})->scaleY(pixels=>$self->thumbnail->{height});
                                } elsif ($self->thumbnail->{width}) {
                                    # Resize width, scale height
                                    $image = $image->scale(xpixels=>$self->thumbnail->{width});
                                } elsif ($self->thumbnail->{height}) {
                                    # Resize height, scale width
                                    $image = $image->scale(ypixels=>$self->thumbnail->{height});
                                }
                                my $thmb_fn = $self->savedir.'/thumb_'.$pic;
                                $thmb_fn = $self->thumbnail->{savedir}.'/thumb_'.$pic if ($self->thumbnail->{savedir});
                                    $image->write(
                                    file        => $thmb_fn,
                                    type        => 'jpeg',
                                    jpegquality => 90
                                );
                            }
                        }
                        unlink($self->savedir.'/'.$pic);
                        #$self->{pic}=$pic;
                     }
                }
            }
        }
    }#end of if upload and submit
}

sub get_value{
    my ($self) = @_;
    my $result='';
    my $request=$self->request;
    
    $result=$self->{pic};
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
    my $class='form_image_select';
    $self->label('&nbsp;') if ($self->label eq '');
    $class=$self->{class}  if exists($self->{class});
    my $name=' name="'.$self->name.'_upload" ';
    my $checked='';
    my $pic='';
    $pic= $self->{pic} if ($self->{pic});
    $pic=$request->{$self->name} if ($request->{$self->name});
    
    if ($options->{frozen}) {    
        $disabled=' disabled ' if ($options->{frozen} == 1);
    }
    
    my $tmpres='';    
    $tmpres.= $self->errormessage if ($self->{sizeerror} && $self->errormessage);
    $tmpres.='<input type="file" class="'.$class.'" '.$self->get_attr().$disabled.$name.'>';
    
    if ($options->{frozen}) {    
        $result .= $tmpres unless ($options->{frozen} == 1 );
    } else {
        $result .= $tmpres;
    }
    
    $result.='<input type="hidden" name="'.$self->name.'" value="'.$pic.'">';
    if ($pic ne ''){        
        $result.="<br /><br />";        
        $result.="<img id='thumbnail' src='".$self->loadurl.$pic."'>" if ($self->loadurl);
    }

  return $self->vor($options).$result.$self->nach;
}

1;


__END__

=head1 HTML::TurboForm::Element::Imageupload

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
