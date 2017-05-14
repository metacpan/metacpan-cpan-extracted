use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::SVK::Commit;
# ABSTRACT: commit dirty files

use File::Temp           qw{ tempfile };
use SVK;
use SVK::XD;
use Moose;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };

use String::Formatter method_stringf => {
  -as => '_format_string',
  codes => {
    c => sub { $_[0]->_get_changes },
    d => sub { require DateTime;
               DateTime->now->format_cldr($_[1] || 'dd-MMM-yyyy') },
    n => sub { "\n" },
    N => sub { $_[0]->zilla->name },
    v => sub { $_[0]->zilla->version },
  },
};

with 'Dist::Zilla::Role::AfterRelease';
with 'Dist::Zilla::Role::SVK::DirtyFiles';


# -- attributes

has commit_msg => ( ro, isa=>Str, default => 'v%v%n%n%c' );


# -- public methods

sub after_release {
    my $self = shift;

    # check if there are dirty files that need to be committed.
    # at this time, we know that only those 2 files may remain modified,
    # otherwise before_release would have failed, ending the release
    # process.
    my @output = sort { lc $a cmp lc $b } $self->list_dirty_files(1);
    return unless @output;

    # write commit message in a temp file
    my ($fh, $filename) = tempfile( 'DZP-svk.XXXX', UNLINK => 1 );
    print $fh $self->get_commit_message;
    close $fh;

    # commit the files in svk
    system( "svk add @output" );
    $self->log_debug($_) for qx "svk commit -F $filename";
    $self->log("Committed @output");
	unlink $filename;
}



sub get_commit_message {
    my $self = shift;

    return _format_string($self->commit_msg, $self);
} # end get_commit_message

# -- private methods

sub _get_changes {
    my $self = shift;

    # parse changelog to find commit message
    my $changelog = Dist::Zilla::File::OnDisk->new( { name => $self->changelog } );
    my $newver    = $self->zilla->version;
    my @content   =
        grep { /^$newver(?:\s+|$)/ ... /^\S/ } # from newver to un-indented
        split /\n/, $changelog->content;
    shift @content; # drop the version line
    # drop unindented last line and trailing blank lines
    pop @content while ( @content && $content[-1] =~ /^(?:\S|\s*$)/ );

    # return commit message
    return join("\n", @content, ''); # add a final \n
} # end _get_changes


1;


=pod

=head1 NAME

Dist::Zilla::Plugin::SVK::Commit - commit dirty files

=head1 VERSION

version 0.10

=head1 SYNOPSIS

In your F<dist.ini>:

    [SVK::Commit]
    changelog = Changes      ; this is the default

=head1 DESCRIPTION

Once the release is done, this plugin will record this fact in svk by
committing changelog and F<dist.ini>. The commit message will be taken
from the changelog for this release.  It will include lines between
the current version and timestamp and the next non-indented line.

The plugin accepts the following options:

=over 4

=item * changelog - the name of your changelog file. defaults to F<Changes>.

=item * allow_dirty - a file that will be checked in if it is locally
modified.  This option may appear multiple times.  The default
list is F<dist.ini> and the changelog file given by C<changelog>.

=item * commit_msg - the commit message to use. defaults to
C<v%v%n%n%c>, meaning the version number and the list of changes.

=back

You can use the following codes in commit_msg:

=over 4

=item C<%c>

The list of changes in the just-released version (read from C<changelog>).

=item C<%{dd-MMM-yyyy}d>

The current date.  You can use any CLDR format supported by
L<DateTime>.  A bare C<%d> means C<%{dd-MMM-yyyy}d>.

=item C<%n>

a newline

=item C<%N>

the distribution name

=item C<%v>

the distribution version

=back

=head1 METHODS

=head2 get_commit_message

This method returns the commit message.  The default implementation
reads the Changes file to get the list of changes in the just-released version.

=for Pod::Coverage after_release

=head1 AUTHOR

Dr Bean <drbean at (a) cpan dot (.) org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dr Bean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

