# ABSTRACT: HiD 'server' subcmd - start up a Plack-based web server for your site


package HiD::App::Command::server;
our $AUTHORITY = 'cpan:GENEHACK';
$HiD::App::Command::server::VERSION = '1.992';
use Moose;
extends 'HiD::App::Command';
with 'HiD::Role::PublishesDrafts';
use namespace::autoclean;

use 5.014;  # strict, unicode_strings
use utf8;
use autodie;
use warnings    qw/ FATAL  utf8     /;
use open        qw/ :std  :utf8     /;
use charnames   qw/ :full           /;
use feature     qw/ unicode_strings /;

use Class::Load      qw/ try_load_class /;
use Plack::Builder;
use Plack::Runner;

use HiD::Server;
use HiD::Server::Handler;
use HiD::Server::Loader;


has auto_refresh => (
  is            => 'ro',
  isa           => 'Bool',
  traits        => [ 'Getopt' ],
  cmd_aliases   => [ qw/ auto A / ],
  documentation => 'auto re-publish when source changes, Default=False',
  lazy          => 1,
  default       => 0,
);


has clean => (
  is          => 'ro' ,
  isa         => 'Bool' ,
  cmd_aliases => 'C' ,
  traits      => [ 'Getopt' ] ,
);


has debug => (
  is          => 'ro' ,
  isa         => 'Bool' ,
  cmd_aliases => 'd' ,
  traits      => [ 'Getopt' ] ,
);


has port => (
  is            => 'ro' ,
  isa           => 'Int' ,
  traits        => [ 'Getopt' ] ,
  cmd_aliases   => 'p' ,
  documentation => 'port to run the server on. Default=5000' ,
  lazy          => 1 ,
  builder       => '_build_port' ,
);

sub _build_port {
  my $self = shift;

  return $self->{port} if defined $self->{port};

  my $config = $self->config;
  return $self->config->{server_port} // 5000;
}

sub _run {
  my( $self , $opts , $args ) = @_;

  my $config = $self->config;
  if ( $self->clean ) {
    $config->{clean_destination} = 1;
  }

  if ( $self->publish_drafts ){
    $config->{publish_drafts} = 1;
  }

  my $app = HiD::Server->new(
    error_pages => ($config->{error_pages} || {} ),
    root        => $self->destination,
  )->to_app;

  if ( $self->debug ) {
    if ( try_load_class( 'Plack::Middleware::DebugLogging' )) {
      $app = builder {
        enable_if { $ENV{PLACK_ENV} eq 'development' } 'DebugLogging';
        $app;
      };
    }
    else {
      print STDERR "*** Plack::Middleware::DebugLogging required for debug logging.\n";
      print STDERR "*** Continuing with normal logging.\n";
    }
  }

  my $runner = Plack::Runner->new;
  my %args   = ( '-p' => $self->port );
  $runner->parse_options(%args);

  # auto refresh
  if ( $self->auto_refresh ) {
    my @dirs = map { $self->hid->get_config($_) } qw/ include_dir layout_dir posts_dir /;

    for my $dir (qw/pages regular_files/) {
      push @dirs, map { $_->input_filename } @{ $self->hid->$dir };
    }

    # FIXME wish there was a better way to override stuff in Plack::Runner. >_<
    $runner->{server} = '+HiD::Server::Handler';
    $runner->{loader} = '+HiD::Server::Loader';
    $runner->loader->watch(@dirs);

    push @{$runner->{options}} , ( hid => $self );

    # no need to explicitly ->publish() here, as that will happen inside
    # HiD::Server::Loader, in the child, after the fork.
  }
  else { $self->publish() }

  $runner->run($app);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HiD::App::Command::server - HiD 'server' subcmd - start up a Plack-based web server for your site

=head1 SYNOPSIS

    $ ../bin/hid server
    HTTP::Server::PSGI: Accepting connections at http://0:5000/

=head1 DESCRIPTION

Start a Plack-based web server that serves your C<destination> directory.

=head1 ATTRIBUTES

=head2 auto_refresh

Automatically refresh result when source file/dir changed, just likey jekyll

Note that setting this will also clean out the destination directory whenever
a watched file changes.

=head2 clean

Remove any existing site directory prior to the publication run

=head2 debug

Emit debug-style logging for requests

=head2 port

Port number to bind. Defaults to 5000.

=head1 SEE ALSO

See L<HiD::App::Command> for additional command line options supported by all
sub commands.

=head1 VERSION

version 1.992

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
