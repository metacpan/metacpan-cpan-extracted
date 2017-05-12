package Gideon::Meta::Attribute::Trait::DBI::Inflate::DateTime;
{
  $Gideon::Meta::Attribute::Trait::DBI::Inflate::DateTime::VERSION = '0.0.3';
}
use Moose::Role;
use DBI;

#ABSTRACT: Auto-inflate DateTime

with 'Gideon::Meta::Attribute::Trait::Inflated';

Moose::Util::meta_attribute_alias('Gideon::DBI::Inflate::DateTime');

use constant FORMAT_CLASS => {
    'mysql'  => 'DateTime::Format::MySQL',
    'pg'     => 'DateTime::Format::Pg',
    'db2'    => 'DateTime::Format::DB2',
    'mssql'  => 'DateTime::Format::MSSQL',
    'oracle' => 'DateTime::Format::Oracle',
    'sqlite' => 'DateTime::Format::SQLite',
    'sybase' => 'DateTime::Format::Sybase',
};

sub get_inflator {
    my ( $self, $source ) = @_;
    my $format_class = $self->_get_format_class($source);
    return sub {
        return unless $_[0];
        $format_class->parse_datetime( $_[0] );
    };
}

sub get_deflator {
    my ( $self, $source ) = @_;

    my $format_class = $self->_get_format_class($source);
    return sub {
        return unless $_[0];
        $format_class->format_datetime( $_[0] );
    };
}

sub _get_format_class {
    my ( $self, $source ) = @_;

    my @dbs = eval { DBI::_dbtype_names( $source, 0 ) };
    my ($db) = grep { FORMAT_CLASS->{ lc($_) } } @dbs;

    die 'Can\'t find format class' unless $db;

    my $format_class = FORMAT_CLASS->{ lc($db) };
    eval "require $format_class";

    return $format_class;
}

1;

__END__

=pod

=head1 NAME

Gideon::Meta::Attribute::Trait::DBI::Inflate::DateTime - Auto-inflate DateTime

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

  package User;
  use Gideon driver => 'DBI';

  has created_at => (
      is => 'rw',
      isa => 'DateTime',
      traits => [ 'Gideon::DBI::Column', 'Gideon::DBI::Inflate::DateTime' ]
  );

=head1 DESCRIPTION

Automatically inflate and deflate DateTime columns when working with RDB

=head1 NAME

Gideon::Meta::Attribute::Trait::DBI::Inflate::DateTime

=head1 VERSION

version 0.0.3

=head1 ALIAS

Gideon::DBI::Inflate::DateTime

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
