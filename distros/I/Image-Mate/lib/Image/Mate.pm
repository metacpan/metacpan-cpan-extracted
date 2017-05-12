####################################################
######################## The Image::Mate module
######################## Created by Lyle Hopkins (Cosmic Networks Ltd).
######################## Provides easy use of GD, Imager or ImageMagick
##################################################

package Image::Mate;

use 5.005;
use strict;
use warnings;
use Carp;
use vars qw(@GMODS %GMODLIST @GMODPREF $GMOD $IMGS @ISA @EXPORT_OK $VERSION);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw( im_available im_setpref );
    $VERSION = 0.05;
} #BEGIN

$GMOD = "";
@GMODS = (
    "Imager",
    "GD",
    "Image::Magick",
);
%GMODLIST = ();
foreach my $module (@GMODS) {
    my $exist = &_CheckForModule($module);
    $GMODLIST{$module} = $exist;
    if ($exist) {
        &_LoadModule($module);
        push (@GMODPREF, $module);
        unless ($GMOD) {
            $GMOD = $module;
        } #unless
    } #if
} #foreach


##################################################
######################## Available graphics modules
##################################################

sub im_available {
    if ($_[1] eq "hash") {
        return %GMODLIST;
    } #if
    if ($_[1] eq "array") {
        return @GMODPREF;
    } #if
} #sub


##################################################
######################## Set module preference
##################################################

sub im_setpref {
    my $name = shift;
    if (scalar(@_) < 1) {
        return "1: Must have at least one preference";
    } #if
    foreach my $module (@_) {
        my $valid = 0;
        foreach my $validmod (@GMODS) {
            $valid = 1 if ($module eq $validmod);
        } #foreach
        croak "Invalid option '$module'" if !$valid;
    } #foreach
    @GMODPREF = @_;
    $GMOD = $_[0];
    return 0;
} #sub


##################################################
######################## Create image object
##################################################

sub new {
    my $class = shift;
    my $self = {};
    bless $self,$class;
    my %input = @_;

    ## Generate a unique image reference
    my @chars=('A'..'Z','a'..'z',0..9);
    my $imgid = join('',@chars[map{rand @chars}(1..16)]);
  
    unless ($input{blank} || $input{file}) {
        $@ = "Requires filename or blank image details";
        return undef;
    } #unless

    ## Imager
    if ($GMOD eq "Imager") {
        if ($input{blank}) {
            my $bits = 8;
            $bits = 16 if $input{blank}->{c};
            $IMGS->{$imgid} = Imager->new(xsize=>$input{blank}->{x},ysize=>$input{blank}->{y},bits=>$bits);
            unless (ref($IMGS->{$imgid})) {
                croak 'Imager Error creating image';
            } #unless
            $self->{X} = $input{blank}->{x};
            $self->{Y} = $input{blank}->{y};
        } #if
        else {
            $IMGS->{$imgid} = Imager->new;
            $IMGS->{$imgid}->read(file => $input{file}) or croak $IMGS->{$imgid}->errstr;
            $self->{X} = $IMGS->{$imgid}->getwidth();
            $self->{Y} = $IMGS->{$imgid}->getheight();
        } #else
    } #if

    ## GD
    if ($GMOD eq "GD") {
        if ($input{blank}) {
            my $truecolour = 0;
            $truecolour = 1 if $input{blank}->{c};
            $IMGS->{$imgid} = GD::Image->new($input{blank}->{x},$input{blank}->{y},$truecolour);
            unless (ref($IMGS->{$imgid})) {
                croak 'Image::Magick Error creating image';
            } #unless
            $self->{X} = $input{blank}->{x};
            $self->{Y} = $input{blank}->{y};
        } #if
        else {
            $IMGS->{$imgid} = GD::Image->new($input{file});
            croak $@ if $@;
            ($self->{X},$self->{Y}) = $IMGS->{$imgid}->getBounds()
        } #else
    } #if

    ## Image::Magick
    if ($GMOD eq "Image::Magick") {
        if ($input{blank}) {
            if ($input{blank}->{c}) {
                $IMGS->{$imgid} = Image::Magick->new(size=>"$input{blank}->{x}x$input{blank}->{y}", type=>'TrueColor');
            } #if
            else {
                $IMGS->{$imgid} = Image::Magick->new(size=>"$input{blank}->{x}x$input{blank}->{y}");
            } #else
            unless (ref($IMGS->{$imgid})) {
                croak 'Image::Magick Error creating image';
            } #unless
            $self->{X} = $input{blank}->{x};
            $self->{Y} = $input{blank}->{y};
            my $x = $IMGS->{$imgid}->ReadImage('xc:white');
            croak $x if $x;
        } #if
        else {
            $IMGS->{$imgid} = Image::Magick->new;
            my $error = $IMGS->{$imgid}->Read($input{file});
            croak $error if $error;
            ($self->{X},$self->{Y}) = $IMGS->{$imgid}->Get('width','height') or croak 'Image::Magick Cannot get width and height';
        } #else
    } #if
  
    $self->{IMGID} = $imgid;

    return $self;
} ## End sub


##################################################
######################## Colour whole image
##################################################

sub fillall {
    my $self=shift;
    unless ($self->{IMGID}) {
        $self->{ERROR}='No image';
        return undef;
    } #unless
    my %input = @_;
    
    ## Imager
    if ($GMOD eq "Imager") {
        $IMGS->{$self->{IMGID}}->box(filled => 1, color => $input{c}) or croak $IMGS->{$self->{IMGID}}->errstr;
    } #if
    
    ## GD
    if ($GMOD eq "GD") {
        my $colour = &_MakeGDColour($self->{IMGID},$input{c});
        $IMGS->{$self->{IMGID}}->filledRectangle(0,0,$self->{X}-1,$self->{Y}-1,$colour);
        croak $@ if $@;
    } #if
    
    ## Image::Magick
    if ($GMOD eq "Image::Magick") {
        my $error = $IMGS->{$self->{IMGID}}->Colorize(fill => $input{c});
        croak $error if $error;
    } #if
    return $self;  
} #sub


##################################################
######################## Draw line in image
##################################################

sub line {
    my $self=shift;
    unless ($self->{IMGID}) {
        $self->{ERROR}='No image';
        return undef;
    } #unless
    my %input = @_;
    
    ## Imager
    if ($GMOD eq "Imager") {
        $IMGS->{$self->{IMGID}}->line(color=>$input{c}, x1=>$input{start}->{x}, x2=>$input{end}->{x}, y1=>$input{start}->{y}, y2=>$input{end}->{y}, aa=>1, endp=>1 ) or croak $IMGS->{$self->{IMGID}}->errstr;
    } #if
    
    ## GD
    if ($GMOD eq "GD") {
        $IMGS->{$self->{IMGID}}->setThickness($input{thick}) if $input{thick};
        my $colour = &_MakeGDColour($self->{IMGID},$input{c});
        $IMGS->{$self->{IMGID}}->line($input{start}->{x},$input{start}->{y},$input{end}->{x},$input{end}->{y},$colour);
        croak $@ if $@;
        $IMGS->{$self->{IMGID}}->setThickness(1) if ($input{thick});
    } #if
    
    ## Image::Magick
    if ($GMOD eq "Image::Magick") {
        $input{thick} = 1 unless $input{thick};
        my $error = $IMGS->{$self->{IMGID}}->Draw(stroke=>$input{c}, primitive=>'line', points=>"$input{start}->{x},$input{start}->{y} $input{end}->{x},$input{end}->{y}", strokewidth=>$input{thick});
        croak $error if $error;
    } #if
    return $self;  
} ## End sub


##################################################
######################## Save image
##################################################

sub save {
    my $self=shift;
    croak 'No image!' unless $self->{IMGID};
    my %input = @_;
    croak 'File exists!' if (-e "$input{filename}" && !$input{overwrite});
    
    ## Imager
    if ($GMOD eq "Imager") {
        if ($input{type} eq "gif") {
            $IMGS->{$self->{IMGID}}->write(file => $input{filename}, type => $input{type}) or croak $IMGS->{$self->{IMGID}}->errstr;
        } #if
        elsif ($input{type} eq "png") {
            $IMGS->{$self->{IMGID}}->write(file => $input{filename}) or croak $IMGS->{$self->{IMGID}}->errstr;
        } #elsif
        else {
            $input{type} = "jpeg";
            if ($input{'quality'}) {
                $IMGS->{$self->{IMGID}}->write(file => $input{filename}, type => $input{type}, jpegquality=>$input{'quality'}) or croak $IMGS->{$self->{IMGID}}->errstr;
            } #if
            else {
                $IMGS->{$self->{IMGID}}->write(file => $input{filename}, type => $input{type}) or croak $IMGS->{$self->{IMGID}}->errstr;
            } #else
        } #else
    } #if
    
    ## GD
    if ($GMOD eq "GD") {
        open (OUTF, ">$input{filename}");
            binmode OUTF;
            if ($input{type} eq "gif") {
                print OUTF $IMGS->{$self->{IMGID}}->gif();
                croak $@ if $@;
            } #if
            elsif ($input{type} eq "png") {
                if ($input{'compression'}) {
                    print OUTF $IMGS->{$self->{IMGID}}->png([$input{compression}]);
                    croak $@ if $@;
                } #if
                else {
                    print OUTF $IMGS->{$self->{IMGID}}->png();
                    croak $@ if $@;
                } #else
            } #if
            else {
                if ($input{'quality'}) {
                    print OUTF $IMGS->{$self->{IMGID}}->jpeg([$input{quality}]);
                    croak $@ if $@;
                } #if
                else {
                    print OUTF $IMGS->{$self->{IMGID}}->jpeg();
                    croak $@ if $@;
                } #else
            } #else
        close(OUTF);
    } #if
    
    ## Image::Magick
    if ($GMOD eq "Image::Magick") {
        if ($input{type} eq "gif") {
            my $error = $IMGS->{$self->{IMGID}}->Write($input{filename});
            croak $error if $error;
        } #if
        elsif ($input{type} eq "png") {
            if ($input{'compression'}) {
                my @compression = qw( None BZip Fax Group4 JPEG JPEG2000 LosslessJPEG LZW RLE Zip );
                my $error = $IMGS->{$self->{IMGID}}->Write(filename => $input{filename}, compression => $compression[ $input{'compression'} ]);
                croak $error if $error;
            } #if
            else {
                my $error = $IMGS->{$self->{IMGID}}->Write(filename => $input{filename});
                croak $error if $error;
            } #else
        } #elsif
        else {
            if ($input{'quality'}) {
                my $error = $IMGS->{$self->{IMGID}}->Write(filename => $input{filename}, quality => $input{'quality'});
                croak $error if $error;
            } #if
            else {
                my $x = $IMGS->{$self->{IMGID}}->Set(magick => 'JPEG');
                croak $x if $x;
                my $error = $IMGS->{$self->{IMGID}}->Write(filename => $input{filename});
                croak $error if $error;
            } #else
        } #else
    } #if
    return $self;  
} ## End sub



##################################################
######################## Make GD colour
##################################################

sub _MakeGDColour {
    my ($imgid, $colour) = @_;
    $colour =~ s/\#//;
    $colour =~ /([0-1a-f][0-1a-f])([0-1a-f][0-1a-f])([0-1a-f][0-1a-f])/i;
    my $gdcolour = $IMGS->{$imgid}->colorAllocate(hex($1),hex($2),hex($3));
} #sub


##################################################
######################## Load Module
##################################################

sub _LoadModule {
    my $module = $_[0];
    my $loadok = 1;
    package main;
    eval "require $module";
    if ($@) {
        package Image::Mate;
        $loadok = 0;
        package main;
    } #if
    else {
        $module->import(@_[1 .. $#_]);
    } #else
    package Image::Mate;
    return $loadok;
} #sub


##################################################
######################## Check for module
##################################################

sub _CheckForModule {
    my $modulename = $_[0];
    my $modulefound = 0;
    $modulename =~ s/::/\//gis;
    foreach my $modulepath (@INC) {
        $modulefound = 1 if (-e "$modulepath/$modulename.pm");
    } #foreach
    return $modulefound;
} #sub






##################################################
######################## Clean Up
##################################################

#END {
#    foreach my $imgid (keys %$IMGS) {
#        &DESTROY($imgid);
#    } #foreach
#} #END

#sub DESTROY {
#  my $imgid=shift;
#  if (defined($IMGS->{$imgid})) {
#    undef($IMGS->{$imgid});
#  } #if
#} #sub








=head1 NAME

Image::Mate - Interface to Gd, Imager, ImageMagick modules

=head1 VERSION

This document refers to Image::Mate.pm version 0.05

=head1 SYNOPSIS

    use Image::Mate;

    # Get available graphics modules
    my %list = &Image::Mate->im_available("hash");

    # Set new preference list
    my $error = &Image::Mate->im_setpref("Imager","GD","Image::Magick");
    
    # create a new image
    $img = Image::Mate->new(blank => {x => 100, y => 100, c => 1});
    $img = Image::Mate->new(file => "image.jpg");

    # colour the whole image red
    $img->fillall(c => "#ff0000");

    # draw a black line in the image
    $img->line(c => "#000000", start => {x => 0, y => 0}, end => {x => 10, y => 10});
    
    # save image
    $img->save(filename => "picture.jpg", type => "jpg", quality => 90);
    
=head1 DESCRIPTION

B<Image::Mate.pm> is an interface to the Perl GD, Imager and ImageMagick
modules. Theoretically you'll be able to code the same image routines no 
matter which of the before mentioned modules you have available. Very useful
if your scripts can end up on all different kinds of servers and you never
know what image modules are available.

=head1 ROUTINES

Here are the routines.

=over 1

=item B<$error = Image::Mate-E<gt>im_available(["array","hash"])>

This method returns a list of what graphics modules are available. List can be in the form of a hash 
listing all modules with either a 1 or 0 value. Or an array listing only those available. NOTE: If 
you run setpref before this routine then the array returned by this method will only contain what 
you set. This routine can be exported the local namespace using use Image::Mate qw( im_available );

=item B<$error = Image::Mate-E<gt>im_setpref(LIST)>

This method allows you to set the preference list of which graphics modules you should use first. 
The default is "Imager","GD","Image::Magick". If successful 0 will be returned, otherwise it'll be 
an error code with descriptive error. You cannot set modules that are not available. If you are 
unsure what graphics modules you have available run Image::Mate->available first.
This routine can be exported the local namespace using use Image::Mate qw( im_setpref );

=item B<$img = Image::Mate-E<gt>new(blank => {x => 100, y => 100, c => 1])>
=item B<$img = Image::Mate-E<gt>new(file => "image.jpg")>

Returns an image object. If there was an error with creating this object it will be in $img->{ERROR}.
"c" can have the value of 0 or 1. 0 for stand colour (usually 8bit) or 1 for high colour (usually 16bit).

=item B<$img = Image::Mate-E<gt>fillall(c => "#FFFFFF")>

Fills the whole image with the set colour.

=item B<$img->line(c => "#000000", start => {x => 0, y => 0}, end => {x => 10, y => 10})>

Draws a line from start x,y point to end x,y point of colour c.

=item B<$img->save(filename => "FILENAME", type => "TYPE", quality => QUALITY, compression => COMPRESSION)>

Saves the image to a file. Supported types are GIF, PNG, and JPG, default is JPG. 
For JPG you can define QUALITY as 0-100 (100 best quality, 0 worest). For PNG you can define 
COMPRESSION as 0-9 (0 best quality, 9 worest).

=back

=head1 Obtaining the GD, Imager and Image::Magick perl modules

They are all available on CPAN. Just run a search http://search.cpan.org
As long as you have any one of these modules installed Image::Mate will work.

On linux I recommend using the CPAN module. Type "perl -MCPAN -e shell;" from
your shell. (If this is the first time you've ran the CPAN module you'll have to
go through a little config first, but don't worry this is menu driven). Then type either
(or all):-
install Imager
install GD
install Image::Magick

On Windows your are probably using ActivePerl from ActiveState (which I also recommend). Use their ppm
utility, from the command prompt type:-
ppm install http://ppd.develop-help.com/ppd/Imager.ppd
ppm install http://theoryx5.uwinnipeg.ca/ppms/GD.ppd
ppm install http://www.bribes.org/perl/ppm/Image-Magick.ppd

Unfortunately, ActiveStates automatic build machine does not include the necessary modules to build
Imager, GD and Image::Magick, so they are not available from their default repository.

=head1 BUGS AND LIMITATIONS

This is the first release and distinctly lacking in features :(
Although I'll be adding new features as time goes on :)
Hopefully others will also add new functions as well :D

=head1 AUTHOR

The Image::Mate interface is copyright 2007, Lyle Raymond Hopkins.  It is
distributed under the same terms as Perl itself.  See the "Artistic
License" in the Perl source code distribution for licensing terms.

I welcome other programmers to submit new features to this module!!

=head1 SEE ALSO

L<Imager>,
L<GD>,
L<Image::Magick>

=cut

1;

__END__
