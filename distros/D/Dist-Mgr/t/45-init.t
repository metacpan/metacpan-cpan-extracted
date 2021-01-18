use warnings;
use strict;

use Cwd qw(getcwd);
use Data::Dumper;
use Test::More;
use Hook::Output::Tiny;
use Dist::Mgr qw(:private);
use Dist::Mgr::FileData qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

my $mods = [qw(Acme::STEVEB)];
my $cwd = getcwd();

my $new_mod_file = "lib/Acme/STEVEB.pm";

my %module_args = (
    author  => 'Steve Bertrand',
    email   => 'steveb@cpan.org',
    modules => $mods,
    license => 'artistic2',
    builder => 'ExtUtils::MakeMaker',
);

my $h = Hook::Output::Tiny->new;

remove_init();

# bad directory
{
    is eval {
        init();
        1
    }, undef, "croak if we try to damage our own repo";
    like $@, qr/Can't run init\(\)/, "...and error is sane";
    after();
}

# params
{
    # no modules
    before();
    is eval { init(); 1 }, undef, "need modules param ok";
    like $@, qr/requires 'modules'/, "...and error is sane";
    after();

    # no author
    before();
    is eval { init(modules => $mods); 1 }, undef, "need author param ok";
    like $@, qr/requires 'author'/, "...and error is sane";
    after();

    # no email
    before();
    is eval { init(modules => $mods, author => 'stevieb9'); 1 }, undef, "need email param ok";
    like $@, qr/requires 'email'/, "...and error is sane";
    after();

    # module not an array ref
    before();
    is
        eval { init(modules => {}, author => 'stevieb9', email => 'steveb@cpan.org'); 1 },
        undef,
        "croaks if 'module' not an aref ok";
    like $@, qr/parameter must be an array ref/, "...and error is sane";
    after();

    # _module_write_template() no module file param
    is
        eval { Dist::Mgr::_module_write_template(); 1 },
        undef,
        "_module_write_template() croaks if no 'module_file' param ok";
    like $@, qr/file name sent in/, "...and error is sane";

    # _module_write_template() no module param
    is
        eval { Dist::Mgr::_module_write_template('module_file'); 1 },
        undef,
        "_module_write_template() croaks if no 'module' param ok";
    like $@, qr/'module', 'author' and 'email'/, "...and error is sane";

    # _module_write_template() no author param
    is
        eval { Dist::Mgr::_module_write_template('module_file', 'module'); 1 },
        undef,
        "_module_write_template() croaks if no 'author' param ok";
    like $@, qr/'module', 'author' and 'email'/, "...and error is sane";

    # _module_write_template() no email param
    is
        eval { Dist::Mgr::_module_write_template('module_file', 'module', 'author'); 1 },
        undef,
        "_module_write_template() croaks if no 'email' param ok";
    like $@, qr/'module', 'author' and 'email'/, "...and error is sane";

    # _module_template_file() no module param
    is
        eval { _module_template_file(); 1 },
        undef,
        "_module_template_file() croaks if no 'module' param ok";
    like $@, qr/'module', 'author' and 'email'/, "...and error is sane";

    # _module_template_file() no author param
    is
        eval { _module_template_file('module'); 1 },
        undef,
        "_module_template_file() croaks if no 'author' param ok";
    like $@, qr/'module', 'author' and 'email'/, "...and error is sane";

    # _module_template_file() no email param
    is
        eval { _module_template_file('module', 'author'); 1 },
        undef,
        "_module_template_file() croaks if no 'email' param ok";
    like $@, qr/'module', 'author' and 'email'/, "...and error is sane";
}

# good init
{
    before();

    $h->flush;
    $h->hook('stderr');
    init(%module_args, verbose => 1);
    $h->unhook('stderr');

    my @e = $h->stderr;

    is $e[0], 'Added to MANIFEST: Changes', "line 0 of stderr ok";
    is $e[1], 'Added to MANIFEST: ignore.txt', "line 1 of stderr ok";
    is $e[2], 'Added to MANIFEST: lib/Acme/STEVEB.pm', "line 2 of stderr ok";
    is $e[3], 'Added to MANIFEST: Makefile.PL', "line 3 of stderr ok";
    is $e[4], 'Added to MANIFEST: MANIFEST', "line 4 of stderr ok";
    is $e[5], 'Added to MANIFEST: README', "line 5 of stderr ok";
    is $e[6], 'Added to MANIFEST: t/00-load.t', "line 6 of stderr ok";
    is $e[7], 'Added to MANIFEST: t/manifest.t', "line 7 of stderr ok";
    is $e[8], 'Added to MANIFEST: t/pod-coverage.t', "line 8 of stderr ok";
    is $e[9], 'Added to MANIFEST: t/pod.t', "line 9 of stderr ok";
    is $e[10], 'Added to MANIFEST: xt/boilerplate.t', "line 10 of stderr ok";
    is defined $e[11], '', "...and that's all folks!";

    # check that the new module file is the same as our baseline template

    chdir 'Acme-STEVEB' or die $!;
    like getcwd(), qr/Acme-STEVEB$/, "in new module directory ok";

    open my $orig_fh, '<', "$cwd/$orig/Module.tpl" or die $!;
    open my $new_fh, '<', $new_mod_file or die $!;

    my @orig_tpl = <$orig_fh>;
    my @new_tpl  = <$new_fh>;

    close $orig_fh;
    close $new_fh;

    for (0..$#new_tpl) {
        if ($_ == 0) {
            is "#$new_tpl[$_]", "$orig_tpl[$_]", "module template line $_ matches ok";
            next;
        }
        if ($orig_tpl[$_] =~ /Copyright.*2020/) {
            like $new_tpl[$_], qr/Copyright.*\d{4}/, "module template line $_ Copyright matches ok";
            next;
        }
        is $new_tpl[$_], $orig_tpl[$_], "module template line $_ matches ok";
    }

    chdir '..' or die $!;
    like getcwd(), qr/init$/, "back in 'init' directory ok";

    check();
    after();
}

remove_init();

done_testing;

sub before {
    like $cwd, qr/dist-mgr/i, "in proper directory ok";

    chdir $work or die $!;
    like getcwd(), qr/$work$/, "in $work directory ok";

    if (! -d 'init') {
        mkdir 'init' or die $!;
    }

    is -d 'init', 1, "'init' dir exists ok";

    chdir 'init' or die $!;
    like getcwd(), qr/$work\/init$/, "in $work/init directory ok";
}
sub after {
    chdir $cwd or die $!;
    like getcwd(), qr/dist-mgr/i, "back in root directory ok";
    remove_init();

    is -e "$work/init", undef, "'init' dir removed ok";
}
sub check {
    is -d 'Acme-STEVEB', 1, "Acme-STEVEB directory created ok";

    chdir 'Acme-STEVEB' or die $!;
    like getcwd(), qr/Acme-STEVEB/, "in Acme-STEVEB dir ok";
}

