package Gimp::Fu;

use Gimp::Data;
use Gimp::Pod;
use strict;
use warnings;
use Carp qw(croak carp);
use base 'Exporter';
use Filter::Simple;
use FindBin qw($RealBin $RealScript);
use File::stat;

our $run_mode;
our $VERSION = "2.38";

# manual import
sub __ ($) { goto &Gimp::__ }

use constant {
  PF_INT8 => Gimp::PDB_INT8,
  PF_INT16 => Gimp::PDB_INT16,
  PF_INT32 => Gimp::PDB_INT32,
  PF_FLOAT => Gimp::PDB_FLOAT,
  PF_STRING => Gimp::PDB_STRING,
  PF_INT32ARRAY => Gimp::PDB_INT32ARRAY,
  PF_INT16ARRAY => Gimp::PDB_INT16ARRAY,
  PF_INT8ARRAY => Gimp::PDB_INT8ARRAY,
  PF_FLOATARRAY => Gimp::PDB_FLOATARRAY,
  PF_STRINGARRAY => Gimp::PDB_STRINGARRAY,
  PF_COLOR => Gimp::PDB_COLOR,
  PF_ITEM => Gimp::PDB_ITEM,
  PF_IMAGE => Gimp::PDB_IMAGE,
  PF_LAYER => Gimp::PDB_LAYER,
  PF_CHANNEL => Gimp::PDB_CHANNEL,
  PF_DRAWABLE => Gimp::PDB_DRAWABLE,
  PF_COLORARRAY => Gimp::PDB_COLORARRAY,
  PF_VECTORS => Gimp::PDB_VECTORS,
  PF_PARASITE => Gimp::PDB_PARASITE,
  PF_TOGGLE => Gimp::PDB_END + 1,
  PF_SLIDER => Gimp::PDB_END + 2,
  PF_FONT => Gimp::PDB_END + 3,
  PF_SPINNER => Gimp::PDB_END + 4,
  PF_ADJUSTMENT => Gimp::PDB_END + 5,
  PF_BRUSH => Gimp::PDB_END + 6,
  PF_PATTERN => Gimp::PDB_END + 7,
  PF_GRADIENT => Gimp::PDB_END + 8,
  PF_RADIO => Gimp::PDB_END + 9,
  PF_CUSTOM => Gimp::PDB_END + 10,
  PF_FILE => Gimp::PDB_END + 11,
  PF_TEXT => Gimp::PDB_END + 12,
};
use constant {
  PF_BOOL => PF_TOGGLE,
  PF_VALUE => PF_STRING,
  PF_COLOUR => Gimp::PDB_COLOR,
};

# key is text, bit in array-ref is number!
# [int, human-description, GIMP-data-type-if>PDB_END-or-infer, passthru]
my %pfname2info = (
   PF_INT8		=> [ PF_INT8, 'integer (8-bit)', ],
   PF_INT16		=> [ PF_INT16, 'integer (16-bit)', ],
   PF_INT32		=> [ PF_INT32, 'integer (32-bit)', ],
   PF_FLOAT		=> [ PF_FLOAT, 'number', ],
   PF_STRING		=> [ PF_STRING, 'string', undef, 1 ],
   PF_INT32ARRAY	=> [ PF_INT32ARRAY, 'list of integers (32-bit)' ],
   PF_INT16ARRAY	=> [ PF_INT16ARRAY, 'list of integers (16-bit)' ],
   PF_INT8ARRAY		=> [ PF_INT8ARRAY, 'list of integers (8-bit)' ],
   PF_FLOATARRAY	=> [ PF_FLOATARRAY, 'list of numbers' ],
   PF_STRINGARRAY	=> [ PF_STRINGARRAY, 'list of strings' ],
   PF_COLOR		=> [ PF_COLOR, 'colour', ],
   PF_ITEM		=> [ PF_ITEM, 'item' ],
   PF_IMAGE		=> [ PF_IMAGE, 'image', ],
   PF_LAYER		=> [ PF_LAYER, 'layer', ],
   PF_CHANNEL		=> [ PF_CHANNEL, 'channel', ],
   PF_DRAWABLE		=> [ PF_DRAWABLE, 'drawable (%[filename:]number or %a = active)', ],
   PF_COLORARRAY	=> [ PF_COLORARRAY, 'list of colours' ],
   PF_VECTORS		=> [ PF_VECTORS, 'vectors' ],
   PF_PARASITE		=> [ PF_PARASITE, 'parasite' ],
   PF_BRUSH		=> [ PF_BRUSH, 'brush', Gimp::PDB_STRING, 1 ],
   PF_GRADIENT		=> [ PF_GRADIENT, 'gradient', Gimp::PDB_STRING, 1 ],
   PF_PATTERN		=> [ PF_PATTERN, 'pattern', Gimp::PDB_STRING, 1 ],
   PF_FONT		=> [ PF_FONT, 'font', Gimp::PDB_STRING, 1 ],
   PF_TOGGLE		=> [ PF_TOGGLE, 'boolean', Gimp::PDB_INT8, ],
   PF_SLIDER		=> [ PF_SLIDER, 'number', Gimp::PDB_FLOAT, ],
   PF_SPINNER		=> [ PF_SPINNER, 'integer', Gimp::PDB_INT32, ],
   PF_ADJUSTMENT	=> [ PF_ADJUSTMENT, 'number', Gimp::PDB_FLOAT, ],
   PF_RADIO		=> [ PF_RADIO, 'data', ],
   PF_CUSTOM		=> [ PF_CUSTOM, 'string', Gimp::PDB_STRING, 1 ],
   PF_FILE		=> [ PF_FILE, 'filename', Gimp::PDB_STRING, 1 ],
   PF_TEXT		=> [ PF_TEXT, 'string', Gimp::PDB_STRING, 1 ],
);
$pfname2info{PF_COLOUR} = $pfname2info{PF_COLOR};
$pfname2info{PF_BOOL} = $pfname2info{PF_TOGGLE};
$pfname2info{PF_VALUE} = $pfname2info{PF_FLOAT};
my %pf2info = map {
   my $v = $pfname2info{$_}; ($v->[0] => [ @$v[1..3] ])
} keys %pfname2info;

my $podreg_re = qr/(\bpodregister\s*{)/;
FILTER {
   return unless /$podreg_re/;
   my $myline = make_arg_line(fixup_args(('') x 9, 1));
   s/$podreg_re/$1\n$myline/;
   warn __PACKAGE__."::FILTER: found: '$1'" if $Gimp::verbose >= 2;
};

our @EXPORT_OK = qw($run_mode save_image);
our %EXPORT_TAGS = (
   params => [ keys %pfname2info ]
);
our @EXPORT = (qw(podregister register main), @{$EXPORT_TAGS{params}});

my @scripts;

sub interact {
   require Gimp::UI;
   goto &Gimp::UI::interact;
}

sub find_script {
   return $scripts[0] if @scripts == 1;
   my @names;
   for my $this (@scripts) {
      my $fun = $this->[0];
      $fun =~ s/^(?:perl_fu|plug_in)_//;
      return $this if lc($_[0] // '') eq lc($fun);
      push @names, $fun;
   }
   die "Must specify proc with -p flag (one of @names)\n" unless defined $_[0];
   die __"function '$_[0]' not found in this script (must be one of @names)\n";
}

my ($latest_image, $latest_imagefile);

sub string2pf($$) {
   my ($s, $type, $name, $desc) = ($_[0] // '', @{$_[1]});
   if($pf2info{$type}->[2] or $type == PF_RADIO) {
      $s;
   } elsif($pf2info{$type}->[0] =~ /integer/) {
      die __"$s: not an integer\n" unless $s==int($s);
      $s*1;
   } elsif($pf2info{$type}->[0] eq 'number') {
      die __"$s: not a number\n" unless $s==1.0*$s;
      $s*1.0;
   } elsif($type == PF_COLOUR) {
      Gimp::canonicalize_colour($s);
   } elsif($pf2info{$type}->[0] eq 'boolean') {
      $s?1:0;
   } elsif($type == PF_IMAGE) {
      my $image;
      if ((my $arg) = $s =~ /%(.+)/) {
	 die "Image %argument '$arg' not integer - if file, put './' in front\n"
	    unless $arg eq int $arg;
	 $image = Gimp::Image->existing($arg);
	 die "'$arg' not a valid image - need to run Perl Server?\n"
	    unless $image->is_valid;
      } else {
	 $image = Gimp->file_load(Gimp::RUN_NONINTERACTIVE, $s, $s),
	 $latest_imagefile = $s;
      }
      $latest_image = $image; # returned as well
   } elsif($type == PF_DRAWABLE) {
      if ((my $arg) = $s =~ /%(.+)/) {
	 if ($arg eq 'a') {
	    $latest_image->get_active_drawable;
	 } elsif (my ($file, $subarg) = $arg =~ /(.*):(\d+)/) {
	    $latest_imagefile = $file;
	    $latest_image = Gimp->file_load(Gimp::RUN_NONINTERACTIVE, $file, $file),
	    ($latest_image->get_layers)[$subarg]->become('Gimp::Drawable');
	 } else {
	    die "Drawable % argument not integer\n"
	       unless $arg eq int $arg;
	    Gimp::Drawable->existing($arg);
	 }
      } else {
	 die "Must specify drawable as %number or %a (active)\n";
      }
   } else {
      die __"Can't convert '$name' from string to '$pf2info{$type}->[0]'\n";
   }
}

# mangle argument switches to contain only a-z0-9 and the underscore,
# for easier typing.
sub mangle_key {
   my $key = shift;
   $key=~y/A-Z /a-z_/;
   $key=~y/a-z0-9_//cd;
   $key;
}

Gimp::on_net {
   require Getopt::Long;
   my $proc;
   Getopt::Long::Configure('pass_through');
   Getopt::Long::GetOptions('p=s' => \$proc);
   Getopt::Long::Configure('default');
   my $this = find_script($proc);
   my(%mangleparam2index,@args);
   my ($interact, $outputfile) = 1;
   my ($function,$blurb,$help,$author,$copyright,$date,
       $menupath,$imagetypes,$type,$params,$results) = @$this;
   @mangleparam2index{map mangle_key($_->[1]), @$params} = (0..$#{$params});
   die "$0: error - try $0 --help\n" unless Getopt::Long::GetOptions(
      'interact|i' => sub { $interact = 1e6 },
      'output|o=s' => \$outputfile,
      map {
	 ("$_=s"=>sub {$args[$mangleparam2index{$_[0]}] = $_[1]; $interact--;})
      } keys %mangleparam2index,
   );
   warn "$$-".__PACKAGE__." on_net (@args) (@ARGV) '$interact'" if $Gimp::verbose >= 2;
   die "$0: too many arguments. Try $0 --help\n" if @ARGV > @$params;
   $interact -= @ARGV;
   map { $args[$_] = $ARGV[$_] } (0..$#ARGV); # can mix & match --args and bare
   # Fill in default arguments
   foreach my $i (0..@$params-1) {
      next if defined $args[$i];
      my $entry = $params->[$i];
      $args[$i] = $entry->[3];
      die __"parameter '$entry->[1]' is not optional\n"
	 unless defined $args[$i] or $interact>0;
   }
   $interact = @$params && $interact > 0;
   for my $i (0..$#args) {
      eval { $args[$i] = string2pf($args[$i], $params->[$i]); };
      die $@ if $@ and not $interact;
   }
   if ($interact) {
      push @$params, [
	 PF_FILE, 'gimp_fu_outputfile', 'Output file', $latest_imagefile
      ] unless $outputfile;
      (my $res, my $input_vals, undef)=interact(
	$function, $blurb, $help, $params, $menupath, undef, [], \@args
      );
      return unless $res;
      @args = @$input_vals;
      $outputfile = pop @args unless $outputfile;
   }
   my $input_image = $args[0] if ref $args[0] eq "Gimp::Image";
   my @retvals = Gimp::callback(
      '-run', $function, Gimp::RUN_NONINTERACTIVE, @args
   );
   if ($outputfile) {
      my @images = grep { defined $_ and ref $_ eq "Gimp::Image" } @retvals;
      if (@images) {
	 for my $i (0..$#images) {
	    my $path = $outputfile =~ /%d/
	       ? sprintf $outputfile, $i : $outputfile;
	    if (@images > 1 and $path eq $outputfile) {
	       $path=~s/\.(?=[^.]*$)/$i./; # insert number before last dot
	    }
	    save_image($images[$i],$path);
	 }
      } elsif ($input_image) {
	 my $path = $outputfile =~ /%d/
	    ? sprintf $outputfile, 0 : $outputfile;
	 save_image($input_image, $path);
      } else {
	 die "$0: outputfile specified but plugin returned no image and no input image\n" unless $menupath =~ /^<Toolbox>/;
      }
   }
};

sub datatype(@) {
   warn __PACKAGE__."::datatype(@_)" if $Gimp::verbose >= 2;
   for(@_) {
      return Gimp::PDB_STRING unless /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/; # perlfaq4
      return Gimp::PDB_FLOAT  unless /^[+-]?\d+$/; # again
   }
   return Gimp::PDB_INT32;
}

sub param_gimpify {
   my $p = shift;
   return $p if $p->[0] < Gimp::PDB_END;
   my @c = @$p; # copy as modifying
   $c[0] = $pf2info{$p->[0]}->[1] // datatype(values %{+{@{$p->[4]}}});
   \@c;
}

sub procinfo2installable {
   my @c = @_;
   $c[9] = [ map { param_gimpify($_) } @{$c[9]} ];
   unshift @{$c[9]}, [&Gimp::PDB_INT32,"run_mode","Interactive:0=yes,1=no"]
      if defined $c[6];
   @c;
}

Gimp::on_query {
   for my $s (@scripts) { Gimp->install_procedure(procinfo2installable(@$s)); }
};

sub make_ui_closure {
   my ($function, $blurb, $help, $author, $copyright, $date, $menupath,
       $imagetypes, $params, $results, $code) = @_;
   warn "$$-Gimp::Fu::make_ui_closure(@_)\n" if $Gimp::verbose >= 2;
   die "Params must be array, instead: $params\n" unless ref $params eq 'ARRAY';
   die "Retvals must be array, instead: $results\n" unless ref $results eq 'ARRAY';
   die "Callback must be code, instead: $code\n" unless ref $code eq 'CODE';
   sub {
      warn "$$-Gimp::Fu closure: (@_)\n" if $Gimp::verbose >= 2;
      $run_mode = defined($menupath) ? shift : Gimp::RUN_NONINTERACTIVE;
      if (
	 $run_mode != Gimp::RUN_NONINTERACTIVE and
	 $run_mode != Gimp::RUN_INTERACTIVE and
         $run_mode != Gimp::RUN_WITH_LAST_VALS
      ) {
         die __"run_mode must be INTERACTIVE, NONINTERACTIVE or RUN_WITH_LAST_VALS\n";
      }
      my @pre;

      # set default arguments
      for (0..$#{$params}) {
         next if defined $_[$_];
         my $default = $params->[$_]->[3];
         $default = $default->[0] if $params->[$_]->[0] == PF_ADJUSTMENT;
         $_[$_] = $default;
      }

      for($menupath) {
         if (not defined $_ or m#^<Toolbox>#) {
	    # no-op
         } elsif (/^<Image>\//) {
	    if (defined $imagetypes and length $imagetypes) {
	       @_ >= 2 or die __"<Image> plug-in called without both image and drawable arguments!\n";
	       @pre = (shift,shift);
	    }
         } elsif (/^<Load>\//) {
            @_ >= 2 or die __"<Load> plug-in called without the 3 standard arguments!\n";
            @pre = (shift,shift);
         } elsif (/^<Save>\//) {
            @_ >= 4 or die __"<Save> plug-in called without the 5 standard arguments!\n";
            @pre = (shift,shift,shift,shift);
         } elsif (defined $_) {
	    die __"menupath _must_ start with <Image>, <Load>, <Save>, <Toolbox>, or <None>!";
         }
      }
      warn "perlsub: rm=$run_mode" if $Gimp::verbose >= 2;
      warn "$$-Gimp::Fu-generated sub: $function(",join(",",(@pre,@_)),")\n"
	 if $Gimp::verbose >= 2;
      my @retvals;
      if ($run_mode == Gimp::RUN_NONINTERACTIVE) {
	 @retvals = $code->(@pre, @_);
      } else {
         my $fudata = $Gimp::Data{"$function/_fu_data"};
	 if ($fudata) {
	    my $data_savetime = shift @$fudata;
	    my $script_savetime = stat("$RealBin/$RealScript")->mtime;
	    undef $fudata if $script_savetime > $data_savetime;
	 } else {
	    undef $fudata;
	 }
	 if ($Gimp::verbose >= 2) {
	    require Data::Dumper;
	    warn "$$-retrieved fudata: ", Data::Dumper::Dumper($fudata);
	 }
         if ($run_mode == Gimp::RUN_WITH_LAST_VALS && $fudata) {
	    @retvals = $code->(@pre, @$fudata);
         } elsif (!@_) {
	    @retvals = $code->(@pre, @_);
	 } else {
	    # prevent the standard arguments from showing up in interact
	    my @hide = splice @$params, 0, scalar @pre;
	    my ($res, $input_vals, $return_vals) = interact(
	       $function, $blurb, $help, $params, $menupath, $code,
	       \@pre, $fudata,
	    );
	    return (undef) x @$results unless $res;
	    unshift @$params, @hide;
	    @_ = @$input_vals;
	    @retvals = @$return_vals;
         }
	 if ($Gimp::verbose >= 2) {
	    require Data::Dumper;
	    warn "$$-storing fudata: ", Data::Dumper::Dumper(\@_);
	 }
	 $Gimp::Data{"$function/_fu_data"}=[time, @_];
      }
      Gimp->displays_flush;
      wantarray ? @retvals : $retvals[0];
   };
}

sub podregister (&) { unshift @_, ('') x 9; goto &register; }
sub register($$$$$$$$$;@) {
   my @procinfo = fixup_args(@_);
   Gimp::register_callback $procinfo[0] => make_ui_closure(@procinfo);
   push @scripts, [ @procinfo[0..7], Gimp::PLUGIN, @procinfo[8,9] ];
}

sub save_image($$) {
   my($img,$path)=@_;
   warn "saving image $path\n" if $Gimp::verbose >= 2;
   my $flatten=0;
   my $interlace=0;
   my $quality=0.75;
   my $smooth=0;
   my $compress=7;
   my $loop=0;
   my $delay=0;
   my $dispose=0;
   my $noextra=0;

   $_ = $path =~ s/^([^:]+):// ? $1 : "";
   my $type=uc($1) if $path=~/\.([^.]+)$/;
   $type = 'XCF' unless defined $type;
   $type = 'JPG' if $type eq 'JPEG';
   # animation standard support: jpg no, pnm no, gif yes, png yes
   # animation file-*-save support: none
   while($_ ne "") {
      $interlace=$1 eq "+",	next if s/^([-+])I//i;
      $flatten=$1 eq "+",	next if s/^([-+])F//i;
      $noextra=$1 eq "+",	next if s/^([-+])E//i;
      $smooth=$1 eq "+",	next if s/^([-+])S//i;
      $quality=$1*0.01,		next if s/^-Q(\d+)//i;
      $compress=$1,		next if s/^-C(\d+)//i;
      $loop=$1 eq "+",		next if s/^([-+])L//i;
      $delay=$1,		next if s/^-D(\d+)//i;
      $dispose=$1,		next if s/^-P(\d+)//i;
      croak __"$_: unknown/illegal file-save option";
   }
   $img->flatten if $flatten;

   # always save the active layer
   my $layer = $img->get_active_layer;

   if ($type eq "JPG") {
      $layer->file_jpeg_save(
	 $path, $path, $quality, $smooth, 1, $interlace, "", 0, 1, 0, 0
      );
   } elsif ($type eq "GIF") {
      unless ($layer->is_indexed) {
         $img->convert_indexed(2, Gimp::CONVERT_PALETTE_GENERATE, 256, 1, 1, "");
      }
      $layer->file_gif_save($path,$path,$interlace,$loop,$delay,$dispose);
   } elsif ($type eq "PNG") {
      $layer->file_png_save($path,$path,$interlace,$compress,(!$noextra) x 5);
   } elsif ($type eq "PNM") {
      $layer->file_pnm_save($path,$path,1);
   } else {
      $layer->file_save($path,$path);
   }
}

sub main {
   return Gimp::main unless $Gimp::help;
   require Getopt::Long;
   my $proc;
   Getopt::Long::Configure('pass_through');
   Getopt::Long::GetOptions('p=s' => \$proc);
   my $this = find_script($proc);
   print __<<EOF;
       interface-arguments are
           -o | --output <filespec>   write image to disk
           -i | --interact            let the user edit the values first
EOF
   print "           -p <procedure> (one of @{[
      map { $_->[0] =~ s/^(?:perl_fu|plug_in)_//r; } @scripts
   ]})\n" if @scripts > 1;
   print "       script-arguments are\n" if @{($this // [])->[9] // []};
   for(@{($this // [])->[9] // []}) {
      my $type=$pf2info{$_->[0]}->[0];
      my $key=mangle_key($_->[1]);
      my $default_text = defined $_->[3]
	  ? " [".(ref $_->[3] eq 'ARRAY' ? "[@{$_->[3]}]" : $_->[3])."]"
	  : "";
      printf "           --%-24s %s%s\n",
	"$key $type",
	$_->[2],
	$default_text;
   }
   0;
}

1;
__END__

=head1 NAME

Gimp::Fu - Easy framework for Gimp-Perl scripts

=head1 SYNOPSIS

  use Gimp;
  use Gimp::Fu;
  podregister {
    # your code
  };
  exit main;
  __END__
  =head1 NAME

  function_name - Short description of the function

  =head1 SYNOPSIS

  <Image>/Filters/Menu/Location...

  =head1 DESCRIPTION

  Longer description of the function...

=head1 DESCRIPTION

This module provides all the infrastructure you need to write Gimp-Perl
plugins. Dov Grobgeld has written an excellent tutorial for Gimp-Perl.
You can find it at C<http://www.gimp.org/tutorials/Basic_Perl/>.

This distribution comes with many example scripts. One is
C<examples/example-fu.pl>, which is a small Gimp::Fu-script you can take
as a starting point for your experiments. You should be able to run it
from GIMP already by looking at "Filters/Languages/_Perl/Test/Dialog".

Your main interface for using C<Gimp::Fu> is the C<podregister> function.

=head1 PODREGISTER

This:

  podregister {
    # your code
  };

does the same as this:

  register '', '', '', '', '', '', '', '', '', sub {
    # your code
  };

It extracts all the relevant values from your script's POD documentation
- see the section on L</"EMBEDDED POD DOCUMENTATION"> for an
explanation. You will also notice you don't need to provide the C<sub>
keyword, thanks to Perl's prototyping.

=head2 AUTOMATIC PERL PARAMETER INSERTION

Thanks to L<Filter::Simple> source filtering, this C<podregister>-ed
function:

  # the POD "PARAMETERS" section defines vars called "x" and "y"
  # the POD "SYNOPSIS" i.e. menupath starts with "<Image>"
  # the POD "IMAGE TYPES" says "*" - this means image and drawable params too
  podregister {
     # code...
  };

will also have the exact equivalent (because it's literally this) of:

  podregister {
     my ($image, $drawable, $x, $y) = @_;
     # code...
  };

This means if you add or remove parameters in the POD, or change their
order, your code will just continue to work - no more maintaining two
copies of the parameter list. The above is the most common scenario,
but see the L</menupath> for the other possibilities for the variable
names you will be supplied with.

=head1 THE REGISTER FUNCTION

  register
    "function_name",
    "blurb", "help",
    "author", "copyright",
    "date",
    "menupath",
    "imagetypes",
    [
      [PF_TYPE,name,desc,optional-default,optional-extra-args],
      [PF_TYPE,name,desc,optional-default,optional-extra-args],
      # etc...
    ],
    [
      # like above, but for return values (optional)
    ],
    sub { code };

All these parameters except the code-ref can be replaced with C<''>, in
which case they will be substituted with appropriate values from various
sections (see below) of the POD documentation in your script.

It is B<highly> recommended you use the L</PODREGISTER> interface,
unless you wish to have more than one interface (i.e. menu entry) to
your plugin, with different parameters.

=over 2

=item function_name

Defaults to the NAME section of the POD, the part B<before> the first
C<->. Falls back to the script's filename.

The PDB name of the function, i.e. the name under which it will be
registered in the GIMP database. If it doesn't start with "perl_fu_",
"file_", "plug_in_" or "extension_", it will be prepended. If you
don't want this, prefix your function name with a single "+". The idea
here is that every Gimp::Fu plug-in will be found under the common
C<perl_fu_>-prefix.

=item blurb

Defaults to the NAME section of the POD, the part B<after> the first C<->.

A one-sentence description of this script/plug-in.

=item help

Defaults to the DESCRIPTION section of the POD.

A help text describing this script. Should give more information than
C<blurb>.

=item author

Defaults to the AUTHOR section of the POD.

The name (and also the e-mail address if possible!) of the script-author.

=item copyright

Defaults to the LICENSE section of the POD.

The copyright designation for this script. Important! Save your intellectual
rights!

=item date

Defaults to the DATE section of the POD.

The "last modified" date of this script. There is no strict syntax here, but
I recommend ISO format (yyyymmdd or yyyy-mm-dd).

=item menupath

Defaults to the SYNOPSIS section of the POD.

The menu entry GIMP should create. B<Note> this is different from
Script-Fu, which asks only for which B<menu> in which to place the entry,
using the second argument to (its equivalent of) C<register> as the actual
label; here, you spell out the B<full> menu entry including label name.

It should start with one of the following:

=over 2

=item <Image>/*/Plugin-menu-label

If the plugin works on or produces an image.

If the "imagetypes" argument (see below) is defined and non-zero-length,
L<Gimp::Fu> will B<supply parameters>:

=over 2

=item * C<PF_IMAGE> called B<image>

=item * C<PF_DRAWABLE> called B<drawable>

=back

as the first parameters to the plugin.

If the plugin is intending to create an image rather than to work on
an existing one, make sure you supply C<undef> or C<""> as the
"imagetypes". In that case, L<Gimp::Fu> will supply a C<PF_IMAGE> return
value if the first return value is not a C<PF_IMAGE>.

In any case, the plugin will be installed in the specified menu location;
almost always under C<File/Create> or C<Filters>.

=item <Load>/Text describing input/file-extensions[/prefixes]

The file-extensions are comma-separated. The prefixes are optional.

Gimp::Fu will automatically register the plugin as a load-handler using
C<Gimp-E<gt>register_load_handler>.

L<Gimp::Fu> will B<supply parameters>:

=over 2

=item * C<PF_STRING> called B<filename>

=item * C<PF_STRING> called B<raw_filename>

=back

as the first parameters to the plugin. It will also automatically add
a return-value which is a C<PF_IMAGE>, unless there is already such a
value as first return value.

=item <Save>/Text describing output/file-extensions[/prefixes]

The file-extensions are comma-separated. The prefixes are optional.

Gimp::Fu will automatically register the plugin as a save-handler using
C<Gimp-E<gt>register_save_handler>. This is not (in GIMP 2.8 terms)
a save-handler anymore, but an export-handler.

L<Gimp::Fu> will B<supply parameters>:

=over 2

=item * C<PF_IMAGE> called B<image>

=item * C<PF_DRAWABLE> called B<drawable>

=item * C<PF_STRING> called B<filename>

=item * C<PF_STRING> called B<raw_filename>

=back

as the first parameters to the plugin.

Outline:

  podregister {
    my $export = Gimp::UI::export_image(
      my $new_image=$image,
      my $new_drawable=$drawable,
      "COLORHTML",
      EXPORT_CAN_HANDLE_RGB
    );
    return if $export == EXPORT_CANCEL;
    # ...
    $new_image->delete if $export == EXPORT_EXPORT;
  };

=item <Toolbox>/Label

This type of plugin will not have the image and drawable passed, nor
will it require (or return) it. It I<will> still have a C<run_mode> added.

=item <None>

If the script does not need to have a menu entry.

=back

=item imagetypes

Defaults to the "IMAGE TYPES" section of the POD.

The types of images your script will accept. Examples are "RGB", "RGB*",
"GRAY, RGB" etc... Most scripts will want to use "*", meaning "any type".
Either C<undef> or "" will mean "none". Not providing the relevant POD
section is perfectly valid, so long as you intend to create and return
an image.

=item the parameter array

Defaults to the "PARAMETERS" section of the POD, passed to C<eval>, e.g.:

  =head PARAMETERS

    [ PF_COLOR, 'color', 'Colour', 'black' ],
    [ PF_FONT, 'font', 'Font', 'Arial' ],

You don't B<have> to indent it so that POD treats it as verbatim, but
it will be more readable in the Help viewer if you do.

An array reference containing parameter definitions. These are similar to
the parameter definitions used for C<gimp_install_procedure> but include an
additional B<default> value used when the caller doesn't supply one, and
optional extra arguments describing some types like C<PF_SLIDER>.

Each array element has the form C<[type, name, description, default_value,
extra_args]>.

<Image>-type plugins get two additional parameters, image (C<PF_IMAGE>)
and drawable (C<PF_DRAWABLE>) B<if and only if> the "image types"
are defined and non-zero-length. Do not specify these yourself - see
the C<menupath> entry above. Also, the C<run_mode> argument is never
given to the script but its value can be accessed in the package-global
C<$Gimp::Fu::run_mode>. The B<description> will be used in the dialog
box as a label.

See the section PARAMETER TYPES for the supported types.

The default values have an effect when called from a menu in GIMP, and
when the script is called from the command line. However, they have a
limited effect when called from Gimp::Net; data types that do not have
an "invalid" value, like text does, may not be passed as an undefined
value; this is because while Perl can use C<undef> instead of anything,
GIMP cannot. For instance, it is possible to pass a C<PF_STRING> as
undef, which will then be set to the supplied default value, but not
a C<PF_COLOR>.

=item the return values

Defaults to the "RETURN VALUES" section of the POD, passed to C<eval>.
Not providing the relevant POD section is perfectly valid, so long as
you intend to return no values.

This is just like the parameter array except that it describes the
return values. Specify the type, variable name and description only. This
argument is optional. If you wish your plugin to return an image, you
must specify that (unless your "image types" is false, see below), e.g.:

  use Gimp;
  use Gimp::Fu;
  register
     'function_name', "help", "blurb", "author", "copyright", "2014-04-11",
     "<Image>/Filters/Render/Do Something...",
     "*",
     [ [PF_INT32, "imagesize", "Image size", 1] ],
     [ [PF_IMAGE, "output image", "Output image"] ],
     sub { Gimp::Image->new($_[0], $_[0], RGB) };

If your "image types" is false, then L<Gimp::Fu> will ensure your first
return parameter is a C<PF_IMAGE>. If for some reason you need to return
an image value that will satisfy the requirement to return the right
number of values but is invalid, you can return either -1 or C<undef>.

You B<must> return the correct number (and types) of values from your
function.

=item the code

This is either an anonymous sub declaration (C<sub { your code here; }>, or a
coderef, which is called when the script is run. Arguments (including the
image and drawable for <Image> plug-ins) are supplied automatically.

You B<must> make sure your plugin returns the correct types of value, or none:

 sub {
   # no return parameters were specified
   ();
 };

If you want to display images, you must have your script do
that. Gimp::Fu will no longer automatically do that for you, so your
plugins will thereby be good GIMP "citizens", able to fit in with
plugins/filters written in other languages.

=back

=head1 PARAMETER TYPES

=over 2

=item PF_INT8, PF_INT16, PF_INT32

All mapped to sliders or spinners with suitable min/max.

=item PF_FLOAT, PF_VALUE

For C<PF_FLOAT> (or C<PF_VALUE>, a synonym), you should probably use a
C<PF_SPINNER> or C<PF_SLIDER> with suitable values.

=item PF_STRING

A string.

=item PF_COLOR, PF_COLOUR

Will accept a colour argument. In dialogs, a colour preview will be created
which will open a colour selection box when clicked. The default value
needs to be a suitable Gimp-Perl colour; see
L<Gimp/"Gimp::canonicalize_colour">.

 [ PF_COLOR, 'colour', 'Input colour', 'white' ],
 [ PF_COLOR, 'colour2', 'Input colour 2', [ 255, 128, 0 ] ],

=item PF_IMAGE

A GIMP image.

=item PF_DRAWABLE

A GIMP drawable (channel or layer).

=item PF_TOGGLE, PF_BOOL

A boolean value (anything Perl would accept as true or false).

=item PF_SLIDER

Uses a horizontal scale. To set the range and stepsize, append an
array ref (see L<Gtk2::Adjustment> for an explanation) C<[range_min,
range_max, step_size, page_increment, page_size]> as "extra argument"
to the description array.  Default values will be substituted for missing
entries, like in:

 [PF_SLIDER, "alpha value", "the alpha value", 100, [0, 255, 1] ]

=item PF_SPINNER

The same as PF_SLIDER, except that this one uses a spinbutton instead of a
scale.

=item PF_RADIO

In addition to a default value, an extra argument describing the various
options I<must> be provided. That extra argument must be a reference
to an array filled with C<Option-Name =E<gt> Option-Value> pairs. Gimp::Fu
will then generate a horizontal frame with radio buttons, one for each
alternative. For example:

 [PF_RADIO, "direction", "direction to move to", 5, [Left => 5,  Right => 7]]]

draws two buttons, when the first (the default, "Left") is activated, 5
will be returned. If the second is activated, 7 is returned.

=item PF_FONT

Lets the user select a font whose name is returned as a string.

=item PF_BRUSH, PF_PATTERN, PF_GRADIENT

Lets the user select a brush/pattern/gradient whose name is returned as a
string. The default brush/pattern/gradient-name can be preset.

=item PF_CUSTOM

Example:

  [PF_CUSTOM, "direction", "Direction to fade(0-8)", 4, sub {
    my $btnTable = new Gtk2::Table(3,3,1);
    $btnTable->set_border_width(6);
    my $btn = new Gtk2::RadioButton;
    my ($u_direction, @buttons);
    for (my $x=0;$x<3;$x++) {
      for (my $y=0;$y<3;$y++) {
	my $dir = $x*3 + $y;
	$buttons[$dir] = $btn = Gtk2::RadioButton->new_from_widget($btn);
	$btn->set_mode(0);
	$btn->signal_connect("clicked", sub { $u_direction = $_[1]; }, $dir);
	$btn->show;
	$btnTable->attach_defaults($btn, $x, $x+1, $y, $y+1);
	my $pixmap = Gtk2::Image->new_from_pixmap(
	  Gtk2::Gdk::Pixmap->colormap_create_from_xpm_d(
	    undef, $btn->get_colormap,
	    $btn->style->bg('normal'), @{$arr[$dir]}
	  )
	);
	$pixmap->show;
	$btn->add($pixmap);
      }
    }
    $btnTable->show;
    ($btnTable, sub { $buttons[$_[0]]->clicked }, sub { $u_direction });
  },],

C<PF_CUSTOM> is for those of you requiring some non-standard-widget. You
supply a reference to code returning three values as the extra argument:

=over 2

=item C<widget>

Gtk2 widget that should be used.

=item C<settor>

Function that takes a single argument, the new value for the widget
(the widget should be updated accordingly).

=item C<gettor>

Function returning the current value of the widget.

=back

The value set and returned must be a string. For an example of this,
see C<examples/example-no-fu>.

=item PF_FILE

This represents a file system object. It usually is a file, but can be
anything (directory, link). It might not even exist at all.

=item PF_TEXT

Similar to PF_STRING, but the entry widget is much larger and has Load,
Save, and Edit (in external editor) buttons.

=back

=head1 EMBEDDED POD DOCUMENTATION

Gimp::Fu uses the Gimp::Pod module to access POD sections that are
embedded in your scripts (see L<perlpod> for an explanation of the POD
documentation format) when the user hits the "Help" button in the dialog
box. More importantly, various sections of the POD can be used instead
of hardcoding strings in the call to C<register>.

Most of the mentioned arguments have default values (see
L</"THE REGISTER FUNCTION">) that are used when the arguments are
undefined or false, making the register call itself much shorter.

=head1 MISCELLANEOUS FUNCTIONS

=over 2

=item C<save_image(img,options_and_path)>

This is the internal function used to save images, which does more than
C<gimp_file_save>.

The C<img> is the GIMP image you want to save (which might get changed
during the operation!), C<options_and_path> denotes the filename and
possibly options. If there are no options, C<save_image> tries to deduce
the filetype from the extension. The syntax for options is

 [OPTIONS...:]filespec

 options valid for all images
 +F	flatten the image
 -F	do not flatten the image (default)

 options for GIF and PNG images
 +I	do save as interlaced
 -I	do not save as interlaced (default)

 options for GIF animations (use with -F)
 +L	save as looping animation
 -L	save as non-looping animation (default)
 -Dn	default frame delay (default is 0)
 -Pn	frame disposal method: 0=don't care, 1 = combine, 2 = replace

 options for PNG images
 -Cn	use compression level n
 -E	Do not skip ancillary chunks (default)
 +E	Skip ancillary chunks

 options for JPEG images
 -Qn	use quality "n" to save file (JPEG only)
 -S	do not smooth (default)
 +S	smooth before saving

Some examples:

 test.jpg	save the image as a simple JPEG
 -Q70:test.jpg	the same but force a quality of 70
 -I-F:test.gif	save a GIF image, non-interlaced and without flattening

You can specify a file with extension C<.xcf>, which will save in XCF format.

=back

=head1 COMMAND LINE USAGE

Your scripts can immediately be used from the command line. E.g.

  /usr/local/lib/gimp/2.0/plug-ins/example-fu -i

Use the C<--help> flag to see the available options:

  Usage: .../example-fu [gimp-args..] [interface-args..] [script-args..]
	 gimp-arguments are
	     -h | -help | --help | -?   print some help
	     -v | --verbose             be more verbose in what you do
	     --host|--tcp HOST[:PORT]   connect to HOST (optionally using PORT)
					(for more info, see Gimp::Net(3))
	 interface-arguments are
	     -o | --output <filespec>   write image to disk
	     -i | --interact            let the user edit the values first
	 script-arguments are
	     --width number             Image width [360]
	     --height integer           Image height [100]
	     --text string              Message [example text]
	     --longtext string          Longer text [more example text]
	     --bordersize integer (32-bit) Border size [10]
	     --borderwidth number       Border width [0.2]
	     --font font                Font
	     --text_colour colour       Text colour [[10 10 10]]
	     --bg_colour colour         Background colour [[255 128 0]]
	     --ignore_cols boolean      Ignore colours [0]
	     --extra_image image        Additional picture to ignore
	     --extra_draw drawable (%[filename:]number or %a = active) Something to ignore as well
	     --type data                Effect type [0]
	     --a_brush brush            An unused brush
	     --a_pattern pattern        An unused pattern
	     --a_gradients gradient     An unused gradients

You may notice that the C<drawable> above offers the option of
"%[filename:]number" (or "%a") - this means you can specify which drawable
by numeric ID, or if specified as C<%filename:number>, Gimp::Fu will
open that file and set the parameter to the C<number>th layer (starting
from zero). From the command line, C<image> may be specified either as
"%number" or as a filename.

If interactive mode is chosen (either by specifying the command-line
flag, or not giving all the arguments), and no output file is given,
Gimp::Fu will add a parameter to get an output file.

If the C<--output> option is given, the argument will be passed to
C<save_image>. This means you can specify various options on how you
want the image to be saved/converted, as part of the "filename".

=head1 AUTHOR

Marc Lehmann <pcg@goof.com>

=head1 SEE ALSO

perl(1), L<Gimp>.
