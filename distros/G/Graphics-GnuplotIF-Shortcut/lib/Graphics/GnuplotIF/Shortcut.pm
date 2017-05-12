package Graphics::GnuplotIF::Shortcut;

our $VERSION = '0.03';
use base 'Graphics::GnuplotIF';

our @EXPORT_OK = 'GnuplotIF';

for my $m ( keys %{Graphics::GnuplotIF::} ) {
  local $_ = $m;
  next unless s/^gnuplot_//;
  next unless length;
  no strict 'refs';
  my $cref = "Graphics::GnuplotIF::$m";
  next unless *{$cref}{CODE};
  *$_ = *$cref;
}

sub GnuplotIF { __PACKAGE__->new(@_) }
1;
__END__

=head1 NAME

Graphics::GnuplotIF::Shortcut - Alternate interface to Graphics::GnuplotIF

=head1 VERSION

This document describes Graphics::GnuplotIF::Shortcut version 0.03


=head1 SYNOPSIS

    use Graphics::GnuplotIF::Shortcut;

=head1 DESCRIPTION

Graphics::GnuplotIF::Shortcut is a wrapper for Graphics::GnuplotIF. The advatage of Graphics::GnuplotIF::Shortcut over Graphics::GnuplotIF is that the code is much better to read.

Graphics::GnuplotIF::Shortcut inherits from Graphics::GnuplotIF. But you can call all method calls prefixed with gnuplot_ without gnuplot_.

For example instead of this code:

  ###
  ###  Graphics::GnuplotIF
  ###

  my  $gp  = Graphics::GnuplotIF->new;

  $gp->gnuplot_set_xrange(  0, 4 ); 
  $gp->gnuplot_set_yrange( -2, 2 );
  $gp->gnuplot_cmd( "set grid" ); 
  $gp->gnuplot_plot_equation(    
    "y1(x) = sin(x)",
    "y2(x) = cos(x)",
    "y3(x) = sin(x)/x" );

  $gp->gnuplot_pause();   
  $gp->gnuplot_plot_equation( "y4(x) = 2*exp(-x)*sin(4*x)" );
  $gp->gnuplot_pause( );      

you can write the above or the one bellow or a mixture of both.

  ###
  ###  Graphics::GnuplotIF::Shortcut
  ###
  
  my  $gp  = Graphics::GnuplotIF::Shortcut->new;

  $gp->set_xrange(  0, 4 ); 
  $gp->set_yrange( -2, 2 );
  $gp->cmd( "set grid" ); 
  $gp->plot_equation(    
    "y1(x) = sin(x)",
    "y2(x) = cos(x)",
    "y3(x) = sin(x)/x" );

  $gp->pause();
  $gp->plot_equation( "y4(x) = 2*exp(-x)*sin(4*x)" );
  $gp->pause();


=head1 INTERFACE 

=head2 GnuplotIF

is a shortcut for 

  my $gp = Graphics::GnuplotIF::Shortcut->new( ... );

but only avail, if you import GnuplotIF in your namespace. With

  use Graphics::GnuplotIF::Shortcut qw/GnuplotIF/;

For everything else please refere to the documentation of Graphics::GnuplotIF


=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Graphics::GnuplotIF::Shortcut requires no configuration files or environment variables.


=head1 DEPENDENCIES

  Graphics::GnuplotIF

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-graphics-gnuplotif-shortcut@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Boris Zentner  C<< <bzm@2bz.de> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, 2009 Boris Zentner C<< <bzm@2bz.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
