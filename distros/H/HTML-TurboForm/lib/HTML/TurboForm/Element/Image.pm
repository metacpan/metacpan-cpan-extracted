package HTML::TurboForm::Element::Image;
use warnings;
use strict;
use base qw(HTML::TurboForm::Element);
use Imager;
__PACKAGE__->mk_accessors( qw/ prev upload keeporiginal width height savedir thumbnail loadurl caption maxsize errormessage / );

sub new{
    my ($class, $request, $upload) = @_;
    my $self = $class->SUPER::new( $request );
    $self->upload( $upload );
    $self->do_img();
    return $self;
}

sub do_img{
    my ($self)=@_;
    my $request=$self->request;
    my $pic='';
    $pic = $self->request->{$self->name} if ($self->request->{$self->name} );

   if ($request->{ $self->name.'_upload' } && $request->{$self->name.'_submit'} ) {
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
                        if (($self->width) and ($self->height)) {
                            # No scale. Resize to given dimensions
                            $image = $image->scaleX(pixels=>$self->width)->scaleY(pixels=>$self->height);
                        } elsif ($self->width) {
                            # Resize width, scale height
                            $image = $image->scale(xpixels=>$self->width);
                        } elsif ($self->height) {
                            # Resize height, scale width
                            $image = $image->scale(ypixels=>$self->height);
                        }

                        $image->write(
                            file        => $self->savedir.'/med_'.$pic,
                            type        => 'jpeg',
                            jpegquality => 90
                        );

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
         if ($request->{$self->name}){
             $result=$request->{$self->name};
         } 
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
    $disabled=' disabled ' if ($options->{frozen} == 1);
    if ($options->{frozen} != 1 ){
        $result.= $self->errormessage if ($self->{sizeerror} && $self->errormessage);
        $result.='<input type="file" class="'.$class.'" '.$self->get_attr().$disabled.$name.'>';
        $result.='<input type="submit" class="form_image_submit" value="'.$self->caption.'" name="'.$self->name.'_submit">';
    }

    $result.='<input type="hidden" name="'.$self->name.'" value="'.$pic.'">';
    if ($pic ne ''){
        $result.="<br /><br />";
        $result.="<img id='thumbnail' src='".$self->loadurl."/thumb_".$pic."'>" if (($self->thumbnail) && ($self->prev));
    }

  return $self->vor($options).$result.$self->nach;
}

1;


__END__

=head1 HTML::TurboForm::Element::Image

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
