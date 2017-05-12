package Gantry::Utils::TablePerms;

use strict;

use Gantry::Utils::CRUDHelp qw( verify_permission );

sub new {
    my $class          = shift;
    my $opts           = shift;
    my $gantry_site    = $opts->{ site           };
    my $real_location  = $opts->{ real_location  };
    my $header_options = $opts->{ header_options };
    my $row_options    = $opts->{ row_options    };

    my $logged_in_user;
    my $admin_user        = 0;
    my $limit_to_user_id;

    my $hide_all_data     = 1;

    my %allow_option;
    my $permissions       = $gantry_site->controller_config->{ permissions };

    if ( $permissions ) {

        # check RETRIEVE permissions

        my $offset    = 1; # in crud, r is in slot 1
        my $owner_bit = substr $permissions->{ bits }, $offset,     1;
        my $group_bit = substr $permissions->{ bits }, $offset + 4, 1;
        my $other_bit = substr $permissions->{ bits }, $offset + 8, 1;

        my $user_row    = $gantry_site->auth_user_row;
        eval {
            $logged_in_user = $user_row->id;
        };
        if ( $@ ) {
            $logged_in_user = 0;
        }

        my $member_of = $gantry_site->auth_user_groups;
        if ( $permissions->{ group }
                      and
             $member_of->{ $permissions->{ group } }
        ) {
            $admin_user = 1;
        }

        if ( $other_bit eq 'r' ) {
            $hide_all_data = 0;
        }

        if ( $admin_user and $group_bit eq 'r' ) {
            $hide_all_data = 0;
        }

        # check for owner
        if ( $hide_all_data and $logged_in_user and $owner_bit eq 'r' ) {
            $limit_to_user_id = $logged_in_user;
            $hide_all_data    = 0;
        }
    }
    else {  # spoof things to look like an admin if their are no perms
        $hide_all_data     = 0;
        $admin_user        = 1;
    }

    my $self = {
        logged_in_user     => $logged_in_user,
        admin_user         => $admin_user,
        limit_to_user_id   => $limit_to_user_id,
        hide_all_data      => $hide_all_data,
        header_options     => $header_options,
        row_options        => $row_options,
        gantry_site        => $gantry_site,
    };

    return bless $self, $class;
}

my %dave_type_for = (
    create   => 'add',
    retrieve => 'view',
    update   => 'edit',
    delete   => 'delete',
);

sub real_header_options {
    my $self    = shift;
    my $options = $self->header_options;

    # determine options
    my @real_options;

    foreach my $option ( @{ $options } ) {
        my $crud_type = $option->{ type } || 'create';
        my $dave_type = $dave_type_for{ $crud_type };

        eval {
            verify_permission(
                {
                    site   => $self->gantry_site,
                    action => $dave_type,
                }
            );
            push @real_options, $option;
        };
    }

    return \@real_options;
}

sub real_row_options {
    my $self    = shift;
    my $row     = shift;
    my $options = $self->row_options;
    my $id      = $row->id;

    # determine options
    my @real_options;

    foreach my $option ( @{ $options } ) {
        my $crud_type = $option->{ type } || 'retrieve';
        my $dave_type = $dave_type_for{ $crud_type };

        eval {
            verify_permission(
                {
                    site   => $self->gantry_site,
                    action => $dave_type,
                    row    => $row,
                }
            );
            my $link;
            if ( $option->{ link } ) {
                $link = "$option->{ link }/$id";
            }
            else {
                my $method = lc $option->{ text };
                $method    =~ s/\s/_/g;

                $link      = $self->gantry_site->location . "/$method/$id";
            }
            push @real_options, {
                text => $option->{ text },
                link => $link,
            };
        };
    }

    # note well: these CANNOT be stored, they vary by row
    return \@real_options;
}

sub logged_in_user {
    my $self = shift;

    return $self->{ logged_in_user };
}

sub admin_user {
    my $self = shift;

    return $self->{ admin_user };
}

sub limit_to_user_id {
    my $self = shift;

    return $self->{ limit_to_user_id };
}

sub hide_all_data {
    my $self = shift;

    return $self->{ hide_all_data };
}

sub gantry_site {
    my $self = shift;

    return $self->{ gantry_site };
}

sub header_options {
    my $self = shift;

    return $self->{ header_options };
}

sub row_options {
    my $self = shift;

    return $self->{ row_options };
}

1;

=head1 NAME

Gantry::Utils::TablePerms - enforces retrieve permssions on main listings

=head1 SYNOPSIS

    use Gantry::Utils::TablePerms;

    # ...
    sub do_main {
        #...
        my $perm_obj = Gantry::Utils::TablePerms->new(
            {
                site           => $self,
                real_location  => $real_location,
                header_options => \@header_options,
                row_options    => \@row_options,
            }
        );

        # useful accessors available after a call to the contstructor:
        my $limit_to_user_id = $perm_obj->limit_to_user_id;
        my $hide_all_data    = $perm_obj->hide_all_data;

        # other accessors available after a call to the contstructor:
        my $logged_in_user   = $perm_obj->logged_in_user;
        my $admin_user       = $perm_obj->admin_user;

        ROW:
        foreach my $row ( @rows ) {
            next ROW if $perm_obj->hide_all_data;
            my $real_options = $perm_obj->real_row_options( $row );
        }

    }

=head1 DESCRIPTION

This module factors out the common task of row level permission handling
for do_main methods.

=head1 METHODS

There is only one method, which is not exported.

=over 4

=item new

This constructor method does a lot of grunt work surrounding the display
of main listing table rows when you use row level permissions.

If your C<controller_config> method's hash has a 'permissions' key, this
method enforces those permissions.  Otherwise, it opens the table to full
access.  To keep people out in that case, auth the whole controlller.

Parameters a single hash ref with these keys:

=over 4

=item gantry_site_object

This is the invocant of your do_ method.

=item real_location

This is usually generated for you by bigtop.  If not, use code like this:

    my $real_location = $self->location() || '';
    if ( $real_location ) {
        $real_location =~ s{/+$}{};
        $real_location .= '/';
    }

The real location becomes the base URL for edit and delete links.

=item header_options

An array ref of options for the whole table.  Each array element is a
hash.  The hashes have the same form as the ones in the C<row_options>,
which are fully described below.  The default type for header options
is 'create'.  Of course, ids are never added to header option links,
since these do not apply to individual rows.

=item row_options

An array ref of options for each row.  Each array element is a hash.  Here's
a full sample:

    [
        { text => 'Edit',    type => 'update',                       },
        { text => 'Special', type => 'retrieve', link => '/your/url' },
        { text => 'Make one like this', type => 'create',            },
        { text => 'Delete',  type => 'delete',                       },
    ]

The keys:

=over 4

=item text

What the user sees in the link text (if they are allowed to click it).

=item type

[optional defaults to 'retrieve']

Pick from C<create>, C<retrieve>, C<update>, or C<delete>. 'create'
links are subject to the 'c' flag in the crudcrudcrud permissions.
'retrieve' links are subject to the 'r' flag.  'update' links are
subject to the 'u'.  'delete' links are subject to the 'd' flag.
If no type is given the 'r' flag governs.

=item link

[optional]

Defaults to C<"real_location/lctext/$id">, where C<real_location>
is the first parameter and C<lctext> is the text parameter with two
changes.  First, all spaces are replaced with underscores.  Second,
it is forced to lower case.  So 'Make PDF' becomes 'make_pdf'.

Note that all links will have C<"/$id"> as their last URL path element.

=back

=back

=item real_header_options

Parameters: none

Returns: an array ref of header options for immediate use by main listing
tempaltes.

=item real_row_options

Parameter: a database row

Returns: an array ref of row options suitable for immediate use by
main listing templates.

=back

=head1 GET ONLY ACCESSORS

The only accessors you really need are C<limit_to_user_id>,
C<hide_all_data>, and C<real_row_options> above.

=over 4

=item limit_to_user_id

This is the id number of the logged in user, but only if the main listing
should be limited to rows owned by that user.

=item hide_all_data

Inidcates that the table permissions prohibit the current user from seeing
any rows in the table.  Use this to make sure no data is actually fed
to the template.

=item logged_in_user  

The id number of the currently logged in user (if anyone is logged in).

=item admin_user

True if the user is an admin or if the page does not have table permissions.

=item gantry_site

For internal use.  Returns the site object you passed to the constructor.

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-7, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

