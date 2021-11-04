package FindApp::Git;

use v5.10;
use strict;
use warnings;
use mro "c3";

use parent qw(FindApp);
use FindApp::Vars  qw(:all);
use FindApp::Utils qw(:all);
use namespace::clean;

sub init { &ENTER_TRACE;
    my($self) = @_;
    $self->next::method;
    debug "adding .git/ dir";
    $self->add_rootdir_wanted(".git/");
    $self->export_git_dir(0);
}

sub copy { &ENTER_TRACE;
    my($to, $from) = @_; 
    $to->next::method($from);
    $from->can($_) && $to->$_($from->$_) for "export_git_dir";
    return $to;
}

# This overrides the FindApp::Object::Behavior method,
# *not* the FindApp::Object::State::Group method.
# We're a FindApp object, not a group object.
sub export_root_to_env { &ENTER_TRACE;
    my $self = &myself;
    $self->next::method(@_);
    if ($Root && $self->export_git_dir) {
        $GIT_DIR = $Root;
        $self->rootdir->bump_exports;
    }
}

sub shell_settings { &ENTER_TRACE;
    my $self = &myself;
    my $settings = $self->SUPER::shell_settings(@_);
    $settings   .= $self->show_shell_var(GIT_DIR => $Root) if $self->export_git_dir;
    return $settings;
}

####################################
# Now our own methods.
####################################

use pluskeys qw{
    UNSAFE_EXPORT
};

sub export_git_dir { &ENTER_TRACE;
    my $self = &myself;
    $self->{+UNSAFE_EXPORT} = !!shift if @_;
    return $self->{+UNSAFE_EXPORT};
}

__PACKAGE__->renew;

1;

=encoding utf8

=head1 NAME

FindApp::Git - FIXME

=head1 SYNOPSIS

 use FindApp::Git;

=head1 DESCRIPTION

=head2 Pluskey Attributes

These are always private; use the methods insteads.

=over

=item UNSAFE_EXPORT

=back

=head2 Public Methods

=over

=item copy

=item export_git_dir

=item export_root_to_env

=item init

=item shell_settings

=back

=head2 Exports

=over

=item FIXME

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

