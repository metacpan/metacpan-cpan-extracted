use strict;
use warnings;
package Metabase::Web::Model::Metabase;
use base 'Catalyst::Model';

our $VERSION = '0.001';
$VERSION = eval $VERSION;

use Catalyst::Utils;
use Params::Util qw(_CLASS);

=head1 NAME

Metabase::Web::Model::Metabase - the Metabase::Web's model for the Metabase

=head1 DESCRIPTION

This model sets up a gateway, complete with librarians and archivers, and
provides easy access to them.  Most of the logic that Metabase::Web will rely
in for retrieving or adding facts is either in
L<Metabase::Web::Controller::Root|Metabase::Web::Controller::Root> or the
Gateway and Librarian classes.

=head1 CONFIGURATION

Configuration can be used to configure the librarians (public and secret), the
gateway, and the archives and indices.  Valid configuration may look like:

  gateway:
    CLASS: the gateway class (defaults to Metabase::Gateway)
    librarian:
      CLASS: the librarian class (defaults to Metabase::Librarian)
      archive:
        CLASS: the archive class (defaults to Metabase::Archive::Filesystem)
      index:
        CLASS: the index class (defaults to Metabase::Index::FlatFile)
    secret_librarian: (same structure as librarian)
  fact_classes: [ arrayref of allowed Fact classes ]

(This section will be expanded in the future.)

=cut

my $default_config = {
  gateway   => {
    CLASS => 'Metabase::Gateway',
    librarian => {
      CLASS => 'Metabase::Librarian',
      archive => { CLASS => 'Metabase::Archive::Filesystem' },
      index   => { CLASS => 'Metabase::Index::FlatFile'     },
    },
    secret_librarian => {
      CLASS   => 'Metabase::Librarian',
      archive => { CLASS => 'Metabase::Archive::Filesystem' },
      index   => { CLASS => 'Metabase::Index::FlatFile'     },
    },
  },
};

sub _initialize {
  my ($self, $entry, $extra) = @_;
  my $merged = Catalyst::Utils::merge_hashes($entry, $extra);

  my $class = delete $merged->{CLASS};
  eval "require $class; 1" or die "couldn't load Model::Metabase class: $@";
  my $obj = $class->new($merged);
}

sub COMPONENT {
  my ($class, $c, $user_config) = @_;

  my $config = Catalyst::Utils::merge_hashes($default_config, $user_config);

  my $self = bless {} => $class;
  
  my $fact_classes = $config->{fact_classes};
  Carp::croak "no fact_classes supplied to $class configuration"
    unless $fact_classes and @$fact_classes;

  # XXX why are we loading classes here?  why not leave to gateway instead?
  # -- dagolden, 2009-03-31
  for my $fact_class (@$fact_classes) {
    Carp::croak "invalid fact class: $fact_class" unless _CLASS($fact_class);
    eval "require $fact_class; 1" or die "couldn't load fact class: $@";
  }

  my %librarian;

  for my $which (qw(librarian secret_librarian)) {
    my ($archive, $index);
    my $config = $config->{gateway}{$which};

    if ($config->{database}) {
      # This branch is here mostly to remind me that something like this should
      # be possible. -- rjbs, 2008-04-14
      $archive = $index = $self->_initialize($config->{database});
    } else {
      $archive = $self->_initialize($config->{archive});
      $index   = $self->_initialize($config->{index});
    }
    
    delete @$config{qw(database archive index)};

    $librarian{ $which } = $self->_initialize(
      $config,
      {
        archive => $archive,
        index   => $index,
      },
    );
  }

  my $gateway = $self->_initialize(
    $config->{gateway},
    {
      fact_classes => $fact_classes,
      %librarian
    },
  );

  # XXX: This is sort of a massive hack, but it makes testing easy by giving us
  # access to the gateway the test server will use. -- rjbs, 2009-03-30
  if (my $code = our $COMPONENT_CALLBACK) {
    $code->($gateway);
  }

  $self->{gateway} = $gateway;
  return $self;
}

=head1 METHODS

=head2 gateway

This method returns the metabase's gateway.

=head2 librarian

This method returns the metabase's public librarian.

=cut

sub gateway   { $_[0]->{gateway} }
sub librarian { $_[0]->gateway->librarian }

=head1 AUTHOR

=over 

=item * David A. Golden (DAGOLDEN)

=item * Ricardo J. B. Signes (RJBS)

=back

=head1 COPYRIGHT AND LICENSE

  Portions copyright (c) 2008-2009 by David A. Golden
  Portions copyright (c) 2008-2009 by Ricardo J. B. Signes

Licensed under the same terms as Perl itself (the "License").
You may not use this file except in compliance with the License.
A copy of the License was distributed with this file or you may obtain a
copy of the License from http://dev.perl.org/licenses/

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
