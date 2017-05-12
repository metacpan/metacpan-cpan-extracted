use strict;
use warnings;
package Git::Sub;
# ABSTRACT: git commands imported as System::Sub subs in git:: namespace
$Git::Sub::VERSION = '0.163320';
use System::Sub ();
use File::Which ();

my $GIT;

sub import
{
    return if @_ <= 1;
    shift;

    if ($_[0] eq 'git') {
	unless (@_ > 2) {
	    require Carp;
	    Carp::croak('missing value for "git" parameter');
	}
	$GIT = $_[1];
	splice @_, 0, 2;
    }

    # The remaining arguments are names of subs
    no strict 'refs';
    while (@_) {
	my $fq_name = 'git::'.shift;
	next if defined *{$fq_name};
	# TODO: check names: /[a-z_]/
	# See subs.pm
	*{$fq_name} = \&{$fq_name};
    }
}

package # no indexing
    git;

use subs
    # Common commands
    qw(version
       commit tag push add rm branch checkout clone fetch init log
       mv notes pull push rebase reset revert status),
    # Ancillary commands
    qw(config filter_branch prune remote repack),
    # Interrogator
    qw(rev_parse),
    # Plumbing: manipulation commands
    qw(apply checkout_index commit_tree hash_object index_pack merge_file
       merge_index mktag mktree pack_objects prune_packed read_tree
       symbolic_ref unpack_objects update_index update_ref write_tree),
    # Plumbing: interrogation commands
    qw(cat_file diff_files diff_index diff_tree for_each_ref ls_files
       ls_remote ls_tree merge_base name_rev pack_redundant rev_list
       show_index show_ref tar_tree unpack_file var verify_pack),
    # Plumbing: synching repositories
    qw(fetch_pack send_pack update_server_info parse_remote receive_pack
       upload_archive upload_pack)
;

sub AUTOLOAD
{
    my $git_cmd = our $AUTOLOAD;
    my $git_sub = $git_cmd = substr($git_cmd, 1+rindex($git_cmd, ':'));
    $git_cmd =~ tr/_/-/; # Seems to the first time I use tr// in the last 2 years
    $GIT ||= File::Which::which('git');

    delete $git::{$git_sub};
    System::Sub->import($AUTOLOAD, [
	'$0' => $GIT,
	'@ARGV' => [ $git_cmd ],
    ]);
    goto &$AUTOLOAD
}

1;
__END__

=encoding UTF-8

=head1 NAME

Git::Sub - git commands imported as L<System::Sub> subs in the git:: namespace

=head1 VERSION

version 0.163320

=head1 SYNOPSIS

    use Git::Sub qw(clone tag push);

    # Git commands are now Perl subs
    git::clone 'git://github.com/dolmen/p5-Git-Sub.git';

    git::tag -a => -m => "Release v$version", "v$version";

    git::push qw(--tags origin master);

    # Commands names with '-' are imported with '_'
    my $master = git::rev_parse 'release';

    # Return in list context is lines (see System::Sub)
    say for git::ls_tree 'master';

    # Process lines using a callback
    git::ls_tree 'master' => sub {
        my ($mode, $type, $object, $file) = split;
        say $file;
    };

=head1 DESCRIPTION

Use L<git|http://www.git-scm.com> commands easily from your Perl program. Each
git command is imported as a L<System::Sub> DWIM sub.

=head1 EXAMPLES

=over 4

=item *

The L<release script|https://github.com/dolmen/angel-PS1/blob/devel/dist> of
my L<angel-PS1|https://github.com/dolmen/angel-PS1> project.

=back

=head1 AUTHOR

Olivier Mengué, C<dolmen@cpan.org>.

=head1 COPYRIGHT & LICENSE

Copyright E<copy> 2016 Olivier Mengué.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.

=cut

# vim:set et sw=4 sts=4:
