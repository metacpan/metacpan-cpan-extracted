package HTML::Meta::Robots;
############################################################################
# A simple HTML meta tag "robots" generator.
# @copyright © 2013, BURNERSK. Some rights reserved.
# @license http://www.perlfoundation.org/artistic_license_2_0 Artistic License 2.0
# @author BURNERSK <burnersk@cpan.org>
############################################################################
# Perl pragmas.
use strict;
use warnings FATAL => 'all';
use utf8;
use version 0.77; our $VERSION = version->new('v0.3.3');

############################################################################
# Register accessor methods.
BEGIN {
  no strict 'refs';  ## no critic (ProhibitNoStrict ProhibitProlongedStrictureOverride)
  use Carp qw( carp );

  my @simple_accessors     = qw( follow archive odp ydir snippet );
  my %deprecated_accessors = (
    open_directory_project => 'odp',
    yahoo                  => 'ydir',
  );

  # Register simple accessors which only can get/set boolean values.
  foreach my $accessor (@simple_accessors) {
    *{"HTML::Meta::Robots::$accessor"} = sub {
      my ( $self, @params ) = @_;
      $self->_accessor( $accessor, @params );
    };
  }

  # Register index accessor which also sets simple accessors.
  *{'HTML::Meta::Robots::index'} = sub {
    my ( $self, @params ) = @_;
    if ( scalar @params ) {
      $self->_accessor( $_, @params ) for @simple_accessors;
    }
    $self->_accessor( 'index', @params );
  };

  # Register DEPRECATED accessors.
  foreach my $accessor ( keys %deprecated_accessors ) {
    *{"HTML::Meta::Robots::$accessor"} = sub {
      my ( $self, @params ) = @_;
      carp sprintf
        q{Usage of %s->%s is DEPRECATED and will be removed in future! Use %s->%s instead},
        __PACKAGE__, $accessor,
        __PACKAGE__, $deprecated_accessors{$accessor};
      $self->_accessor( $deprecated_accessors{$accessor}, @params );
    };
  }
}

############################################################################
# Class constructor.
sub new {
  my ( $class, %params ) = @_;
  my $self = bless {}, $class;

  # Setup property order.
  $self->{order} = [qw( index follow archive odp ydir snippet )];

  # Allow all properties by default.
  $self->{props}->{$_} = 1 for @{ $self->{order} };

  # Set properties configured by init parameters.
  $self->$_( $params{$_} ) for grep { exists $self->{props}->{$_} } keys %params;

  return $self;
}

############################################################################
# INTERNAL - Simple getter/setter for internal fields.
sub _accessor {
  my ( $self, $field, @params ) = @_;
  if ( scalar @params ) {
    $self->{props}->{$field} = $params[0] ? 1 : 0;
    return $self;
  }
  return $self->{props}->{$field};
}

############################################################################
# Return robots meta tag's content.
sub content {
  my ($self) = @_;
  return join q{,}, map { $self->{props}->{$_} ? $_ : "no$_" } @{ $self->{order} };
}

############################################################################
# Return robots meta tag.
sub meta {
  my ( $self, $no_xhtml ) = @_;
  if ( !$no_xhtml ) {
    return sprintf '<meta name="robots" content="%s"/>', $self->content;
  }
  else {
    return sprintf '<meta name="robots" content="%s">', $self->content;
  }
}

############################################################################
# Parses external robot meta tag content.
sub parse {
  my ( $self, $content ) = @_;
  my %props = map { $_ =~ m/^(no)?(.+)$/s; $2 => $1 ? 0 : 1 } split /\s*,\s*/s, lc $content;
  $self->index( delete( $props{index} ) // 1 );
  $self->$_( delete $props{$_} ) for grep { exists $self->{props}->{$_} } keys %props;
  $self->{unknown_props} = \%props if scalar keys %props;
  return $self;
}

############################################################################
1;
__END__
=pod

=encoding utf8

=head1 NAME

HTML::Meta::Robots - A simple HTML meta tag "robots" generator.

=head1 VERSION

v0.3

=head1 SYNOPSIS

    use HTML::Meta::Robots;
    
    # Default "robots" as meta tag element.
    my $robots = HTML::Meta::Robots->new;
    print sprintf '<html><head>%s</head></html>', $robots->meta;
    
    # Default "robots" as meta tag content.
    my $robots = HTML::Meta::Robots->new;
    printf '<html><head><meta name="robots" content="%s"/></head></html>', $robots->content;
    
    # Do not "allow" creation of google snippets.
    my $robots = HTML::Meta::Robots->new;
    $robots->snippet(0);
    
    # Do not "allow" creation of google snippets and indexing by the Yahoo crawler.
    my $robots = HTML::Meta::Robots->new;
    $robots->snippet(0);
    $robots->ydir(0);
    # on as one-liner:
    $robots->snippet(0)->ydir(0);
    
    # What is the indexing state of the Open Directory Project?
    my $robots = HTML::Meta::Robots->new;
    printf "It's %s\n", $robots->odp ? 'allowed' : 'denied';

=head1 DESCRIPTION

HTML::Meta::Robots is a simple helper object for generating HTML "robot"
meta tags such as:

    <meta name="robots" content="index,allow"/>

HTML::Meta::Robots currently supports the following "robots" attributes:

=over

=item (no)index

Allows or denies any search engine to index the page.

=item (no)follow

Allows or denies any search engine to follow links on the page.

=item (no)archive

Allows or denies the L<Internet Archive|http://www.archive.org/> to cache
the page.

=item (no)odp

Allows or denies the L<Open Directory Project|http://www.dmoz.org/> search
engine to index the page.

=item (no)ydir

Allows or denies the L<Yahoo|http://www.yahoo.com/> search engine to index
the page.

=item (no)snippet

Allows or denies the L<Google|http://www.google.com/> search engine to
display an abstract of the page and at the same time to cache the page.

=back

=head2 Why don't use Moo(se)?

Yes, I could reduce a lot of the code by using Moo(se). However I decided to
not use Moo(se) because of my own experience with "more strict" corporation.
The problem is that some corporation have to review the code they use for
security reasons including all dependencies. Some handlers require this in
order to handle corporation data such as credit cards (PCI-DSS). Doing a
security review is kind of boring and take a lot of valuable time for the
corporation so I have written this Module with no-deps.

=head1 METHODS

=head2 new

Creates and returns a new HTML::Meta::Robots object. For example:

    my $robots = HTML::Meta::Robots->new;

Optional parameters are:

=over

=item index => (1|0)

See L</"index"> for details.

=item follow => (1|0)

See L</"follow"> for details.

=item archive => (1|0)

See L</"archive"> for details.

=item odp => (1|0)

See L</"odp"> for details.

=item ydir => (1|0)

See L</"ydir"> for details.

=item snippet => (1|0)

See L</"snippet"> for details.

=back

=head2 index

Get or set the index state. For example:

    # Retrieve index state:
    my $state = $robots->index;
    
    # Set index state to allow:
    $robots->index(1);
    
    # Set index state to deny:
    $robots->index(0);

B<Note>, that C<index> will apply its state to all the other attributes when
called as setter!

=head2 follow

Get or set the follow state. For example:

    # Retrieve follow state:
    my $state = $robots->follow;
    
    # Set follow state to allow:
    $robots->follow(1);
    
    # Set follow state to deny:
    $robots->follow(0);

=head2 archive

Get or set the archive state. For example:

    # Retrieve archive state:
    my $state = $robots->archive;
    
    # Set archive state to allow:
    $robots->archive(1);
    
    # Set follow state to deny:
    $robots->archive(0);

=head2 open_directory_project

DEPRECATED - See L</"odp">.

=head2 odp

Get or set the Open Directory Project state. For example:

    # Retrieve archive state:
    my $state = $robots->odp;
    
    # Set open_directory_project state to allow:
    $robots->odp(1);
    
    # Set open_directory_project state to deny:
    $robots->odp(0);

=head2 yahoo

DEPRECATED - See L</"odp">.

=head2 ydir

Get or set the Yahoo state. For example:

    # Retrieve yahoo state:
    my $state = $robots->ydir;
    
    # Set yahoo state to allow:
    $robots->ydir(1);
    
    # Set yahoo state to deny:
    $robots->ydir(0);

=head2 snippet

Get or set the snippet state. For example:

    # Retrieve snippet state:
    my $state = $robots->snippet;
    
    # Set snippet state to allow:
    $robots->snippet(1);
    
    # Set snippet state to deny:
    $robots->snippet(0);

=head2 content

Returns the content part of an HTML robots meta tag. For example:

    printf '<html><head><meta name="robots" content="%s"/></head></html>', $robots->content;

=head2 meta

Returns a string representing a full HTML robots meta tag. For example:

    printf '<html><head>%s</head></html>', $robots->meta;

=head2 parse

Returns the content part of an HTML robots meta tag. For example:

    my $content = 'noindex,follow,archive,odp,ydir,snippet';
    my $robots = HTML::Meta::Robots->new->parse($content);
    printf "%s is %sed\n", 'index', $robots->index ? 'allow' : 'deny';
    printf "%s is %sed\n", 'follow', $robots->follow ? 'allow' : 'deny';

=head1 BUGS AND LIMITATIONS

Report bugs and feature requests as a
L<GitHub Issue|https://github.com/burnersk/HTML-Meta-Robots/issues>, please.

=head1 AUTHOR

=over

=item *

L<BURNERSK|https://metacpan.org/author/BURNERSK> E<lt>L<burnersk@cpan.org|mailto:burnersk@cpan.org>E<gt>

=back

But there are more people who have contributed to HTML::Meta::Robots:

L<HORNBURG|https://metacpan.org/author/HORNBURG>,
L<MITHALDU|https://metacpan.org/author/MITHALDU>

=head1 LICENSE

HTML::Meta::Robots by BURNERSK is licensed under a
L<Artistic 2.0 License|http://www.perlfoundation.org/artistic_license_2_0>.

=head1 COPYRIGHT

Copyright © 2013, BURNERSK. Some rights reserved.

=cut
