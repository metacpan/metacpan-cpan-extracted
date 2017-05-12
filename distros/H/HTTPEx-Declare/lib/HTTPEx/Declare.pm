package HTTPEx::Declare;
use strict;
use warnings;
our $VERSION = '0.03';
use HTTP::Engine;
use HTTP::Engine::Response;

sub compat_exports {
    require HTTP::Engine::Compat;
    HTTP::Engine::Compat->import;
    {
        middlewares => \&middlewares,
        interface   => \&interface,
        run         => \&run,
    };
}

use Sub::Exporter -setup => {
    exports => [qw/ middlewares interface run res /],
    groups  => {
        default => [qw/ interface run res /],
        Compat  => \&compat_exports,
    },
};

my ($module, $args);

sub middlewares (@)  { HTTP::Engine::Compat->load_middlewares(@_) }

sub interface ($$) { ( $module, $args ) = @_ }

sub run (&;@) {
    unless ($module && $args) {
        require Carp;
        Carp::croak 'please define interface previously';
    }
    my $request_handler = shift;
    my $engine          = HTTP::Engine->new(
        interface => {
            module          => $module,
            args            => $args,
            request_handler => sub {
                no warnings 'redefine';
                local *_res = sub { HTTP::Engine::Response->new(@_) };
                $request_handler->(@_);
            },
        },
    );
    undef $module;
    undef $args;
    $engine->run(@_);
}

sub res { goto &_res; }

sub _res {
    require Carp;
    Carp::croak "Can't call res() outside run block";
}

1;
__END__

=for stopwords Tokuhiro Matsuno DebugScreen  ModuleReload  middlewares  preload

=head1 NAME

HTTPEx::Declare - Declarative HTTP::Engine

=head1 SYNOPSIS

  use HTTPEx::Declare;

  interface ServerSimple => {
      host => 'localhost',
      port => 1978,
  };

  use Data::Dumper;
  run {
      my $req = shift;
      res( body => Dumper($req) );
  };

for HTTP::Engine::Compat

  use HTTPEx::Declare -Compat;

  interface ServerSimple => {
      host => 'localhost',
      port => 1978,
  };

  use Data::Dumper;
  run {
      my $c = shift;
      $c->res->body( Dumper($c->req) );
  };

middlewares preload
  middlewares 'DebugScreen', 'ModuleReload';

=head1 DESCRIPTION

HTTPEx::Declare is DSL to use L<HTTP::Engine> easily. 

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

Tokuhiro Matsuno

=head1 SEE ALSO

L<HTTP::Engine>,
L<HTTP::Engine::Compat>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/HTTPEx-Declare/trunk HTTPEx-Declare

HTTPEx::Declare's Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
