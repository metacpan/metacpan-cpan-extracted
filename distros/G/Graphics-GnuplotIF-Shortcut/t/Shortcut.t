
## copy Graphics::GnuplotIF/t/GnuplotIF.t
#
# s/\bgnuplot_//g
# s/Graphics::GnuplotIF/Graphics::GnuplotIF::Shortcut/g

use strict;
use warnings;
use Math::Trig;

use Test::More tests => 7;    # last test to print

use Graphics::GnuplotIF::Shortcut qw/GnuplotIF/;

#---------------------------------------------------------------------------
#  tests
#---------------------------------------------------------------------------
ok( test1(), 'run Graphics::GnuplotIF::Shortcut demo 1' );
ok( test2(), 'run Graphics::GnuplotIF::Shortcut demo 2' );
ok( test3(), 'run Graphics::GnuplotIF::Shortcut demo 3' );
ok( test4(), 'run Graphics::GnuplotIF::Shortcut demo 4' );
ok( test5(), 'run Graphics::GnuplotIF::Shortcut demo 5' );
ok( test6(), 'run Graphics::GnuplotIF::Shortcut demo 6' );
ok( test7(), 'run Graphics::GnuplotIF::Shortcut demo 7' );

#---------------------------------------------------------------------------
#  test function 1
#---------------------------------------------------------------------------
sub test1 {

  if ( !$ENV{'DISPLAY'} ) { return 1; }    # no display; skip this test

  my @x  = ( -2, -1.50, -1, -0.50, 0,  0.50,  1,  1.50, 2 );    # x values
  my @y1 = ( 4,  2.25,  1,  0.25,  0,  0.25,  1,  2.25, 4 );    # function 1
  my @y2 = ( 2,  0.25,  -1, -1.75, -2, -1.75, -1, 0.25, 2 );    # function 2
  my $wait       = 3;
  my $plotnumber = 0;

  my $timeformat = '%d-%m-%y %H:%M:%S';

  #---------------------------------------------------------------------------
  #  plot object 1
  #---------------------------------------------------------------------------
  my $plot1 =
    Graphics::GnuplotIF::Shortcut->new(
                              title       => 'line',
                              style       => 'points',
                              plot_titles => [ 'function 1.1', 'function 1.2' ],
    );

  $plotnumber++;
  $plot1->cmd(
          "set timestamp \"plot number ${plotnumber} / ${timeformat}\" bottom");
  $plot1->plot_y( \@x );    # plot 9 points over 0..8

  $plot1->pause($wait);     # wait

  $plot1->set_title('parabola');    # new title
  $plot1->set_style('lines');       # new line style

  $plotnumber++;
  $plot1->cmd(
          "set timestamp \"plot number ${plotnumber} / ${timeformat}\" bottom");
  $plot1->plot_xy( \@x, \@y1, \@y2 );    # rewrite plot1 : y1, y2 over x
  $plot1->pause($wait);

  #  Plot same data again, this time with all default settings.
  $plot1->reset();
  $plotnumber++;
  $plot1->cmd(
          "set timestamp \"plot number ${plotnumber} / ${timeformat}\" bottom");
  $plot1->plot_xy( \@x, \@y1, \@y2 );    # rewrite plot1 : y1, y2 over x
  $plot1->pause($wait);

  #  Plot same data again, again starting from default settings,
  #  but with individual plotting styles applied per function
  my %y1 = ( 'y_values' => \@y1, 'style_spec' => 'lines lw 3' );
  my %y2 =
    ( 'y_values' => \@y2, 'style_spec' => 'points pointtype 4 pointsize 5' );

  $plotnumber++;
  $plot1->cmd(
          "set timestamp \"plot number ${plotnumber} / ${timeformat}\" bottom");
  $plot1->plot_xy_style( \@x, \%y1, \%y2 );
  $plot1->pause($wait);

  #---------------------------------------------------------------------------
  #  plot object 2
  #---------------------------------------------------------------------------
  my $plot2 = Graphics::GnuplotIF::Shortcut->new;

  $plot2->set_xrange( 0, '2*pi' );    # set x range
  $plot2->set_yrange( -2, 2 );        # set y range
  $plot2->cmd('set grid');            # send a gnuplot command
  $plot2->plot_equation(              # 3 equations in one plot
                         'y1(x) = sin(x)',
                         'y2(x) = cos(x)',
                         'y3(x) = sin(x)/x'
  );

  $plot2->pause($wait);               # wait

  $plot2->plot_equation(              # rewrite plot 2
                         'y4(x) = 2*exp(-x)*sin(4*x)'
  );

  $plot2->pause($wait);               # wait

  return 1;
}    # ----------  end of subroutine test1  ----------

#---------------------------------------------------------------------------
#  test function 2 : write a script file
#---------------------------------------------------------------------------
sub test2 {

  if ( !$ENV{'DISPLAY'} ) { return 1; }    # no display; skip this test

  my $wait           = 4;
  my $scriptfilename = 't/test2.gnuplot';
  my @x = ( 0, +1, +0.8, 0, -1, -0.8, 0, +1, +0.8, 0, -1, -0.8, 0 );

  if ( -e $scriptfilename ) {
    unlink $scriptfilename;
  }
  my $plot =
    Graphics::GnuplotIF::Shortcut->new(
                                        title       => 'function #2',
                                        style       => 'lines',
                                        plot_titles => ['function 2'],
                                        scriptfile  => $scriptfilename,
    );
  $plot->set_yrange( -1.5, +1.5 );    # set y range
  $plot->cmd('set xzeroaxis');

  $plot->plot_y( \@x )->pause($wait);    # plot and wait

  $plot->plot_y( \@x );

  foreach my $count ( 1 ... 30 ) {       # wait for the plot file
    if ( -e $scriptfilename ) {
      my @args = ( 'gnuplot', $scriptfilename );
      system(@args) == 0
        or die "system @args failed: $!";
      $plot->pause(4);
      return 1;
    }
    sleep 1;
  }

  return 0;
}    # ----------  end of subroutine test2  ----------

#---------------------------------------------------------------------------
#  test function 3 : animation
#---------------------------------------------------------------------------
sub test3 {

  if ( !$ENV{'DISPLAY'} ) { return 1; }    # no display; skip this test

  my $steps     = 10;
  my $intervall = 2 * pi;
  my $n;

  my $plot1 =
    Graphics::GnuplotIF::Shortcut->new(title => 'Fourier Series -- Square Wave',
                                       silent_pause => 0, );

  $plot1->cmd('set grid');                 # send a gnuplot command
  $plot1->cmd('set key off');              # send a gnuplot command
  $plot1->cmd('set timestamp bottom');     # send a gnuplot command
  $plot1->set_xrange( 0, $intervall );     # set x range

  my $fourier = q{};
  foreach my $i ( 1 .. $steps ) {
    $n = 2 * $i - 1;
    $fourier .= " +sin($n*x)/$n";
    $plot1->cmd("plot (4/pi)*($fourier)")->pause(.4);
  }

  return 1;
}    # ----------  end of subroutine test3  ----------

#---------------------------------------------------------------------------
#  test function 4 : hardcopy
#---------------------------------------------------------------------------
sub test4 {

  if ( !$ENV{'DISPLAY'} ) { return 1; }    # no display; skip this test
  my @x = ( 0, +1, +1, 0, -1, -1, 0, +1, +1, 0, -1, -1, 0 );    # x values
  my @y1 = ( 4, 2.25, 1, 0.25, 0, 0.25, 1, 2.25, 4 );           # function 1

  my $plot =
    Graphics::GnuplotIF::Shortcut->new( title => 'function #4',
                                        style => 'lines', );
  $plot->set_yrange( -1.5, +1.5 );                              # set y range
  $plot->cmd('set xzeroaxis');
  $plot->plot_y( \@x );

  $plot->hardcopy( 't/function4.gnuplot.ps', 'postscript', 'color' );
  $plot->plot_y( \@x );
  $plot->restore_terminal();
  $plot->pause(4);

  return 1;
}    # ----------  end of subroutine test4  ----------

#---------------------------------------------------------------------------
#  test function 5 : 3-D-plot
#---------------------------------------------------------------------------
sub test5 {

  if ( !$ENV{'DISPLAY'} ) { return 1; }    # no display; skip this test

  my $plot =
    Graphics::GnuplotIF::Shortcut->new( title => 'function #5',
                                        style => 'lines', );
  $plot->set_title('x*y*sin(x)*sin(y)');    # new title
  $plot->set_plot_titles('surface 1');

  my @array;
  foreach my $i ( 0 .. 64 ) {
    foreach my $j ( 0 .. 64 ) {
      $array[$i][$j] = $i * $j * sin( 0.2 * $i ) * sin( 0.2 * $j );
    }
  }

  $plot->plot_3d( \@array )->pause(6);

  return 1;
}    # ----------  end of subroutine test5  ----------

#---------------------------------------------------------------------------
#  test function 6 :
#---------------------------------------------------------------------------
sub test6 {

  if ( !$ENV{'DISPLAY'} ) { return 1; }    # no display; skip this test

  my $plot = GnuplotIF(                    # constructor; short form
                        title      => 'test 6',
                        style      => 'lines',
                        objectname => '=polynomials=',
  );
  $plot->cmd('set grid');                     # send a gnuplot command
  $plot->cmd('set xzeroaxis linestyle 1');    # send a gnuplot command

  my $timeformat = '%d-%m-%y %H:%M:%S';
  my @x;
  my @y;

  foreach my $n ( 1 ... 4 ) {
    my ( $id, $name ) = $plot->get_object_id();
    my $plotnumber = $plot->get_plotnumber();
    $plot->set_plot_titles("(x-1)**$n");
    foreach my $i ( 0 ... 40 ) {
      $x[$i] = 0.1 * $i - 2.0;
      $y[$i] = $x[$i]**$n;
    }

    $plot->cmd(
"set timestamp \"plot object ${id} / plot number ${plotnumber} / ${timeformat}\" bottom"
    );
    $plot->cmd(
               "set timestamp \"plot number ${plotnumber} / %d/%m/%y %H:%M\"" );
    $plot->plot_xy( \@x, \@y )->pause(.4);
  }

  return 1;
}    # ----------  end of subroutine test6  ----------

#---------------------------------------------------------------------------
#  test function 7
#---------------------------------------------------------------------------
sub test7 {

  if ( !$ENV{'DISPLAY'} ) { return 1; }    # no display; skip this test

  my @x1 = ( -2, -1.50, -1, -0.50, 0, 0.50, 1, 1.50, 2 );    # x values (1.set)
  my @y1 = ( 4,  2.25,  1,  0.25,  0, 0.25, 1, 2.25, 4 );    # y-values (1.set)

  my @x2 = ( -4, -3.50, -3, -2.50, -2, -1.50, -1, -0.50, 0 ); # x values (2.set)
  my @y2 = ( 5,  3.25,  2,  1.25,  1,  1.25,  2,  3.25,  5 ); # y-values (2.set)

  my @x3 = ( 0, 0.50, 1, 1.50,  2,  2.50,  3, 3.50, 4 );      # x values (3.set)
  my @y3 = ( 3, 1.25, 0, -0.75, -1, -0.75, 0, 1.25, 3 );      # y-values (3.set)

  my $wait       = 3;
  my $plotnumber = 0;

  my $timeformat = '%d-%m-%y %H:%M:%S';

  #---------------------------------------------------------------------------
  #  plot object 1
  #---------------------------------------------------------------------------
  my $plot1 =
    Graphics::GnuplotIF::Shortcut->new(
              title       => 'x-y-plot(s) not sharing an x-axis',
              style       => 'lines',
              plot_titles => [ 'function 1.1', 'function 1.2', 'function 1.3' ],
    );

  $plotnumber++;
  $plot1->cmd(
          "set timestamp \"plot number ${plotnumber} / ${timeformat}\" bottom");
  $plot1->plot_many( \@x1, \@y1 )->pause($wait);

  $plotnumber++;
  $plot1->cmd(
          "set timestamp \"plot number ${plotnumber} / ${timeformat}\" bottom");
  $plot1->plot_many( \@x1, \@y1, \@x2, \@y2 )->pause($wait);

  $plotnumber++;
  $plot1->cmd(
          "set timestamp \"plot number ${plotnumber} / ${timeformat}\" bottom");
  $plot1->plot_many( \@x1, \@y1, \@x2, \@y2, \@x3, \@y3 )->pause($wait);

  my %f1 =
    ( 'x_values' => \@x1, 'y_values' => \@y1, 'style_spec' => "lines lw 3" );
  my %f2 = (
             'x_values'   => \@x2,
             'y_values'   => \@y2,
             'style_spec' => "points pointtype 4 pointsize 5"
  );

  $plot1->plot_many_style( \%f1, \%f2 )->pause($wait);

  #---------------------------------------------------------------------------
  #  plot object 2
  #---------------------------------------------------------------------------
  my @x21 = ( -2, -1.50, -1, -0.50, 0, 0.50, 1, 1.50, 2 );    # 9 points
  my @y21 = ( 4,  2.25,  1,  0.25,  0, 0.25, 1, 2.25, 4 );    # function 1

  my @x22 = ( -1.1, -0.1, 0.9, 1.9, 2.9 );                    # 5 points
  my @y22 = ( 0.1,  0.2,  0.3, 0.4, 0.5 );                    # function 2

  my $plot2 =
    Graphics::GnuplotIF::Shortcut->new( title => "parabola",
                                        style => "lines" );

  $plot2->plot_many( \@x21, \@y21, \@x22, \@y22 )->pause($wait);

  return 1;
}    # ----------  end of subroutine test7  ----------
