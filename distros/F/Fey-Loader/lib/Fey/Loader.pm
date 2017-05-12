package Fey::Loader;
{
  $Fey::Loader::VERSION = '0.13';
}

use strict;
use warnings;

use Fey::Loader::DBI;

sub new {
    my $class = shift;
    my %p     = @_;

    my $dbh    = $p{dbh};
    my $driver = $dbh->{Driver}{Name};

    my $subclass = $class->_determine_subclass($driver);

    return $subclass->new(%p);
}

sub _determine_subclass {
    my $class  = shift;
    my $driver = shift;

    my $subclass = $class . '::' . $driver;

    {

        # Shuts up UNIVERSAL::can
        no warnings;
        return $subclass if $subclass->can('new');
    }

    return $subclass if eval "use $subclass; 1;";

    die $@ unless $@ =~ /Can't locate/;

    warn <<"EOF";

There is no driver-specific $class subclass for your driver ($driver)
... falling back to the base DBI implementation. This may or may not
work.

EOF

    return $class . '::' . 'DBI';
}

1;

# ABSTRACT: Load your schema definition from a DBMS



=pod

=head1 NAME

Fey::Loader - Load your schema definition from a DBMS

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  my $loader = Fey::Loader->new( dbh => $dbh );

  my $loader = Fey::Loader->new(
      dbh          => $dbh,
      schema_class => '...',
      table_class  => '...',
  );

  my $schema = $loader->make_schema();

=head1 DESCRIPTION

C<Fey::Loader> takes a C<DBI> handle and uses it to construct a set of
Fey objects representing that schema. It will attempt to use an
appropriate DBMS subclass if one exists, but will fall back to using a
generic loader otherwise.

The generic loader simply uses the various schema information methods
specified by C<DBI>. This in turn depends on these methods being
implemented by the driver.

See the L<Fey::Loader::DBI> class for more details on what parameters the
C<new()> method accepts.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Loader->new( dbh => $dbh )

Given a connected C<DBI> handle, this method returns a new loader. If
an appropriate subclass exists, it will be loaded and used. Otherwise,
it will warn and fall back to using L<Fey::Loader::DBI>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-fey-loader@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

