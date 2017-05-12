package Kolab::Templates;

########################################################################
##                                                                    ##
##  Copyright (c) 2003, 2004  Code Fusion cc                          ##
##   <http://www.codefusion.co.za/>                                   ##
##  Writen by Stuart Bingë  <s.binge@codefusion.co.za>                ##
##                                                                    ##
##  Portions based on work by the following people:                   ##
##    (c) 2003  Tassilo Erlewein  <tassilo.erlewein@erfrakon.de>      ##
##    (c) 2003  Martin Konold     <martin.konold@erfrakon.de>         ##
##    (c) 2003  Achim Frank       <achim.frank@erfrakon.de>           ##
##                                                                    ##
##  This  program is free  software; you can redistribute  it and/or  ##
##  modify it  under the terms of the GNU  General Public License as  ##
##  published by the  Free Software Foundation; either version 2, or  ##
##  (at your option) any later version.                               ##
##                                                                    ##
##  This program is  distributed in the hope that it will be useful,  ##
##  but WITHOUT  ANY WARRANTY; without even the  implied warranty of  ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU  ##
##  General Public License for more details.                          ##
##                                                                    ##
##  You can view the  GNU General Public License, online, at the GNU  ##
##  Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.   ##
##                                                                    ##
########################################################################

use 5.008;
use strict;
use warnings;
use IO::File;
use File::Copy;
use Kolab;
use Kolab::Util;
use Kolab::LDAP;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
        &buildTemplates
        &build
    ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = sprintf('%d.%02d', q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

# This modules' logging prefix
sub PREFIX()                { return "Templates.pm"; }

# What meta tags are currently available
sub META_DESTINATION()      { return "destination"; }
sub META_DIFF_CMD()         { return "diff_cmd"; }
sub META_ALWAYS_CHANGE()    { return "always_change"; }
sub META_ON_CHANGE()        { return "on_change"; }
sub META_DISABLED()         { return "disabled"; }

sub buildTemplates
{
    my $nochange = shift || 0;

    # First Phase: Enumerate all the template files.
    my $tmpldir = $Kolab::config{"kolab_templates"};
    my $backupdir = $Kolab::config{"kolab_backups"};
    Kolab::log(PREFIX, "Enumerating templates in $tmpldir", KOLAB_DEBUG);

    if (!opendir(TMPLDIR, $tmpldir)) {
        Kolab::log(PREFIX, "Unable to open template directory $tmpldir", KOLAB_ERROR);
        exit(1);
    }
    # Get all the normal files in the template directory
    my @filelist = grep { -f "$tmpldir/$_" } readdir(TMPLDIR);
    closedir(TMPLDIR);

    # Second Phase: Read the mvars from each template file.
    my %templates;
    my $file;
    my $fh;
    foreach $file (@filelist) {
        $file = "$tmpldir/$file";
        Kolab::log(PREFIX, "Reading $file mvars", KOLAB_DEBUG);
        if (!($fh = IO::File->new($file, "r"))) {
            Kolab::log(PREFIX, "Unable to open $file", KOLAB_WARN);
            next;
        }

        # TODO: Find out what the 'correct' way to assign this reference is
        %{ $templates{$file} } = readMeta($fh);

        if ($templates{$file}->{META_DISABLED()}) {
            Kolab::log(PREFIX, "Skipping template $file (mvar " . META_DISABLED . " is set)");
            delete $templates{$file};
            next;
        }

        $templates{$file}->{"__FILE_HANDLE"} = $fh;
    }

    # Third Phase: Calculate the dependancy tree.
    #  - Does nothing, for the moment. We'll need this later on when we
    #    start doing patching/appending/prepending, etc.

    # Fourth Phase: Step through the dependancy tree, reading and patching the templates as required.
    #   Also calculates if a change occured.
    my $new;
    my $old;
    my $tmp = $Kolab::config{"kolab_var"} . "/.conf_scratch";
    my @tmpbackups;
    my $tmpfile;
    my $diffcmd;
    my $haschanged;
    my $stdout;
    my %changehandlers;
    foreach $file (keys %templates) {
        Kolab::log(PREFIX, "Parsing template $file", KOLAB_DEBUG);

        $new = '';
        $old = '';
        $haschanged = 0;

        if (!$templates{$file}->{META_DESTINATION()}) {
            # If there isn't a destination, then there's no need to write
            Kolab::log(PREFIX, "Skipping write (mvar " . META_DESTINATION . " is not set)", KOLAB_DEBUG);
        } else {
            $templates{$file}->{META_DESTINATION()} = lerpVar($templates{$file}->{META_DESTINATION()})
                if $templates{$file}->{META_DESTINATION()};

            $new = $templates{$file}->{META_DESTINATION()};
            $old = $backupdir . trim(`basename $new`) if $backupdir ne "";
            if ($old eq "") {
                $old = $Kolab::config{"kolab_var"} . "/.tmp_" . trim(`basename $new`);
                push @tmpbackups, $old;
            }

            $Kolab::config{"NEW_CONFIG_FILE"} = $new;
            $Kolab::config{"OLD_CONFIG_FILE"} = $old;

            # Interpolate the mvars. We do it here instead of when we read the
            # mvars as we know 'new_config_file' and 'old_config_file' here.
            Kolab::log(PREFIX, "Lerping mvars", KOLAB_DEBUG);
            $templates{$file}->{META_DIFF_CMD()} = lerpVar($templates{$file}->{META_DIFF_CMD()})
                if $templates{$file}->{META_DIFF_CMD()};
            $templates{$file}->{META_ON_CHANGE()} = lerpVar($templates{$file}->{META_ON_CHANGE()})
                if $templates{$file}->{META_ON_CHANGE()};

            if (!($tmpfile = IO::File->new($tmp, 'w'))) {
                Kolab::log(PREFIX, "Unable to open temporary file $tmp", KOLAB_ERROR);
                exit 1;
            }

            # Substitate the cvars
            Kolab::log(PREFIX, "Writing out temp conf", KOLAB_DEBUG);
            $fh = ${$templates{$file}->{"__FILE_HANDLE"}};
            while (<$fh>) {
                while (/\@{3}(\S+)\@{3}/) {
                    if ($Kolab::config{$1}) {
                        s/\@{3}(\S+)\@{3}/$Kolab::config{$1}/;
                    } else {
                        Kolab::log(PREFIX, "Cvar $1 does not exist", KOLAB_WARN);
                        s/\@{3}(\S+)\@{3}//;
                    }
                }
                print $tmpfile $_;
            }

            undef $fh;
            undef $tmpfile;

            copy($new, $old);
            copy($tmp, $new);

            chown($Kolab::config{"kolab_uid"}, $Kolab::config{"kolab_gid"}, $new);
        }

        if ($nochange) {
            Kolab::log(PREFIX, "Skipping diff cmd (option 'nochange' specified)", KOLAB_DEBUG);
        } elsif ($templates{$file}->{META_ALWAYS_CHANGE()}) {
            # If always_change is set, then there's no need to perform the diff command
            Kolab::log(PREFIX, "Skipping change calc (mvar " . META_ALWAYS_CHANGE . " is set)", KOLAB_DEBUG);
            $haschanged = 1;
        } elsif (!$templates{$file}->{META_DIFF_CMD()}) {
            # If there isn't a command to calculate changes, then there's no need to go on
            Kolab::log(PREFIX, "Skipping change calc (mvar " . META_DIFF_CMD . " is not set)", KOLAB_DEBUG);
        } else {
            $diffcmd = $templates{$file}->{META_DIFF_CMD()};

            Kolab::log(PREFIX, "Executing diff cmd $diffcmd", KOLAB_DEBUG);
            $stdout = `$diffcmd`;
            $haschanged = $? >> 8;
            chomp($stdout);

            Kolab::log(PREFIX, "Diff cmd returned $haschanged w/ stdout $stdout", KOLAB_DEBUG);
        }

        if ($nochange) {
            Kolab::log(PREFIX, "Skipping change event (option 'nochange' specified)", KOLAB_DEBUG);
        } elsif (!$haschanged) {
            # No change occurred, so we don't need to execute the change event
            Kolab::log(PREFIX, "Skipping change event (no change detected)", KOLAB_DEBUG);
        } elsif (!$templates{$file}->{META_ON_CHANGE()}) {
            # If the change event hasn't been specified, then there's no need to go on
            Kolab::log(PREFIX, "Skipping change event (mvar " . META_ON_CHANGE . " is not set)", KOLAB_DEBUG);
        } else {
            Kolab::log(PREFIX, "Change detected", KOLAB_DEBUG);
            $changehandlers{$templates{$file}->{META_ON_CHANGE()}} = 1;
        }
    }

    # Fifth phase: Perform any on_change events
    my $changehandler;
    foreach $changehandler (keys %changehandlers) {
        Kolab::log(PREFIX, "Executing change cmd $changehandler", KOLAB_DEBUG);
        $stdout = `$changehandler`;
        $haschanged = $? >> 8;
        chomp($stdout);

        Kolab::log(PREFIX, "Change cmd returned $haschanged w/ stdout $stdout", KOLAB_DEBUG);
    }

    # Sixth phase: Cleanup
    unlink $tmp;
    unlink @tmpbackups;

    Kolab::log(PREFIX, "Finished building configs", KOLAB_DEBUG);
}

# sub buildCyrusGroups
# {
#     Kolab::log(PREFIX, 'Building Cyrus groups', KOLAB_DEBUG);
#
#     my $prefix = $Kolab::config{'kolab_root'};
#     my $cfg = "$prefix/etc/imapd/imapd.group";
#     my $oldcfg = $cfg . '.old';
#     copy($cfg, $oldcfg);
#     chown($Kolab::config{'kolab_uid'}, $Kolab::config{'kolab_gid'}, $oldcfg);
#     copy("$prefix/etc/kolab/imapd.group.template", $cfg);
#     my $groupconf;
#     if (!($groupconf = IO::File->new($cfg, 'a'))) {
#         Kolab::log(PREFIX, "Unable to open configuration file `$cfg'", KOLAB_ERROR);
#         exit(1);
#     }
#
#     my $ldap = Kolab::LDAP::create(
#         $Kolab::config{'ldap_ip'},
#         $Kolab::config{'ldap_port'},
#         $Kolab::config{'bind_dn'},
#         $Kolab::config{'bind_pw'}
#     );
#
#     my $mesg = $ldap->search(
#         base    => $Kolab::config{'base_dn'},
#         scope   => 'sub',
#         filter  => '(objectclass=groupofnames)'
#     );
#     if ($mesg->code) {
#         Kolab::log(PREFIX, 'Unable to locate Cyrus groups in LDAP', KOLAB_ERROR);
#         exit(1);
#     }
#
#     my $ldapobject;
#     my $count = 60000;
#     if ($mesg->code <= 0) {
#         foreach $ldapobject ($mesg->entries) {
#             my $group = $ldapobject->get_value('cn') . ":*:$count:";
#             my $userlist = $ldapobject->get_value('uid', asref => 1);
#             foreach (@$userlist) { $group .= "$_,"; }
#             $group =~ s/,$//;
#             print $groupconf $group . "\n";
#             Kolab::log(PREFIX, "Adding cyrus group `$group'");
#             $count++;
#         }
#     } else {
#         Kolab::log(PREFIX, 'No Cyrus groups found');
#     }
#
#     $groupconf->close;
#     Kolab::LDAP::destroy($ldap);
#
#     chown($Kolab::config{'kolab_uid'}, $Kolab::config{'kolab_gid'}, $cfg);
#
#     if (-f $oldcfg) {
#         my $rc = `diff -q $cfg $oldcfg`;
#         chomp($rc);
#         if ($rc) {
#            Kolab::log(PREFIX, "`$cfg' change detected: $rc", KOLAB_DEBUG);
#            $Kolab::haschanged{'imapd'} = 1;
#         }
#     } else {
#         $Kolab::haschanged{'imapd'} = 1;
#     }
#
#     Kolab::log(PREFIX, 'Finished building Cyrus groups');
# }

sub build
{
    my $nochange = shift || 0;

    buildTemplates($nochange);
#    buildCyrusGroups();
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kolab::Templates - Perl extension for Kolab template generation

=head1 ABSTRACT

  Kolab::Templates handles the generation of template files.

=head1 AUTHOR

Stuart Bingë, E<lt>s.binge@codefusion.co.zaE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003  Code Fusion cc

Portions based on work by the following people:

  (c) 2003  Tassilo Erlewein  <tassilo.erlewein@erfrakon.de>
  (c) 2003  Martin Konold     <martin.konold@erfrakon.de>
  (c) 2003  Achim Frank       <achim.frank@erfrakon.de>

This  program is free  software; you can redistribute  it and/or
modify it  under the terms of the GNU  General Public License as
published by the  Free Software Foundation; either version 2, or
(at your option) any later version.

This program is  distributed in the hope that it will be useful,
but WITHOUT  ANY WARRANTY; without even the  implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You can view the  GNU General Public License, online, at the GNU
Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.

=cut
