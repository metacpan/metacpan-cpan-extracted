# $Id: Repsys.pm 103942 2007-01-03 23:40:24Z nanardon $

package MDV::Repsys;

use strict;
use warnings;
use Carp;
use SVN::Client;
use RPM4;
use POSIX qw(getcwd);

our $VERSION = '1.00';

my $error = undef;
my $verbosity = 0;

=head1 NAME

MDV::Repsys

=head1 SYNOPSYS

Module to build rpm from a svn

=head1 FUNCTIONS

=cut

my %b_macros = (
    '_sourcedir' => 'SOURCES',
    '_patchdir' => 'SOURCES',
    '_specdir' => 'SPECS',
);

my %optional_macros = (
    '_builddir' => 'BUILD',
    '_rpmdir' => 'RPMS',
    '_srcrpmdir' => 'SRPMS',
);

=head2 set_verbosity($level)

Set the verbosity verbosity of the module:

  0 silent
  1 progress message
  2 debug message

=cut

sub set_verbosity {
    my ($level) = @_;
    $verbosity = $level || 0;
}

sub _print_msg {
    my ($level, $fmt, @args) = @_;
    croak('No message given to _print_msg') unless($fmt);
    return if ($level > $verbosity);
    printf("$fmt\n", @args);
}

=head2 set_rpm_dirs($dir)

Set internals rpm macros that are used by rpm building functions:

  _sourcedir to $dir/SOURCES
  _patchdir  to $dir/SOURCES
  _specdir   to $dir/SPECS

And, if their directories are not writable, these macros are set:  
  _rpmdir    to $dir/RPMS
  _srcrpmdir   to $dir/SRPMS
  _builddir  to $dir/BUILD
=cut

sub set_rpm_dirs {
    my ($dir, %relative_dir) = @_;
    if ($dir !~ m:^/:) {
        $dir = getcwd() . "/$dir";
    }
    foreach my $m (keys %b_macros, keys %relative_dir) {
        RPM4::add_macro(
            sprintf(
                '%s %s/%s', 
                $m, $dir, 
                (defined($relative_dir{$m}) ? $relative_dir{$m} : $b_macros{$m}) || '',
            ),
        );
    }
    foreach my $m (keys %optional_macros) {
        if (! -w RPM4::expand('%' . $m)) { 
            RPM4::add_macro(
                sprintf(
                    '%s %s/%s', 
                    $m, $dir, 
                    (defined($relative_dir{$m}) ? $relative_dir{$m} : $optional_macros{$m}) || '',
                ),
            );
        }
    }

}

=head2 create_rpm_dirs

Create directories used by rpm building functions:

  _sourcedir
  _patchdir
  _specdir

Return 1 on sucess, 0 on failure.

=cut

sub create_rpm_dirs {
    foreach my $m (keys %b_macros, keys %optional_macros) {
        my $dtc = RPM4::expand('%' . $m); # dir to create
        if (! -d $dtc) {
            _print_msg(2, 'Create directory %s', $dtc);
            if (!mkdir($dtc)) {
                $error = "can't create $dtc: $!";
                return 0;
            }
        }
    }
    1;
}

=head2 extract_srpm($rpmfile, $directory)

Extract (install) a source package into $directory.

=cut

sub extract_srpm {
    my ($rpmfile, $working_dir, %releative_dir) = @_;

    set_rpm_dirs($working_dir, %releative_dir);
    create_rpm_dirs() or return 0;
    _print_msg(2, 'Extracting %s', $rpmfile);
    RPM4::installsrpm($rpmfile);
}

sub _find_unsync_source {
    my (%options) = @_;
    
    my $svn = $options{svn} || SVN::Client->new();
    my $working_dir = $options{working_dir};

    my $spec = RPM4::specnew($options{specfile}, undef, '/', undef, 1, 0) or do {
        $error = "Can't read specfile";
        return;
    };

    my %sources;
    my $abs_spec = $spec->specfile;
    if ($abs_spec !~ m:^/:) {
        $abs_spec = getcwd() . "/$abs_spec";
    }
    $sources{$abs_spec} = 1;
    $sources{$_} = 1 foreach (map { RPM4::expand("\%_sourcedir/$_") } $spec->sources);
    eval {
        $sources{$_} = 1 foreach (map { RPM4::expand("\%_sourcedir/$_") } $spec->icon);
    };

    my @needadd;
    $svn->status(
        $working_dir,
        'HEAD',
        sub {
            my ($entry, $status) = @_;
            if ($status->text_status eq '2') {
                if (grep { $entry eq $_ } (RPM4::expand('%_specdir'), RPM4::expand('%_sourcedir'))) {
                    push(@needadd, $entry);
                }
            }
        },
        0,
        1,
        0,
        1,
    );

    foreach my $toadd (@needadd) {
        _print_msg(1, "Adding %s", $toadd);
        $svn->add($toadd, 0);
    }
    @needadd = ();
    my @needdel;

    foreach my $dir (RPM4::expand('%_specdir'), RPM4::expand('%_sourcedir')) {
            $svn->status(
            $dir,
            'HEAD',
            sub {
                my ($entry, $status) = @_;
                grep { $entry eq $_ } (
                    RPM4::expand('%_specdir'),
                    RPM4::expand('%_sourcedir')
                    ) and return;

                if ($status->text_status eq '2') {
                    if ($sources{$entry}) {
                        push(@needadd, $entry);
                    }
                }
                if (grep { $status->text_status eq $_ } ('3', '4', '5')) {
                    if(!$sources{$entry}) {
                        push(@needdel, $entry);
                    }
                }
            },
            1, # recursive
            1, # get_all
            0, # update
            1, # no_ignore
        );
    }
    
    return(\@needadd, \@needdel);
}

sub _sync_source {
    my (%options) = @_;

    my $svn = $options{svn} || SVN::Client->new();
    my ($needadd, $needdel) = ($options{needadd}, $options{needdel});
    
    foreach my $toadd (sort @{$needadd || []}) {
        _print_msg(1, "Adding %s", $toadd);
        $svn->add($toadd, 0);
    }
    foreach my $todel (sort @{$needdel || []}) {
        _print_msg(1, "Removing %s", $todel);
        $svn->delete($todel, 1);
    }

    1;
}

=head2 find_unsync_files($working_dir, $specfile)

Return two array ref of lists of files that should be added or removed
from the svn working copy to be sync with the specfile.

=cut

sub find_unsync_files {
    my ($working_dir, $specfile, %relative_dir) = @_;

    if ($working_dir !~ m:^/:) {
        $working_dir = getcwd() . "/$working_dir";
    }

    set_rpm_dirs($working_dir, %relative_dir);
    _print_msg(2, 'Looking sources from specfile %s', $specfile);
   
    my $svn = SVN::Client->new();

    _find_unsync_source(
        svn => $svn,
        specfile => $specfile,
        working_dir => $working_dir,
    );
}

=head2 sync_svn_copy($add, $remove)

Perform add or remove of files listed in both array ref.

=cut

sub sync_svn_copy {
    my ($needadd, $needdel) = @_;

    my $svn = SVN::Client->new();

    _sync_source(
        svn => $svn,
        needadd => $needadd,
        needdel => $needdel,
    );
}

=head2 sync_source($workingdir, $specfile)

Synchronize svn content by performing add/remove on file need to build
the package. $workingdir should a svn directory. No changes are applied
to the repository, you have to commit yourself after.

Return 1 on success, 0 on error.

=cut

sub sync_source {
    my ($working_dir, $specfile, %relative_dir) = @_;

    if ($working_dir !~ m:^/:) {
        $working_dir = getcwd() . "/$working_dir";
    }

    set_rpm_dirs($working_dir, %relative_dir);
    _print_msg(2, 'Looking sources from specfile %s', $specfile);
   
    my $svn = SVN::Client->new();

    my ($needadd, $needdel) = _find_unsync_source(
        svn => $svn,
        specfile => $specfile,
        working_dir => $working_dir,
    ) or return;

    _sync_source(
        svn => $svn,
        needadd => $needadd,
        needdel => $needdel,
    );
}



sub _strip_changelog {
    my ($specfile, $dh) = @_;

    my $changelog = '';
    my $newspec = $dh || new File::Temp(
        UNLINK => 1
    ) or do {
        $error = $!;
        return;
    };

    if (open(my $oldsfh, "<", $specfile)) {
        my $ischangelog = 0;
        my $emptyline = "";
        while(my $line = <$oldsfh>) {
            if ($line =~ /^\s*$/) {
                $emptyline .= $line;
                next;
            }
            if ($line =~ /^%changelog/i) {
                $ischangelog = 1;
                next;
            }
            if ($line =~ /^%(files|build|check|prep|post|pre|package|description)/i) {
                $ischangelog = 0;
            }
            if ($ischangelog) {
                $changelog .= $emptyline . $line;
                $emptyline = "";
            } else {
                print $newspec $emptyline . $line;
                $emptyline = "";
            }
        }
        close($oldsfh);
    } else {
        $error = "Can't open $specfile: $!";
        return;
    }

    return($changelog, $newspec);
}

=head2 strip_changelog($specfile)

Remove the %changelog section from the specfile.

=cut

sub strip_changelog {
    my ($specfile) = @_;
    
    _print_msg(1, 'removing changleog from %s', $specfile);
    my ($changelog, $newspec) = _strip_changelog($specfile);

    $changelog or return 1;

    seek($newspec, 0, 0);
    if (open(my $oldspec, ">", $specfile)) {
        while (<$newspec>) {
            print $oldspec $_;
        }
        close($oldspec);
    } else {
        $error = "can't open $specfile: $!";
        return;
    }

    1;
}

=head2 build($dir, $what, %options)

Build package locate in $dir. The type of packages to build is
set in the string $what: b for binaries, s for source.

If $options{specfile} is set, the build is done from this specfile
and not the one contains in SPECS/ directory.

=cut

sub build {
    my ($working_dir, $what, %options) = @_;

    set_rpm_dirs(
        $working_dir,
        $options{destdir} ?
            (
                _rpmdir => 'RPMS',
                _srcrpmdir => 'SRPMS',
            ) : ()
    );
    create_rpm_dirs() or return 0;

    my $specfile = $options{specfile} || (glob(RPM4::expand('%_specdir/*.spec')))[0];
    if (!$specfile) {
        $error = "Can't find specfile";
        return;
    }

    RPM4::del_macro("_signature"); # don't bother
    my $spec = RPM4::specnew(
        $specfile, undef, 
        $options{root} || '/',
        undef, 0, 0) or do {
        $error = "Can't read specfile $specfile";
        return;
    };

    if (! $options{nodeps}) {
        my $db = RPM4::newdb();
        my $sh = $spec->srcheader();
        $db->transadd($sh, "", 0);
        $db->transcheck;
        my $pbs = $db->transpbs();
     
        if ($pbs) {
            $pbs->init;
            $error = "\nFailed dependencies:\n";
            while($pbs->hasnext) {
                $error .= "\t" . $pbs->problem() . "\n";
            }
            return;
        }
    }

    my @bflags = ();
    my %results = ();
    
    if ($what =~ /b/) {
        push(@bflags, qw(PREP BUILD INSTALL CHECK FILECHECK PACKAGEBINARY CLEAN RMBUILD));
        if (!-d RPM4::expand('%_rpmdir')) {
            mkdir RPM4::expand('%_rpmdir') or do {
                $error = "Can't create " . RPM4::expand('%_rpmdir') . ": $!";
                return;
            };
        }
        foreach my $rpm ($spec->binrpm) {
            push(@{$results{bin}}, $rpm);
            my ($dirname) = $rpm =~ m:(.*)/:;
            if (! -d $dirname) {
                mkdir $dirname or do {
                    $error = "Can't create $dirname: $!";
                    return;
               }; 
            }
        }
    }
    if ($what =~ /s/) {
        push(@bflags, qw(PACKAGESOURCE));
        if (!-d RPM4::expand('%_srcrpmdir')) {
            mkdir RPM4::expand('%_srcrpmdir') or return;
        }
        foreach my $rpm ($spec->srcrpm) {
            push(@{$results{src}}, $rpm);
            my ($dirname) = $rpm =~ m:(.*)/:;
            if (! -d $dirname) {
                mkdir $dirname or do {
                    $error = "Can't create $dirname: $!";
                    return;
                };
            }
        }
    }

    RPM4::setverbosity('INFO') if ($verbosity);
    $spec->build([ @bflags ]) and return;
    RPM4::setverbosity('WARNING');

    return %results;
}

=head2 repsys_error

Return the last repsys error.

=cut


sub repsys_error {
    $error
}

# Exemple of use:
# my $msg = "rere" ; MDV::Repsys::_commit_editor(\$msg); print $msg;

sub _commit_editor {
    my ($msg) = @_;
    
    my $tmp = new File::Temp();
    $tmp->unlink_on_destroy(1);
    printf $tmp  <<EOF, ($$msg || "");
%s
SVN: Line begining by SVN are ignored
SVN: MDV::Repsys $VERSION
EOF
    close($tmp);
    my ($editor) = map { $ENV{$_} }  grep { $ENV{$_} } qw(SVN_EDITOR VISUAL EDITOR);
    $editor ||= 'vi';
    if (system($editor, $tmp->filename) == -1) {
        warn "Cannot start $editor\n";
        $$msg = undef;
        return 0;
    }
    if (open(my $rh, "<", $tmp->filename)) {
        my $rmsg = '';
        while (<$rh>) {
            m/^SVN:/ and next;
            $rmsg .= $_;
        }
        close ($rh);
        chomp($rmsg);
        $$msg = $rmsg;
    } else {
        $$msg = undef;
        return 0;
    }
    1;
}

1;

__END__

=head1 AUTHORS

Olivier Thauvin <nanardon@mandriva.org>

=head1 SEE ALSO

L<Repsys::Remote>

=cut
