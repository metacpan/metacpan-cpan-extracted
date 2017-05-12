package Image::Caption;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Image::Caption ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	add_caption
);
our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Image::Caption macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Image::Caption $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::Caption - Perl module for captioning RGB data

=head1 SYNOPSIS

  use Image::Caption;

  open(RGB, "<image.rgb");
  my $fr = join("", <RGB>);
  close(RGB);

  add_caption($fr, 320, 240,
    -font  => "ncenB24.bdf",
    -scale => 0.34,
    -blur  => 3,
    -pos   => "-10 -10",
    -right,
    -text  => "%a, %d-%b-%Y %l:%M:%S %p %Z",
  );

  open(PPM, ">image.ppm");
  print PPM "P6\n";      # PPM
  print PPM "320 240\n"; # dimensions
  print PPM "255\n";     # colour depth
  print PPM $fr;
  close(PPM);

=head1 DESCRIPTION

This module is used to add caption text to raw RGB data such as that found in
PPM files or grabbed from a frame grabber card using Video4linux.

This code was written in C by Jamie Zawinski <jwz@jwz.org> as found at
http://www.jwz.org/ppmcaption/ and ported to perl (perlxs) by myself.

=head1 AUTHOR

Iain Wade, <iwade@optusnet.com.au>

=head1 SEE ALSO

perl(1).

=cut
