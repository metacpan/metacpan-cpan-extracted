package FindApp::Subs;

use v5.10;
use strict;
use warnings;

use Exporter     qw<import>;
use FindApp::Utils <function stashes>;
use FindApp ();

my %seen;
for my $stash (stashes @FindApp::ISA, @FindApp::Object::ISA) {
    while (my($name, $glob) = each %$stash) {
        ref \$glob eq "GLOB"    &&   # weird things find their way into the stashes
        *$glob{CODE}            &&   # only want code refs
        $name =~ /\p{lower}/    &&   # avoid all-caps idents
        $name =~ /^\w+$/        &&   # avoid for example "(eq" for overloaded eq ops
        $name !~ /^op_/         &&   #          or their implementations
        $name !~ /^as_/         &&   #          or their implementations
        $seen{$name}++          
    }
}

delete @seen{ <import init copy params> };

        ##########################
        # BUILD *ALL*THE*THINGS* #
        ##########################

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
for my $SUB (@EXPORT_OK = sort keys %seen) {
    function $SUB => sub { FindApp->old->$SUB(@_) };
    #say $SUB;
}

*EXPORT = $EXPORT_TAGS{all} = \@EXPORT_OK;

1;

=encoding utf8

=head1 NAME

FindApp::Subs - FIXME

=head1 SYNOPSIS

 use FindApp::Subs;

=head1 DESCRIPTION

FIXME

=head2 Exports

=over

=item add_allowed_bindirs

=item add_allowed_libdirs

=item add_allowed_mandirs

=item add_allowed_rootdir

=item add_bindirs_allowed

=item add_bindirs_found

=item add_bindirs_wanted

=item add_found_bindirs

=item add_found_libdirs

=item add_found_mandirs

=item add_found_rootdir

=item add_libdirs_allowed

=item add_libdirs_found

=item add_libdirs_wanted

=item add_mandirs_allowed

=item add_mandirs_found

=item add_mandirs_wanted

=item add_rootdir_allowed

=item add_rootdir_found

=item add_rootdir_wanted

=item add_wanted_bindirs

=item add_wanted_libdirs

=item add_wanted_mandirs

=item add_wanted_rootdir

=item adopts_children

=item adopts_parents

=item allocate_groups

=item allowed

=item allowed_bindirs

=item allowed_libdirs

=item allowed_mandirs

=item allowed_rootdir

=item another_file_required

=item another_module_used

=item app_root

=item bindirs

=item bindirs_allowed

=item bindirs_are

=item bindirs_found

=item bindirs_have

=item bindirs_wanted

=item canonical_subdirs

=item class

=item constraint_text

=item copy_founds_to_globals

=item debug

=item debugging

=item default_origin

=item export_bin_to_env

=item exported_envars

=item export_lib_to_env

=item export_man_to_env

=item export_root_to_env

=item export_to_env

=item findapp

=item findapp_and_export

=item findapp_root

=item findapp_root_from_path

=item find_devperl_bin

=item find_devperl_lib

=item find_devperl_man

=item forgotten_devperl_bin

=item forgotten_devperl_lib

=item forgotten_devperl_man

=item forgotten_devperls

=item found

=item found_bindirs

=item found_libdirs

=item found_mandirs

=item found_rootdir

=item get_allowed_bindirs

=item get_allowed_libdirs

=item get_allowed_mandirs

=item get_allowed_rootdir

=item get_bindirs_allowed

=item get_bindirs_found

=item get_bindirs_wanted

=item get_found_bindirs

=item get_found_libdirs

=item get_found_mandirs

=item get_found_rootdir

=item get_libdirs_allowed

=item get_libdirs_found

=item get_libdirs_wanted

=item get_mandirs_allowed

=item get_mandirs_found

=item get_mandirs_wanted

=item get_rootdir_allowed

=item get_rootdir_found

=item get_rootdir_wanted

=item get_wanted_bindirs

=item get_wanted_libdirs

=item get_wanted_mandirs

=item get_wanted_rootdir

=item group

=item group_names

=item groups

=item has_app_root

=item has_origin

=item libdirs

=item libdirs_allowed

=item libdirs_are

=item libdirs_found

=item libdirs_have

=item libdirs_wanted

=item load_files

=item load_libraries

=item load_modules

=item load_wanted

=item mandirs

=item mandirs_allowed

=item mandirs_are

=item mandirs_found

=item mandirs_have

=item mandirs_wanted

=item new

=item object

=item old

=item origin

=item original_exports

=item path_passes_constraints

=item prefers_dot

=item renew

=item required_files

=item reset_all_groups

=item reset_origin

=item rootdir

=item rootdir_allowed

=item rootdir_found

=item rootdir_has

=item rootdir_is

=item rootdirs

=item rootdir_wanted

=item set_allowed_bindirs

=item set_allowed_libdirs

=item set_allowed_mandirs

=item set_allowed_rootdir

=item set_bindirs_allowed

=item set_bindirs_found

=item set_bindirs_wanted

=item set_found_bindirs

=item set_found_libdirs

=item set_found_mandirs

=item set_found_rootdir

=item set_libdirs_allowed

=item set_libdirs_found

=item set_libdirs_wanted

=item set_mandirs_allowed

=item set_mandirs_found

=item set_mandirs_wanted

=item set_rootdir_allowed

=item set_rootdir_found

=item set_rootdir_wanted

=item set_wanted_bindirs

=item set_wanted_libdirs

=item set_wanted_mandirs

=item set_wanted_rootdir

=item shell_settings

=item show_shell_var

=item some_devperl_dir

=item subgroup_names

=item subgroups

=item tracing

=item use_all_devperls

=item used_modules

=item use_my_devperl

=item use_no_devperls

=item use_some_devperls

=item wanted

=item wanted_bindirs

=item wanted_libdirs

=item wanted_mandirs

=item wanted_rootdir


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

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

