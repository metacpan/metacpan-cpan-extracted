# This software is copyright (c) 2004 Alex Robinson.
# It is free software and can be used under the same terms as perl,
# i.e. either the GNU Public Licence or the Artistic License.

package MasonX::Request::ExtendedCompRoot::WithApacheSession;

use strict;

our $VERSION = '0.04';

use base qw(MasonX::Request::WithApacheSession MasonX::Request::ExtendedCompRoot);


sub new
	{
	my $class = shift;
	$class->alter_superclass(
		$MasonX::Request::WithApacheSession::VERSION ?
		'MasonX::Request::WithApacheSession' :
		$HTML::Mason::ApacheHandler::VERSION ?
		'HTML::Mason::Request::ApacheHandler' :
		$HTML::Mason::CGIHandler::VERSION ?
		'HTML::Mason::Request::CGI' :
		'HTML::Mason::Request' );
	my $self = $class->SUPER::new(@_);

	return $self->_init_extended(@_);
	}
#
# Call WithApacheSession's exec, then put comp_root back 
# to what it was when the current request or subrequest was made
#
sub exec
	{
	my $self = shift;
	$self->comp_root(@{$self->_base_comp_root});
	my $return_exec = $self->SUPER::exec(@_);
	#$self->reset_comp_root;
	$self->comp_root(@{$self->_base_comp_root});
	return $return_exec;
	}

#
# Simply pass the buck
#
sub _fetch_comp
	{
	return MasonX::Request::ExtendedCompRoot::_fetch_comp(@_);
	}
# and again
sub comp
	{
	return MasonX::Request::ExtendedCompRoot::comp(@_);
	}
# and again
sub content
	{
	return MasonX::Request::ExtendedCompRoot::content(@_);
	}

1;


__END__

=head1 NAME

MasonX::Request::ExtendedCompRoot::WithApacheSession - Extend functionality of Mason's comp_root and add a session to the Mason Request object

=head1 SYNOPSIS

In your F<httpd.conf> file:

  PerlSetVar  MasonRequestClass         MasonX::Request::ExtendedCompRoot::WithApacheSession
  PerlSetVar  MasonResolverClass        MasonX::Resolver::ExtendedCompRoot
  PerlSetVar  MasonSessionCookieDomain  .example.com
  PerlSetVar  MasonSessionClass         Apache::Session::MySQL
  PerlSetVar  MasonSessionDataSource    dbi:mysql:somedb

Or when creating an ApacheHandler object:

  my $ah =
      HTML::Mason::ApacheHandler->new
          ( request_class         => 'MasonX::Request::ExtendedCompRoot::WithApacheSession',
            resolver_class        => 'MasonX::Resolver::ExtendedCompRoot',
            session_cookie_domain => '.example.com',
            session_class         => 'Apache::Session::MySQL',
            session_data_source   => 'dbi:mysql:somedb',
          );

In a component:

  # use a session
  $m->session->{foo} = 1;
  if ( $m->session->{bar}{baz} > 1 ) { ... }

  # dynamically add a root to the component root
  $m->prefix_comp_root('key=>/path/to/root');
  
  # call a component in a specific component root
  <& key=>/path/to/comp &>

=head1 DESCRIPTION

This module simply integrates C<MasonX::Request::ExtendedCompRoot> and C<MasonX::Request::WithApacheSession>.

=head1 USAGE

=head2 SET UP

To use this module you need to tell Mason to use this class for requests and C<MasonX::Resolver::ExtendedCompRoot> for its resolver.  This can be done in two ways.  If you are configuring Mason via your F<httpd.conf> file, simply add this:

  PerlSetVar  MasonRequestClass    MasonX::Request::ExtendedCompRoot::WithApacheSession
  PerlSetVar  MasonResolverClass   MasonX::Resolver::ExtendedCompRoot

If you are using a F<handler.pl> file, simply add this parameter to
the parameters given to the ApacheHandler constructor:

  request_class  => 'MasonX::Request::ExtendedCompRoot::WithApacheSession'
  resolver_class => 'MasonX::Resolver::ExtendedCompRoot'

=head2 METHODS

This class adds two methods from C<MasonX::Request::WithApacheSession> to the Request object (C<session> and C<delete_session>), and three from L<MasonX::Request::ExtendedCompRoot>, (C<comp_root>, C<prefix_comp_root> and C<reset_comp_root>).

See the respective modules for documentation of these methods.

=head1 PREREQUISITES

MasonX::Request::ExtendedCompRoot, MasonX::Request::WithApacheSession

=head1 BUGS

No known bugs.

=head1 VERSION

0.04

=head1 SEE ALSO

L<HTML::Mason>, L<MasonX::Request::ExtendedCompRoot>, L<MasonX::Request::WithApacheSession>

=head1 AUTHOR

Alex Robinson, <cpan[@]alex.cloudband.com>

=head1 LICENSE

MasonX::Request::ExtendedCompRoot::WithApacheSession is free software and can be used under the same terms as Perl, i.e. either the GNU Public Licence or the Artistic License.

=cut