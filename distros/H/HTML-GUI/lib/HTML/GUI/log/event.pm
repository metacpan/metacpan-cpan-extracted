package HTML::GUI::log::event;

use warnings;
use strict;
use POSIX;
use HTML::GUI::widget;

=head1 NAME

HTML::GUI::log::event - Create and control a event input for webapp

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our @ISA = qw(HTML::GUI::widget);

=head1 EVENT

The event module to log all errors/debug/information messages

=cut


=head1 PUBLIC METHODS

=pod 

=head3 new

=cut

sub new($$$)
{
  my($class,$params) = @_;
		my $this = $class->SUPER::new($params);
	  #the basic logging infos
		$this->{ 'time'} = time;
		$this->{stack}  = HTML::GUI::log::event::getCurrentStack();
		if (defined $params && $params->{source}){
				$this->{source} = $params->{source};
		}

    bless($this, $class);
}


=pod

=head3 getCurrentStack

   Description :
		  return a array of the current stack

=cut
sub getCurrentStack
{
  my ($self) = @_;
	my @stack =() ;
	my $i=1;
  my ($package, $filename, $line,$subroutine) ;
	while ($i==1 || $filename){
	  ($package, $filename, $line,$subroutine) = caller($i);
			push @stack, {
					'package' => $package,
					filename => $filename,
					line			=> $line,
					subroutine=> $subroutine,
			} unless (!defined $filename);
			$i++;
	}
	return \@stack;
}


=pod

=head3 getMessage

   Description :
		  return the message corresponding for the current event

=cut

sub getMessage
{
  my ($self)=@_;
	return "no message for generic event";
}

=pod

=head3 dump

   Description :
		  return a human readable string of the current event

=cut

sub dump
{
  my ($self)=@_;
  if (!exists $self->{stack}){
		return "No stack found !!!\n";
	}
	my $dumpString = '';
	$dumpString .= "[".$self->printTime($self->{time})."] : ";
	$dumpString .= $self->getMessage()."\n";
	foreach my $frame (@{$self->{stack}}){
		$dumpString .= "  ->".$frame->{subroutine};
		if ($frame->{filename} !~ /\.pm$/){
			$dumpString .=	" in ".$frame->{filename}.":".$frame->{line};
		}else{
			$dumpString .=	" line:".$frame->{line};
		}
		$dumpString .= "\n";
	}
	$dumpString .="\n";
	return $dumpString;
}

=pod

=head3 printTime

   Parameters :
      $time : string : a value returned by the function time
   Description :
		  return a human readable string of the date $time

=cut
sub printTime($$)
{
  my ($self,$time)=@_;
  return  strftime "%Y:%m:%d %H:%M:%S", localtime($time);
}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-event at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-GUI-widget>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::GUI::widget

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-GUI-widget>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-GUI-widget>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-GUI-widget>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-GUI-widget>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jean-Christian Hassler, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::GUI::event::event
