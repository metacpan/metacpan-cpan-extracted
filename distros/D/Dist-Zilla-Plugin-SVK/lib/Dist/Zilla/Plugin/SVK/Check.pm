use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::SVK::Check;
# ABSTRACT: check your svk repository before releasing

use SVK; use SVK::XD;
use Moose;

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::SVK::DirtyFiles';

use Cwd;

# -- public methods

sub before_release {
    my $self = shift;
    my $output;

	my $dir = getcwd;
	my @file = qx "svk status";

    # everything but files listed in allow_dirty should be in a
    # clean state
    my @dirty = $self->list_dirty_files;
    if ( @dirty ) {
        my $errmsg =
            "branch at $dir has modified files not on waiver list:\n" .
            join "\n", map { "\t$_" } @dirty;
        $self->log_fatal($errmsg);
    }

    # no files should be untracked
	my @virgin = grep m/^\?/, @file;
	if ( @virgin ) {
		my $errmsg =
			"branch at $dir has unversioned files:\n" .
			join "\n", map { "\t$_" } @virgin;
		$self->log_fatal($errmsg);
    }

    $self->log( "branch \$branch is in a clean state and no unversioned files" );

}

1;


=pod

=head1 NAME

Dist::Zilla::Plugin::SVK::Check - check your svk repository before releasing

=head1 VERSION

version 0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [SVK::Check]
    allow_dirty = dist.ini
    allow_dirty = README
    changelog = Changes      ; this is the default

=head1 DESCRIPTION

This plugin checks that svk is in a clean state before releasing. The following checks are performed before releasing:

=over 4

=item * there should be no unversioned files in the working copy

=item * the working copy should be without local modifications. The files listed in C<allow_dirty> can be modified locally, though.

=back

If those conditions are not met, the plugin will die, and the release will thus be aborted. This lets you fix the problems before continuing.

The plugin accepts the following options:

=over 4

=item * changelog - the name of your changelog file. defaults to F<Changes>.

=item * allow_dirty - a file that is allowed to have local modifications.  This option may appear multiple times.  The default list is F<dist.ini> and the changelog file given by C<changelog>.  You can use C<allow_dirty => to prohibit all local modifications.

=back

=for Pod::Coverage before_release

=head1 AUTHOR

Dr Bean <drbean at (a) cpan dot (.) org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dr Bean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

