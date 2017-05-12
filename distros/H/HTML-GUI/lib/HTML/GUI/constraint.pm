package HTML::GUI::constraint;

use warnings;
use strict;

use HTML::Template;

=head1 NAME

HTML::GUI::constraint - constraint managing 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';



=head1 CONSTRAINT

Module for managing the contraints 

=cut

#a list of the messages to use in case a constraint is violated

my %errorMessages = (
  	required => 'The input "<TMPL_VAR NAME=widgetLabel>" is mandatory.'	,
  	default => 'The constraint "<TMPL_VAR NAME=constraint-name>" is violated. Please correct it.'	
);

=head1 PUBLIC METHODS

=pod 

=head3 getMessage
		
		returns the message corresponding to $constrName filled
		with the values of $params

   Parameters :
	    constrName : a string containing the name of the constraint
      params : hash ref containing the values to fill the message

=cut

sub getMessage{
		my ($params)=@_;
		my $tplTxt = '';
		my $constrName = $params->{'constraint-name'};
		if (exists $errorMessages{$constrName}){
				$tplTxt = $errorMessages{$constrName};
		}else{
				$tplTxt = $errorMessages{default};
		}
		my $tplObj = HTML::Template->new( scalarref => \$tplTxt,
                                      option => 'value',
																			die_on_bad_params => 0,
                                    );
		$tplObj->param($params);
		return $tplObj->output();

}

=head1 AUTHOR

Jean-Christian Hassler, C<< <jhassler at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-gui-libhtml-constraint at rt.cpan.org>, or through the web interface at
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

1; # End of HTML::GUI::constraint
