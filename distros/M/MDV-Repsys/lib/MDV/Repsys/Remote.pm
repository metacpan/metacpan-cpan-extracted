package MDV::Repsys::Remote;

use strict;
use warnings;
use Carp;
use MDV::Repsys qw(sync_source extract_srpm);
use Config::IniFiles;
use SVN::Client;
use Date::Parse;
use Date::Format;
use POSIX qw(getcwd);
use RPM4;
use File::Temp qw(tempfile);
use File::Tempdir;
use File::Path;

our $VERSION = ('$Revision: 103942 $' =~ m/(\d+)/)[0];

=head1 NAME

MDV::Repsys::Remote

=head1 SYNOPSYS

Module to access and build rpm from a svn

=head1 FUNCTIONS

=head2 new(%options)

Create a new MDV::Repsys::Remote object

options:

=over 4

=item configfile

Use this repsys configuration file instead /etc/repsys.conf

=item nocommit

Disable commit action, usefull for testing purpose

=back

=cut

sub new {
    my ($class, %options) = @_;

    my $homerepsys = (
        $ENV{REPSYS_CONF} ?
        $ENV{REPSYS_CONF} :
        "$ENV{HOME}/.repsys/repsys.conf"
    );

    my $cfg = Config::IniFiles->new(
        (-r $homerepsys ? (-file => $homerepsys) : ()),
        '-import' => Config::IniFiles->new(
            -file => $options{configfile} || "/etc/repsys.conf",
        ) || undef,
    );

    my $home_cfg = (
        -r $homerepsys ?
        Config::IniFiles->new(-file => $homerepsys, '-import' => $cfg,) :
        undef
    ) || Config::IniFiles->new('-import' => $cfg,);

    $cfg or return undef;

    my $repsys = {
        config => $cfg,
        svn => SVN::Client->new(),
        nocommit => $options{nocommit},
        default => {
            pkgversion => 'current',
            revision => 'HEAD',
        },
        error => undef,
        tempdir => [],
    };

    bless($repsys, $class);
    $repsys->set_verbosity(0);

    $repsys
}

=head2 last_error

Return the last error message after a failure.

=cut

sub last_error {
    return $_[0]->{error};
}

=head2 set_verbosity($level)

Set the verbosity verbosity of the module:

  0 silent
  1 progress message
  2 debug message

=cut

sub set_verbosity {
    my ($self, $level) = @_;
    $self->{verbosity} = $level || 0;
    # not 0 ? (INFO, DEBUG) : ERROR
    RPM4::setverbosity($level ? $level + 5 : 3);
} 

sub _print_msg {
    my ($self, $level, $fmt, @args) = @_;
    $fmt or croak "No message given to _print_msg";
    $level > 0 or croak "message cannot be < 1 ($level)";
    return if $level > $self->{verbosity};
    printf("$fmt\n", @args);
}

=head2 get_pkgurl_parent($pkgname, %options)

Return the parent svn url location for package named $pkgname

=cut

sub get_pkgurl_parent {
    my ($self, $pkgname) = @_;
    sprintf(
        "%s/%s",
        $self->{config}->val('global', 'default_parent') || "",
        $pkgname,
    );
}

=head2 get_pkgname_from_wc

Return the package name from current working copy

=cut

sub get_pkgname_from_wc { 
    my ($self) = @_;

    my $ctx = new SVN::Client();
    our $url;
    my $receiver = sub {
        my( $path, $info, $pool ) = @_;
        our $url = $info->URL;
    };
    eval { 
        $ctx->info(getcwd(), undef, 'WORKING', $receiver, 0); 
    };
    if ($@) {
        return ;
    }
    my $parent = $self->{config}->val('global', 'default_parent');
    $url =~ /^\Q$parent\E\/([^\/]*)\/?.*$/;
    return $1 
}

=head2 get_pkgurl($pkgname, %options)

Return the svn url location for package named $pkgname

=cut

sub get_pkgurl {
    my ($self, $pkgname, %options) = @_;
    sprintf(
        "%s/%s",
        $self->get_pkgurl_parent($pkgname),
        $options{pkgversion} || $self->{default}{pkgversion},
    );
}

=head2 checkout_pkg($pkgname, $destdir, %options)

Checkout a package from svn into $destdir directory

=cut

sub checkout_pkg {
    my ($self, $pkgname, $destdir, %options) = @_;

    $destdir ||= $pkgname;

    my $revision;
    $self->_print_msg(1, 'Checkout package %s into %s/', $pkgname, $destdir);
    eval {
        $revision = $self->{svn}->checkout(
            $self->get_pkgurl($pkgname, %options),
            $destdir,
            $options{revision} || $self->{default}{revision},
            1,
        );
    };
    if ($@) {
        $self->{error} = "Can't checkout $pkgname: $@";
        return;
    }

    return $revision;
}

=head2 get_old_changelog($pkgname, $handle, %options)

Read old changelog entry from svn and write it into $handle.
If not specified, $handle is set to STDOUT.

=cut

sub get_old_changelog {
    my ($self, $pkgname, $handle, %options) = @_;
    
    $handle ||= \*STDOUT;

    $self->_print_msg(2, 'Get old changelog for %s', $pkgname);
    eval {
        $self->{svn}->cat(
            $handle,
            sprintf(
                "%s/%s/log",
                $self->{config}->val('log', 'oldurl'),
                $pkgname,
            ),
            $options{revision} || $self->{default}{revision},
        ); 
    };
    if ($@) {
        $self->{error} = "Can't get old changelog for $pkgname: $@";
        return;
    }
    return 1;
}

sub _old_log_pkg {
    my ($self, $pkgname, %options) = @_;

    my $templog = File::Temp->new(UNLINK => 1);

    $self->get_old_changelog($pkgname, $templog, %options) or return;

    my @cl;

    seek($templog, 0, 0);

    while(my $line = <$templog>) {
        chomp($line);
        $line or next;
        $line =~ /^%changelog/ and next;
        if ($line =~ /^\* (\w+\s+\w+\s+\d+\s+\d+)\s+(.*)/) {
            push(
                @cl,
                {
                    'time' => str2time($1, 'UTC') || 0,
                    author => $2 || '',
                    text => '',
                }
            );
        } else {
            if (!@cl) {
                push(@cl, { header => 1, text => '', 'time' => 0 });
            }
            $cl[-1]->{text} .= "$line\n";
        }
    }

    @cl;
}

sub _log_pkg {
    my ($self, $pkgname, %options) = @_;
    
    my @cl;

    eval {
        $self->{svn}->log(
            $self->get_pkgurl($pkgname, %options, pkgversion => 'releases'),
            $options{revision} || $self->{default}{revision}, 
            0, 1, 0,
            sub {
                my ($changed_paths, $revision, $author, $date, $message) = @_;
                #print "$revision, $author, $date, $message\n";
                foreach (keys %{$changed_paths || {}}) {
                    my $info = $changed_paths->{$_};
                    $info->copyfrom_rev() > 0 or next;
                    m!releases/(?:([^:/]+):)?([^/]+)/([^/]+)! or next;
                    push(
                        @cl,
                        {
                            revision => $info->copyfrom_rev(),
                            author => '',
                            'time' => str2time($date),
                            text => '',
                            evr => "$2-$3",
                        }
                    );
                }
            }
        );
    };

    my $callback = sub {
        my ($changed_paths, $revision, $author, $date, $message) = @_;
        my $cltoupdate;
        foreach my $clg (sort { $b->{revision} <=> $a->{revision} } @cl) {
            if ($revision > $clg->{revision}) {
                next;
            } else {
                $cltoupdate = $clg;
            }
        }

        if (!$cltoupdate) {
            $cltoupdate = {
                revision => $revision,
                author => $author,
                'time' => str2time($date),
                text => '',
            };

            push(@cl, $cltoupdate);
        }

        $cltoupdate->{author} ||= $author,
        my @gti = gmtime(str2time($date));

        my ($textentry) = grep { $_->{author} eq $author } @{$cltoupdate->{log} || []};

        if (!$textentry) {
            $textentry = {
                author => $author,
                text => [],
            };
            push(@{$cltoupdate->{log}}, $textentry);
        }

        push(@{$textentry->{text}}, $message);
        
    };

    eval {
        $self->{svn}->log(
            $self->get_pkgurl($pkgname, %options),
            $options{revision} || $self->{default}{revision},
            0, 0, 0,
            $callback,
        );
    };
    if ($@) {
        $self->{error} = "Can't get svn log: $@";
        return;
    }

    @cl
}

sub _fmt_cl_entry {
    my ($self, $cl) = @_;
    $cl->{'time'} or return $cl->{text};
    my @gti = gmtime($cl->{'time'});

    # subversion changelog is having empty commit
    return if not $cl->{author};
    my $text = $cl->{text};
    if (!$text) {
        my $indent = '';
        foreach my $log (@{$cl->{log} || []}) {
            if ($log->{author} ne $cl->{author}) {
                $text .= "- from " . $self->{config}->val('users', $log->{author}, $log->{author}) . "\n";
            }
            foreach my $mes (@{$log->{text}}) {
                my $dash = '- ';
                $mes =~ s/^(\s|-|\*)*/$indent- /;
                foreach (split(/\n/, $mes)) {
                    chomp;
                    $_ or next;
                    s/([^%])?%([^%])?/$1%%$2/g;
                    s/^(\s|\*)*/$indent/;
                    if (!m/^-/) {
                        s/^/  /;
                    }
                    $text .= "$_\n";
                    $dash = '  ';
                }
            }
            $indent = '  ';
        }
    }
    $text =~ s/^\*/-/gm;
    sprintf
        "* %s %s%s\n%s%s\n",
        #  date
        #     author
        #         svn date + rev
        #           message
        strftime("%a %b %d %Y", @gti), # date
        $self->{config}->val(
            'users', 
            $cl->{author}, 
            $cl->{author}
        ),                             # author
        ($cl->{evr} ? " $cl->{evr}" : ''),
        ($cl->{revision} ? 
            sprintf(
                "+ %s (%s)\n",
                #  svn date
                #      revision
                strftime("%Y-%m-%d %T", @gti),   # svn date
                $cl->{revision},           # revision
            ) : ''
        ),                             # svn date + rev
        $text;                         # message
}

=head2 log_pkg($pkgname, $handle, %options)

Build a log from svn and print it into $handle.
If not specified, $handle is set to STDOUT.

=cut

sub log_pkg {
    my ($self, $pkgname, $handle, %options) = @_;
    $handle ||= \*STDOUT;
    foreach my $cl ($self->_log_pkg($pkgname, %options)) {
            print $handle $self->_fmt_cl_entry($cl);
    }
    1;
}

=head2 build_final_changelog($pkgname, $handle, %options)

Build the complete changelog for a package and print it into $handle.
If not specified, $handle is set to STDOUT.

=cut

sub build_final_changelog {
    my ($self, $pkgname, $handle, %options) = @_;

    $handle ||= \*STDOUT;

    $self->_print_msg(1, 'Building final changelog for %s', $pkgname);
    my @cls = $self->_log_pkg($pkgname, %options) or return 0;
    push(@cls, $self->_old_log_pkg($pkgname, %options));
 
    print $handle "\%changelog\n";

    foreach my $cl (sort {
            $b->{'time'} && $a->{'time'} ?
            $b->{'time'} <=> $a->{'time'} :
            $a->{'time'} <=> $b->{'time'}
        } grep { $_ } @cls) {
        print $handle $self->_fmt_cl_entry($cl);
    }
    1;
}

=head2 get_final_spec_fd($pecfile, $fh, %options)

Generated the final specfile from $pecfile into $fh filehandle.

=cut

sub get_final_spec_fd {
    my ($self, $specfile, $dh, %options) = @_;

    my $pkgname = $options{pkgname};

    if (!$pkgname) {
        my $spec = RPM4::specnew($specfile, undef, '/', undef, 1, 1) or do {
            $self->{error} = "Can't parse specfile $specfile";
            return;
        };
        my $h = $spec->srcheader or return; # can't happend
        $pkgname = $h->queryformat('%{NAME}');
    }

    if (defined(MDV::Repsys::_strip_changelog($specfile, $dh))) {

        print $dh "\n";
        $self->build_final_changelog(
            $pkgname,
            $dh,
            %options,
        ) or return;
    } else {
        $self->{error} = "Can't open $specfile for reading: $!";
        return;
    }
    1;
}

=head2 get_final_spec($specfile, %options)

Build the final changelog for upload from $specfile.

$options{pkgname} is the package name, if not specified, it is evaluate
from the specfile.

The new specfile will generated into $options{specfile} is specified,
otherwise a file with same name is create into $options{destdir}.

The module is safe, the source and destination can be the same file,
the content will be replaced.

if $options{destdir} is not specified, a temporary directory is created.
This directory will be trashed on MDV::Repsys::Remote object destruction.
So this kind of code will not work:

    my $o = MDV::Repsys::Remote->new();
    my $newspec = $o->get_final_spec($specfile);
    $o = undef;
    do_something_with($newspecfile); # the directory has been deleted

Notice this kind of code produce a warning.

=cut

sub get_final_spec {
    my ($self, $specfile, %options) = @_;

    $self->_print_msg(1, 'Building final specfile from %s', $specfile);

    if (!($options{destdir} || $options{specfile})) {
        warn "Using get_final_spec() without destdir or specfile option is unsafe, see perldoc MDV::Respsys::Remote";
    }

    my $odir;
    my $destfile;

    if ($options{specfile}) {
        $destfile = $options{specfile};
    } else {
        $odir = File::Tempdir->new($options{destdir});
        push(@{$self->{_temp_late_destroy}}, $odir);
        my ($basename) = $specfile =~ m!(?:.*/)?(.*)$!;
        $destfile = $odir->name() . "/$basename";
    }

    # avoid race condition is source == dest
    my $tempfh = File::Temp->new(UNLINK => 1);
    $self->get_final_spec_fd($specfile, $tempfh, %options);

    if (open(my $dh, ">", $destfile)) {
        seek($tempfh, 0, 0);
        while (<$tempfh>) {
            print $dh $_;
        }
        close($dh);
    } else {
        $self->{error} = "Can't open temporary file for writing: $!";
        return;
    }
    close($tempfh);

    return $destfile;
}

=head2 get_pkg_lastrev($pkgname, %options)

Return the real last revision change for a package.

=cut

sub get_pkg_lastrev {
    my ($self, $pkgname, %options) = @_;
    my $url = $self->get_pkgurl($pkgname, %options);
    my $leafs;

    eval {
        $leafs = $self->{svn}->ls(
            $url, 
            $options{revision} || $self->{default}{revision},
            1,
        );
    };
    if ($@) {
        $self->{error} = "Can't get information from $url: $@";
        return;
    }
    my $revision = 0;
    foreach my $leaf (%{$leafs || {}}) {
        defined($leafs->{$leaf}) or next;
        if ($leafs->{$leaf}->created_rev > $revision) {
            $revision = $leafs->{$leaf}->created_rev;
        }
    }
        
    $revision;
}

=head2 get_dir_lastrev($dir, %options)

Return the real last revision change for package checkout into $dir.

=cut

sub get_dir_lastrev {
    my ($self, $dir, %options) = @_;

    $self->_print_msg(2, 'Finding last rev from %s', $dir);
    my $revision = 0;
    eval {
        $self->{svn}->status(
            $dir,
            $options{revision} || $self->{default}{revision},
            sub {
                my ($path, $status) = @_;
                my $entry = $status->entry() or return;
                $revision = $entry->cmt_rev if($revision < $entry->cmt_rev);
            },
            1, # recursive
            1, # get_all
            0, # update
            0, # no_ignore
        );
    };
    if ($@) {
        $self->{error} = "can't get status of $dir: $@";
        return;
    }

    $revision
}

=head2 get_srpm($pkgname, %options)

Build the final src.rpm from the svn. Return the svn revision and
the src.rpm location.

=cut

sub get_srpm {
    my ($self, $pkgname, %options) = @_;

    my $odir = File::Tempdir->new($options{destdir});

    $self->checkout_pkg($pkgname, $odir->name(), %options) or return 0;

    my $revision = $self->get_dir_lastrev($odir->name(), %options) or return;

    MDV::Repsys::set_rpm_dirs($odir->name());
    RPM4::add_macro("_srcrpmdir " . ($options{destdir} || getcwd()));
    
    my $specfile = $self->get_final_spec(
        $odir->name() . "/SPECS/$pkgname.spec",
        %options,
        pkgname => $pkgname,
        destdir => $odir->name(),
    );

    my $spec = RPM4::specnew($specfile, undef, '/', undef, 1, 0) or do {
        $self->{error} = "Can't parse specfile $specfile";
        return 0;
    };

    RPM4::setverbosity(0) unless($self->{verbosity});
    RPM4::del_macro("_signature");
    $spec->build([ qw(PACKAGESOURCE) ]);
    return ($revision, $spec->srcrpm());

    1;
}

=head2 create_pkg($pkgname)

Create a package directory on the svn.

=cut

sub create_pkg {
    my ($self, $pkgname, %options) = @_;

    my $pkgurl_parent = $self->get_pkgurl_parent($pkgname, %options);
    my $pkgurl = $self->get_pkgurl($pkgname, %options);

    if ($self->_check_url_exists($pkgurl, %options)) {
        $self->{error} = "$pkgname is already inside svn";
        return;
    }

    my $message = $options{message} || "Create $pkgname";
    $self->{svn}->log_msg(sub {
            $_[0] = \$message;
            return 0;
        });
    $self->_print_msg(1, "Creating %s", $pkgname);
    $self->{svn}->mkdir([ $pkgurl_parent, $pkgurl, "$pkgurl/SOURCES", "$pkgurl/SPECS" ], );
    $self->{svn}->log_msg(undef);

    1;
}

=head2 import_pkg($rpmfile, %options)

Import a source package into the svn.

=cut

sub import_pkg {
    my ($self, $rpmfile, %options) = @_;

    my $h = RPM4::rpm2header($rpmfile) or do {
        $self->{error} = "Can't read rpm file $rpmfile";
        return;
    };
    if($h->hastag('SOURCERPM')) {
        $self->{error} = "$rpmfile is not a source package";
        return;
    }
    my $pkgname = $h->queryformat('%{NAME}');

    if ($self->_check_url_exists($self->get_pkgurl($pkgname), %options)) {
        $self->{error} = "$pkgname is already inside svn";
        return;
    }

    my $odir = File::Tempdir->new($options{destdir});

    eval {
        $self->{svn}->checkout(
            $self->{config}->val('global', 'default_parent') || '',
            $odir->name(),
            'HEAD', # What else ??
            0, # Don't be recursive !!
        );
    };
    if ($@) {
        $self->{error} = "Can't checkout " . $self->{config}->val('global', 'default_parent') . ": $@";
        return;
    }

    my $pkgdir = $odir->name() . "/$pkgname";

    $self->{svn}->update(
        $pkgdir,
        'HEAD',
        0,
    );

    if (-d $pkgdir) {
        $self->{error} = "$pkgname is already inside svn";
        return;
    }

    $self->{svn}->mkdir($pkgdir);
    $self->{svn}->mkdir("$pkgdir/current");

    $self->_print_msg(1, 'Importing %s', $rpmfile);
    MDV::Repsys::set_rpm_dirs("$pkgdir/current");
    my ($specfile, $cookie) =  MDV::Repsys::extract_srpm(
        $rpmfile,
        "$pkgdir/current",
    ) or do {
        $self->{error} = MDV::Repsys::repsys_error();
        return 0;
    };
    
    MDV::Repsys::set_rpm_dirs("$pkgdir/current");
    MDV::Repsys::sync_source("$pkgdir/current", $specfile) or do {
        $self->{error} = MDV::Repsys::repsys_error();
        return;
    };

    return if(!$self->splitchangelog(
        $specfile, 
        %options,
        pkgname => $pkgname,
    ));
   
    $self->_commit(
        $pkgdir,
        %options,
        pkgname =>  $pkgname,
        message => $options{message} || "Import $pkgname",
    );
}

sub _commit {
    my ($self, $dir, %options) = @_;
    my $pkgname = $options{pkgname} || $dir;

    my $message = $options{message};

    $self->{svn}->log_msg(
        $message ?
        sub {
            $_[0] = \$message;
            return 0;
        } :
        sub {
            MDV::Repsys::_commit_editor($_[0])
        }
    );
    $self->_print_msg(1, "Committing %s", $pkgname);
    my $revision = -1;
    if (!$self->{nocommit}) {
        my $info = $self->{svn}->commit($dir, 0) unless($self->{nocommit});
        $revision = $info->revision() if ($info);
    }
    $self->{svn}->log_msg(undef);

    $revision;
}


=head2 splitchangelog($specfile, %options)

Strip the changelog from a specfile and commit it into the svn.

=cut

sub splitchangelog {
    my ($self, $specfile, %options) = @_;

    my ($basename) = $specfile =~ m!(?:.*/)?(.*)$!;
    
    my $pkgname = $options{pkgname};

    if (!$pkgname) {
        my $spec = RPM4::specnew($specfile, undef, '/', undef, 1, 0) or do {
            $self->{error} = "Can't parse specfile $specfile";
            return;
        };
        my $h = $spec->srcheader or return; # can't happend
        $pkgname = $h->queryformat('%{NAME}');
    }

    my ($changelog, $newspec) = MDV::Repsys::_strip_changelog($specfile);

    if (!$changelog) {
        return -1;
    }
    my $revision = -1;

    my $odir = File::Tempdir->new();

    my $resyslog = $self->{config}->val('log', 'oldurl');
    if ($resyslog) {
        my $oldchangelogurl = "$resyslog/$pkgname";
        eval {
            $self->{svn}->checkout(
                $resyslog,
                $odir->name(),
                'HEAD',
                0,
            );
        };
        if ($@) {
            $self->{error} = "Can't checkout $resyslog: $@";
            return;
        }
        $self->{svn}->update(
            $odir->name() . "/$pkgname",
            'HEAD',
            1
        );
        if (! -d $odir->name() . "/$pkgname") {
            $self->{svn}->mkdir($odir->name() . "/$pkgname");
        }
        if (-f $odir->name() . "/$pkgname/log") {
            $self->{error} = "An old changelog file already exists for $pkgname, please fix";
            return;
        }
        if (open(my $logh, ">", $odir->name() . "/$pkgname/log")) {
            print $logh $changelog;
            close($logh);
        } else {
            $self->{error} = "Can't open new log file";
            return 0;
        }
        $self->{svn}->add($odir->name() . "/$pkgname/log", 0);
        my $message = $options{message} || "import old changelog for $pkgname";
        $self->{svn}->log_msg(sub {
            $_[0] = \$message;
            return 0;
        });
        $self->_print_msg(1, "Committing %s/log", $pkgname);
        if (!$self->{nocommit}) {
            my $info;
            eval {
                $info = $self->{svn}->commit($odir->name(), 0);
            };
            if ($@) {
                $self->{error} = "Error while commiting changelog: $@";
                return;
            }
            $revision = $info->revision();
        }

        $self->{svn}->log_msg(undef);
    }

    seek($newspec, 0, 0);
    if (open(my $oldspec, ">", $specfile)) {
        while (<$newspec>) {
            print $oldspec $_;
        }
        close($oldspec);
    } else {
        $self->{error} = "Can't open $specfile for writing: $!";
        return;
    }
    $revision;
}

=head2 commit($dir, %options)

Synchronize sources found into the spec and commit files into the svn.

=cut

sub commit {
    my ($self, $dir, %options) = @_;
    my $specfile = (glob('SPECS/*.spec'))[0];

    MDV::Repsys::set_rpm_dirs($dir);
    my ($toadd, $todel) = MDV::Repsys::_find_unsync_source(
        working_dir => $dir,
        specfile => $specfile,
        svn => $self->{svn},

    ) or do {
        $self->{error} = MDV::Repsys::repsys_error();
        return;
    };

    my $callback = $options{callback} || sub { 1; };
    if (@{$toadd || []} + @{$todel || []}) {
        if ($callback->($toadd, $todel)) {
            MDV::Repsys::_sync_source(
                svn => $self->{svn},
                needadd => $toadd,
                needdel => $todel,
            );
        }
    }

    $self->_commit(
        $dir,
        %options,
    );
}

sub _check_url_exists {
    my ($self, $url, %options) = @_;
    my ($parent, $leaf) = $url =~ m!(.*)?/+([^/]*)/*$!;

    my $leafs;

    eval {
        $leafs = $self->{svn}->ls(
            $parent, 
            $options{revision} || $self->{default}{revision},
            0,
        );
    };
    if ($@) {
        $self->{error} = "Can't list $parent: $@";
        return;
    }
    exists($leafs->{$leaf})
}

=head2 tag_pkg($pkgname, %options)

TAG a package into the svn, aka copy the current tree into
VERSION/RELEASE/. The operation is done directly into the svn.

=cut

sub tag_pkg {
    my ($self, $pkgname, %options) = @_;

    my ($handle, $tempspecfile) = tempfile();

    eval {
        $self->{svn}->cat(
            $handle,
            $self->get_pkgurl($pkgname) . "/SPECS/$pkgname.spec",
            $options{revision} || $self->{default}{revision},
        );
    };
    if ($@) {
        $self->{error} = "Can't get specfile " . $self->get_pkgurl($pkgname) . "/SPECS/$pkgname.spec: $@";
        return;
    }

    close($handle);

    my $spec = RPM4::specnew($tempspecfile, undef, '/', undef, 1, 1) or do {
        $self->{error} = "Can't parse $tempspecfile";
        return 0;
    };
    my $header = $spec->srcheader or return 0;

    my $ev = $header->queryformat('%|EPOCH?{%{EPOCH}:}:{}|%{VERSION}');
    my $re = $header->queryformat('%{RELEASE}');

    my $tagurl = $self->get_pkgurl($pkgname, pkgversion => 'releases');
    my $pristineurl = $self->get_pkgurl($pkgname, pkgversion => 'pristine');

    if (!$self->_check_url_exists($tagurl)) {
        $self->{svn}->mkdir($tagurl);
    }

    if (!$self->_check_url_exists("$tagurl/$ev")) {
        $self->{svn}->mkdir("$tagurl/$ev");
    }

    if ($self->_check_url_exists("$tagurl/$ev/$re")) {
        $self->{error} = "$tagurl/$ev/$re already exists";
        return;
    }

    my $message = "Tag release $ev-$re";
    $self->{svn}->log_msg(
        sub {
            $_[0] = \$message;
            return 0;
        }
    );
    $self->_print_msg(1, 'Tagging %s to %s/%s', $pkgname, $ev, $re);
    $self->{svn}->copy(
        $self->get_pkgurl($pkgname),
        $options{revision} || $self->{default}{revision},
        "$tagurl/$ev/$re",
    );
    eval {
        $self->{svn}->delete($pristineurl, 1);
    };
    $self->_print_msg(1, 'Tagging %s to pristine', $pkgname);
    $self->{svn}->copy(
        $self->get_pkgurl($pkgname),
        $options{revision} || $self->{default}{revision},
        $pristineurl
    );
    $self->{svn}->log_msg(undef);
 
    1;    
}

=head2 get_pkg_info($pkgname, %options)

Return a hash containing usefull information about $pkgname:

=over 4

=item pkgname

The name of the package

=item size

The size of the package (sum of files size)

=item last_rev

The revision of the last changed

=item last_author

The author of the last change

=item last_time

The time of last change (integer value, use loacaltime to have a human
readable value)

=back

=cut

sub get_pkg_info {
    my ($self, $pkgname, %options) = @_;
    my $url = $self->get_pkgurl($pkgname, %options);
    my $leafs;

    eval {
        $leafs = $self->{svn}->ls(
            $url, 
            $options{revision} || $self->{default}{revision},
            1,
        );
    };
    if ($@) {
        $self->{error} = "Can't get information from $url: $@";
        return;
    }
    my %info = (
        pkgname => $pkgname,
        last_rev => 0,
        size => 0,
    );
    foreach my $leaf (%{$leafs || {}}) {
        defined($leafs->{$leaf}) or next;
        $info{size} += $leafs->{$leaf}->size;
        if ($leafs->{$leaf}->created_rev > $info{last_rev}) {
            $info{last_rev} = $leafs->{$leaf}->created_rev();
            $info{last_time} = $leafs->{$leaf}->time();
            $info{last_author} = $leafs->{$leaf}->last_author();
        }
    }

    %info;
}

=head2 submit($pkgname, %options)

Submit the package on the build host.

=cut

sub submit {
    my ($self, $pkgname, %options) = @_;
    
    my $pkgurl_parent = $self->get_pkgurl_parent($pkgname, %options);
    if (!$self->_check_url_exists($pkgurl_parent, %options)) {
        $self->{error} = "$pkgname is not in svn";
        return;
    }

    my $host = $self->{config}->val('global', 'default_parent');
    $host = (split("/", $host))[2];

    my $createsrpm = $self->{config}->val('helper', 'create-srpm');
    
    # back to default
    $options{'target'} ||= $self->{config}->val('submit', 'default');
    
    # TODO we can also use xml-rpc, even if not implemented on the server side
    my @command = (
        'ssh',
        $host,
        $createsrpm,
        $pkgurl_parent,
        '-r', $options{'revision'}, 
        '-t', $options{'target'}
    );
    system(@command) == 0;
}

=head2 cleanup

This module creates a number of temporary directories; all are deleted when
the program terminates, but with this function you can force a removal of
these directories.

=cut

sub cleanup { $_[0]->{_temp_late_destroy} = []; 1; }

sub DESTROY { goto &cleanup }

1;

__END__

=head1 FUNCTION OPTIONS

=over 4

=item revision

Work on this revision from the svn

=item destdir

Extract files into this directories instead a temporary directory.

=back

=head1 AUTHORS

Olivier Thauvin <nanardon@mandriva.org>

=head1 SEE ALSO

L<Repsys>

=cut
