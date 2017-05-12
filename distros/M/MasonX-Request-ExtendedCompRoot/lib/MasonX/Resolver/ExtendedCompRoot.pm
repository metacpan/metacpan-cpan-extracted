# This software is copyright (c) 2004 Alex Robinson.
# It is free software and can be used under the same terms as perl,
# i.e. either the GNU Public Licence or the Artistic License.

package MasonX::Resolver::ExtendedCompRoot;

use strict;

our $VERSION = '0.04';

use base qw(HTML::Mason::Resolver::File);

use HTML::Mason::Tools qw(read_file_ref);

#
# call ApacheHandler's apache_request_to_comp_path in a way 
# that doesn't cause standalone invocations to choke
#
sub apache_request_to_comp_path
	{
	return HTML::Mason::Resolver::File::apache_request_to_comp_path(@_);
	}


1;


__END__

=head1 NAME

MasonX::Resolver::ExtendedCompRoot - Extend functionality of C<HTML::Mason::Resolver::File> to allow specific comp_roots to be called

=head1 SYNOPSIS

In your F<httpd.conf> file:

  PerlSetVar   MasonResolverClass   MasonX::Resolver::ExtendedCompRoot

Or when creating an ApacheHandler object:

  my $ah =
      HTML::Mason::ApacheHandler->new
          ( 
           resolver_class => 'MasonX::Resolver::ExtendedCompRoot',
          );

Or when using Mason in standalone mode:

  my $resolver = MasonX::Resolver::ExtendedCompRoot->new( comp_root => '/var/www/mason' );

  my $info = $resolver->get_info('/some/comp.html');

=head1 DESCRIPTION

This subclass of L<HTML::Mason::Resolver::File>, the basic default Mason resolver, enables calls to specific component roots to be made, eg.

  <& comp_root_name=>path/to/comp &>

It is dependent on C<MasonX::Request::ExtendedCompRoot> - otherwise its behaviour is identical to that of C<HTML::Mason::Resolver::File>.

=head1 USAGE

To use this module you need to tell Mason to use this class for its resolver and C<MasonX::Request::ExtendedCompRoot> for requests.  This can be done in two ways. If you are configuring Mason via your F<httpd.conf> file, simply add this:

  PerlSetVar  MasonRequestClass    MasonX::Request::ExtendedCompRoot
  PerlSetVar  MasonResolverClass   MasonX::Resolver::ExtendedCompRoot

If you are using a F<handler.pl> file, simply add this parameter to the parameters given to the ApacheHandler constructor:

  request_class  => 'MasonX::Request::ExtendedCompRoot'
  resolver_class => 'MasonX::Resolver::ExtendedCompRoot'

=head1 PREREQUISITES

HTML::Mason

=head1 BUGS

No known bugs.

=head1 VERSION

0.04

=head1 SEE ALSO

L<HTML::Mason::Resolver::File>, L<MasonX::Request::ExtendedCompRoot>, L<MasonX::Request::ExtendedCompRoot::WithApacheSession>

=head1 AUTHOR

Alex Robinson, <cpan[@]alex.cloudband.com>

=head1 LICENSE

MasonX::Resolver::ExtendedCompRoot is free software and can be used under the same terms as Perl, i.e. either the GNU Public Licence or the Artistic License.

=cut
