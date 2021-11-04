package FindApp::Object::Behavior::Shortcuts;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Vars qw(:all);
use FindApp::Utils qw(:all);

use namespace::clean;

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
    *rootdir = *rootdir = \&rootdirs;

    my $is_pl    = $DIR ne "root";
    my $NAMEDIR  = $DIR . "dir" . ($is_pl && "s");
    my $has_have = $is_pl ? "have" : "has";
    my $is_are   = $is_pl ? "are"  : "is";

    my %access_verb = (
        wanted  => $has_have,
        allowed => $is_are,
    );

    while (my($ACCESSOR, $VERB) = each %access_verb) {
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

1;

__END__

=head1 NAME

FindApp::Object::Behavior::Shortcuts - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item add_bindirs_allowed

=item add_bindirs_found

=item add_bindirs_wanted

=item add_libdirs_allowed

=item add_libdirs_found

=item add_libdirs_wanted

=item add_mandirs_allowed

=item add_mandirs_found

=item add_mandirs_wanted

=item add_rootdir_allowed

=item add_rootdir_found

=item add_rootdir_wanted

=item allowed

=item bindirs

=item bindirs_allowed

=item bindirs_are

=item bindirs_found

=item bindirs_have

=item bindirs_wanted

=item export_bin_to_env

=item export_lib_to_env

=item export_man_to_env

=item export_root_to_env

=item found

=item get_bindirs_allowed

=item get_bindirs_found

=item get_bindirs_wanted

=item get_libdirs_allowed

=item get_libdirs_found

=item get_libdirs_wanted

=item get_mandirs_allowed

=item get_mandirs_found

=item get_mandirs_wanted

=item get_rootdir_allowed

=item get_rootdir_found

=item get_rootdir_wanted

=item libdirs

=item libdirs_allowed

=item libdirs_are

=item libdirs_found

=item libdirs_have

=item libdirs_wanted

=item mandirs

=item mandirs_allowed

=item mandirs_are

=item mandirs_found

=item mandirs_have

=item mandirs_wanted

=item rootdir

=item rootdir_allowed

=item rootdir_found

=item rootdir_has

=item rootdir_is

=item rootdir_wanted

=item rootdirs

=item set_bindirs_allowed

=item set_bindirs_found

=item set_bindirs_wanted

=item set_libdirs_allowed

=item set_libdirs_found

=item set_libdirs_wanted

=item set_mandirs_allowed

=item set_mandirs_found

=item set_mandirs_wanted

=item set_rootdir_allowed

=item set_rootdir_found

=item set_rootdir_wanted

=item wanted

=back

=head1 SEE ALSO

=head1 AUTHOR

=head1 LICENCE AND COPYRIGHT
