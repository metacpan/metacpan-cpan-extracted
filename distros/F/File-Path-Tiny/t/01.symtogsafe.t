use strict;
use warnings;

use Test::More;
use Test::Exception;

use File::Path::Tiny;

if ( !-x "/bin/mv" || !-x "/bin/mkdir" ) {    # dragons! patches welcome
    plan skip_all => 'Only operate on systems w/ /bin/mv and /bin/mkdir, for reasons see the cource code comments';
}
else {
    plan tests => 22;
}

use File::Temp;
use Cwd;
use File::Spec;

my $orig_dir = Cwd::cwd();
my $dir      = File::Temp->newdir();
our $catdir_toggle = sub { };
our @catdir_calls;

chdir $dir || die "Could not chdir into temp directory: $!\n";    # so we can pathrm(), dragons!

{
    ##############################################################################
    #### Wrap catdir() to control a symlink toggle in the path traversal loops. ##
    ##############################################################################
    no strict "refs";
    no warnings "redefine", "once";
    my $real_catdir = \&{ $File::Spec::ISA[0] . "::catdir" };
    local *File::Spec::catdir = sub {
        my ( $self, @args ) = @_;
        push @catdir_calls, \@args;
        $catdir_toggle->(@args);
        goto &$real_catdir;
    };

    mkdir "empty_dir";
    mkdir "empty_dir/sanity";
    File::Path::Tiny::empty_dir("empty_dir");
    is( @catdir_calls, 1, "sanity check: catdir was actually called in the empty_dir() loop" );

    mkdir "rm";
    mkdir "rm/sanity";
    File::Path::Tiny::rm("rm");
    is( @catdir_calls, 2, "sanity check: catdir was actually called in the pathrmdir() loop" );

    ####################
    #### Actual tests ##
    ####################

    for my $func (qw(empty_dir rm)) {
        _test( $func, "cwd/foo/bar/baz", "bails when high level changes" );
        _test( $func, "cwd/foo/bar",     "bails when mid level changes" );
        _test( $func, "cwd/foo",         "bails when low level changes" );
        _test( $func, "cwd",             "bails when CWD level changes" );
        _test( $func, "",                "bails when below level changes" );
    }

    # TODO: cover readdir, chdir, and post loop failures
}

chdir $orig_dir || die "Could not chdir back to original directory: $!\n";

###############
#### helpers ##
###############

sub _test {
    my ( $func, $toggle, $label ) = @_;

    _setup_tree($func);

    {
        local @catdir_calls  = ();
        local $catdir_toggle = sub {
            chdir $dir || die "could not toggle dir/symlink (chdir): $!";

            my $parent = "";
            if ($toggle) {
                $parent = $toggle;
                $parent =~ s{[^/]+$}{};

                # use system call since the perl to do this will likely use File::Spec
                system("/bin/mkdir -p moved/$func/$parent") and die "could not toggle dir/symlink (mkdir): $?\n";
            }

            # use system call since the perl to do this will likely use File::Spec
            system("/bin/mv $dir/$func/$toggle $dir/moved/$func/$toggle") and die "could not toggle dir/symlink (mv): $?\n";
            symlink( "$dir/victim", "$dir/$func" . ( $toggle ? "/$toggle" : "" ) ) or die "could not toggle dir/symlink (sym): $!\n";

            chdir "$func/cwd" || die "could not toggle dir/symlink (back into $func/cwd): $!\n";
        };

        throws_ok { no strict "refs"; "File::Path::Tiny::$func"->("foo/bar/baz") }
        qr/directory .* changed: expected dev=.* ino=.*, actual dev=.* ino=.*, aborting/,
          "$func() detected symlink toggle: $label";

        is( @catdir_calls, 1, "sanity check: catdir was actually called in $func() ($label)" );
    }

    _teardown_tree($func);
}

sub _teardown_tree {
    my ($base) = @_;

    chdir $dir || die "Could not chdir back into temp dir: $!\n";

    File::Path::Tiny::rm($base);
    File::Path::Tiny::rm("moved/");
    File::Path::Tiny::rm("victim/");

    return;
}

sub _setup_tree {
    my ($base) = @_;

    for my $dir ( "moved", "victim", "victim/cwd", $base, "$base/cwd", "$base/cwd/foo", "$base/cwd/foo/bar", "$base/cwd/foo/bar/baz" ) {
        mkdir $dir || die "Could not make test tree ($dir): $!\n";
        open my $fh, ">", "$dir/file.txt" || die "Could not make test file in ($dir): $!\n";
        print {$fh} "oh hai\n";
        close($fh);
    }

    chdir "$base/cwd" || die "Could not chdir into $base/cwd: $!\n";

    return;
}
