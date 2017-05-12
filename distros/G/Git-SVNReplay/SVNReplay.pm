package Git::SVNReplay;

use strict;
use warnings;

use DBM::Deep;
use File::Spec;
use File::Find;
use File::Path;
use File::Slurp qw(write_file slurp);
use Term::GentooFunctions qw(:all);
use IPC::System::Simple qw(systemx capturex);
use Date::Parse; # dates in (Date::Manip will not handle git/date-R time...)
use POSIX; # dates out

our $VERSION = '1.0214';

our %DEFAULTS = (
    db_file       => "replay.rdb",
    patch_format  => '%s [%h]%n%n%b%n%aN <%aE>%n%ai%n%H',
    src_branch    => "master",
    mirror_branch => "mirror",
    git_repo      => "g.repo",
    svn_repo      => "s.repo",
    svn_co        => "s.co",
);

# new {{{
sub new {
    my $class = shift;
    my $this = bless {%DEFAULTS, @_}, $class;

    $this;
}
# }}}
# set {{{
sub set {
    my $this = shift;
    my %h = @_;
    $this->{$_} = $h{$_} for keys %h;
    $this;
}
# }}}
# create_db {{{
sub create_db {
    my $this = shift;

    return $this->{dbm} if $this->{dbm};

    my $TOP = new DBM::Deep($this->{db_file});

    $TOP->{$this->{svn_co}} = {}
        unless $TOP->{$this->{svn_co}};

    $this->{dbm} = $TOP->{$this->{svn_co}};
}
# }}}

# setup_git_in_svnco {{{
sub setup_git_in_svnco {
    my $this = shift;

    my $repo = $this->{git_repo}; $repo = File::Spec->rel2abs($repo) if -d $repo;
    chdir $this->{svn_co} or edie "couldn't chdir into svn_co ($this->{svn_co}): $!";

    if( not -d "$this->{svn_co}/.git/" ) {
        ebegin "cloning $this->{git_repo} ($this->{src_branch})";
        $this->logging_systemx(qw(git init));
        $this->logging_systemx(qw(git symbolic-ref HEAD), "refs/heads/$this->{mirror_branch}");
        eend 1;

    } else {
        ebegin "resettting mirror";
        $this->logging_systemx(qw(git checkout -q), $this->{mirror_branch});
        $this->logging_systemx(qw(git reset --hard));
        eend 1;

    }

    ebegin "pulling updates from $this->{git_repo} ($this->{src_branch})";
    $this->logging_systemx(qw(git pull), $repo, "$this->{src_branch}:$this->{mirror_branch}");
    eend 1;

    $this;
}
# }}}
# run {{{
sub run {
    my $this = shift;
       $this->create_db;

    my @commits = capturex(qw(git rev-list --reverse mirror)); chomp @commits;
       @commits = grep { !$this->{dbm}{already_replayed}{$_} } @commits;

    my $total = @commits;
    my $cur = 1;

    for my $commit ( @commits ) {
        $this->{_progress} = "[$cur/$total]:$commit";

        if( $this->replay($commit) and $this->inform_svn($commit) ) {
            push @{ $this->{dbm}{replayed_commits_in_order} }, $commit;
            $this->{dbm}{already_replayed}{$commit} = 1

        } else {
            edie("no point in continuing, something is wrong");
        }

        $cur ++;
    }

    $this;
}
# }}}

# replay {{{
sub replay {
    my ($this, $commit) = @_;

    einfo "REPLAY $this->{_progress}";
    eindent;

    einfo "git checkout";
    $this->logging_systemx(qw(git checkout -q), $commit);
    eend 1;

    ebegin "dumping commit log to .msg";
    write_file(".msg" => capturex(qw(git show -s), '--pretty=format:' . $this->{patch_format}));
    eend 1;

    eoutdent;

    return 1;
}
# }}}
# inform_svn {{{
sub inform_svn {
    my ($this, $commit) = @_;

    einfo "INFORM $this->{_progress}";
    eindent;

    my @files;
    my @dirs;

    &File::Find::find({wanted => sub {
        if( -f $_ ) {
            unless( $_ eq ".msg" ) {
                push @files, $File::Find::name;
            }

        } elsif( -d _ ) {
            if( m/^\.(?:git|svn)\z/ ) {
                $File::Find::prune = 1;

            } elsif( not m/^\.{1,2}\z/ ) {
                push @dirs, $File::Find::name;
            }
        }

    }}, '.' );

    if( my $parent = $this->{dbm}{replayed_commits_in_order}[-1] ) {
        for my $f (@{ $this->{dbm}{last_files}{$parent} }) {
            unless( -f $f ) {
                einfo "removing file \"$f\" from svn:  ";
                $this->logging_systemx(qw(svn rm), $f);
                eend 1;

                $this->{dbm}{already_tracking_file}{$f} = 0;
            }
        }

        for my $d (@{ $this->{dbm}{last_dirs}{$parent} }) {
            unless( -d $d ) {
                einfo "removing directory \"$d\" from svn:  ";
                $this->logging_systemx(qw(svn rm), $d);
                eend 1;

                $this->{dbm}{already_tracking_dir}{$d} = 0;
            }
        }
    }

    for my $d (@dirs) {
        next if $this->{dbm}{already_tracking_dir}{$d};

        einfo "adding directory \"$d\" to svn:  ";
        $this->logging_systemx(qw(svn add), $d);
        eend 1;

        $this->{dbm}{already_tracking_dir}{$d} = 1;
    }

    for my $f (@files) {
        next if $this->{dbm}{already_tracking_file}{$f};

        einfo "adding file \"$f\" to svn:  ";
        $this->logging_systemx(qw(svn add), $f);
        eend 1;

        $this->{dbm}{already_tracking_file}{$f} = 1;
    }

    ebegin "comitting changes to svn";
    $this->logging_systemx(qw(svn commit -F .msg));
    eend 1;

    if( my $gdate = capturex(qw(git show -s --pretty=format:%at)) ) {
        my $date = strftime('%Y-%m-%dT%H:%M:%S.000000Z', gmtime($gdate));

        ebegin "changing commit date to $date";
        $this->logging_systemx(qw(svn propset --revprop -r HEAD svn:date), $date);
        eend 1;

    } else {
        ewarn "date not found for $commit";
    }

    $this->{dbm}{last_dirs}{$commit}  = \@dirs;
    $this->{dbm}{last_files}{$commit} = \@files;

    # svn commits sometimes alters things causing git merge problems (very rare).
    # This resets everything that's tracked by git.
    $this->logging_systemx(qw(git reset --hard));

    eoutdent;

    return 1;
}
# }}}


# create_svn_repo {{{
sub create_svn_repo {
    my $this = shift;

    my $svn_repo = File::Spec->rel2abs( $this->{svn_repo} );

    # automatically skip anything we don't need to bother doing
    unless( -d $svn_repo ) {
        einfo "creating svn repo: $this->{svn_repo}";
        $this->logging_systemx(svnadmin => 'create', $svn_repo);
        eend 1;

        einfo "installing pre-revprop-change (svn:date only) hook";
            my $prpc_file = "$svn_repo/hooks/pre-revprop-change";
            my $prpc_text = slurp("$prpc_file.tmpl");
               $prpc_text =~ s/svn:log/svn:date/g;

            write_file( $prpc_file => $prpc_text );
            chmod 0755, $prpc_file or edie "chmod() error: $!";
        eend 1;
    }

    unless( -d $this->{svn_co} ) {
        einfo "checking out new svn: $this->{svn_repo} -> $this->{svn_co}";
        $this->logging_systemx(qw(svn co), "file://$svn_repo", $this->{svn_co});
        eend 1;
    }

    $this;
}
# }}}
# add_svn_dir {{{
sub add_svn_dir {
    my ($this, $cod) = @_;

    $this->{_co} ||= File::Spec->rel2abs( $this->{svn_co} );
    chdir $this->{_co} or edie "couldn't chdir into svn_co ($this->{svn_co}): $!";

    my $r  = File::Spec->rel2abs( $cod );
       $r =~ s/^\Q$this->{_co}\E\///
           or edie "$cod doesn't want to be located under $this->{svn_co}";

    unless( -d $r ) {
        ebegin "adding $cod to $this->{svn_co}";
        eindent;

        ebegin "mkdir -p $cod";
        mkpath($r); # uses umask and 0777 to create
        eend 1;

        my @split = split m/\//, $r; $r = shift @split; {
            ebegin "svn add $r";
            $this->logging_systemx(qw(svn add), $r);
            eend 1;

         # NOTE: SVN apparnetly does this recursively
         #  if( @split ) {
         #      $r .= "/" . (shift @split);
         #      redo;
         #  }

        }

        ebegin "svn commit";
        $this->logging_systemx(qw(svn commit -m), "git-svn-replay added $cod to $this->{svn_co}");
        eend 1;

        eoutdent;
        eend 1;
    }

    $this;
}
# }}}

# stdoutlog {{{
sub stdoutlog {
    my $this = shift;
    return unless $this->{stdoutlog};

    write_file( $this->{stdoutlog}, {append=>1}, scalar localtime, @_ );

    $this;
}
# }}}
# logging_systemx {{{
sub logging_systemx {
    my $this = shift;
    my @res = eval { (capturex(@_), "my res pop") }; my $l = __LINE__;
    my @c = caller;
    unless( pop @res ) {
        my $e = $@; $e =~ s/line $l/$c[2]/g;
        edie $e;
    }
    $this->stdoutlog("-- execvp(@_)\n", @res);

    $this;
}
# }}}

# quiet {{{
sub quiet {
    no warnings 'redefine';

    *eend   = sub(@) {};
    *einfo  = sub($) {};
    *ebegin = sub($) {};
    *ewarn  = sub($) {};

    $_[0];
}
# }}}

no warnings;
"my codes are perfect (too)"; # I ♡ github.
