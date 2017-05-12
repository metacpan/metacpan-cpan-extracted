package Imager::Album;

use strict;
use Storable (); # Avoid imports

use File::Basename;
use File::Spec;

use vars qw($VERSION @suf);

@suf = qw( jpeg jpg tiff tif gif png ppm pgm pbm png );


$VERSION = '0.06';

#
# Methods
#


sub new {
  my $class = shift;
  my %opts = @_;
  my $self = {};
  bless $self,$class;
  $self->{'preview_opts'} = {xpixels => 100, qtype=>'preview'};
  $self->{'commands'} = [ ['Rotate cw', \&rotate_image_cw],
			  ['Rotate ccw', \&rotate_image_ccw],
			  ['Export', sub { shift; $self->{'gui'}->export_gallery(@_); } ],
			  ['Captions', sub { shift; $self->{'gui'}->label(@_); } ],
			  ['Store', sub { shift; $self->store(); }],
			  ['Remove', sub { shift; $self->{'gui'}->remove_images(@_); }],
			  ['Quit', sub { shift; $self->{'gui'}->shutdown(); }],
			  ];



   my $dir = exists $opts{'working_dir'} ? $opts{'working_dir'} : undef;
  $self->set_working_dir($dir);

  $self->{'seq'} = 1;
  if (-f $self->{'dir'}."/store") {
    $self->{'images'} = Storable::retrieve($self->{'dir'}."/store");
    $self->{'ordering'} = Storable::retrieve($self->{'dir'}."/ordering");
#  $self->{'ordering'} = [keys %{$self->{images}}];	
    print "@{$self->{ordering}}\n";
    for (keys %{$self->{'images'}}) {
      $self->{'seq'}=$_+1 if $_ >= $self->{'seq'};
    }
  } else {
    $self->{'images'} = {};
    $self->{'orering'} = [];
  }
  return $self;
}




sub store {
  my $self = shift;
  my %imcopy = %{$self->{'images'}};
  for (keys %imcopy) {
    delete $imcopy{$_}->{'gdk_preview'};
  }

  Storable::nstore(\%imcopy, $self->{'dir'}."/store");
  Storable::nstore($self->{'ordering'}, $self->{'dir'}."/ordering");
  print "stored current status in directory: ".$self->{'dir'}."\n";
}





sub set_working_dir {
  my $self = shift;
  my $base = shift || $ENV{HOME}."/.Imager__Album_$$";
  if (!-d $base) {
    mkdir($base,0777)
      or die "Couldn't create working dir '$base': $!\n";
  }
  if (!-d "$base/preview") {
    mkdir("$base/preview",0777)
      or die "Couldn't create working dir '$base/preview': $!\n";
  }
  $self->{'dir'} = $base;
}




sub add_image {
  my $self  = shift;
  my $fname = shift;
  my $num   = $self->{'seq'}++;

  my ($name, $path, $suffix) = fileparse($fname, @suf);
  my %hash;

  return undef unless -f $fname;

  $hash{path}    = $fname;
  $hash{name}    = $name;
  $hash{caption} = $name;
  $hash{rotated} = 0;
  $hash{valid}   = 0;


  push(@{$self->{'ordering'}}, $num);
  $self->{'images'}->{$num} = \%hash;
}


sub get_image {
  my ($self, $imageno) = @_;
  return $self->{'images'}->{$imageno};
}


sub get_preview_path {
  my ($self, $imageno) = @_;
  my $path = File::Spec->catfile($self->{'dir'},
				 'preview',
				 $imageno.".png");
  return $path;
}



# Find which images need to have previews
# updated and call update_preview on those.

sub update_previews {
  my $self    = shift;
  my %images  = %{$self->{'images'}};
  my @process = grep { !$images{$_}->{valid} } keys %images;
  my $imageno;
  my $c = 1;
  for $imageno (@process) {
    print "Updating preview $c/".@process."\n";
    $c++;
    $self->update_preview($imageno);
  }
}



# Update an images preview file

sub update_preview {
  my $self    = shift;
  my $imageno = shift;
  my %opts    = %{$self->{'preview_opts'}};

  my $image   = $self->{'images'}->{$imageno};
  my $file    = $image->{'path'};
  my $img     = Imager->new();

  if (!$img->read(file=>$file)) {
    print "ERROR $file: ".$img->errstr;
    return ();
  }

  my $prev = $img->scale(%opts);
  if ($image->{'rotated'}) {
    $prev = $prev->rotate(degrees=>$image->{'rotated'}*90);
  }
  my $dir = $self->{'dir'};
  $prev->write(file=>"$dir/preview/$imageno.png") or die $!;
  $image->{'valid'} = 1;
}



sub rotate_image_cw {
  my ($self, @imagenos) = @_;
  my @images = map { $self->{'images'}->{$_} } @imagenos;

  for (@images) {
    $_->{'rotated'}++;
    $_->{'valid'} = 0;
  }
}


sub rotate_image_ccw {
  my ($self, @imagenos) = @_;
  my @images = map { $self->{'images'}->{$_} } @imagenos;

  for (@images) {
    $_->{'rotated'}--;
    $_->{'valid'} = 0;
  }
}


sub change_order {
  my ($self, $from, $to) = @_;
  my $aref = $self->{'ordering'};
  my $tmp = splice(@{$aref}, $from, 1);
  splice(@{$aref}, $to, 0, $tmp);
}


# Give ids
sub remove_images {
  my ($self, @imagenos) = @_;
  delete $self->{'images'}->{$_} for @imagenos;

  my $imageno;
  for $imageno (@imagenos) {
    my @order = @{$self->{'ordering'}};
    for (0..@order-1) {
      if ($imageno == $order[$_]) {
	splice(@{$self->{'ordering'}}, $_, 1);
      }
    }
    @order = @{$self->{'ordering'}};
  }
}





















sub export {
  my ($self, $destdir, $albumname) = @_;
  my @images = @{$self->{'ordering'}};

  print "Exporting images: @images\n";

  my %opts1 = (xpixels => 688, ypixels => 688, type=>'min');
  my %opts2 = (xpixels => 200, ypixels => 200, type=>'min');

  mkdir($destdir, 0777) or die "$!\n";

  my $imageno;
  my $cnt = 0;

  for $imageno (@images) {
    print "Processing image $cnt/".@images."\n";
    $cnt++;
    my $ihash = $self->{'images'}->{$imageno};
    my $img = Imager->new();
    $img->read(file=>$ihash->{'path'}) or die $img->errstr;

    my %sopts1 = %opts1;
    my %sopts2 = %opts2;

    if ($ihash->{'rotated'} % 2) {
      my $t = $sopts1{'xpixels'};
      $sopts1{'xpixels'}  = $sopts1{'ypixels'};
      $sopts1{'ypixels'}  = $t;

      $t = $sopts2{'xpixels'};
      $sopts2{'xpixels'}  = $sopts2{'ypixels'};
      $sopts2{'ypixels'}  = $t;

    }

    $img = $img->scale(%sopts1);

    if ($ihash->{'rotated'}) {
      $img = $img->rotate(degrees=>$ihash->{'rotated'}*90);
    }

    $img->write(file=>"$destdir/$imageno.jpg") or die $img->errstr;
    $img = $img->scale(%sopts2);
    $img->write(file=>"$destdir/${imageno}_h.jpg") or die $img->errstr;
  }

  local *FHIDX;
  open(FHIDX, ">$destdir/index.html") or die "Cannot open >$destdir/index.html : $!\n";

  print FHIDX "<HTML><HEAD><TITLE>$albumname</TITLE></HEAD>\n";
  print FHIDX "<BODY BGCOLOR=\"#FFFFFF\" LINK=\"#000000\" VLINK=\"#000000\"><CENTER>\n";
  print FHIDX "<FONT FACE=\"Helvetica, Arial\">\n";
  print FHIDX "<FONT SIZE=\"+1\"><B>$albumname</B></FONT>\n";
  print FHIDX "<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=24>\n";
  my $c = 0;
  for $imageno (@images) {
    my $ihash   = $self->{'images'}->{$imageno};
    my $name    = $ihash->{'name'};
    my $caption = $ihash->{'caption'};

    print FHIDX "</TR><TR>" if !($c++%3);


    print FHIDX "<TD><A HREF=\"${imageno}.html\"><IMG SRC=\"${imageno}_h.jpg\"></A><BR><BR>\n";
    print FHIDX "<FONT FACE=\"Helvetica, Arial\"><B>$name</B></FONT></TD>\n";


    local *FH;
    open(FH, ">$destdir/${imageno}.html") or die $!;
    print FH "<HTML><HEAD><TITLE>$albumname</TITLE></HEAD>\n";
    print FH "<BODY BGCOLOR=\"#FFFFFF\"><CENTER>\n";
    print FH "<FONT FACE=\"Helvetica, Arial\">\n";
    print FH "<TABLE BORDER=0><TR><TD>\n";
    print FH "<IMG SRC=\"${imageno}.jpg\" BORDER=1><P>\n";
    print FH "<B>$name</B><BR>\n";
    print FH "$caption\n";
    print FH "</TD></TR></TABLE>\n";
    print FH "</CENTER></BODY></HTML>\n";
  }

  print FHIDX "</TR>\n";
  print FHIDX "</TABLE></CENTER>\n";
  print FHIDX "</BODY></HTML>\n";
  close(FHIDX);
}




1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Imager::Album - Perl extension for processing Images for output to 
web.

=head1 SYNOPSIS

  use Imager::Album;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Imager::Album, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut



