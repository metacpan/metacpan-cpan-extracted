package FindApp::Object::State::Group::Behavior;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Vars  qw(:all);
use FindApp::Utils qw(:all);
#use Env qw(@PATH);

sub bin2man() { 
    my(@manpath, %seen);
    for my $bindir (@PATH) {
        next if $bindir =~ /^[.]{0,2}\z/;
        my $parent = dirname($bindir);
        for my $mandir (map "$parent/$_", qw(man share/man)) {
            next if $seen{$mandir}++;
            next unless -d $mandir;
            my($dev, $ino) = stat _;
            next if $seen{$dev, $ino}++;
            push @manpath, $mandir;
        }   
    }   
    return @manpath;
}

use namespace::clean;

sub base_has_wanteds { &ENTER_TRACE_2;
    good_args(@_ == 2);
    my($self, $base) = @_;
    # alloweds are always dirs, so tack on a trailing slash
    my @have = $self->allowed->count
                 ? grep { -e } map { "$base/$_" } $self->allowed
                 : $base;
    # Can we find everthing we want in what we have?
    for my $want (map { /^\w+(::\w+)+$/ ? module2path : $_ } $self->wanted) {
        my $found;
        for my $have (@have) {
            if ($found = -e "$have/$want") { 
                debug "found $have/$want";
                last;
            }
        }
        return unless $found;
    }
    $self->found(map { abs_path } @have);
    return 1;
}

sub expected_name {
    good_args(@_ == 2);
    my($self, $want_name) = @_;
    my $have_name = $self->name;
    unless ($have_name eq $want_name) {
        panic "group $have_name is not a $want_name group";
    }
}

sub export_to_env { &ENTER_TRACE_2;
    my $self = shift;
    my $exporter = "export_" . $self->name . "_to_env";
    $self->$exporter;
}

sub export_root_to_env { &ENTER_TRACE_2;
    my $self = shift;
    $self->expected_name("root");
    if ($self->have_exported) { debug "already exported root to env" }
    ($APP_ROOT) = $self->found;
    debug("\$APP_ROOT = '$APP_ROOT';");
    $self->bump_exports;
}

sub export_lib_to_env { &ENTER_TRACE_2;
    my $self = shift;
    $self->expected_name("lib");
    return unless my @libdirs = $self->found;
    if ($self->have_exported) { debug "already exported lib to env" }
    debug qq{use lib (@libdirs);};
    eval   q{use lib (@libdirs); 1} || die;
    $self->bump_exports;
}

sub export_bin_to_env { &ENTER_TRACE_2;
    my $self = shift;
    $self->expected_name("bin");
    return unless my @bindirs = $self->found;
    my @old_path = @PATH;
    my @new_path = uniq @bindirs, @PATH;
    return if @old_path  ==  @new_path   &&
             "@old_path" eq "@new_path";
    if ($self->have_exported) { debug "already exported bin to env" }
    debug("\@PATH = (@new_path);");
    @PATH = @new_path;
    $self->bump_exports;
}

sub export_man_to_env { &ENTER_TRACE_2;
    my $self = shift;
    $self->expected_name("man");
    return unless my @mandirs = $self->found;
    if ($self->have_exported) { debug "already exported man to env" }
    unless ($MANPATH) {
        local $/ = "\n";
        # temp variable so we don't clobber real one on error
        my $manpath = `manpath 2>&1`;
        chomp $manpath if defined $manpath;
        if ($?) {
            debug("`manpath` command failed with wstat=$?: $manpath");
            $manpath = join ":", bin2man();
        }
        return unless $manpath;
        $MANPATH = $manpath;
        debug("\$MANPATH = $MANPATH;");
        $self->bump_exports;
    } 
    my @old_path = split /:/, $MANPATH, -1;
    my @new_path = uniq @mandirs, @old_path;
    return if @old_path  ==  @new_path   &&
             "@old_path" eq "@new_path";
    $MANPATH = join ":", @new_path;
    debug("\$MANPATH = $MANPATH;");
    debug("\@MANPATH = (@new_path);");
    $self->bump_exports;
}


1;

__END__

=encoding utf8

=head1 NAME

FindApp::Object::State::Group::Behavior - implement group-specific behaviors for FindApp groups

=head1 DESCRIPTION

This class makes up part of the implementation for L<FindApp::Object> groups.
It has only two jobs: first, to make sure all the "wanted" constraints are met,
and second, export anything need into the user's environment.

=head2 Methods

=over

=item base_has_wanteds I<PATH>

Returns true if all the constaints of the group can be met for the given I<PATH> argument,
and false otherwise.

=item expected_name

Make sure that the expected method has been called on the expected group.

=item export_bin_to_env

Export any bin directories found into the PATH environment variable.
If debugging has been enabled, shows what it is doing while it's doing it.

=item export_lib_to_env

Calls C<use lib> on any libs found.  B<NOTE>: Does I<not> set PERL5LIB.

If debugging has been enabled, shows what it is doing while it's doing it.

=item export_man_to_env

Export any man directories found into the MANPATH environment variable.

If debugging has been enabled, shows what it is doing while it's doing it.

=item export_root_to_env

Export the object's C<app_root> to the APP_ROOT environement variable.

If debugging has been enabled, shows what it is doing while it's doing it.

=item export_to_env

Dispatch method that calls the group-specific exporters just mentioned above.
That way you can just say 

    $group->export_to_env

for any group, and it will automatically call the right one.

=back

=head1 ENVIRONMENT

Sets the APP_ROOT, PATH, and MANPATH environment variables, and
respects the value of FINDAPP_DEBUG.

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

An attempt is made to avoid adding duplicate elements to paths, but you
probably don't want to export things more than once, because it doesn't
delete old values.

=head1 BUGS AND LIMITATIONS

In theory this can be extended via subclassing to more than the four basic
directory groups, but this has not been tested.

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

