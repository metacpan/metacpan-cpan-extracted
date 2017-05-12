###############################################################################
#Variable.pm
#Last Change: 2009-02-09
#Copyright (c) 2009 Marc-Seabstian "Maluku" Lucksch
#Version 0.4
####################
#This file is an addon to the Dotiac::DTL project. 
#http://search.cpan.org/perldoc?Dotiac::DTL
#
#Variable.pm is published under the terms of the MIT license, which  
#basically means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with this distribution. A copy of
#the license is (at the time of writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
###############################################################################


package Dotiac::DTL::Addon::html_template::Variable;
use strict;
use warnings;

use base qw/Dotiac::DTL::Variable/;


our $VERSION = 0.4;

sub new {
	my $class=shift;
	my $self={p=>shift()};
	bless $self,$class;
	$self->{name}=shift;
	$self->{filters}=shift;
	return $self;
}

sub next {
	my $self=shift;
	$self->{n}=shift;
}

1;

__END__

=head1 NAME

Dotiac::DTL::Addon::html_template::Variable - Custom variable tag for Dotiac::DTL::Addon::html_template

=head1 SYNOPSIS

	my $var=Dotiac::DTL::Addon::html_template::Variable->new("",$name,\@filters);
	$var->next(Dotiac::DTL::Tag->new("");

=head1 DESCRIPTION

Excatly the same as Dotiac::DTL::Variable, but has a next method.

=head1 SEE ALSO

L<Dotiac::DTL>, L<Dotiac::DTL::Addon>, L<http://www.dotiac.com>, L<http://www.djangoproject.com>

=head1 AUTHOR

Marc-Sebastian Lucksch

perl@marc-s.de

=cut
