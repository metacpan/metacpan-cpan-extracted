package Gantry::Plugins::DBIxClassConn;
use strict; use warnings;

use base 'Exporter';

our @EXPORT = qw( get_schema get_auth_schema );

sub get_schema {
    my $self = shift;

    return $self->{__SCHEMA__} if defined $self->{__SCHEMA__};

    my $base = $self->schema_base_class;

    $self->{__SCHEMA__} = $base->connect( 
        $self->fish_config( 'dbconn' ),
        $self->fish_config( 'dbuser' ),
        $self->fish_config( 'dbpass' ),
        $base->get_db_options
    );
    
    return $self->{__SCHEMA__};
}

sub get_auth_schema {
    my $self = shift;

    return $self->{__AUTH_SCHEMA__} if defined $self->{__AUTH_SCHEMA__};

    if ( $self->can( 'schema_auth_base_class' ) ) {
        my $base = $self->schema_auth_base_class;

        $self->{__AUTH_SCHEMA__} = $base->connect( 
            $self->fish_config( 'auth_dbconn' ),
            $self->fish_config( 'auth_dbuser' ),
            $self->fish_config( 'auth_dbpass' ),
            $base->get_db_options
        );
        return $self->{__AUTH_SCHEMA__};
    }
    else {
        return $self->get_schema();
    }
}

1;

__END__

=head1 NAME

Gantry::Plugins::DBIxClassConn - DBIx::Class schema accessor mixin

=head1 SYNOPSIS

In any controller:

    use YourModel;
    use YourAuthModel;
    sub schema_base_class { return 'YourModel'; }
    sub schema_auth_base_class { return 'YourAuthModel'; }
    use Gantry::Plugins::DBIxClassConn;

    sub some_method {
        my $self   = shift;
        #...

        my $schema = $self->get_schema;

        # Use $schema as instructed in DBIx::Class docs.
    }

    sub some_auth_method {
        my $self        = shift;
        my $auth_schema = $self->get_auth_schema();
    }

    package YourModel;

    sub get_db_options {
        return { AutoCommit => 1 };  # or whatever options you want
    }

    package YourAuthModel;

    sub get_db_options {
        return { AutoCommit => 1 };  # or whatever options you want
    }

Alternatively, in your controller which uses Gantry::Plugins::DBIxClassConn:

    sub some_method {
        my $self = shift;

        my @rows = $MY_TABLE->gsearch( $self, { ... }, { ... } );
    }

=head1 DESCRIPTION

This mixin gives you an accessor which returns the DBIx::Class schema
object for your data model.  It expects dbconn, dbuser, and dbpass
to be in your site conf, so it can call fish config to get them.
If you use get_auth_schema, it expects auth_dbconn, auth_dbuser and
auth_dbpass to be in your site conf.

In order for this module to help you, your model (and/or auth model)
must provide one helper:

=over 4

=item get_db_options

This supplies the default DBI parameters to the connection method.
This is usually sufficient:

    sub get_db_options { return {}; }

Note that the return value must be a hash reference.

=back

If you model inherits from Gantry::Utils::DBIxClass, it will have a family
of convenience methods meant to reduce typing.  These are the same methods
DBIx::Class makes available through resultsets, but with a couple of
twists.  First, the names of the methods have a g in front.  Second,
the g methods expect to be called as class methods on the model.  Third,
the g methods expect the Gantry site object as their first (non-invoking)
parameter.  The rest of the parameters are the same as for the corresponding
call via a DBIC resultset.

Note that for the g methods to work on the model, your site object must
use this mixin.  The g methods call get_schema.

=head1 METHOD EXPORTED into YOUR PACKAGE

=over 4

=item get_schema

Exported.

Returns a DBIx::Class schema ready for use (if you set up your connection
info in the right way, see Gantry::Docs::DBConn).

=item get_auth_schema

Exported.

Returns a DBIx::Class schema ready for use (if you set up your connection
info in the right way, see Gantry::Docs::DBConn).

=back

=head1 SEE ALSO

Gantry::Docs::DBConn, Gantry::Utils::ModelHelper, but only if you use
a different ORM than DBIx::Class.

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
