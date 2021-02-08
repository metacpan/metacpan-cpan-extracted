use warnings;
use strict;
use Test::More;

use Data::Dumper;
use Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

check_skip();

my $d = 't/data/work';
my $f = 't/data/orig/No.pm';

my @valid = ("$d/One.pm", "$d/Two.pm", "$d/Three.pm");

my $u = 'stevieb9';
my $r = 'test-repo';

unlink_module_files();
copy_module_files();

# bad params
{
    is eval{ci_badges(); 1}, undef, "croak if no params ok";
    like $@, qr/\Qci_badges() needs\E/, "...and error is sane";

    is eval{ci_badges('stevieb9'); 1}, undef, "croak if only author param ok";
    like $@, qr/\Qci_badges() needs\E/, "...and error is sane";
}

# files & content (live run)
{
    for my $file (@valid) {
        my $ret = ci_badges($u, $r, $file);

        is $ret, 0, "proper return from ci_badges()";
        verify_file($file);
    }
}

# files & content (live run, duplicate) (fail)
{
    for my $file (@valid) {
        my $ret = ci_badges($u, $r, $file);

        if ($file !~ /Three\.pm/) {
            is $ret, -1, "proper return from ci_badges() if trying to add dup";
        }

        verify_file($file);
    }
}

unlink_module_files();
verify_clean();

sub verify_file {
    my ($file) = @_;

    open my $fh, '<', $file or die $!;
    my @c = <$fh>;
    close $fh;

    if ($file =~ /Three\.pm/) {
        is grep(/^=for html$/, @c), 0, "'$file': header line not included if no NAME header ok";
        is grep(/stevieb9/, @c), 0, "'$file': author not included if no NAME header ok";
        is grep(/test-repo/, @c), 0, "'$file': repo not included if no NAME header ok";

        return;
    }

    is grep(/^=for html$/, @c), 1, "'$file': header line included ok";
    is grep(/stevieb9/, @c), 2, "'$file': proper count of author name ok";
    is grep(/test-repo/, @c), 2, "'$file': proper count of repo name ok";
}

done_testing();

