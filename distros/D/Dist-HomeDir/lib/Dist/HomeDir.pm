package Dist::HomeDir;
$Dist::HomeDir::VERSION = '0.006';
# ABSTRACT:  easily find the distribution home directory for code never intended to be installed via a package manager
use warnings;
use strict;
use Path::Tiny;

my $home;

sub import {
    my ($pkg, %libs) = @_;
    my $libs = $libs{lib};
    require lib;
    my $home = dist_home();
    $_ = $home->child($_)->stringify for @$libs;
    lib->import(@$libs);
}

sub dist_home {
    return $home if $home;
    my $caller = [(caller)];
    if ($caller->[0] eq 'Dist::HomeDir') {
        $caller = [caller(2)];
    }
    my $cwd = path($caller->[1])->parent;
    $home = _get_dist_home($cwd);
    return $home->absolute;
}

sub _get_dist_home {
    my ($dir) = @_;
    my @ls;
    my $itr = $dir->iterator;
    while (my $f = $itr->() ) {
        push @ls, $f;
    }
    if ( grep { $_->basename =~ /^Makefile.PL|Build.PL|dist.ini|cpanfile|lib|blib$/ 
                    && $_->parent->basename !~ /^t|script|bin$/
            } @ls ) {
        return $dir;
    }
    else {
        return _get_dist_home($dir->parent);
    }
}
1;
__END__
=head2 NAME

Dist::HomeDir

=head2 SUMMARY

    use Dist::HomeDir;
    my $dist_home = Dist::Homedir::dist_home(); # A Path::Tiny object of the Dist home

    use Dist::HomeDir lib => [qw( script/lib t/lib )];
    # @INC now contains $dist_home->child('script/lib') and t/lib

Easily find the dist homedir for an application set up as a cpan(ish)
distribution but intended to be deployed via git checkout or by a tarball
in a self contained directory.  You can also optionally modify @INC as
documented above.

DO NOT use this in code that is B<ever> likely to be installed via cpan
or other package manager.

=head2 DESCRIPTION

This module was inspired by Catalyst::Utils->home() to obtain the root
directory for obtaining application code and self-contained support data in
directories relative to the distribution root.  It does this by returning a
L<Path::Tiny> object which has a very nice interface.  However
Catalyst::Utils->home only works for perl classes.  This works for class
files and perl scripts via examining C<(caller)[1]> and thus should
B<never> be used in code that will be instaled via a cpan client or other
package manager.

Sometimes support libaries will also live in the C<t/lib> directory and the
C<script/lib> directory.  C<dist_home> will ignore these C<lib> directories
as part of finding the distribution root.  Future versions of this module
may make the list of what directories to ignore other C<lib> sub directories
user-configurable (patches welcome).

If you want to modify C<@INC> with the import syntax in the second example
<<<<<<< HEAD
in the summary, be careful.  In particular if you use L< Dist::HomeDir> in
test files and in code to be used in production, C<@INC> might be modified
in unexpeted ways depending on the structure of your codebase.  The best
thing to do here is only use the import syntax in test files or maybe other
support files (e.g. in C<script>), and never in code in the main package
hierarchy.

=head2 FUNCTIONS

dist_home

Returns a L<Path::Tiny> object of where the current code file executed
thinks the distribution home directory is.


=head2 ALTERNATIVES

L<Mojo::Home> - lots of features, no non-core perl dependencies

L<FindBin>    - perl core, comes with gotchas if called multiple times.

L<Test::InDistDir> - where the import syntax for L<Dist::HomeDir> came from.

=head2 AUTHOR

Kieren Diment <zarquon@cpan.org>

=head2 COPYRIGHT

This code can be distributed under the same terms as perl itself.

=cut
