package Devel::Git::MultiBisect::Init;
use v5.14.0;
use warnings;
use Carp;
use Cwd;
use File::Spec;
use File::Temp;

our $VERSION = '0.21';
$VERSION = eval $VERSION;

=head1 NAME

Devel::Git::MultiBisect::Init - Initializer for Devel::Git::MultiBisect

=head1 DESCRIPTION

This package exports no subroutines.  Subroutine C<init(()> should be called
with a fully qualified name inside C<Devel::Git::MultiBisect->new()>.

=head1 SUBROUTINES

=head2 C<init()>

=over 4

=item * Purpose

Initializer, to be called from within constructors such as that of
F<Devel::Git::MultiBisect>.  Not meant to be publicly called.

=item * Argument

    my $data = Devel::Git::MultiBisect::Init::init($params);

Single hash reference, typically, the output of C<Devel::Git::MultiBisect::Opts::process_options()>.

=item * Return Value

Single hash reference.

=back

=cut

sub init {
    my $params = shift;
    my %data;

    while (my ($k,$v) = each %{$params}) {
        $data{$k} = $v;
    }

    my @missing_dirs = ();
    for my $dir ( qw| gitdir outputdir | ) {
        push @missing_dirs, $data{$dir}
            unless (-d $data{$dir});
    }
    if (@missing_dirs) {
        croak "Cannot find directory(ies): @missing_dirs";
    }

    $data{last_short} = substr($data{last}, 0, $data{short});
    $data{commits} = _get_commits(\%data);
    $data{targets} //= [];
    $data{commit_counter} = 0;

    return \%data;
}

sub _get_commits {
    my $dataref = shift;
    my $cwd = cwd();
    chdir $dataref->{gitdir} or croak "Unable to chdir";
    my @commits = ();
    my ($older, $cmd);
    my $err = File::Temp->new( UNLINK => 1, SUFFIX => '.err' );
    if ($dataref->{last_before}) {
        $older = '^' . $dataref->{last_before};
        $cmd = "git rev-list --reverse $older $dataref->{last} 2>$err";
    }
    else {
        $older = $dataref->{first} . '^';
        $cmd = "git rev-list --reverse ${older}..$dataref->{last} 2>$err";
    }
    chomp(@commits = `$cmd`);
    if (! -z $err) {
        open my $FH, '<', $err or croak "Unable to open $err for reading";
        my $error = <$FH>;
        chomp($error);
        close $FH or croak "Unable to close $err after reading";
        croak $error;
    }
    my @extended_commits = map { {
        sha     => $_,
        short   => substr($_, 0, $dataref->{short}),
    } } @commits;
    chdir $cwd or croak "Unable to return to original directory";
    return [ @extended_commits ];
}

1;

