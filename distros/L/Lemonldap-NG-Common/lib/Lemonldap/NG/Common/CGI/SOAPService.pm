## @file
# SOAP wrapper used to restrict exported functions

## @class
# SOAP wrapper used to restrict exported functions
package Lemonldap::NG::Common::CGI::SOAPService;

require SOAP::Lite;

our $VERSION = '1.9.1';

## @cmethod Lemonldap::NG::Common::CGI::SOAPService new(object obj,string @func)
# Constructor
# @param $obj object which will be called for SOAP authorizated methods
# @param @func authorizated methods
# @return Lemonldap::NG::Common::CGI::SOAPService object
sub new {
    my ( $class, $obj, @func ) = @_;
    s/.*::// foreach (@func);
    return bless { obj => $obj, func => \@func }, $class;
}

## @method datas AUTOLOAD()
# Call the wanted function with the object given to the constructor.
# AUTOLOAD() is a magic method called by Perl interpreter fon non existent
# functions. Here, we use it to call the wanted function (given by $AUTOLOAD)
# if it is authorizated
# @return datas provided by the exported function
sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://;
    if ( grep { $_ eq $AUTOLOAD } @{ $self->{func} } ) {
        my $tmp = $self->{obj}->$AUTOLOAD(@_);
        unless ( ref($tmp) and ref($tmp) eq 'SOAP::Data' ) {
            $tmp = SOAP::Data->name( result => $tmp );
        }
        return $tmp;
    }
    elsif ( $AUTOLOAD ne 'DESTROY' ) {
        die "$AUTOLOAD is not an authorizated function";
    }
    1;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::CGI::SOAPService - Wrapper for all SOAP functions of
Lemonldap::NG CGIs.

=head1 SYNOPSIS

See L<Lemonldap::NG::Common::CGI>

=head1 DESCRIPTION

Private class used by L<Lemonldap::NG::Common::CGI> to control SOAP functions
access.

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Common::CGI>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2009-2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2010-2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
