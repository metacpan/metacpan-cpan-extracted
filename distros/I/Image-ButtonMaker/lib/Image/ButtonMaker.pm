package Image::ButtonMaker;

our $VERSION  = '0.1.4';

use strict;
use utf8;
use Image::ButtonMaker::ButtonClass;
use Image::ButtonMaker::ClassContainer;
use Image::ButtonMaker::Lexicon;
use locale;

my @default = (
               image_dirs   => undef,
               font_dirs    => undef,
               target_dir   => undef,
               lang_id      => undef, 

               classes     => undef,      ## Class container
               buttons     => undef,      ## Button hash
               lexicon     => undef,      ## Lexicon object
               );

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;

    my $object = {@default, @_};
    $object->{image_dirs}   = [];
    $object->{font_dirs}    = [];


    $object->{classes}      = Image::ButtonMaker::ClassContainer->new();
    $object->{buttons}      = [];

    bless $object, $class;
}

#### Replace path specific properties
sub replace_properties {
    my $self = shift;
    my $butref = shift;
    my $lexicon = $self->{lexicon};
    my $lang_id = $self->{lang_id};

    my %buthash = (@$butref);
    my $properties = $buthash{properties};

    my $noLex = $properties->{NoLexicon} ? 1:0;

    foreach my $key (keys(%$properties)) {
        my $value = $properties->{$key};

        #### Lexicon lookup
        if(!$noLex && ($key eq 'Text')) {
            if($lexicon && length($lang_id)) {
                my $replace = $lexicon->lookup($lang_id, $value);
                if(length($replace)) {
                    $properties->{$key} = $replace;
                } else {
                    print STDERR "WARNING: lexicon lookup($lang_id, $value) returned nothing\n";
                }
            }
        }

        #### Path replacements ################################
        elsif($key eq 'TextFont') {
            my $filename = $self->find_font_file($value);
            print STDERR "WARNING: could not find file for font: $value"
              unless(defined $filename);
            $properties->{$key} = $filename;
        }
        elsif($key eq 'CanvasTemplateImg') {
            $properties->{$key} = $self->find_image_file($value);
        }
        elsif($key eq 'IconName') {
            $properties->{$key} = $self->find_image_file($value);
        }
    }
}


### Instance Specific Methods ########################################
sub read_classfile {
    my $self      = shift;
    while(my $classfile = shift) {
        my $classcontainer = $self->{classes};

        my $classList  = do $classfile;
        die "Error reading classfile $classfile: $@" if($@);
        die "Error reading classfile $classfile: $!" if($!);

        foreach my $class (@$classList) {
            $self->replace_properties($class);
            my $class_obj = Image::ButtonMaker::ButtonClass->new(@$class);
            die "CLASSERROR ($Image::ButtonMaker::ButtonClass::error) $Image::ButtonMaker::ButtonClass::errorstr"
              unless($class_obj);
            $classcontainer->add_class($class_obj);
        }

        die "Could not read classfile $classfile because:\n $@" if($@);
    }

    return 1;
}


sub read_buttonfile {
    my $self       = shift;
    my $buttonfile = shift;

    my $classcontainer  = $self->{classes};
    my $buttoncontainer = $self->{buttons};

    my $buttonList  = do $buttonfile;
    die "Error reading buttonfile $buttonfile: $@" if($@);
    die "Error reading buttonfile $buttonfile: $!" if($!);

    foreach my $button (@$buttonList) {
        $self->replace_properties($button);
        my $button_obj = Image::ButtonMaker::Button->new(@$button,
                                                   classcontainer => $classcontainer);
        die "BUTTERR $Image::ButtonMaker::Button::errorstr" unless($button_obj);

        push @$buttoncontainer, $button_obj;
    }
    return 1;
}


sub clear_buttonlist {
    my $self = shift;
    $self->{buttons} = [];
    return;
}


sub clear_classcontainer {
    my $self = shift;
    $self->{classes} = Image::ButtonMaker::ClassContainer->new;
    return;
}


sub add_image_dir {
    my $self = shift;
    my $dir  = shift;
    die "add_image_dir: Dir $dir not found" unless(-d $dir);

    my $imagedirs = $self->{image_dirs};
    push @$imagedirs, $dir;

    return;
}


sub get_image_dirs {
    my $self = shift;
    return (@{$self->{image_dirs}});
}


sub add_font_dir {
    my $self = shift;
    my $dir  = shift;
    die "add_font_dir: Dir $dir not found" unless(-d $dir);

    my $fontdirs = $self->{font_dirs};
    push @$fontdirs, $dir;

    return;
}


sub get_font_dirs {
    my $self = shift;
    return (@{$self->{font_dirs}});
}


sub set_target_dir {
    my $self = shift;
    $self->{target_dir} = shift;
    return;
}

sub get_target_dir {
    my $self = shift;
    return $self->{target_dir};
}


sub set_lang_id {
    my $self = shift;
    $self->{lang_id} = shift;
    return;
}

sub get_lang_id {
    my $self = shift;
    return $self->{lang_id};
}


sub generate {
    my $self = shift;
    my $buttonlist = $self->{buttons};
    my $target_dir = $self->{target_dir};
    
    foreach my $but (@$buttonlist) {
        my $img = $but->write($target_dir);
        die "BUTERR: $Image::ButtonMaker::Button::errorstr"
            unless($img);
        #print "BUTFILENAME :",$but->lookup_filename, "\n"
    }
    return; 
}

sub find_font_file {
    my $self = shift;
    my $file = shift;
    my $dirs = $self->{font_dirs};

    foreach my $d (@$dirs) {
        return "$d/$file" if(-f "$d/$file");
    }

    return undef;
}

sub find_image_file {
    my $self = shift;
    my $file = shift;
    my $dirs = $self->{image_dirs};
    foreach my $d (@$dirs) {
        return "$d/$file" if(-f "$d/$file");
    }

    return undef;
}

############################################################
## Private-ish methods

sub reset_error {
    my $self = shift;

    $self->{error} = 0;
    $self->{errstr} = '';
    return;
}


sub set_error {
    my $self = shift;

    $self->{error}  = shift;
    $self->{errstr} = shift;
    return;
}

sub is_error {
    my $self = shift;
    return ($self->{error} != 0);
}

#### Package Methods #######################################
sub find_file_in_dirs {
    my $file = shift;
    my $dirs = shift;

    foreach my $d (@$dirs) {
        my $f = "$d/$file";
        return $f if(-f $f);
    }
    return undef;
}

1;
__END__

=head1 NAME

Image::ButtonMaker - Button generator.

=head1 SYNOPSIS

    #Create Image::ButtonMaker object
    $bmaker = Image::ButtonMaker->new();

    # Add directory with some truetype fonts in it
    $bmaker->add_font_dir('./happyfonts');

    # Add directory with icons to be used inside buttons
    $bmaker->add_image_dir('./happyfaces');

    #This is where the output will go
    $bmaker->set_target_dir('/httpd/happybuttons');

    # Read the list of classes
    $bmaker->read_classfile('happyclasses.pl');

    # Read the list of buttons to be generated
    $bmaker->read_buttonfile('buttonlist.pl');

    # Generate buttons
    $bmaker->generate;


=head1 DESCRIPTION

Image::ButtonMaker is a helper module for people who need to generate
vast amounts of button images. The module supports dividing your
buttons into classes, who inherit appearance from each other and
overriding needed parameters on class level or on single button level.

Image::ButtonMaker was developed as a part of a large scale web
application with multiple language support, themes and products.


Image::ButtonMaker B<requires> Image::Magick with TrueType Font
support to run.

=head1 MAIN PRINCIPLES

Each button has a set of different attributes, which determine the
appearance of the button. The button can belong to a B<class> which
acts as a template for the button. The class can be a member of a
B<class tree>, where attributes are inherited from parent class to child
class.

The class tree can be stored in one or multiple files. The
Image::ButtonMaker object method C<read_classfile> will read those
files and build the class tree.

With the class tree in place it is time for the button definition.

=head1 CLASS FILE SYNTAX

Class file contains a list of classes written in Perl syntax as a list
of lists:

     ## Button class list
     [
      [
       classname  => 'basicbutton',
       properties => {
           FileType => 'png',

           HeightMin        => 17,
           HeightMax        => 17,
           WidthMin         => 90,

           CanvasType        => 'pixmap',
           CanvasTemplateImg => 'rounded_button_template.png',
           CanvasCutRight    => 1,
           CanvasCutLeft     => 1,
           CanvasCutTop      => 1,
           CanvasCutBottom   => 1,

           ArtWorkType   => 'text',
           ArtWorkHAlign => 'center',
           ArtWorkVAlign => 'baseline',

           TextColor     => '#606060',
           TextSize      => 11,
           TextFont      => 'verdana.ttf',
           TextAntiAlias => 'yes',

           MarginLeft   => 6,
           MarginRight  => 6,
           MarginTop    => 3,
           MarginBottom => 4,
        }
       ],

       [
        classname  => 'basicbutton_with_arrow',
        parent     => 'basicbutton',
        properties => {
            ArtWorkType        => 'icon+text',
            ArtWorkHAlign      => 'left',

            IconName           => 'smallarrow.gif',
            IconSpace          =>  3,
            IconVerticalAdjust =>  0,

            WidthMin         => 100,
            WidthMax         => 100,
       }
       ],

       [
        classname  => 'errorbutton',
        parent     => 'basicbutton',
        properties => {
             TextColor => '#f00000',
        }
       ],
      ]


Every class definition has two or three attributes:

=over 4

=item * B<classname>

The name of the class. Should be something unique for every class.

=item * B<parent> (optional)

Specify the class to inherit from.

=item * B<properties>

A list of properties for the button. Properties can be inherited or
defined for each class, depending on presence of a parent.

The properties will be passed to the L<Image::ButtonMaker::Button>
module and are listed in this modules man page.

=back

=head1 BUTTON FILE SYNTAX

The button list file syntax is very similar to the class list
syntax. A list of buttons is defined. Every button belongs to a class
and has a list of properties that can override class defaults:

     ### Button list 
     [
      [
       name   => 'submitForm',
       classname  => 'basicbutton',
       properties => {
           Text => 'Submit Data',
       }
       ],

      [
       name       => 'goBack',
       classname  => 'basicbutton_with_arrow',
       properties => {
           Text => 'Back to Main',
       }
       ],

      [
       name       => 'showAlert',
       classname  => 'errorbutton',
       properties => {
           Text => 'Important Info',
       }
      ],
     ]

Each button definition has three attributes:

=over 4

=item * B<name>

Button name. Will eventually become the name of the generated file
(with suffix matching FileType attribute)

=item * B<classname>

Class that this button calls home.

=item * B<properties>

Hash of properties with name similar to properties in the class files
and the attributes of the L<Image::ButtonMaker::Button> package.

=back

=head1 METHODS

=over 4

=item * B<new>

The constructor. Returns the Image::ButtonMaker object.

=item * B<read_classfile>

Read the class file and add it to the class tree.

=item * B<read_buttonfile>

Read button list and add found buttons to the list of buttons to be
generated with the C<generate> method.

=item * B<clear_buttonlist>

Empty the button list.

=item * B<add_image_dir>

Add a path to the list of paths, where the ButtonMaker looks for images.

=item * B<get_image_dirs>

Return list of paths.

=item * B<add_font_dir>

Add a path to the list of paths, where the ButtonMaker looks for fonts.

=item * B<get_font_dirs>

Return list of font paths.

=item * B<set_target_dir>

Set the directory for the ButtonMaker to use for output files.

=item * B<get_target_dir>

Return the directory for output paths.

=item * B<get_lang_id>

Get current language ID (for use with the undocumented Lexicon)

=item * B<set_lang_id>

Set current language ID (for use with the undocumented Lexicon)

=item * B<generate>

Generate buttons.

=back

=head1 AUTHORS

Piotr Czarny <F<picz@sifira.dk>> wrote this module and this crappy
documentation.

=head1 SEE ALSO

L<Image::ButtonMaker::Button>, L<Image::ButtonMaker::Lexicon>

=cut
