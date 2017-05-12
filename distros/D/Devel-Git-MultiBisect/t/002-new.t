# -*- perl -*-
# t/002-new.t
use strict;
use warnings;
use Devel::Git::MultiBisect::AllCommits;
use Devel::Git::MultiBisect::Opts qw( process_options );
use Test::More tests => 10;
use Cwd;
use File::Spec;

my $cwd = cwd();

my (%args, $params, $self);

my ($good_gitdir, $good_last_before, $good_last);
$good_gitdir = File::Spec->catdir($cwd, qw| t lib list-compare |);
$good_last_before = '2614b2c2f1e4c10fe297acbbea60cf30e457e7af';
$good_last = 'd304a207329e6bd7e62354df4f561d9a7ce1c8c2';
%args = (
    gitdir => $good_gitdir,
    #    targets => [ @good_targets ],
    last_before => $good_last_before,
    last => $good_last,
);
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');

my ($bad_gitdir, $bad_last_before, $bad_last);
{
    local $@;
    $bad_gitdir = File::Spec->catdir('', qw| home jkeenan gitwork mist-compare |);
    $args{gitdir} = $bad_gitdir;
    $params = process_options(%args);
    eval { $self = Devel::Git::MultiBisect::AllCommits->new($params); };
    like($@, qr/\QCannot find directory(ies): $bad_gitdir\E/,
        "Got expected error: missing directory $bad_gitdir"
    );
    $args{gitdir} = $good_gitdir;
}

{
    local $@;
    $bad_last_before = 'xxxxx';
    $args{last_before} = $bad_last_before;
    $params = process_options(%args);
    eval { $self = Devel::Git::MultiBisect::AllCommits->new($params); };
    like($@, qr/fatal:/s,
        "Got expected error: bad last_before"
    );
    $args{last_before} = $good_last_before;
}

{
    local $@;
    $bad_last = 'xxxxx';
    $args{last} = $bad_last;
    $params = process_options(%args);
    eval { $self = Devel::Git::MultiBisect::AllCommits->new($params); };
    like($@, qr/fatal:/s,
        "Got expected error: bad last"
    );
    $args{last} = $good_last;
}

my ($good_first, $bad_first);
delete $args{last_before};
$good_first = '2a2e54af709f17cc6186b42840549c46478b6467';
$args{first} = $good_first;
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');

{
    local $@;
    $bad_first = 'yyyyy';
    $args{first} = $bad_first;
    $params = process_options(%args);
    eval { $self = Devel::Git::MultiBisect::AllCommits->new($params); };
    like($@, qr/fatal:/s,
        "Got expected error: bad first"
    );
    $args{first} = $good_first;
}

$args{verbose} = 1;
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');
