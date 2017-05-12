#$Id: WebDAO.pm 344 2008-09-30 12:45:11Z zag $

package HTML::WebDAO;

use strict;
use warnings;
use HTML::WebDAO::Base;
use HTML::WebDAO::Element;
use HTML::WebDAO::Component;
use HTML::WebDAO::Container;
use HTML::WebDAO::Engine;
use HTML::WebDAO::Session;
use HTML::WebDAO::Sessionco;
use HTML::WebDAO::Lib::RawHTML;
our @ISA = qw();

our $VERSION = '0.91';



1;
__END__

=head1 NAME

HTML::WebDAO - Perl extension for create complex web application

=head1 SYNOPSIS

  use HTML::WebDAO;

=head1 ABSTRACT
 
    Perl extension for create complex web application

=head1 DESCRIPTION

Perl extension for create complex web application

=head1 SEE ALSO

http://sourceforge.net/projects/webdao

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
