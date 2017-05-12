package Gantry::Utils::CRUDHelp;
use strict;

use base 'Exporter';

our @EXPORT = qw(
    clean_dates
    form_profile
    clean_params
    write_file
    verify_permission
);

sub write_file {
    my( $self, $field, $archive, $extra_dir, $forced_file_name ) = @_;
    
    my $upload = $self->file_upload( $field );

    my $id = $upload->{unique_key};

    if ( $forced_file_name ) {
        $upload->{ident} = $forced_file_name . $upload->{suffix};
    }
    else {
        $upload->{ident} = $id  . $upload->{suffix};    
    }
    
    my $file = File::Spec->catfile( $archive, $extra_dir, $upload->{ident} );

    my $dir  = File::Spec->catfile( $archive, $extra_dir );
    File::Path::mkpath( $dir );
    
    open( FH, ">", $file ) or die "Error unable to open $file: $!";
    binmode FH;

    my( $buffer, $buffer_size ) = ( '', 14096 );
    while ( read( $upload->{filehandle}, $buffer, $buffer_size ) ) {
        print FH $buffer;
    }        
    close FH;
    
    my $h = {
        "$field"            => $file,
        "${field}_ident"    => $upload->{ident},
        "${field}_suffix"   => $upload->{suffix},
        "${field}_mime"     => $upload->{mime},
        "${field}_name"     => $upload->{name},
        "${field}_size"     => $upload->{size},              
    };
    
    $h->{"${field}_directory"} = $extra_dir if $extra_dir;
    
    return( $h );

}

# If a field is a date and its value is false, make it undef.
sub clean_dates {
    my ( $params, $fields ) = @_;

    foreach my $field ( @{ $fields } ) {
        my $name = $field->{name};

        if ( ( $field->{is} eq 'date' )
                and
             ( not $params->{ $name } )
           )
        {
            $params->{ $name } = undef;
        }
    }
}

# build the profile that Data::FormValidator wants
sub form_profile {
    my ( $form_fields ) = @_;
    my @required;
    my @optional;
    my %constraints;

    foreach my $item ( @{ $form_fields } ) {
        if ( defined $$item{optional} and $$item{optional} ) {
            push @optional, $$item{name};
        }
        elsif ( defined $$item{type} and $$item{type} eq 'display' ) {
            push @optional, $$item{name};            
        }
        else {
            push @required, $$item{name};
        }

        if ( defined $$item{constraint} and $$item{constraint} ) {
            $constraints{ $$item{name} } = $$item{constraint};
        }
    }

    my %retval;

    $retval{required}           = \@required    if @required;
    $retval{optional}           = \@optional    if @optional;
    $retval{constraint_methods} = \%constraints if ( keys %constraints );

    return \%retval;
}

# If a field's type is not boolean, and its value is false, make that
# value undef.
sub clean_params {
    my ( $params, $fields ) = @_;

    foreach my $p ( keys %{ $params } ) {
        delete( $params->{$p} ) if $p =~ /^\./;
    }
    
    FIELD:
    foreach my $field ( @{ $fields } ) {
        my $name = $field->{name};

        next FIELD unless ( defined $field->{ is } );
        next FIELD unless ( defined $field->{ name } );
        next FIELD unless ( defined $params->{ $name } );

        if ( $field->{ is } =~ /^varchar/i and $params->{ $name } eq '' ) {
            $params->{ $name } = undef;
        }
        elsif ( $field->{ is } =~ /^int/i and $params->{ $name } eq '' ) {
            $params->{ $name } = undef;
        }
        elsif ( ( $field->{is} !~ /^bool/i and $field->{is} !~ /^int/i )
                and
             ( not $params->{ $name } )
           )
        {
            $params->{ $name } = undef;
        }
    }
}

my %action_offset = (
    add      => 0,
    retrieve => 1,
    edit     => 2,
    delete   => 3,
);

# Full permissions bits:
#  123456789 1
# crudcrudcrud

sub verify_permission {
    my $opts = shift;

    my $site        = $opts->{ site        };
    my $row         = $opts->{ row         };
    my $permissions = $opts->{ permissions };
    my $action      = $opts->{ action      };
    my $params      = $opts->{ params      } || {};  # default for delete

    if ( not defined $action ) {
        $action = $site->action();
        $action =~ s/^do_//;
    }

    $permissions ||= $site->controller_config->{ permissions };
    return if ( not defined $permissions );  # no permissions => every body in

    my $offset      = $action_offset{ $action };
    my $action_bit  = substr 'crud', $offset, 1;

    my $owner_bit   = substr $permissions->{ bits }, $offset,     1;
    my $group_bit   = substr $permissions->{ bits }, $offset + 4, 1;
    my $other_bit   = substr $permissions->{ bits }, $offset + 8, 1;

    # there are three ways you could be allowed to add, if permissions
    # are in use
    # 1. You are not logged in, but the other block has perm bit
    # 2. You are logged in and the user block has perm bit
    # 3. You are logged in and belong to the tables group which has perm bit

    my $user_row = $site->auth_user_row;
    my $user_id  = $user_row->id;

    if ( $action eq 'add' ) {
        # For add, set the id in case we need it.  Anonymous users get id 0.
        $params->{ user_id } = $user_id || 0;

        # is user logged in? if so an owner_bit will work
        return if ( $user_id
                        and
                    $owner_bit eq $action_bit
               );
    }
    elsif ( $action eq 'edit' or $action eq 'delete' ) {
        delete $params->{ user_id };  # no form spoofing to change owner

        return if ( $user_id and $user_id eq $row->user_id
                        and
                    $owner_bit eq $action_bit
               );
    }

    # group work here
    my $member_of = $site->auth_user_groups;

    return if ( $permissions->{ group }
                    and
                $member_of->{ $permissions->{ group } }
                    and
                $group_bit eq $action_bit
           );

    # last chance, is it open to all?
    return if $other_bit eq $action_bit;

    if ( $action eq 'add' ) {
        die "You are not authorized to add records here.\n";
    }
    elsif ( $action eq 'edit' ) {
        die "You are not authorized to edit this record.\n";
    }
    elsif ( $action eq 'delete' ) {
        die "You are not authorzied to delete this record.\n";
    }
} # end of verify_permissions

1;

__END__

=head1 NAME 

Gantry::Utils::CRUDHelp - helper routines for CRUD plugins

=head1 SYNOPSIS

    use Gantry::Utils::CRUDHelp;

=head1 DESCRIPTION

Exports helper functions useful when writing CRUD plugins.

=head1 FUNCTIONS

=over 4

=item clean_params

Pass a hash of form parameters and the fields list from a
C<Gantry::Plugins::AutoCRUD > style form method.  Any field with
key is whose value is not boolean is examined in the params hash.  If its
value is false, that value is changed to undef.  This keeps the ORM
from trying to insert a blank string into a date and integer fields which
is fatal, at least for DBIx::Class inserting into Postgres.

=item clean_dates

Pass a hash of form parameters and the fields list from a
C<Gantry::Plugins::AutoCRUD > style form method.  Any field with
key is whose value is date is examined in the params hash.  If its
value is false, that value is changed to undef.  This keeps the ORM
from trying to insert a blank string into a date field which is fatal,
at least for Class::DBI inserting into Postgres.

=item form_profile

Pass in the fields list from a C<Gantry::Plugins::AutoCRUD > style _form
method.  Returns a hash reference suitable for passing to the
check method of Data::FormValidator.

=item verify_permission

Use this method if you want to enforce crudcrudcrud style table permissions.

Returns: undef if the permissions allow the requested action

Dies: when user is barred by permissions from performing the requested action

Parameters:

Pass the parameters in a hashref with these keys:

=over 4

=item site

Your gantry site object.

=item row

[Optional] For use with edit and delete actions.  This must be an ORM
object which responds to the C<user_id> method.  Usually, that happens
when your table has a column of that name.

=item params

[Optional] The hash of form parameters.  If you like, this method can enforce
rules for C<user_id>'s.  These are the rules it enforces:

=over 4

=item during add

If there is a logged in user, their id becomes the user_id in params.
Otherwise, the user_id in params becomes 0.

=item during edit (and delete)

The user_id key of the params hash is deleted to avoid form spoofing
changes to row ownership.

=back

AutoCRUD uses this approach.  In your CRUD controller, you could choose
to do something different.  Like, you could allow admin users to alter
the user_id of an existing row.  To do something like that, simply do
not pass your params hash to this method.

=item action

[optional]
What the user is trying to do.  Pick from: add, edit, or delete.  Yes, these
should have had names from the CRUD acronym.

By default the action comes from calling C<action> on <$site> and
stripping the leading C<do_>.  So, if your method is called C<do_delete>,
the action default will be C<delete>.

=item permissions

[optional, see Default below]

This must be a hash like this:

    {
        'group' => 'admin',
        'bits' => 'crud-rudcr--'
    };

The group is optional.  If present, logged in users who are members
of the named group will have group rights to the table.

The bits are actually 12 characters, each of which is flag.  If all the letters
are there, everyone can do everything and you might as well not use this
method.  To turn off a permission, replace the letter with a dash (although
anything other than the expected letter would actually work).  This is
common: crudcrud-r--.  It allows row owners and members of the table's
group to do anything, but only allows read access for others.

The example above allows row owners and admin group members to do anything
(the missing c for group members is more than covered by the c for owner
and others).  All users (whether logged in or not) can create rows and
retrieve all rows.

The letters in the string must be lower case.

Default:

If you don't supply this parameter, it will be the C<permissions>
key returned by a call C<controller_config> on your C<site> object.

=back

=back

=head2 write_file( <form field name>, <file archive> );

write_file provides the code to collect a file from the form and write it to 
disk. This is to be called in the edit_post_action or add_post_action callback.

=head3 usage

 sub edit_post_action {
    my( $self, $row ) = @_;
    
    my %params = $self->get_param_hash;
        
    if ( defined %params{'myfile'} ) {
    
        my $u = $self->write_file( 'myfile', '/home/html/images' );
        $row->update( $u );
    }   
 }

=head3 recommend database fields

 <file field>   varchar  -- /path to file>/11677952634.59186549016706.jpg
 <file field>_ident  varchar -- 11677952634.59186549016706.jpg ( unique )
 <file field>_suffix varchar -- .txt
 <file field>_mime   varchar -- text/html
 <file field>_name   varchar -- originalfilename.txt
 <file field>_size   int     -- 2323

=head3 returns

will produce a hash ref

 {
    '<file field>'  => '/home/archive/11677952634.59186549016706.jpg',
    '<file field>_ident'  => '11677952634.59186549016706.jpg',
    '<file field>_suffix' => '.txt',
    '<file field>_mime'   => 'text/html',
    '<file field>_name'   => 'originalfilename.txt',
    '<file field>_size'   => '2323',
 }

=head1 SEE ALSO

 Gantry::Plugins::AutoCRUD (for simpler situations)
 Gantry::Plugins::CRUD (for slightly more complex situations)

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT

Copyright (c) 2005, Phil Crow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
