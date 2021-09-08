# -*- perl -*-
# t/004-set-targets-t
use 5.14.0;
use warnings;
use Devel::Git::MultiBisect::AllCommits;
use Devel::Git::MultiBisect::Opts qw( process_options );
use Test::More;
unless (
    $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR}
        and
    (-d $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR})
) {
    plan skip_all => "No git checkout of List-Compare found";
}
else {
    plan tests => 24;
}
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );

my $startdir = cwd();
chdir $ENV{PERL_LIST_COMPARE_GIT_CHECKOUT_DIR}
    or croak "Unable to change to List-Compare checkout directory";

my (%args, $params, $self);
my ($good_gitdir, $good_last_before, $good_last);
my ($target_args, $full_targets);
my $bad_target_args;

note("Test use of 'last_before' option");

$good_gitdir = cwd();
$good_last_before = '2614b2c2f1e4c10fe297acbbea60cf30e457e7af';
$good_last = 'd304a207329e6bd7e62354df4f561d9a7ce1c8c2';
%args = (
    gitdir => $good_gitdir,
    #    targets => [ @good_targets ],
    last_before => $good_last_before,
    last => $good_last,
    outputdir => tempdir( CLEANUP => 1 ),
);
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');
for my $d (qw| gitdir outputdir |) {
    ok(defined $self->{$d}, "'$d' has been defined");
    ok(-d $self->{$d}, "'$d' exists: $self->{$d}");
}

$target_args = [
    File::Spec->catdir( qw| t 44_func_hashes_mult_unsorted.t |),
    File::Spec->catdir( qw| t 45_func_hashes_alt_dual_sorted.t |),
];
$full_targets = $self->set_targets($target_args);
ok($full_targets, "set_targets() returned true value");
is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
is_deeply(
    [ map { $_->{path} } @{$full_targets} ],
    [ map { File::Spec->catfile($self->{gitdir}, $_) } @{$target_args} ],
    "Got expected full paths to target files for testing",
);

{
    local $@;
    $bad_target_args = [
        File::Spec->catdir( qw| t 44_func_hashes_mult_unsorted.t |),
        File::Spec->catdir( qw|   45_func_hashes_alt_dual_sorted.t |),
    ];
    eval { $full_targets = $self->set_targets($bad_target_args); };
    like($@, qr/\QCannot find file(s) to be tested:\E.*\Q$bad_target_args->[1]\E/,
        "Got expected error message: bad target file: $bad_target_args->[1]");
}

note("Test use of 'first' option");

my ($good_first, $bad_first);
delete $args{last_before};
$good_first = '2a2e54af709f17cc6186b42840549c46478b6467';
$args{first} = $good_first;
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');

$full_targets = $self->set_targets($target_args);
ok($full_targets, "set_targets() returned true value");
is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
is_deeply(
    [ map { $_->{path} } @{$full_targets} ],
    [ map { File::Spec->catfile($self->{gitdir}, $_) } @{$target_args} ],
    "Got expected full paths to target files for testing",
);

note("Error conditions");
{
    {
        local $@;
        $bad_target_args = [
            't/44_func_hashes_mult_unsorted.t',
            '45_func_hashes_alt_dual_sorted.t',
        ];
        eval { $full_targets = $self->set_targets($bad_target_args); };
        like($@, qr/\QCannot find file(s) to be tested:\E.*\Q$bad_target_args->[1]\E/,
            "Got expected error message: bad target file: $bad_target_args->[1]");
    }

    {
        local $@;
        $bad_target_args = {
            't/44_func_hashes_mult_unsorted.t',
            't/45_func_hashes_alt_dual_sorted.t',
        };
        eval { $full_targets = $self->set_targets($bad_target_args); };
        like($@, qr/\QExplicit targets passed to set_targets() must be in array ref\E/,
            "Got expected error message: non-array-ref argument to set_targets()");
    }
}
note("targets provided via new()");

%args = (
    gitdir => $good_gitdir,
    #    targets => [ @good_targets ],
    last_before => $good_last_before,
    last => $good_last,
    outputdir => tempdir( CLEANUP => 1 ),
);
$params = process_options(%args);
$self = Devel::Git::MultiBisect::AllCommits->new($params);
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');

$good_gitdir = cwd();
$good_last_before = '2614b2c2f1e4c10fe297acbbea60cf30e457e7af';
$good_last = 'd304a207329e6bd7e62354df4f561d9a7ce1c8c2';
%args = (
    gitdir => $good_gitdir,
    #    targets => [ @good_targets ],
    last_before => $good_last_before,
    last => $good_last,
    outputdir => tempdir( CLEANUP => 1 ),
);
$params = process_options(%args);
$target_args = [
    't/44_func_hashes_mult_unsorted.t',
    't/45_func_hashes_alt_dual_sorted.t',
];
$self = Devel::Git::MultiBisect::AllCommits->new( {
    %{$params},
    targets => $target_args,
} );
ok($self, "new() returned true value");
isa_ok($self, 'Devel::Git::MultiBisect::AllCommits');

$full_targets = $self->set_targets();
ok($full_targets, "set_targets() returned true value");
is(ref($full_targets), 'ARRAY', "set_targets() returned array ref");
is_deeply(
    [ map { $_->{path} } @{$full_targets} ],
    [ map { File::Spec->catfile($self->{gitdir}, $_) } @{$target_args} ],
    "Got expected full paths to target files for testing",
);

chdir $startdir or croak "Unable to return to $startdir";

__END__
