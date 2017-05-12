package GitHub::WebHook::Clone;
use strict;
use warnings;
use v5.10;

use parent 'GitHub::WebHook::Run';

our $VERSION = '0.11';

sub new {
    my ($class, %config) = @_;

    my $branch = $config{branch} || 'master';
    my $work_tree = $config{work_tree} // die "missing work_tree parameter";
    my $git_dir = $config{git_dir} // "$work_tree/.git";

    my @git = $git_dir eq "$work_tree/.git"
            ? ('git')
            : ('git',"--git-dir=$git_dir");

    bless {
        cmd => sub {
            my ($payload, $event, $id, $log) = @_;
            my $origin = $_[0]->{repository}->{clone_url} or die 'missing clone_url';
            if ( -d $git_dir ) {
                chdir $work_tree;
                return [@git,'pull',$origin,$branch];
            } else {
                return [@git,'clone',$origin,'-b',$branch,$work_tree];
            }
        }
    }, $class;
}

1;
__END__

=head1 NAME

GitHub::WebHook::Clone - Clone and update a working tree via GitHub WebHook

=head1 SYNOPSIS

    use Plack::App::GitHub::WebHook;
    
    Plack::App::GitHub::WebHook->new(
        hook => { 
            Clone => [
                branch    => 'master',
                work_tree => $directory,
            ]
        )
    )->to_app;

=head1 DESCRIPTION

This module can be used to clone and update a git repository via GitHub WebHook.

=head1 CONFIGURATION

=over

=item branch

Which branch to clone (C<master> by default).

=item work_tree

Working tree directory.

=item git_dir

Repository directory. By default this is directory C<.git> in the working tree
directory.

=back

=head1 SEE ALSO

L<GitHub::WebHook>, L<GitHub::WebHook::Run>, L<Git::Repository>

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voss, 2015-

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
