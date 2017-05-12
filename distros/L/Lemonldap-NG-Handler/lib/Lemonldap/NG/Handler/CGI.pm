# Auto-protected CGI mechanism
package Lemonldap::NG::Handler::CGI;

use strict;

use Lemonldap::NG::Common::CGI;
use Lemonldap::NG::Handler::SharedConf qw(:all);
use base qw(Lemonldap::NG::Common::CGI Lemonldap::NG::Handler::SharedConf);

our $VERSION = '1.9.1';

## @cmethod Lemonldap::NG::Handler::CGI new(hashRef args)
# Constructor.
# @param $args configuration parameters
# @return new object
sub new {
    my ( $class, $args ) = @_;
    my $self = $class->SUPER::new() or $class->abort("Unable to build CGI");
    Lemonldap::NG::Handler::SharedConf->init($args);
    Lemonldap::NG::Handler::SharedConf->checkConf($self);

    # Get access control rule
    my $rule = $self->{protection} || $localConfig->{protection};
    $rule =~ s/^rule\s*:?\s*//;
    return $self if ( $rule eq "none" );
    $rule =
      $rule eq "authenticate" ? "accept" : $rule eq "manager" ? "" : $rule;
    my $request = {};
    Lemonldap::NG::Handler::API->newRequest($request);
    my $res = $self->run($rule);

    if ( $res == 403 ) {
        $self->abort( 'Forbidden',
            "You don't have rights to access this page" );
    }
    elsif ($res) {
        print $self->header( -status => $res, %{ $request->{respHeaders} } );
        $self->quit;
    }
    else {
        return $self;
    }
}

## @method hashRef user()
# @return hash of user datas
sub user {
    return $datas;
}

## @method boolean group(string group)
# @param $group name of the Lemonldap::NG group to test
# @return boolean : true if user is in this group
sub group {
    my ( $self, $group ) = @_;
    return ( $datas->{groups} =~ /\b$group\b/ );
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Handler::CGI - Perl extension for using Lemonldap::NG
authentication in Perl CGI without using Lemonldap::NG::Handler

=head1 SYNOPSIS

  use Lemonldap::NG::Handler::CGI;
  my $cgi = Lemonldap::NG::Handler::CGI->new ( {
      # Local storage used for sessions and configuration
      localStorage        => "Cache::FileCache",
      localStorageOptions => {...},
      # How to get my configuration
      configStorage       => {
          type                => "DBI",
          dbiChain            => "DBI:mysql:database=lemondb;host=$hostname",
          dbiUser             => "lemonldap",
          dbiPassword          => "password",
      },
      https               => 0,
      # Optional
      protection    => 'rule: $uid eq "admin"',
      # Or to use rules from manager
      protection    => 'manager',
      # Or just to authenticate without managing authorization
      protection    => 'authenticate',
    }
  );
  
  # See CGI(3) for more about writing HTML pages
  print $cgi->header;
  print $cgi->start_html;
  
  # Since authentication phase, you can use user attributes and macros
  my $name = $cgi->user->{cn};
  
  # Instead of using "$cgi->user->{groups} =~ /\badmin\b/", you can use
  if( $cgi->group('admin') ) {
    # special html code for admins
  }
  else {
    # another HTML code
  }

=head1 DESCRIPTION

Lemonldap::NG::Handler provides the protection part of Lemonldap::NG web-SSO
system. It can be used with any system used with Apache (PHP or JSP pages for
example). If you need to protect only few Perl CGI, you can use this library
instead.

Warning, this module must not be used in a Lemonldap::NG::Handler protected
area because it hides Lemonldap::NG cookies. 

=head1 SEE ALSO

L<http://lemonldap-ng.org/>
L<CGI>, L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Manager>,
L<Lemonldap::NG::Portal>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2007-2015 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Copyright (C) 2010-2015 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
