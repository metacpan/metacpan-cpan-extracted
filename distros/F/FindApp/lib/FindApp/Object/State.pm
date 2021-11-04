package FindApp::Object::State;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Utils qw(:all);
use FindApp::Vars  qw(:all);
BEGIN {
    subuse "Group";
    subuse "Group::State::Dirs";
}
use namespace::clean;

################################################################

sub canonical_subdirs {
    # There may not be a singleton yet, and if not, we cannot
    # autogenerate one at this point, since that needs rootdir etc.
    return +BLM unless defined &rootdir;  # FIXME: wrong namespace for &rootdir
    my $self = &myself;
    return $self->subgroup_names;
}

sub exported_envars() {
    state $vars = [
        qw($Root),
        subdir_map { map { ('$'.$_, '@'.$_) } ucfirst },
    ];
    return @$vars;
}

################################################################
# Declare object attributes...
use pluskeys qw{
    ORIGIN
    DEFAULT
    GROUPS
};

# And define their accessors:

sub allocate_groups {
    my $self = &myself;
    $$self{+GROUPS} = { alldir_map { $_ => subpackage("Group")->new($_) } };
}

# Attribute group: hash mapping directory grouping names to f:o:s:Group objects.
sub group {
    my $self = &myself;
    bad_args(@_ > 1);
    if (@_) {
        return $$self{+GROUPS}{lc shift};
    } else {
        return $$self{+GROUPS};
    }
}

# All the group names.
sub group_names {
    my $self = &myself;
    bad_args(@_ > 0);
    return keys %{ $self->group };
}

# All the individual groups.
sub groups {
    my $self = &myself;
    bad_args(@_ > 0);
    return values %{ $self->group };
}

# Group names excluding root.
sub subgroup_names {
    my $self = &myself;
    bad_args(@_ > 0);
    return sort grep { $_ ne "root" } keys %{ $self->group };
}

# Groups excluding the root group.
sub subgroups {
    my $self = &myself;
    bad_args(@_ > 0);
    return @{ $self->group          }
            { $self->subgroup_names };
}

# Attribute default_origin.
sub default_origin {
    my $self = &myself;
    bad_args(@_ > 1);
    if (@_) {
        my($where) = @_;
        $where =~ /^(?:cwd|script)$/
            || croak "default origin must be either 'cwd' or 'script', not '$where'";
        $$self{+DEFAULT} = $where;
    }
    return $$self{+DEFAULT} || "script";
}

sub has_origin {
    my $self = &myself;
    bad_args(@_ != 0);
    return defined $$self{+ORIGIN};
}

sub prefers_dot {
    my $self = &myself;
    bad_args(@_ != 0);
    $self->default_origin eq "cwd";
}

# Attribute origin.
sub origin {
    my $self = &myself;
    bad_args(@_ > 1);

    if (@_) {
        my $origin = shift;
        bad_args(!defined $origin);
        $$self{+ORIGIN} = $origin;
    }
    elsif (!$self->has_origin) {
        $$self{+ORIGIN} = $self->default_origin eq "cwd"
                             ? getcwd()
                             : $FindBin::Bin;
    }

    return $$self{+ORIGIN};
}

sub reset_origin {
    my $self = &myself;
    bad_args(@_ > 0);
    my $old_origin = $self->origin;
    undef $$self{+ORIGIN};
    return $old_origin;
}
    

# Pseudo-attribute: app_root

sub has_app_root {
    my $self = &myself;
    good_args(@_ == 0);
    return !!$self->rootdir->found->count;
}

sub app_root {
    my $self = &myself;
    good_args(@_ == 0);
    return $self->rootdir->found->first;
}

1;

=encoding utf8

=head1 NAME

FindApp::Object::State - FIXME

=head1 SYNOPSIS

 use FindApp::Object::State;

=head1 DESCRIPTION

=head2 Pluskey Attributes

These are always private; use the methods insteads.

=over

=item DEFAULT

Either "cwd" or "script",

=item GROUPS

Ref to hash mapping directory grouping names to L<FindApp:Object:State:Group> objects.

=item ORIGIN

Directory to start the search from. If unset, either the working directory or C<$FindBin::Bin>
depending on the value of L</DEFAULT>.

=back

=head2 Methods

=over

=item allocate_groups

=item app_root

=item canonical_subdirs

=item default_origin

=item exported_envars

=item group

=item group_names

=item groups

=item has_app_root

=item has_origin

=item origin

=item prefers_dot

=item reset_origin

=item subgroups

=item subgroup_names

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

