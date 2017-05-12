#
#===============================================================================
#
#         FILE: GnuplotIF.pm
#
#  DESCRIPTION:  A simple and easy to use Perl interface to gnuplot.
#                (see POD below)
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Dr. Fritz Mehner (fgm), mehner.fritz@web.de
#      VERSION: 1.0
#      CREATED: 02.01.2016 11:31
#      VERSION:  see $VERSION below
#      CREATED:  16.07.2005 13:43:11 CEST
#     REVISION: ---
#===============================================================================

use strict;

package Graphics::GnuplotIF;

use strict;
use warnings;
use Carp;
use Cwd;
use File::Spec;
use IO::Handle;

our $VERSION     = '1.8';                       # version number

use base qw(Exporter);
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

# Symbols to be exported by default
@EXPORT_OK     = ( 'GnuplotIF' );

#---------------------------------------------------------------------------
#  Code common to gnuplot_plot_xy and gnuplot_plot_y to allow user-specified
#  titles set by gnuplot_set_plot_titles.  This code assumes the plot titles
#  were all set in the command to the literal text "<PLOT_TITLE>", without any
#  surrounding quotes.  This function replaces that text.
#---------------------------------------------------------------------------
my $private_apply_plot_titles = sub {
    my ($self, $cmd_ref)   = @_;
    my $default_plot_title = q{-};              # Title if user did not specify one
    if (defined $self->{plot_titles} ) {
        #  Substitute each plot title sequentially with the user-supplied value
        for my $plot_title (@{$self->{plot_titles}}) {
            if ( !defined $plot_title ) {
                $plot_title = $default_plot_title;
            }
            ${$cmd_ref} =~ s/title <PLOT_TITLE>/title "$plot_title"/;
        }
    }

    # Substitute any plot titles we did not already catch globally
    ${$cmd_ref} =~ s/title <PLOT_TITLE>/title "$default_plot_title"/g;
};

#---------------------------------------------------------------------------
#  Code generates a file comment for a plot script.
#---------------------------------------------------------------------------
my $private_plot_script_header  = sub {
    my  ( $self )   = @_;
    my  $localtime  = scalar localtime;

    my  $comment;
    ($comment = <<"END") =~ s/^\s+//gm;
    #
    # This file is a GNUPLOT plot script.
    # It was generated automatically by '${0}'
    # using the Graphics::GnuplotIF extension to perl.
    # Creation time : ${localtime}
    #
END

    $self->gnuplot_cmd( $comment );
    return;
};

#---------------------------------------------------------------------------
#  warn if unix and there is no graphic display
#---------------------------------------------------------------------------
if (($^O ne 'MSWin32') and ($^O ne 'cygwin')) {
  if ( ! $ENV{'DISPLAY'} ) {
    warn "Graphics::GnuplotIF : cannot find environment variable DISPLAY \n"
  }
}

#===  FUNCTION  ================================================================
#         NAME:  new
#  DESCRIPTION:  constructor
# PARAMETER  1:  anonymous hash containing some plot parameter (defaults shown):
#                 style   => "lines"
#                 title   => "",
#                 xlabel  => "",
#                 ylabel  => "",
#                 xrange  => [],
#                 yrange  => [],
#             scriptfile  => "",
#                persist  => 0,
#             objectname  => "",
#      RETURNS:  object reference
#===============================================================================
{
    my  $object_number  = 0;                    # number of objects created

    sub new {

        my  ( $class, %args ) = @_;

        my  $self   = {
	    program         => 'gnuplot', # something like 'C:\gnuplot\binaries\gnuplot.exe' on Windows
            style           => 'lines',
            title           => q{},
            xlabel          => q{},
            ylabel          => q{},
            xrange          => [],
            yrange          => [],
            plot_titles     => [],
            scriptfile      => q{},
            persist         => 0,
            objectname      => q{},
            silent_pause    => 1,
            plot_also       => 0,
	    no_error_log    => 0,
            %args,
            __pausetime     => -1,
            __pausemess     => q{},
            __objectnumber  => ++$object_number,
            __plotnumber    => 1,
            __error_log     => q{},
	    __iohandle_pipe => undef,
            __iohandle_file => undef,
        };
	## if {program} is a fully resolved path and the gnuplot
	## executable is installed someplace that has a space in it,
	## such as "/home/bruce/a b" or "C:\Program Files\Gnuplot",
	## the space will confuse the system call to open the pipe,
	## very likely resulting in an error like "Couldn't write to
	## pipe: Broken pipe at ..."
	##
	## a solution to this is to "escape" the space by surrounding
	## the executable name with double quotes.  This method of
	## escaping the space is chosen because it works on both
	## unix-like and Windows.  Take care, though, not to duplicate
	## the double quotes, on the off chance that the caller
	## supplies them.
	$self->{program} = q{"}.$self->{program} if $self->{program} !~ m{\A"};
	$self->{program} = $self->{program}.q{"} if $self->{program} !~ m{"\z};

        bless $self, $class ;

        # let plot windows survive after gnuplot exits
        my  $persist    = q{};
        if ( $self->{persist} == 1 ) {
            $persist    = '-persist';
        }

	## if the current working directory has a space in it, such as
	## "/home/bruce/a b", the space will confuse the system call
	## to open the pipe, very likely resulting in an error like
	## "Couldn't write to pipe: Broken pipe at ..."
	##
	## a solution to this is to "escape" the space by surrounding
	## the log file name with double quotes.  This method of
	## specifying the fully resolved log file location /and/
	## escaping the space is chosen because it works on both
	## unix-like and Windows.
	##
	## Using Path::Class would be great, but File::Spec is a
	## standard module
        $self->{__error_log} =
	  q{"} .
	  File::Spec->catfile(cwd(), ".gnuplot.${$}.${object_number}.stderr.log") .
	  q{"};

        #-------------------------------------------------------------------------------
        #  open pipe
        #-------------------------------------------------------------------------------
        if ( $self->{scriptfile} eq q{} || ( $self->{scriptfile} ne q{} && $self->{plot_also} != 0 ) ) {
	    if ( $self->{no_error_log} ) {
	       open $self->{__iohandle_pipe}, '|- ', $self->{program}." ${persist}"
		 or die "\n$0 : failed to open pipe to \"gnuplot\" : $!\n";
	    } else {
	       open $self->{__iohandle_pipe}, '|- ', $self->{program}." ${persist} 2> $self->{__error_log}"
		 or die "\n$0 : failed to open pipe to \"gnuplot\" : $!\n";
	    }
	    $self->{__iohandle_pipe}->autoflush(1);
        }
        #-------------------------------------------------------------------------------
        #  open script file
        #-------------------------------------------------------------------------------
        if ( $self->{scriptfile} ne q{} ) {
            open $self->{__iohandle_file}, '>', $self->{scriptfile}
                or die "\n$0 : failed to open file \"$self->{scriptfile}\" : $!\n";
        }

        $self->$private_plot_script_header();
        $self->gnuplot_set_style (   $self->{style }  );
        $self->gnuplot_set_title (   $self->{title }  );
        $self->gnuplot_set_xlabel(   $self->{xlabel}  );
        $self->gnuplot_set_ylabel(   $self->{ylabel}  );
        $self->gnuplot_set_xrange( @{$self->{xrange}} );
        $self->gnuplot_set_yrange( @{$self->{yrange}} );

        return $self;
    } # ----------  end of subroutine new  ----------
}

#===  CLASS METHOD  ============================================================
#         NAME:  GnuplotIF
#      PURPOSE:  constructor - short form
#   PARAMETERS:  see new
#===============================================================================
sub GnuplotIF {
    my  @args   = @_;
    return __PACKAGE__->new(@args);
}   # ----------  end of subroutine GnuplotIF  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  DESTROY
#      PURPOSE:  destructor - close pipe or file
#   PARAMETERS:  ---
#===============================================================================
sub DESTROY {
    my  $self = shift;
    #---------------------------------------------------------------------------
    #  close pipe to gnuplot / close the script file
    #---------------------------------------------------------------------------
    if ( defined $self->{__iohandle_pipe} && !close $self->{__iohandle_pipe} ) {
            print { *STDERR } "Graphics::GnuplotIF (object $self->{__objectnumber}): "
            ."problem closing communication to gnuplot\n";
    }
    if ( defined $self->{__iohandle_file} && !close $self->{__iohandle_file} ) {
            print { *STDERR } "Graphics::GnuplotIF (object $self->{__objectnumber}): "
            ."problem closing file $self->{scriptfile}\n";
    }
    #---------------------------------------------------------------------------
    #  remove empty error logfiles, if any
    #---------------------------------------------------------------------------
    my  @stat   = stat $self->{__error_log};

    if ( defined $stat[7] && $stat[7]==0 ) {
        unlink $self->{__error_log}
            or croak "Couldn't unlink $self->{__error_log}: $!"
    }
    return;
} # ----------  end of subroutine DESTROY  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_set_style
#      PURPOSE:  Sets one of the allowed line styles in a plot command.
#   PARAMETERS:  plotstyle (string)
#      RETURNS:  ---
#     SEE ALSO:  new()
#===============================================================================
{
    my  %linestyles =                               # allowed line styles
    (
        boxes       => q{},
        dots        => q{},
        filledcurves=> q{},
        fsteps      => q{},
        histeps     => q{},
        impulses    => q{},
        lines       => q{},
        linespoints => q{},
        points      => q{},
        steps       => q{},
    );

    sub gnuplot_set_style {
        my  $self   = shift;
        my  $style  = shift;
        if ( defined $style && exists $linestyles{$style} ) {
            $self->{style}  = $style;
        }
        return;
    } # ----------  end of subroutine gnuplot_set_style  ----------
}

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_plot_y
#      PURPOSE:  Plot one or more arrays over 0, 1, 2, 3, ...
#   PARAMETERS:  array reference(s)
#      RETURNS:  ---
#===============================================================================
sub gnuplot_plot_y {
    my  ( $self, @yref )  = @_;
    my  $parnr  = 0;
    my  $cmd  = " '-' with $self->{style} title <PLOT_TITLE>,\\\n" x (scalar @yref);
    $cmd =~ s/,\\$//s;
    $self->$private_apply_plot_titles(\$cmd); # Honor gnuplot_set_plot_titles
    return $self if $cmd eq q{};

    $self->gnuplot_cmd( "plot \\\n$cmd\n" );

    foreach my $item ( @yref ) {
        $parnr++;
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_y : $parnr. "
          ."argument not an array reference\n"
          if ref($item) ne 'ARRAY';
        $self->gnuplot_cmd( join( "\n", @{$item}), 'e' );
    }       # -----  end foreach  -----
    $self->{__plotnumber}++;
    return $self;
} # ----------  end of subroutine gnuplot_plot_y  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_plot_xy
#      PURPOSE:  x-y-plot(s)
#   PARAMETERS:  1. array reference : x-values
#                2. array reference : y-values
#                 ...
#      RETURNS:  ---
#  DESCRIPTION:  Takes two or more array references. The first array is assumed
#                to contain the x-values for the following function values.
#===============================================================================
sub gnuplot_plot_xy {
    my  ( $self, $xref, @yref )   = @_;
    my  $parnr  = 1;
    my  $cmd  = " '-' using 1:2 with $self->{style} title <PLOT_TITLE>,\\\n" x (scalar @yref);
    $cmd =~ s/,\\\n$//s;
    $self->$private_apply_plot_titles(\$cmd); # Honor gnuplot_set_plot_titles
    return $self if $cmd eq q{};

    $self->gnuplot_cmd( "plot \\\n$cmd\n" );

    die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_xy : $parnr. "
    ."argument not an array reference\n"
    if ref($xref) ne 'ARRAY';

    foreach my $j ( 0..$#yref ) {
        $parnr++;
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_xy - "
        ."$parnr. argument not an array reference\n"
        if ref($yref[$j]) ne 'ARRAY';

        # there may be lesser y-values than x-values

        my  $min    = $#{$xref} < $#{$yref[$j]}  ?  $#{$xref}  :  $#{$yref[$j]};
        foreach my $i ( 0..$min ) {
            $self->gnuplot_cmd( "$$xref[$i] $yref[$j]->[$i]" );
        }
        $self->gnuplot_cmd( 'e' );
    }
    $self->{__plotnumber}++;
    return $self;
} # ----------  end of subroutine gnuplot_plot_xy  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_plot_many
#      PURPOSE:  x-y-plot(s) not sharing an x-axis
#   PARAMETERS:  1. array reference1 : x-values
#                2. array reference1 : y-values
#               (3. array reference2 : x-values)
#               (4. array reference2 : y-values)
#                 ...
#      RETURNS:  ---
#  DESCRIPTION:  Takes pairs of array references. The first array in each pair
#                is assumed to contain the x-values and the second pair is
#                assumed to contain y-values
#===============================================================================
sub gnuplot_plot_many {
    my ( $self, @array_refs ) = @_;

    my $parnr = 0;
    my $cmd   = " '-' using 1:2 with $self->{style} title <PLOT_TITLE>,\\\n" x
        ( ( scalar @array_refs ) / 2 );
    $cmd =~ s/,\\\n$//s;
    $self->$private_apply_plot_titles( \$cmd );    # Honor gnuplot_set_plot_titles
    return $self if $cmd eq q{};

    $self->gnuplot_cmd("plot \\\n$cmd\n");

    while (@array_refs) {
        my $xxr = shift @array_refs;
        $parnr++;
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_many - "
            . "$parnr. argument not an array reference\n"
            if ref($xxr) ne 'ARRAY';
        my $yyr = shift @array_refs;
        $parnr++;
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_many - "
            . "$parnr. argument not an array reference\n"
            if ref($yyr) ne 'ARRAY';

        # there may be fewer y-values than x-values

        my $min = $#{$xxr} < $#{$yyr} ? $#{$xxr} : $#{$yyr};
        foreach my $i ( 0 .. $min ) {
            $self->gnuplot_cmd("$$xxr[$i] $$yyr[$i]");
        }
        $self->gnuplot_cmd('e');
    }
    $self->{__plotnumber}++;
    return $self;
}    # ----------  end of subroutine gnuplot_plot_many  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_plot_xy_style
#      PURPOSE:  x-y-plot(s) with each graph using individual settings
#   PARAMETERS:  1. array reference : x-values
#                2. hash reference : (y-values, y-style)
#                 ...
#      RETURNS:  ---
#  DESCRIPTION:  Takes one array reference and one or more hash references.
#                The first array is assumed to contain the x-values for the
#                following function values. The following hashes are assumed
#                to contain pairs of values and settings.
#===============================================================================
sub gnuplot_plot_xy_style {
    my  ( $self, $xref, @yref )   = @_;
    my  $parnr  = 1;
    my  ( $cmd, @cmd );

    foreach my $j ( 0..$#yref ) {
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_xy_style - "
        .($parnr + $j + 1).". argument not a suitable hash reference\n"
        if ! (ref($yref[$j]) eq 'HASH'
        && exists $yref[$j]->{'style_spec'} && exists $yref[$j]->{'y_values'});

        push @cmd, " '-' using 1:2 with $yref[$j]->{'style_spec'} title <PLOT_TITLE>";
    }
    $cmd = join ", \\\n", @cmd;
    $self->$private_apply_plot_titles(\$cmd); # Honor gnuplot_set_plot_titles
    return $self if $cmd eq q{};

    $self->gnuplot_cmd( "plot \\\n$cmd" );

    die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_xy_style : $parnr. "
    ."argument not an array reference\n"
    if ref($xref) ne 'ARRAY';

    foreach my $j ( 0..$#yref ) {
        $parnr++;
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_xy_style - "
        ."$parnr. argument is missing an array reference\n"
        if ref($yref[$j]->{'y_values'}) ne 'ARRAY';

        # there may be lesser y-values than x-values

        my  $min    = $#{$xref} < $#{$yref[$j]->{'y_values'}}
                    ? $#{$xref}
                    : $#{$yref[$j]->{'y_values'}};
        foreach my $i ( 0..$min ) {
            $self->gnuplot_cmd( "$$xref[$i] $yref[$j]->{'y_values'}->[$i]" );
        }
        $self->gnuplot_cmd( 'e' );
    }
    $self->{__plotnumber}++;
    return $self;
} # ----------  end of subroutine gnuplot_plot_xy_style  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_plot_many_style
#      PURPOSE:  x-y-plot(s) not sharing an x-axis using individual settings
#   PARAMETERS:  1. hash reference1 : (x-values, y-values, y-style)
#                2. hash reference2 : (x-values, y-values, y-style)
#                 ...
#      RETURNS:  ---
#  DESCRIPTION:  Takes array of hash references. The hashes are assumed
#                to contain x- and y-values and settings.
#===============================================================================
sub gnuplot_plot_many_style {
    my  ( $self, @hash_refs )   = @_;
    my  $parnr  = 0;
    my  ( $cmd, @cmd );

    foreach my $rh (@hash_refs) {
        $parnr++;
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_many_style - "
        .($parnr).". argument not a suitable hash reference\n"
        if ! (   ref($rh) eq 'HASH'
              && exists $rh->{'style_spec'}
              && exists $rh->{'x_values'}
              && exists $rh->{'y_values'}
         );
        my $style = $rh->{'style_spec'};
        push @cmd, " '-' using 1:2 with $style title <PLOT_TITLE>";
    };
    $cmd = join ", \\\n", @cmd;
    $self->$private_apply_plot_titles(\$cmd); # Honor gnuplot_set_plot_titles
    return $self if $cmd eq q{};
    $self->gnuplot_cmd( "plot \\\n$cmd\n" );

    $parnr  = 0;
    foreach my $rh (@hash_refs) {
        my $xref   = $rh->{'x_values'};
        my $yref   = $rh->{'y_values'};
        $parnr++;
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_many_style - "
        ."$parnr. 'x_values' argument not an array reference\n"
        if ref($xref) ne 'ARRAY';
        die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_many_style - "
        ."$parnr. 'y_values' argument not an array reference\n"
        if ref($yref) ne 'ARRAY';

        # there may be fewer y-values than x-values
        my  $min    = $#{$xref} < $#{$yref}  ?  $#{$xref}  :  $#{$yref};
        foreach my $i ( 0..$min ) {
            $self->gnuplot_cmd( "$$xref[$i] $$yref[$i]" );
        }
        $self->gnuplot_cmd( 'e' );
    }
    $self->{__plotnumber}++;
    return $self;
} # ----------  end of subroutine gnuplot_plot_many_style  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_plot_equation
#      PURPOSE:  Plot one or more functions described by strings.
#   PARAMETERS:  strings describing functions
#      RETURNS:  ---
#===============================================================================
sub gnuplot_plot_equation {
    my  ( $self, @equations ) = @_;
    my  $leftside;
    my  @leftside;

    foreach my $equ ( @equations ) {
        $self->gnuplot_cmd( "$equ" );
        ( $leftside ) = split /=/, $equ;
        push @leftside, $leftside;
    }       # -----  end foreach  -----
    @leftside = map  {$_." with $self->{style}"} @leftside;
    $leftside = join ', ', @leftside;
    return $self if $leftside eq q{};
    $self->gnuplot_cmd( "plot $leftside" );
    $self->{__plotnumber}++;
    return $self;
} # ----------  end of subroutine gnuplot_plot_equation  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_plot_3d
#      PURPOSE:  Draw 3-d plots.
#   PARAMETERS:  Reference to a 2-D-matrix containing the z-values.
#      RETURNS:  ---
#===============================================================================
sub gnuplot_plot_3d {
    my  ( $self, $arrayref )  = @_;
    my  $parnr  = 0;
    my  $cmd  = " '-' matrix with $self->{style} title <PLOT_TITLE>," ;
    $cmd =~ s/,$//;
    $self->$private_apply_plot_titles(\$cmd); # Honor gnuplot_set_plot_titles
    return $self if $cmd eq q{};

    $self->gnuplot_cmd( "splot $cmd" );

    die "Graphics::GnuplotIF (object $self->{__objectnumber}): gnuplot_plot_3d : "
        ."argument not an array reference\n"
    if ref($arrayref) ne 'ARRAY';

    foreach my $i ( @{$arrayref} ) {
        $self->gnuplot_cmd( join q{ }, @{$i} ) ;
    }
    $self->gnuplot_cmd( "\ne" );

    $self->{__plotnumber}++;
    return $self;
} # ----------  end of subroutine gnuplot_plot_3d  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_pause
#      PURPOSE:  Wait a specified amount of time.
#   PARAMETERS:  1. parameter (optional): time value (seconds):
#                   -1  do not wait
#                    0  wait for a carriage return
#                   >0  wait the specified number of seconds
#                2. parameter (optional): text
#                   message to display
#      RETURNS:  ---
#===============================================================================
sub gnuplot_pause {
    my  ( $self, $pause, $message ) = @_;

    $self->{__pausetime}    = 0;                # default: wait for a carriage return
    if ( defined $pause && $pause =~ m/^[+-]?(\d+|\d+\.\d*|\d*\.\d+)$/x ) {
        $self->{__pausetime}    = $pause;
    }
    if ( defined $message && $message ne q{} ) {
        $self->{__pausemess}    = "\"$message\"";
    }
    my  $msg0 = "Graphics::GnuplotIF (object $self->{__objectnumber}):  $self->{__pausemess}  --  ";
    my  $msg1 = "hit RETURN to continue \n";
    my  $msg2 = "wait $self->{__pausetime} second(s) \n";
    if ( $self->{__pausetime} == 0 ) {
        print "$msg0$msg1";
        my $dummy = <>;                         # hit RETURN to go on
    }
    elsif ( $self->{__pausetime} < 0 ) {
      $self->gnuplot_cmd("\n");
    }
    else {
        if ( $self->{silent_pause} == 1 ) {
            print "$msg0$msg2";
        }
        $self->gnuplot_cmd( "pause $self->{__pausetime}" );
    }
    return $self;
}   # ----------  end of subroutine gnuplot_pause  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_cmd
#      PURPOSE:  Pass on one or more Gnuplot commands.
#   PARAMETERS:  string(s)
#      RETURNS:  ---
#===============================================================================
sub gnuplot_cmd {
    my  ($self, @commands)  = @_;
    @commands = map {$_."\n"} @commands;
    if ( defined $self->{__iohandle_pipe} ) {
        print { $self->{__iohandle_pipe} } @commands
            or croak "Couldn't write to pipe: $!";
    }
    if ( defined $self->{__iohandle_file} ) {
        print { $self->{__iohandle_file} } @commands
            or croak "Couldn't write to file $!";
    }
    return $self;
} # ----------  end of subroutine gnuplot_cmd  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_hardcopy
#      PURPOSE:  Write a plot into a file.
#   PARAMETERS:  1. file name
#                2. gnuplot terminal type
#                3. terminal settings (optional)
#      RETURNS:  ---
#===============================================================================
sub gnuplot_hardcopy {
    my  ($self, $filename, $terminal, @keywords)  = @_;

    # remember the current terminal including its settings
    $self->gnuplot_cmd( 'set terminal push' );

    my  $set_terminal   = "set terminal $terminal @keywords\n";
    my  $set_output     = "set output \"$filename\"\n";
    $self->gnuplot_cmd( $set_terminal, $set_output );
    return $self;
} # ----------  end of subroutine gnuplot_hardcopy  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_restore_terminal
#      PURPOSE:  Restore the terminal settings before the last hardcopy.
#   PARAMETERS:  ---
#      RETURNS:  ---
#===============================================================================
sub gnuplot_restore_terminal {
    my  ($self)  = @_;
    $self->gnuplot_cmd( 'set output', 'set terminal pop' );
    return $self;
} # ----------  end of subroutine gnuplot_restore_terminal  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_set_plot_titles
#      PURPOSE:  Sets the list of titles used in the key.
#   PARAMETERS:  array of titles
#      RETURNS:  ---
#===============================================================================
sub gnuplot_set_plot_titles {
    my  ( $self, @user_plot_titles )  = @_;
    my @plot_titles = @user_plot_titles;
    $self->{plot_titles} = \@plot_titles;
    return $self;
}

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_reset
#      PURPOSE:  Set all options set with the set command to their
#                gnuplot default values.
#   PARAMETERS:  ---
#      RETURNS:  ---
#===============================================================================
sub gnuplot_reset {
    my  ($self)  = @_;
    $self->{plot_titles} = undef;
    $self->gnuplot_cmd( 'reset' );
    return $self;
} # ----------  end of subroutine gnuplot_reset  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_set_title
#      PURPOSE:  Sets the plot title.
#   PARAMETERS:  title (string)
#      RETURNS:  ---
#===============================================================================
sub gnuplot_set_title {
    my  ( $self, $title ) = @_;
    if ( defined $title ) {
        $self->gnuplot_cmd( "set title  '$title'" );
    };
    return $self;
} # ----------  end of subroutine gnuplot_set_title  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_set_xlabel
#      PURPOSE:  Sets the x axis label.
#   PARAMETERS:  string
#      RETURNS:  ---
#===============================================================================
sub gnuplot_set_xlabel {
    my  ( $self, $xlabel )    = @_;
    if ( defined $xlabel ) {
        $self->gnuplot_cmd( "set xlabel  \"$xlabel\"" );
    };
    return $self;
} # ----------  end of subroutine gnuplot_set_xlabel  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_set_ylabel
#      PURPOSE:  Sets the y axis label.
#   PARAMETERS:  string
#      RETURNS:  ---
#===============================================================================
sub gnuplot_set_ylabel {
    my  ( $self, $ylabel )    = @_;
    if ( defined $ylabel ) {
        $self->gnuplot_cmd( "set ylabel  \"$ylabel\"" );
    };
    return $self;
} # ----------  end of subroutine gnuplot_set_ylabel  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_set_xrange
#      PURPOSE:  Sets the horizontal range that will be displayed.
#   PARAMETERS:  1. parameter: range, left value
#                2. parameter: range, right value
#      RETURNS:  ---
#===============================================================================
sub gnuplot_set_xrange {
    my  ( $self, $xleft, $xright )  = @_;
    if ( defined $xleft && defined $xright ) {
        $self->gnuplot_cmd( "set xrange [ $xleft : $xright ]" );
    }
    return $self;
} # ----------  end of subroutine gnuplot_set_xrange  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_set_yrange
#      PURPOSE:  Sets the vertical range that will be displayed.
#   PARAMETERS:  1. parameter: range, low value
#                2. parameter: range, high value
#      RETURNS:  ---
#===============================================================================
sub gnuplot_set_yrange {
    my  ( $self, $yleft, $yright )  = @_;
    if ( defined $yleft && defined $yright ) {
        $self->gnuplot_cmd( "set yrange [ $yleft : $yright ]" );
    }
    return $self;
} # ----------  end of subroutine gnuplot_set_yrange  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_get_plotnumber
#      PURPOSE:  Get the (internal) plot number
#   PARAMETERS:  ---
#      RETURNS:  object number
#===============================================================================
sub gnuplot_get_plotnumber {
    my  ( $self )   = @_;
    return $self->{__plotnumber};
}   # ----------  end of subroutine gnuplot_get_plotnumber  ----------

#===  CLASS METHOD  ============================================================
#         NAME:  gnuplot_get_object_id
#      PURPOSE:  Get the (internal) object number
#   PARAMETERS:  ---
#      RETURNS:  object number
#===============================================================================
sub gnuplot_get_object_id {
    my  ( $self )   = @_;
    if ( wantarray ) {
        return ( $self->{__objectnumber}, $self->{objectname} );
    }
    else {
        return $self->{__objectnumber};
    }
}   # ----------  end of subroutine gnuplot_get_object_id  ----------

END { }                                         # module clean-up code

1;

#__END__
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#  Module Documentation
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

=head1 NAME

Graphics::GnuplotIF - A dynamic Perl interface to gnuplot

=head1 VERSION

This documentation refers to Graphics::GnuplotIF version 1.6

=head1 SYNOPSIS

  use Graphics::GnuplotIF qw(GnuplotIF);

  my  @x  = ( -2, -1.50, -1, -0.50,  0,  0.50,  1, 1.50, 2 ); # x values
  my  @y1 = (  4,  2.25,  1,  0.25,  0,  0.25,  1, 2.25, 4 ); # function 1
  my  @y2 = (  2,  0.25, -1, -1.75, -2, -1.75, -1, 0.25, 2 ); # function 2

  my  $plot1 = Graphics::GnuplotIF->new(title => "line", style => "points");

  $plot1->gnuplot_plot_y( \@x );                # plot 9 points over 0..8

  $plot1->gnuplot_pause( );                     # hit RETURN to continue

  $plot1->gnuplot_set_title( "parabola" );      # new title
  $plot1->gnuplot_set_style( "lines" );         # new line style

  $plot1->gnuplot_plot_xy( \@x, \@y1, \@y2 );   # plot 1: y1, y2 over x
  $plot1->gnuplot_plot_many( \@x, \@y1, \@x, \@y2 ); # plot 1: y1 - x, y2 - x

  my  $plot2  = Graphics::GnuplotIF->new;       # new plot object

  $plot2->gnuplot_set_xrange(  0, 4 );          # set x range
  $plot2->gnuplot_set_yrange( -2, 2 );          # set y range
  $plot2->gnuplot_cmd( "set grid" );            # send a gnuplot command
  $plot2->gnuplot_plot_equation(                # 3 equations in one plot
    "y1(x) = sin(x)",
    "y2(x) = cos(x)",
    "y3(x) = sin(x)/x" );

  $plot2->gnuplot_pause( );                     # hit RETURN to continue

  $plot2->gnuplot_plot_equation(                # rewrite plot 2
    "y4(x) = 2*exp(-x)*sin(4*x)" );

  $plot2->gnuplot_pause( );                     # hit RETURN to continue

  my  $plot3  = GnuplotIF;                      # new plot object

  my    @xyz    = (                             # 2-D-matrix, z-values
    [0,  1,  4,  9],
    [1,  2,  6, 15],
    [4,  6, 12, 27],
    [9, 15, 27, 54],
  );

  $plot3->gnuplot_cmd( "set grid" );            # send a gnuplot command
  $plot3->gnuplot_set_plot_titles("surface");   # set legend
  $plot3->gnuplot_plot_3d( \@xyz );             # start 3-D-plot
  $plot3->gnuplot_pause( );                     # hit RETURN to continue

=head1 DESCRIPTION

Graphics::GnuplotIF is a simple and easy to use dynamic Perl interface to
B<gnuplot>.  B<gnuplot> is a freely available, command-driven graphical display
tool for Unix.  It compiles and works quite well on a number of Unix flavours
as well as other operating systems, including Windows with C<gnuplot.exe>.

This module enables sending display requests asynchronously to B<gnuplot>
through simple Perl subroutine calls.

A gnuplot session is an instance of class Graphics::GnuplotIF.  The constructor
starts B<gnuplot> as a separate process for each session. The plot commands are
send through a I<pipe>. The graphical output from B<gnuplot> will be displayed
immediately.

Several independent plots can be started from one script.  Each plot has its
own pipe.  All pipes will be closed automatically by the destructor when the
script terminates.  The B<gnuplot> processes terminate when the corresponding
pipes are closed.  Their graphical output will now disappear (but see parameter
L<persist|new>).

Graphics::GnuplotIF is similar to C< gnuplot_i >, a C interface to B<gnuplot>
( http://ndevilla.free.fr/gnuplot/ ), and to  C< gnuplot_i++ >, a C++ interface
to B<gnuplot> ( http://jijo.cjb.net/code/cc++ ).

=head1 SUBROUTINES/METHODS

An object of this class represents an interface to a running B<gnuplot>
process.  During the creation of an object such an process will be started for
each such object.  Communication is done through an unidirectional pipe; the
resulting  stream  is  write-only.

Most methods return a reference to the Graphics::GnuplotIF object, allowing
method calls to be chained like so:

  $plot1 -> gnuplot_plot_xy(\@x, \@y)
     -> gnuplot_reset;

The exception to this are L</gnuplot_get_plotnumber> and
L</gnuplot_get_object_id>, which are used to obtain specific scalar
values.

=head2 new

The constructor creates a new B<gnuplot> session object, referenced by a
handle:

  $plot1  = Graphics::GnuplotIF->new( );

A few named arguments can be passed as key - value  pairs (here shown with
their default values):

  program      => 'gnuplot' # fully qualified name of the Gnuplot executable
  style        => 'lines',  # one of the gnuplot line styles (see below)
  title        => '',       # string
  xlabel       => 'x',      # string
  ylabel       => 'y',      # string
  xrange       => [],       # array reference; autoscaling, if empty
  xrange       => [],       # array reference; autoscaling, if empty
  plot_titles  => [],       # array of strings; titles used in the legend
  scriptfile   => '',       # write all plot commands to the specified file
  plot_also    => 0,        # write all plot commands to the specified file,
                            # in addition show the plots
  persist      => 0,        # let plot windows survive after gnuplot exits
                            # 0 : close / 1 : survive
  objectname   => '',       # an optional name for the object
  silent_pause => 1,        # 0 suppress message from gnuplot_pause()
  no_error_log => 0,        # suppress ".gnuplot.${$}.${object_number}.stderr.log" file

These attributes are stored in each object.

Allowed line styles are

  boxes     dots   filledcurves  fsteps  histeps
  impulses  lines  linespoints   points  steps

The generated B<gnuplot> commands can be stored to a file instead of beeing
executed immediately.  This file can be used as input to B<gnuplot>, e.g.

  gnuplot < function_set_1.gnuplot

A script file can also be used for checking the commands send to B<gnuplot>.

The objects are automatically deleted by a destructor.  The destructor closes
the pipe to the B<gnuplot> process belonging to that object.  The B<gnuplot>
process will also terminate and remove the graphic output.  The termination can
be controlled by the method L<C<gnuplot_pause> | gnuplot_pause> .

The program argument is provided to allow Graphics::GnuplotIF to be
used with Gnuplot on Windows using C<gnuplot.exe>, a compilation
which includes code that emulates a unix pipe.

=head2 GnuplotIF

The short form of the constructor above (L<C<new>|new>):

  use Graphics::GnuplotIF qw(GnuplotIF);

  $plot1  = GnuplotIF;

This subroutine is exported only on request.

=head2  gnuplot_plot_y

  $plot1->gnuplot_plot_y( \@y1, \@y2 );

C<gnuplot_plot_y> takes one or more array references and plots the values over
the x-values 0, 1, 2, 3, ...

=head2 gnuplot_plot_xy

  $plot1->gnuplot_plot_xy( \@x, \@y1, \@y2 );

C<gnuplot_plot_xy> takes two or more array references.  The first array is
assumed to contain the x-values for the following function values.

=head2 gnuplot_plot_xy_style

  %y1 = ( 'y_values' => \@y1, 'style_spec' => "lines lw 3" );
  %y2 = ( 'y_values' => \@y2,
          'style_spec' => "points pointtype 4 pointsize 5" );

  $plot1->gnuplot_plot_xy_style( \@x, \%y1, \%y2 );

C<gnuplot_plot_xy_style> takes one array reference and one or more hash
references.  The first array is assumed to contain the x-values for the
following function values. The following hashes are assumed to contain pairs of
y-values and individual style specifications for use in the plot command. The
'style_spec' settings are placed between C<with> and C<title> of B<gnuplot>'s
C<plot> command.

=head2 gnuplot_plot_many

  $plot1->gnuplot_plot_xy( \@x1, \@y1, \@x2, \@y2 );

C<gnuplot_plot_many> takes pairs of array references.  Each pair represents a
function and is a reference to the arrays of x- and y-values for that function.

=head2 gnuplot_plot_many_style

  %f1 = ( 'x_values' => \@x1, 'y_values' => \@y1,
          'style_spec' => "lines lw 3" );
  %f2 = ( 'x_values' => \@x2, 'y_values' => \@y2,
          'style_spec' => "points pointtype 4 pointsize 5" );

  $plot1->gnuplot_plot_many_style( \%f1, \%f2 );

C<gnuplot_plot_many_style> takes one or more hash references.  The hashes are
assumed to contain array referenses to x-values and y-values and individual
style specifications for use in the plot command. The 'style_spec' settings are
placed between C<with> and C<title> of B<gnuplot>'s C<plot> command.

=head2 gnuplot_plot_equation

  $plot2->gnuplot_plot_equation(         # 3 equations in one plot
    "y1(x) = sin(x)",
    "y2(x) = cos(x)",
    "y3(x) = sin(x)/x" );

C<gnuplot_plot_equation> takes one or more B<gnuplot> function descriptions as
strings.  The plot ranges can be controlled by
L<C<gnuplot_set_xrange>|gnuplot_set_xrange> and
L<C<gnuplot_set_yrange>|gnuplot_set_yrange> .

=head2 gnuplot_plot_3d

  $plot2->gnuplot_plot_3d( \@array );    # 3-D-plot

C<gnuplot_plot_3d> takes one reference to an 2-D-array of z-values.

=head2 gnuplot_pause

  $plot1->gnuplot_pause( [time] [,text] );

This is an emulation of the B<gnuplot> C<pause> command.  It displays any text
associated with the command and waits a specified amount of time or until the
carriage return is pressed. The message can be suppressed by

  silent_pause => 0

given to the constructor (see L<new | new>).

C<time> may be any constant or expression. Choosing 0 (default) will
wait until a carriage return is hit, a negative value won't pause at
all, and a positive number will wait the specified number of seconds.

The time value and the text are stored in the object and reused.  A sequence
like

  $plot1->gnuplot_plot_y( \@y1 );
  $plot1->gnuplot_pause( 5.5 );          # delay is 5.5 seconds

  $plot1->gnuplot_plot_y( \@y2 );
  $plot1->gnuplot_pause( );

  $plot1->gnuplot_plot_y( \@y3 );
  $plot1->gnuplot_pause( );

will display 3 plots with 5.5 seconds delay.


=head2 gnuplot_cmd

  $plot2->gnuplot_cmd( 'set grid',
                       'set timestamp "%d/%m/%y %H:%M" 0,0 "Helvetica"'
                       );

C<gnuplot_cmd> can be used to send one or more B<gnuplot> commands, especially
those not wrapped by a Graphics::GnuplotIF method.

=head2 gnuplot_reset

  $plot1->gnuplot_reset();

Set all options set with the C<set> command to their B<gnuplot> default values.

=head2 gnuplot_set_style

  $plot1->gnuplot_set_style( "steps" );   # new line style

Sets one of the allowed line styles (see L<new | new>)
in a plot command.

=head2 gnuplot_set_title

  $plot1->gnuplot_set_title("parabola");  # new title

Sets the plot title.
Equivalent to the B<gnuplot> command C<set title "parabola">.

=head2 gnuplot_set_xlabel

  $plot1->gnuplot_set_xlabel("time (days)");

Sets the x axis label.
Equivalent to the B<gnuplot> command C<set xlabel "time (days)">.

=head2 gnuplot_set_ylabel

  $plot1->gnuplot_set_ylabel("bugs fixed");

Sets the y axis label.
Equivalent to the B<gnuplot> command C<set ylabel "bugs fixed">.

=head2 gnuplot_set_xrange

  $plot1->gnuplot_set_xrange( left, right );

Sets the horizontal range that will be displayed.
Equivalent to the B<gnuplot> command C<set xrange [left:right]>.

=head2 gnuplot_set_yrange

  $plot1->gnuplot_set_yrange( low, high );

Sets the vertical range that will be displayed.
Equivalent to the B<gnuplot> command C<set yrange [low:high]>.

=head2 gnuplot_set_plot_titles

  $plot1->gnuplot_set_plot_titles( @ytitles );

Sets the list of titles used in the key for each of the y-coordinate data sets
specified in subsequent calls to gnuplot_plot_xy or gnuplot_plot_y commands.
This is not equivalent to a complete B<gnuplot> command; rather it adds a
C<title> clause to each data set specified in a B<gnuplot> C<plot> command.

=head2 gnuplot_hardcopy

C<gnuplot_cmd> can be used to write a plot into a file or make a printable file
by setting/resetting the terminal and the output file:

  $plot1->gnuplot_hardcopy( 'function1.gnuplot.ps',
                            'postscript',
                            'color lw 3' );

  $plot1->gnuplot_plot_xy( \@x, \@y1, \@y2 );

  $plot1->gnuplot_restore_terminal();

The 1. parameter is a file name,  the 2. parameter is a B<gnuplot> terminal type,
the 3. parameter is a string with additional terminal parameters (optional).
The current terminal settings will be saved.

=head2 gnuplot_restore_terminal

Restores the saved terminal settings after a call to C<gnuplot_hardcopy()>.
Output will go to C<STDOUT> again.

=head3 Print a plot directly

A hardcopy can be made with an appropriate output format and a pipe to a
printer:

  $plot1->gnuplot_cmd( 'set terminal postscript',
                       'set output   " | lpr " ' );

  $plot1->gnuplot_plot_xy( \@x, \@y1, \@y2 );

  $plot1->gnuplot_cmd( 'set output',
                       'set terminal x11' );

=head2 gnuplot_get_object_id

Get the (internal) object number (and the object name):

   $obj_number              = $plot1->gnuplot_get_object_id();
  ($obj_number, $obj_name)  = $plot1->gnuplot_get_object_id();

The object number is set automatically by the constructor.  The object name can
be set by the constructor (objectname => 'MyName').

=head2 gnuplot_get_plotnumber

Get the (internal) plot number of the B<next> plot:

   $plot_number             = $plot1->gnuplot_get_plotnumber()

The plot number is set automatically by the constructor starting with 1.  Each
call to

  gnuplot_plot_y
  gnuplot_plot_xy
  gnuplot_plot_xy_style
  gnuplot_plot_many
  gnuplot_plot_many_style
  gnuplot_plot_equation
  gnuplot_plot_3d

increments this number by 1. This can be used to identify single plots, e.g.
with

  $plot->gnuplot_cmd( "set timestamp \"plot number ${plot_number} / %c\"" );

=head1 EXPORTS

B<GnuplotIF>     constructor, short form (see L<C<GnuplotIF> | GnuplotIF>).

=head1 DIAGNOSTICS

Dialog messages and diagnostic messages start with
C< Graphics::GnuplotIF (object NR): ... > .

C<NR> is the number of the corresponding Graphics::GnuplotIF object and output
stream.  NR counts the objects in the order of their generation.

The gnuplot messages going to STDERR will be redirected to the file
C<.gnuplot.PPP.OOO.stderr.log>. PPP is the process number, OOO is the number of
the plot object (see L<C<gnuplot_get_object_id>|gnuplot_get_object_id>).

=head1 CONFIGURATION AND ENVIRONMENT

The environment variable DISPLAY is checked for the display.

=head1 DEPENDENCIES

=over 2

=item *

C<gnuplot> ( http://sourceforge.net/projects/gnuplot ) must be installed.

Using Graphics::GnuplotIF on Windows requires having the
C<gnuplot.exe> version installed.  This is the version that emulates a
pipe.  The Graphics::GnuplotIF object must then be instantiated with
the C<program> argument, like so:

  my $plot = Graphics::GnuplotIF -> new(program => 'C:\gnuplot\binaries\gnuplot.exe');

A recent compilation of Gnuplot for Windows can be found at
SourceForge: L<http://sourceforge.net/projects/gnuplot/files/gnuplot/>.

=item *

The module C<Carp> is used for error handling.

=item *

The module C<IO::Handle> is used to handle output pipes.  Your operating system
must support pipes, of course.

=back

=head1 INCOMPATIBILITIES

There are no known incompatibilities.

=head1 BUGS AND LIMITATIONS

  $plot1->gnuplot_cmd("pause -1");     # send the gnuplot pause command

does not work. Use

  $plot1->gnuplot_pause( );

There are no known bugs in this module.  Please report problems to author.
Patches are welcome.

=head1 AUTHOR

Dr.-Ing. Fritz Mehner (mehner.fritz@web.de)

=head1 CREDITS

Stephen Marshall (smarshall at wsi dot com) contributed C<gnuplot_set_plot_titles>.

Georg Bauhaus (bauhaus at futureapps dot de) contributed C<gnuplot_plot_xy_style>.

Bruce Ravel (bravel at bnl dot gov) contributed C<gnuplot_plot_many>
and C<gnuplot_plot_many_style>, made method calls chainable, and added
Windows support.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2005-2011 by Fritz Mehner

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See perldoc perlartistic.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=head1 SEE ALSO

C<gnuplot(1)>.

=cut

