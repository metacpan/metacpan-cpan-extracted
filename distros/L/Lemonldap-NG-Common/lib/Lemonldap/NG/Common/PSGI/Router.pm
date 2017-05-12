package Lemonldap::NG::Common::PSGI::Router;

use Mouse;
use Lemonldap::NG::Common::PSGI;
use Lemonldap::NG::Common::PSGI::Constants;

our $VERSION = '1.9.1';

extends 'Lemonldap::NG::Common::PSGI';

# Properties
has 'routes' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { GET => {}, POST => {}, PUT => {}, DELETE => {} } }
);
has 'defaultRoute' => ( is => 'rw', default => 'index.html' );

# Routes initialization

sub addRoute {
    my ( $self, $word, $dest, $methods ) = (@_);
    $methods ||= [qw(GET POST PUT DELETE)];
    foreach my $method (@$methods) {
        $self->genRoute( $self->routes->{$method}, $word, $dest );
    }
    return $self;
}

sub genRoute {
    my ( $self, $routes, $word, $dest ) = @_;
    if ( ref $word eq 'ARRAY' ) {
        foreach my $w (@$word) {
            $self->genRoute( $routes, $w, $dest );
        }
    }
    else {
        if ( $word =~ /^:(.*)$/ ) {
            $routes->{'#'} = $1;
            die "Target required for $word" unless ($dest);
            $word = ':';
        }
        else {
            $dest ||= $word;
        }
        if ( my $t = ref $dest ) {
            if ( $t eq 'CODE' ) {
                $routes->{$word} = $dest;
            }
            elsif ( $t eq 'HASH' ) {
                $routes->{$word} ||= {};
                foreach my $w ( keys %$dest ) {
                    $self->genRoute( $routes->{$word}, $w, $dest->{$w} );
                }
            }
            elsif ( $t eq 'ARRAY' ) {
                $routes->{$word} ||= {};
                foreach my $w ( @{$dest} ) {
                    $self->genRoute( $routes->{$word}, $w );
                }
            }
            else {
                die "Type $t unauthorizated in routes";
            }
        }
        elsif ( $dest =~ /^(.+)\.html$/ ) {
            my $tpl = $1 or die;
            $routes->{$word} = sub { $self->sendHtml( $_[1], $tpl ) };
        }
        elsif ( $self->can($dest) ) {
            $routes->{$word} = sub { shift; $self->$dest(@_) };
        }
        else {
            die "$dest() isn't a method";
        }
        $self->lmLog( "route $word added", 'debug' );
    }
}

sub handlerAbort {
    my ( $self, $path, $msg ) = @_;
    delete $self->routes->{$path};
    $self->addRoute(
        $path => sub {
            my ( $self, $req ) = @_;
            return $self->sendError( $req, $msg, 500 );
        }
    );
}

# Methods that dispatch requests

sub handler {
    my ( $self, $req ) = @_;

    #print STDERR Dumper($self->routes);use Data::Dumper;

    # Reinitialize configuration message
    $Lemonldap::NG::Common::Conf::msg = '';

    # Launch reqInit() if exists
    if ( $self->can('reqInit') ) {
        $self->reqInit($req);
    }

    # Only words are taken in path
    my @path = grep { $_ =~ /^[\.\w]+/ } split /\//, $req->path();
    $self->lmLog( "Start routing " . ( $path[0] // 'default route' ), 'debug' );

    unless (@path) {
        push @path, $self->defaultRoute;

        # TODO: E-Tag, Expires,...
        #
        ## NB: this is not HTTP compliant: host and protocol are required !
        #my $url = '/' . $self->defaultRoute;
        #return [
        #    302,
        #    [ 'Content-Type' => 'text/plain', 'Location' => $url ],
        #    ['Document has moved here: $url']
        #];
    }
    return $self->followPath( $req, $self->routes->{ $req->method }, \@path );
}

sub followPath {
    my ( $self, $req, $routes, $path ) = @_;
    if ( $path->[0] and defined $routes->{ $path->[0] } ) {
        my $w = shift @$path;
        if ( ref( $routes->{$w} ) eq 'CODE' ) {
            return $routes->{$w}->( $self, $req, @$path );
        }
        return $self->followPath( $req, $routes->{$w}, $path );
    }
    elsif ( $routes->{':'} ) {
        my $v = shift @$path;
        $req->params->{ $routes->{'#'} } = $v;
        if ( ref( $routes->{':'} ) eq 'CODE' ) {
            return $routes->{':'}->( $self, $req, @$path );
        }
        return $self->followPath( $req, $routes->{':'}, $path );
    }
    elsif ( my $sub = $routes->{'*'} ) {
        return $self->$sub( $req, @$path );
    }
    else {
        $self->lmLog( 'Bad request received (' . $req->path . ')', 'error' );
        return $self->sendError( $req, 'Bad request', 400 );
    }
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::PSGI::Router - Base library for REST APIs of Lemonldap::NG.

=head1 SYNOPSIS

  package My::PSGI;
  
  use base Lemonldap::NG::Common::PSGI::Router;
  
  sub init {
    my ($self,$args) = @_;
    # Will be called 1 time during startup
    
    # Declare REST routes (could be HTML templates or methods)
    $self->addRoute ( 'index.html', undef, ['GET'] )
         ->addRoute ( books => { ':book' => 'booksMethod' }, ['GET', 'POST'] )
         ->addRoute ( properties => { '*' => 'propertiesMethod' }, ['GET', 'POST', 'PUT', 'DELETE']);
  
    # Default route (ie: PATH_INFO == '/')
    $self->defaultRoute('index.html');
  
    # See Lemonldap::NG::Common::PSGI for other options
  
    # Return a boolean. If false, then error message has to be stored in
    # $self->error
    return 1;
  }
  
  sub booksMethod {
    my ( $self, $req, @otherPathInfo ) = @_;
    my $book = $req->params('book');
    my $method = $req->method;
    ...
    $self->sendJSONresponse(...);
  }
  
  sub propertiesMethod {
    my ( $self, $property, @otherPathInfo ) = @_;
    my $method = $req->method;
    ...
    $self->sendJSONresponse(...);
  }

This package could then be called as a CGI, using FastCGI,...

  #!/usr/bin/env perl
  
  use My::PSGI;
  use Plack::Handler::FCGI; # or Plack::Handler::CGI

  Plack::Handler::FCGI->new->run( My::PSGI->run() );

=head1 DESCRIPTION

This package provides base class for Lemonldap::NG REST API but could be
used regardless.

=head1 METHODS

See L<Lemonldap::NG::Common::PSGI> for logging methods, content sending,...

=head2 Initialization methods

=head3 addRoute ( $word, $dest, $methods )

Declare a REST route. Arguments:

=over

=item $word:

the first word of /path/info.

=item $dest:

string, sub ref or hash ref (see "Route types" below)

=item $methods:

array ref containing the methods concerned by this route.

=back

=head4 Route types

As seen in "SYNOPSIS", you can declare routes with variable component. $dest
can be:

=over

=item a word:

the name of the method to call

=item undef:

$word is used as $dest

=item a ref to code:

an anonymous subroutin to call

=item a hash ref:

it's a recursive call to `{ $word => $dest }`

=item an array ref:

in this case each element of the array will be considered as
`{ $element => $element }`. So each element must be a word that makes a
correspondence between a path_info word and a subroutine

=back

Some special $word:

=over

=item ':name':

the word in path_info will be stored in GET parameters

=item '*':

the subroutine will be called with the word of path_info as second argument
(after $req)

=item 'something.html':

if $word finishes with '.html', then sendHtml() will be called with
'something.tpl' as template name. In this case, $dest is not used.

=back

Examples:

=over

=item to manage http://.../books/127 with book() where 127 is the book number, use:

  $self->addRoute( books => { ':bookId' => 'book' }, ['GET'] );

booId parameter will be stored in $req->params('bookId');

=item to manage http://.../books/127/pages/5 with page(), use:

  $self->addRoute( books => { ':bookId' => { pages => { ':pageId' => 'page' } } }, ['GET'] );

=item to manage simultaneously the 2 previous examples 

  $self->addRoute( books => { ':bookId' => { pages => { ':pageId' => 'page' } } }, ['GET'] )
       ->addRoute( books => { ':bookId' => { '*' => 'book' } }, ['GET'] );

Note that book() will be called for any path_info containing /books/<$bookid>/<$other>
except if $other == 'pages'.

=item to manage /properties/p1, /properties/p2 with p1() and p2(), use:

  $self->addRoute( properties => [ 'p1', 'p2' ] );

=back

=head3 defaultRoute($path)

This method defined which path_info to use if path_info is '/' or empty.

=head2 Accessors

See L<Lemonldap::NG::Common::PSGI> for inherited accessors (error, languages,
logLevel, staticPrefix, templateDir, links, syslog).

=head1 SEE ALSO

L<http://lemonldap-ng.org/>, L<Lemonldap::NG::Portal>, L<Lemonldap::NG::Handler>,
L<Plack>, L<PSGI>, L<Lemonldap::NG::Common::PSGI>,
L<Lemonldap::NG::Common::PSGI::Request>, L<HTML::Template>, 

=head1 AUTHORS

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2015-2016 by Clément Oudot, E<lt>clem.oudot@gmail.comE<gt>

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
