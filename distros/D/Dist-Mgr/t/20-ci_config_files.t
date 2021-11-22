use warnings;
use strict;
use Test::More;

use Cwd qw(getcwd);
use Data::Dumper;
use Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $cwd  = getcwd();
my $work = "$cwd/t/data/work";
my $orig = "$cwd/t/data/orig";
my $orig_file = "$orig/github_ci_default.yml";

my $ci_dir = "$work/ci";
my $ci_file = "$ci_dir/.github/workflows/github_ci_default.yml";

remove_ci();
unlink_ci_files();

mkdir $ci_dir or die $!;
chdir $ci_dir or die $!;

like getcwd(), qr/$ci_dir$/, "changed to $ci_dir ok";
die "We're not in the $ci_dir!" if getcwd() !~ /$ci_dir$/;

# bad params
{
    for ({}, sub {}, \'string') {
        is eval{ci_github($_); 1}, undef, "ci_github() croaks with param ref " . ref $_;
    }

    is
        eval {Dist::Mgr::_ci_github_write_file({}); 1 },
        undef,
        "_ci_github_write_file() croaks if not sent in an array ref";

    like $@, qr/requires an array ref/, "...and error is sane";
}

# no params (default: linux, windows, macos)
{
    my @ci = ci_github();

    is grep(/\s+ubuntu-latest,/, @ci), 1, "no param linux included ok";
    is grep (/\s+windows-latest,/, @ci), 1, "no param windows included ok";
    is grep (/\s+macos-latest/, @ci), 1, "no param macos included ok";

    my $os_line = "        os: [ ubuntu-latest, windows-latest, macos-latest ]";
    compare_contents('none', $os_line, @ci);
    clean();
}

# windows
{
    my @ci = ci_github([qw(w)]);

    is grep(/ubuntu-latest/, @ci), 1, "w param no linux included ok";
    is grep (/\s+windows-latest\s+/, @ci), 1, "w param windows included ok";
    is grep (/macos-latest/, @ci), 0, "w param no macos included ok";

    my $os_line = "        os: [ windows-latest ]";
    compare_contents('w', $os_line, @ci);
    clean();
}

# linux
{
    my @ci = ci_github([qw(l)]);

    is grep(/\s+ubuntu-latest\s+/, @ci), 1, "l param linux included ok";
    is grep (/windows-latest/, @ci), 0, "l param no windows included ok";
    is grep (/macos-latest/, @ci), 0, "l param no macos included ok";

    my $os_line = "        os: [ ubuntu-latest ]";
    compare_contents('l', $os_line, @ci);
    clean();
}

# macos
{
    my @ci = ci_github([qw(m)]);

    is grep(/ubuntu-latest/, @ci), 1, "m param no linux included ok";
    is grep (/windows-latest/, @ci), 0, "m param no windows included ok";
    is grep (/\s+macos-latest\s+/, @ci), 1, "m param macos included ok";

    my $os_line = "        os: [ macos-latest ]";
    compare_contents('m', $os_line, @ci);
    clean();
}

# linux, windows, macos
{
    my @ci = ci_github([qw(l w m)]);

    is grep(/\s+ubuntu-latest,/, @ci), 1, "no param linux included ok";
    is grep (/\s+windows-latest,/, @ci), 1, "no param windows included ok";
    is grep (/\s+macos-latest\s+/, @ci), 1, "no param macos included ok";

    my $os_line = "        os: [ ubuntu-latest, windows-latest, macos-latest ]";
    compare_contents('l w m', $os_line, @ci);
    clean();
}

chdir $cwd or die $!;
is getcwd(), $cwd, "back in '$cwd' directory ok";

unlink_ci_files();
remove_ci();

sub clean {
    is -e $ci_file, 1, "CI file exists ok";
    unlink $ci_file or die $!;
    is -e $ci_file, undef, "CI file removed ok";
}
sub contents {
    open my $fh, '<', $orig_file or die $!;
    my @contents = <$fh>;
    return @contents;
}
sub compare_contents {
    my ($params, $os_line, @new) = @_;

    my @orig = contents();

    for my $i (0..$#orig) {
        chomp $orig[$i];
        chomp $new[$i];
        $orig[$i] =~ s/[\r\n]//g;
        $orig[$i] =~ s/^"//;
        $orig[$i] =~ s/",$//;

        if ($new[$i] =~ /^\s+os: \[/) {
            is $new[$i], $os_line, "OS matrix ok for params '$params'";
            next;
        }
        is $new[$i], $orig[$i], "CI file line '$i' with params '$params' matches ok";
    }
}

done_testing;

