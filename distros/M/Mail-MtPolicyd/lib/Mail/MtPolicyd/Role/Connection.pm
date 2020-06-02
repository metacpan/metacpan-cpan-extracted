package Mail::MtPolicyd::Role::Connection;

use strict;
use MooseX::Role::Parameterized;

use Mail::MtPolicyd::ConnectionPool;

# ABSTRACT: role to consume connections from connection pool
our $VERSION = '2.04'; # VERSION

parameter name => (
  isa => 'Str',
  default => 'db',
);

parameter type => (
  isa => 'Str',
  default => 'Sql',
);

parameter initialize_early => (
  isa => 'Bool',
  default => 1,
);

role {
  my $p = shift;
  my $name = $p->name;
  my $conn_attr = '_'.$p->name;
  my $handle_attr = $conn_attr.'_handle';
  my $conn_class = 'Mail::MtPolicyd::Connection::'.$p->type;

  if( $p->initialize_early ) {
    before 'init' => sub {
        my $self = shift;
        $self->$conn_attr;
        return;
    };
  }

  has $name => (
    is => 'ro', 
    isa => 'Str',
    default => $name,
  );

  has $conn_attr => (
    is => 'ro',
    isa => $conn_class,
    lazy => 1,
    default => sub {
      my $self = shift;
      my $conn = Mail::MtPolicyd::ConnectionPool->get_connection($self->$name);
      if( ! defined $conn ) {
        die("no connection $name configured!");
      }
      return $conn;
    },
  );

  method $handle_attr => sub {
    my $self = shift;
    return $self->$conn_attr->handle;
  };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Role::Connection - role to consume connections from connection pool

=head1 VERSION

version 2.04

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
