package Ploonga;

use strict;
use warnings;
use Carp;
use Groonga::API;
use Groonga::API::Constants qw/GRN_CTX_USE_QL/;
use JSON::XS ();
no bytes;

use constant DEFAULT_PORT => 10041;

our $VERSION = $Groonga::API::VERSION;

sub new {
  my ($class, %args) = @_;

  Groonga::API::init();

  $args{_ctx} = my $ctx = Groonga::API::ctx_open(GRN_CTX_USE_QL)
    or croak "failed to create a Groonga context";

  if (my $dbfile = $args{dbfile}) {
    if (-f $dbfile) {
      $args{_db} = Groonga::API::db_open($ctx, $dbfile)
        or croak "failed to open a Groonga database";
    }
    elsif (!$args{no_create}) {
      $args{_db} = Groonga::API::db_create($ctx, $dbfile, undef)
        or croak "failed to create a Groonga database";
    }
    else {
      croak "failed to open a Groonga database";
    }
  }
  elsif (my $host = $args{host}) {
    my $port = $args{port} || DEFAULT_PORT;
    my $rc = Groonga::API::ctx_connect($ctx, $host, $port, 0);
    croak "failed to connect to $host:$port ($rc)" if $rc;
  }

  $args{_json} = JSON::XS->new->utf8($args{encoding} ? 1 : 0);

  bless \%args, $class;
}

sub do {
  my ($self, @args) = @_;

  my $ctx = $self->{_ctx} or croak "no Groonga context";
  my $db = $self->{_db} or croak "no Groonga database";

  my $rc;

  for my $arg (@args) {
    my $encoded = $self->{encoding} ? Encode::encode($self->{encoding}, $arg) : $arg;
    $rc = Groonga::API::ctx_send($ctx, $encoded, bytes::length($encoded), 0);
    croak "command failed ($rc)" if $rc;
  }

  $rc = Groonga::API::ctx_recv($ctx, my $res, my $len, my $flags);
  croak "command failed ($rc)" if $rc;
  $res = substr($res, 0, $len);

  if ($self->{encoding}) {
    $res = Encode::decode($self->{encoding}, $res);
  }

  eval { $self->{_json}->decode($res) } || $res;
}

sub ctx { shift->{_ctx} }
sub db  { shift->{_db} }

sub DESTROY {
  my $self = shift;
  if (my $ctx = $self->{_ctx}) {
    if (my $db = $self->{_db}) {
      Groonga::API::obj_unlink($ctx, $db);
    }
    if (Groonga::API::get_major_version() > 1) {
      Groonga::API::ctx_close($ctx);
    } else {
      Groonga::API::ctx_fin($ctx);
    }
  }
  Groonga::API::fin();
}

1;

__END__

=head1 NAME

Ploonga - (yet another) interface to Groonga

=head1 SYNOPSIS

  use Ploonga;

  # Standalone mode
  my $ploonga = Ploonga->new(
    dbfile => 'db/test.db',
    no_create => 0, # set this to true if necessary
  );

  # Client mode
  my $ploonga = Ploonga->new(
    host => 'localhost',
    port => 10041,
  );

  # You can pass whatever builtin Groonga client accepts.
  my $ret = $ploonga->do('table_create --name Site --flags TABLE_HASH_KEY --key_type ShortText');

  # Extra args, instead of passing via stdin
  my $ret = $ploonga->do('load --table Site', <<'JSON');
  [
  {"_key":"http://example.org/","title":"This is test record 1!"},
  {"_key":"http://example.net/","title":"test record 2."},
  {"_key":"http://example.com/","title":"test test record three."},
  {"_key":"http://example.net/afr","title":"test record four."},
  {"_key":"http://example.org/aba","title":"test test test record five."},
  {"_key":"http://example.com/rab","title":"test test test test record six."},
  {"_key":"http://example.net/atv","title":"test test test record seven."},
  {"_key":"http://example.org/gat","title":"test test record eight."},
  {"_key":"http://example.com/vdw","title":"test test record nine."},
  ]
  JSON

=head1 DESCRIPTION

Unless you really want to do some complex stuff, this is the module you want to use to communicate with a Groonga database/server. The interface is almost the same as the builtin Groonga client. You simply don't need to quote commands nor decode json output by yourself.

If you do need, try L<Groonga::API>, which provides raw interface to Groonga C APIs.

=head1 METHODS

=head2 new

Creates a client object. Available options are: dbfile/no_create (for standalone mode), host/port (for client mode).

You can also set C<encoding> option to decode/encode when you send/receive data.

=head2 do

Takes a string expression which must contain a Groonga command (and optional string arguments to send), and returns the result, which may be a scalar, or some complex data structure.

=head2 ctx, db

Accessors to internal objects. Only useful when you use L<Groonga::API>.

=head1 SEE ALSO

L<Groonga::API>

L<http://groonga.org/>

L<https://github.com/yappo/p5-Groonga/>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
