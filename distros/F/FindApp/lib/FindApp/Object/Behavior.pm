package FindApp::Object::Behavior;

use v5.10;
use strict;
use warnings;
use mro "c3";

require FindBin;

use FindApp::Vars qw(:all);
use FindApp::Utils qw(:all);

sub apply                   ;
sub constraint_failure      ;
sub generate_helper_methods ;

use namespace::clean;

sub constraint_text         ;
sub copy_founds_to_globals  ;
sub export_to_env           ;
sub findapp                 ;
sub findapp_and_export      ;
sub findapp_root            ;
sub findapp_root_from_path  ;
sub path_passes_constraints ;
sub reset_all_groups        ;
sub shell_settings          ;
sub show_shell_var          ;

################################################################
################################################################
# This is where everything happens.
################################################################
################################################################

sub findapp { &ENTER_TRACE;
    my $self = &myself;
    $self->findapp_root(@_) || constraint_failure($self);
    $self->copy_founds_to_globals;
    return $self->app_root;
}

sub findapp_and_export { &ENTER_TRACE;
    my $self = &myself;
    $self->findapp;
    () = $self->export_to_env;
}

sub export_to_env { &ENTER_TRACE;
    my $self = &myself;
    apply $self => alldir_map { "export_${_}_to_env" };
}

sub apply {
    my $self = &myself;
    function method_map => sub   { map { $self->$_ } @_     };
    if (my $context = wantarray) { return       &method_map }
    elsif (!defined $context)    { &method_map; return      }
    else {
        panic "called in scalar context not void context or list context";
    }
}

sub copy_founds_to_globals { &ENTER_TRACE;
    my $self = &myself;
    for my $dir ($self->group_names) {
        my $var = ucfirst lc $dir;
        my $dirmeth = $dir . "dirs";
        my @dirs = $self->$dirmeth;
        no strict "refs";
        $$var = (@$var = @dirs)[0];
    }
}

sub constraint_failure {
    my $self = shift;
    croak "no app root above ",    $self->origin,
          " matching constraint ", $self->constraint_text;
}

# Generate pretty text corresponding to all the constraints.
sub constraint_text {
    my $self = &myself;
    my $pair = function allow_want_constraint_text_pair => sub {
        my $self = shift;  # this is a group object
        bad_args(@_ > 1);
        my $allowed = @_ ? [shift] : [$self->allowed];
        return $self->wanted->count ? [ $allowed => [$self->wanted] ] : ();
    };
    return commify_and map {    commify_and ( @{ $$_[1] } )
                             . " in "
                             .  commify_or  ( @{ $$_[0] } )
    } ( $self->rootdir->$pair("root"),
        map { $_->$pair() } $self->subgroups,
    );
}

sub findapp_root { &ENTER_TRACE;
    my $self = &myself;
    bad_args(@_ > 1);
    my($path) = @_;

    if (@_) {
        # if it's the same as before, return cached version
        # XXX: ignores constraint changes
        if ($self->has_app_root && $path eq $self->app_root) {
           debug "findapp_root returning cached $path";
           return $path;
        }
        else {
           return $self->findapp_root_from_path($path);
        }
    }

    if ($self->has_origin) {
        return $self->findapp_root_from_path($self->origin);
    }

    # no path, so try both ways
    my($first, $second) = ($FindBin::Bin, getcwd());
      ($first, $second) = ($second, $first) if $self->default_origin eq "cwd";

    return $self->findapp_root_from_path($first)
        || $self->findapp_root_from_path($second);
}

sub findapp_root_from_path { &ENTER_TRACE;
    my $self = &myself;
    good_args(@_ == 1);
    my($path) = @_;

    $self->origin($path);
    for (my $dir = abs_path($path) || $path;
            $dir ne "/";
            $dir = dirname($dir))
    {
        return $dir if $self->path_passes_constraints($dir);
    }
    $self->reset_origin;
    return;

}

# Takes a directory argument and makes sure that everything
# wanted can be found in any of the allowed (sub)directories.
# Returns a boolean success value.
sub path_passes_constraints { &ENTER_TRACE;
    my $self = &myself;
    my($candidate_dir) = @_;

    $self->reset_all_groups;

    my %groups  = %{ $self->group };
    my @groups  = delete $groups{root};
    push @groups, values %groups;

    for my $group (@groups) {
        next if $group->base_has_wanteds($candidate_dir);
        $self->reset_all_groups;
        return;
    }

    return 1;
}

sub reset_all_groups {
    my $self = &myself;
    $_->found->reset for values %{ $self->group };
}

################################################################
# Misc methods.

sub shell_settings {
    my $self = &myself;
    return q() unless $self->has_app_root;
    return join q() => (
        $self->show_shell_var(APP_ROOT => $self->app_root),
        $self->show_shell_var(PERL5LIB => $self->libdirs),
        $self->show_shell_var(PATH     => $self->bindirs),
        $self->show_shell_var(MANPATH  => $self->mandirs),
    );
}

sub show_shell_var {
    &all_args_defined;
    my $self = &myself;
    state $poly = { map { $_ => 1 } qw(PERL5LIB PATH MANPATH) };
    my($varname, @dirs) = @_;
    $varname =~ /^\w+$/         || croak "$varname doesn't look like a good shell variable name";
    my $retstr = q();
    if (@dirs) {
        $retstr  = is_csh()
                    ? "setenv $varname "
                    : "export $varname=" ;
        push(@dirs, '$' . $varname)  if $$poly{$varname};
        $retstr .= sprintf qq{"%s";\n}, colonize @dirs;
    }
    return $retstr;
}

#################################################################
# BUILDERS
#################################################################

# All generated functions are given proper names, thus allowing for
# not merely "not-from-hell" stack traces, but even better, letting you
# breakpoint and even list them in the debugger.  The builders are
# all written in a way to make it utterly clear which lexicals are
# being accessed from outside the closure's scope.  These are really
# paramerized function-building templates, like macros, and so $ALL_CAPS
# is used for the template "arguments"; that is, the stuff outside
# our scope that we are relying inside the closure.

no namespace::clean;

sub generate_helper_methods {
    my $class = shift || __PACKAGE__;
    my @_SUBDIRS = +BLM;
    my @_ALLDIRS = (root => @_SUBDIRS);

    for my $DIR (@_ALLDIRS) {
        # BUILD: export_bin_to_env
        # BUIOD: export_lib_to_env
        # BUIOD: export_man_to_env
        # BUIOD: export_root_to_env
        function "export_${DIR}_to_env" => sub { &ENTER_TRACE;
            my $self = &myself;
            good_args(@_ == 0);
            $self->group($DIR)->export_to_env;
        };
        # BUILD: bindirs libdirs mandirs rootdirs
        function "${DIR}dirs" => sub {
            my $self = &myself;
            good_args(@_ == 0);
            my $group = $self->group($DIR);
            return wantarray ? $group->found : $group;
        };
        *rootdir = \&rootdirs;

        my $is_pl    = $DIR ne "root";
        my $NAMEDIR  = $DIR . "dir" . ($is_pl && "s");
        my $has_have = $is_pl ? "have" : "has";
        my $is_are   = $is_pl ? "are"  : "is";

        my %access_verb = (
            wanted  => $has_have,
            allowed => $is_are,
        );

        while (my($ACCESSOR, $VERB) = each %access_verb) {
            print "making ${NAMEDIR}_${VERB}\n";
            function $NAMEDIR . "_" . $VERB => sub {
                my $self = &myself;
                my $action = join("_" => (@_ ? "set" : "get"), $NAMEDIR, $ACCESSOR);
                $self->$action(@_);
            };
        }

    } ## for my @DIR (@_ALLDIRS)

    my @ACCESSORS = qw(allowed found wanted);

    for my $TYPE (@ACCESSORS) {
        # BUILD: allowed found wanted
        function $TYPE => sub {
            my $self = &myself;
            good_args(@_ == 1);
            my $dir = shift;
            return $self->group($dir)->$TYPE;
        };

        for my $DIR (@_ALLDIRS) {
            my $is_pl = $DIR ne "root";
            my $NAMEDIR = $DIR . "dir" . ($is_pl && "s");

            my $ACTION  = $NAMEDIR . "_" . $TYPE;

            # BUILD: <{rootdir,{bin,lib,man}dirs}_{allowed,found,wanted}>
            # BUILD: rootdir_allowed rootdir_found rootdir_wanted
            # BUILD: bindirs_allowed bindirs_found bindirs_wanted
            # BUILD: libdirs_allowed libdirs_found libdirs_wanted
            # BUILD: mandirs_allowed mandirs_found mandirs_wanted
            function $ACTION => sub {
                my $self = &myself;
                good_args(@_ == 0);
                return $self->group($DIR)->$TYPE;
            };

            for my $OP (qw(add get set)) {
                my $FUNC_NAME = "${OP}_${ACTION}";
                # BUILD: <{add,get,set}_{rootdir,{bin,lib,man}dirs}_{allowed,found,wanted}>
                # BUILD: add_rootdir_allowed add_rootdir_found add_rootdir_wanted
                # BUILD: add_bindirs_allowed add_bindirs_found add_bindirs_wanted
                # BUILD: add_libdirs_allowed add_libdirs_found add_libdirs_wanted
                # BUILD: add_mandirs_allowed add_mandirs_found add_mandirs_wanted
                # BUILD: get_rootdir_allowed get_rootdir_found get_rootdir_wanted
                # BUILD: get_bindirs_allowed get_bindirs_found get_bindirs_wanted
                # BUILD: get_libdirs_allowed get_libdirs_found get_libdirs_wanted
                # BUILD: get_mandirs_allowed get_mandirs_found get_mandirs_wanted
                # BUILD: set_rootdir_allowed set_rootdir_found set_rootdir_wanted
                # BUILD: set_bindirs_allowed set_bindirs_found set_bindirs_wanted
                # BUILD: set_libdirs_allowed set_libdirs_found set_libdirs_wanted
                # BUILD: set_mandirs_allowed set_mandirs_found set_mandirs_wanted
                function $FUNC_NAME => sub {
                    my $self = &myself;
                    croak("$FUNC_NAME: no args allowed") if @_ && $OP eq "get";
                    return $self->group($DIR)->$TYPE->$OP(@_);
                };
            } ## for my $OP (qw(add get set))

        } ## for my @DIR (@_ALLDIRS)
    } ## for my $TYPE (@ACCESSORS)

} ## sub generate_helper_methods

#BEGIN { generate_helper_methods() }

#use namespace::clean;

no namespace::clean;


1;

=encoding utf8

=head1 NAME

FindApp::Object::Behavior - FIXME

=head1 SYNOPSIS

 use FindApp::Object::Behavior;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

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

=item allowed

=item allowed_bindirs

=item allowed_libdirs

=item allowed_mandirs

=item allowed_rootdir

=item bindirs

=item bindirs_allowed

=item bindirs_found

=item bindirs_wanted

=item constraint_text

=item copy_founds_to_globals

=item export_bin_to_env

=item export_lib_to_env

=item export_man_to_env

=item export_root_to_env

=item export_to_env

=item findapp

=item findapp_and_export

=item findapp_root

=item findapp_root_from_path

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

=item libdirs

=item libdirs_allowed

=item libdirs_found

=item libdirs_wanted

=item mandirs

=item mandirs_allowed

=item mandirs_found

=item mandirs_wanted

=item path_passes_constraints

=item reset_all_groups

=item rootdir

=item rootdir_allowed

=item rootdir_found

=item rootdir_wanted

=item rootdirs

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

