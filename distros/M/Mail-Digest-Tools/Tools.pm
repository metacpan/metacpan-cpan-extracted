package Mail::Digest::Tools;
$VERSION = 2.12;        # 05/14/2011
use strict;
use warnings;
use Time::Local;
our @ISA = ("Exporter");
our @EXPORT_OK = qw(
    process_new_digests
    reprocess_ALL_digests
    reply_to_digest_message
    repair_message_order
    consolidate_threads_multiple
    consolidate_threads_single
    delete_deletables
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

########################## Package Variables ###################################

our %month30 = map {$_, 1} (4,6,9,11);
our %month31 = map {$_, 1} (1,3,5,7,8,10,12);
our %unix    = map {$_, 1} 
    qw| Unix linux darwin freebsd netbsd openbsd mirbsd cygwin solaris |;

############################### Initializer ###################################

sub _config_check {
    my ($config_in_ref, $config_out_ref) = @_;
    die "Cannot find ${$config_out_ref}{'dir_digest'}: $!" 
        unless (-d ${$config_out_ref}{'dir_digest'});
    die "Missing threads directory: $!" 
        unless (-d ${$config_out_ref}{'dir_threads'});
    die "Except for '\n' newline, backslashes are not permitted\n  in Thread Message Delimiter: $!"
        if (${$config_out_ref}{'thread_msg_delimiter'} =~ /\\[^n]|\\$/);
    # to do:  
    # here do error checking on other digest.data info that is 
    # absolutely necessary for all conceivable uses of Mail::Digest::Tools
}

############################ Public Methods ####################################

sub process_new_digests {
    my ($config_in_ref, $config_out_ref) = @_;
    _config_check($config_in_ref, $config_out_ref);
    my $choice = _start_new_only(${$config_out_ref}{'title'});
    _main_processor($config_in_ref, $config_out_ref, $choice);
}

sub reprocess_ALL_digests {
    my ($config_in_ref, $config_out_ref) = @_;
    _config_check($config_in_ref, $config_out_ref);
    my $choice = _start_ALL(${$config_out_ref}{'title'});
    _main_processor($config_in_ref, $config_out_ref, $choice);
}

sub reply_to_digest_message {
    my ($config_in_ref, $config_out_ref, 
        $dig_number, $dig_entry, $dir_for_reply) = @_;
    _config_check($config_in_ref, $config_out_ref);
    my $digests_ref = _get_digest_list(
        $config_in_ref, 
        $config_out_ref,
    );
    my $digest_verified = _identify_target_digest(
        $config_in_ref, 
        $config_out_ref,
        $dig_number, 
        $dig_entry, 
        $digests_ref
    );
    my $replyfile = _strip_down_for_reply(
        $config_in_ref, 
        $config_out_ref,
        $digest_verified,
        $dig_entry,
        $dir_for_reply,
    );
    return $replyfile;
}

sub repair_message_order {
    # But what about todays_topics.txt?  It will be out of order as well.
    my ($config_in_ref, $config_out_ref, $error_date_ref) = @_;
    _config_check($config_in_ref, $config_out_ref);
    local $_;
    my $date_threshold = _verify_date($error_date_ref);
    my $delimiter   = ${$config_out_ref}{'thread_msg_delimiter'};
    my $dir_threads = ${$config_out_ref}{'dir_threads'};
    my (@threadfiles, @resorted_threadfiles);
    chdir $dir_threads or die "Unable to change to $dir_threads: $!";
    opendir DIR, $dir_threads or die "Unable to open $dir_threads: $!";
    @threadfiles = grep {! m/^\./ } readdir DIR; 
    closedir DIR or die "Unable to close $dir_threads: $!";
    foreach my $in (@threadfiles) {
        my (@msgids);
        my (%messages);
        my $mtime = (stat($in))[9];
        if ($date_threshold < $mtime) {
            my $msgs_ref = _get_array_of_messages($in, $delimiter);
            foreach my $msg (@{$msgs_ref}) {
                my @lines = split(/\n/, $msg);
                my ($ln);
                while (defined($ln = shift(@lines))) {
                    if ($ln =~ /^Message:      ([\d_]+)$/) {
                        push(@msgids, $1);
                        $messages{$1} = $msg;
                        last;
                    }
                }
            }
            my ($need_resort_flag);
            for (my $el = 1; $el <= $#msgids; $el++) {
                if ($msgids[$el] lt $msgids[$el-1]) {
                    $need_resort_flag++;
                    last;
                }
            }
            if ($need_resort_flag) {
                my $out = "$in.bak";
                open OUT, ">$out" or die "Couldn't open $out for writing: $!";
                foreach my $msg (sort keys %messages) {
                    print OUT $messages{$msg}, $delimiter;
                }
                close OUT or die "Couldn't close $out after writing: $!";
                rename($out, $in) or die "Couldn't rename $out to $in: $!";
                push(@resorted_threadfiles, $in);
            }
        }
    }
    if (@resorted_threadfiles) {
        print "Message order has been re-sorted in\n";
        print "  $_\n" foreach @resorted_threadfiles;
    }
}

sub consolidate_threads_multiple {
    my ($config_in_ref, $config_out_ref);
    $config_in_ref  = shift;
    $config_out_ref = shift;
    my $first_common_letters = defined $_[0] ? $_[0] : 20;
    my $delimiter   = ${$config_out_ref}{'thread_msg_delimiter'};
    my $dir_threads = ${$config_out_ref}{'dir_threads'};
    local $_;
    my (@threadfiles, %threadstubs, %stubs_for_consol);
    chdir $dir_threads or die "Unable to change to $dir_threads: $!";
    opendir DIR, $dir_threads or die "Unable to open $dir_threads: $!";
    @threadfiles = map {/(.*)\.thr\.txt$/} readdir DIR;
    closedir DIR or die "Unable to close $dir_threads: $!";
    foreach (@threadfiles) {
        my $stub = substr($_, 0, $first_common_letters);
        push @{$threadstubs{$stub}}, "$_.thr.txt";
    }
    my ($k,$v, $consolcount);
    CONSOL: while ( ($k,$v) = each(%threadstubs)) {
        if (@{$v} > 1) {
            $consolcount++;
            print "Candidates for consolidation:\n";
            foreach my $thrfile (@{$v}) {
                print "  $thrfile\n";
            }
            while () {
                my ($selection);
                print "\nTo consolidate, type YES:  ";
                chomp ($selection = <>);
                if ($selection eq 'YES') {
                    print "\n  Files will be consolidated\n\n";
                    $stubs_for_consol{$k} = $v;
                } else {
                    print "\n  Files will not be consolidated\n\n";
                }
                next CONSOL;
            }
        }
    }
    unless ($consolcount) {
        warn "\nAnalysis of the first $first_common_letters letters of each file in\n  $dir_threads\n  shows no candidates for consolidation.  Please hard-code\n  names of files you wish to consolidate as arguments to\n  \&consolidate_threads_single:\n $!";
    }
    foreach my $k (keys %stubs_for_consol) {
        consolidate_threads_single(
            $config_in_ref, 
            $config_out_ref, 
            \@{$stubs_for_consol{$k}}
        );
    }
}

sub consolidate_threads_single {
    my ($config_in_ref, $config_out_ref, $filesref) = @_;
    my $delimiter   = ${$config_out_ref}{'thread_msg_delimiter'};
    my $dir_threads = ${$config_out_ref}{'dir_threads'};
    local $_;
    my (%messages, @superseded);
    foreach my $in (@{$filesref}) {
        unless ($in =~ /^$dir_threads/) {
            $in = "$dir_threads/$in";
        }
        my $msgs_ref = _get_array_of_messages($in, $delimiter);
        foreach my $msg (@{$msgs_ref}) {
            my @lines = split(/\n/, $msg);
            my ($ln);
            while (defined($ln = shift(@lines))) {
                if ($ln =~ /^Message:      ([\d_]+)$/) {
                    die "Message $1 already exists: $!"
                        if (exists $messages{$1});
                    $messages{$1} = [ $msg, $in ];
                    last;
                }
            }
        }
        push(@superseded, $in);
    }
    my @msgids = sort keys %messages;
    my $first_in_thread = "$messages{$msgids[0]}[1]";
    my $out =  $first_in_thread . '.bak';
    open OUT, ">$out" or die "Couldn't open $out for writing: $!";
    foreach (sort keys %messages) {
        print OUT $messages{$_}[0], $delimiter;
    }
    close OUT or die "Couldn't close $out after writing: $!";
    foreach (@superseded) {
        rename($_, $_ . '.DELETABLE') or die "Couldn't rename $_: $!";
    }
    rename($out, $first_in_thread) 
        || die "Couldn't rename $out to $first_in_thread: $!";
}

sub delete_deletables {
    my $config_out_ref = shift;
    my $dir_threads = ${$config_out_ref}{'dir_threads'};
    local $_;
    my (@deletables);
    chdir $dir_threads or die "Unable to change to $dir_threads: $!";
    opendir DIR, $dir_threads or die "Unable to open $dir_threads: $!";
    @deletables = grep { /\.DELETABLE$/ } readdir DIR;
    closedir DIR or die "Unable to close $dir_threads: $!";
    foreach (@deletables) {
        print "Deleting $_\n";
        unlink $_ or die "Couldn't unlink $_: $!";
    }
}

############################ Private Methods ###################################

sub _start_new_only {
    my $full_title = shift;
    print "\nProcessing new $full_title digest files only!\n\n";
    return '';
}

sub _start_ALL {
    # prints screen prompts which ask user to choose between
    # default version (process newly arrived digests only) and
    # full version (process or re-process all digests)
    my $full_title = shift @_;
    my ($choice);
    print "\n                            " . uc($full_title) . "\n";
    print <<XQ18;

     By default, this program processes only NEWLY ARRIVED
     $full_title files found in this directory.  Messages in
     these new digests are sorted and appended to the appropriate
     ".thr.txt" files in the "Threads" subdirectory.

     However, by choosing method 'reprocess_ALL_digests()' you have
     indicated that you wish to process ALL digest files found in this     
     directory -- regardless of whether or not they have previously been
     processed.  This is recommended ONLY for initialization and testing 
     of this program.
     
     Since this will wipe out all threads files ('.thr.txt') as well -- 
     including threads files for which you no longer have their source 
     digest files -- please confirm that this is your intent by typing 
     ALL at the prompt.


                               GOT IT?

XQ18
        
    print qq{Hit 'Enter' -- or, to process ALL digests in this directory,
type 'ALL' and hit 'Enter':  };
    chomp ($choice = <STDIN>);
    if ($choice eq 'ALL') {
        print qq{
     You have chosen to WIPE OUT all '.thr.txt' files currently
     existing in the 'Threads' subdirectory and reprocess all
     $full_title digest files from scratch.

     Please re-confirm your choice by once again typing 'ALL'
         and hitting 'Enter': };

        chomp (my $confirm = <STDIN>);
        if ($choice eq $confirm) {
            print "\n              Processing ALL digests in this directory!\n";
        } else {
            die "\n              Choice not confirmed; exiting program.  $!\n";
        }
    } else {
        print "\n                  Processing new digest files only!\n";
        $choice = '';
    }
    print "\n";
    return $choice;
}

sub _main_processor {
    my ($config_in_ref, $config_out_ref, $choice) = @_;

    my $recentref   = _archive_or_kill($config_out_ref);

    my $digests_ref = _get_digest_list($config_in_ref, $config_out_ref);
    
    my $in_out_ref  = _prep_source_file(
        $config_in_ref, $config_out_ref, $digests_ref);  #v1.94

    $in_out_ref     = _get_log_data($config_out_ref, $choice, $in_out_ref);

    my ($message_count, $thread_count);
    ($in_out_ref, $message_count, $thread_count) = _strip_down(
        $in_out_ref, 
        $config_in_ref,
        $config_out_ref,
        $recentref,
    );

    _update_all_topics($choice, $config_out_ref, $in_out_ref);

    _print_results(
        scalar(keys %$in_out_ref),
        $message_count,
        $config_out_ref,
        $thread_count,
    );
}

sub _archive_or_kill {
    my $config_out_ref = shift;
    my $dir_threads = ${$config_out_ref}{'dir_threads'};
    my $trigger = ${$config_out_ref}{'archive_kill_trigger'};
    my $threshold = defined ${$config_out_ref}{'archive_kill_days'}
                  ? ${$config_out_ref}{'archive_kill_days'}
                  : 14;  # v1.95
    my ($thr, %recent, %nonrecent, $recentref);
    chdir($dir_threads) || die "cannot chdir to $dir_threads $!";
    opendir THR, $dir_threads or die "cannot open $dir_threads: $!";
    while ($thr = readdir THR) {
        next unless ( ($thr =~ /\.thr\.txt$/) and (-f $thr) );
        if ($trigger == 0) {
            $recent{$thr}++;
        } else {
            -M $thr <= $threshold  # v1.95
                ? $recent{$thr}++
                : $nonrecent{$thr}++;
        }
    }
    closedir THR or die "Cannot close $dir_threads: $!";
    return \%recent if ($trigger == 0);
    if ($trigger == 1) {
        _archive_old_files($config_out_ref, \%nonrecent);
    } elsif ($trigger == -1) {
        _kill_old_files($config_out_ref, \%nonrecent);
    } else {
        die "$trigger is invalid value for archive_kill_trigger: $!";
    }
    return \%recent;
}

sub _archive_old_files {
    my ($config_out_ref, $nonrecentref) = @_;
    my $dir_threads     = ${$config_out_ref}{'dir_threads'};
    my $archfile        = defined ${$config_out_ref}{'archived_today'}
                        ? ${$config_out_ref}{'archived_today'}
                        : "${$config_out_ref}{'dir_digest'}/archived_today.txt";
    my $dir_archive_top = ${$config_out_ref}{'dir_archive_top'};
    die "Missing top archive directory: $!" unless (-d $dir_archive_top);
    foreach ('a'..'z') {
        die "Missing archive subdirectory $_: $!" unless (-d "$dir_archive_top/$_");
    }
    die "Missing archive subdirectory 'other': $!" unless (-d "$dir_archive_top/other");

    open ARCH, ">$archfile" or die "Couldn't open $archfile for writing: $!";
    print ARCH 'Archived today (', scalar(localtime), "):\n";
    print ARCH '-' x 41, "\n";

    my ($thr, $archstr);
    my $toarchive = 0;
    foreach $thr (sort keys %{$nonrecentref}) {
        my $initial = lc(substr $thr, 0, 1);
        print "Archiving: $thr\n";
        $archstr .= $thr . "\n";
        if ($initial =~ /[a-zA-Z]/) {
            rename($thr, "$dir_archive_top/$initial/$thr") or die "Couldn't move $thr: $!";
        } else {
            rename($thr, "$dir_archive_top/other/$thr") or die "Couldn't move $thr: $!";
        }
        $toarchive++;
        print "$toarchive files archived\n\n" if ($toarchive % 100 == 0);
    }
    print "$toarchive files archived\n\n";
    $toarchive ? print ARCH $archstr : print ARCH "[None.]\n";
    close ARCH or die "Couldn't close $archfile after writing: $!";
}

sub _kill_old_files {
    my ($config_out_ref, $nonrecentref) = @_;
    my $dir_threads = ${$config_out_ref}{'dir_threads'};
    my $killfile = defined ${$config_out_ref}{'deleted_today'}
                 ? ${$config_out_ref}{'deleted_today'}
                 : "${$config_out_ref}{'dir_digest'}/deleted_today.txt"; # v1.95
    open KILL, ">$killfile" or die "Couldn't open $killfile for writing: $!";
    print KILL 'Deleted today (', scalar(localtime), "):\n";
    print KILL '-' x 40, "\n";

    my ($thr, $killstr);
    my $tokill = 0;
    foreach $thr (sort keys %{$nonrecentref}) {
        print "Unlinking: $thr\n";
        $killstr .= $thr . "\n";
        unlink $thr or die "Couldn't unlink $thr: $!";
        $tokill++;
        print "$tokill files deleted\n" if ($tokill % 100 == 0);
    }
    print "$tokill files deleted\n";
    $tokill ? print KILL $killstr : print KILL "[None.]\n";
    close KILL or die "Couldn't close $killfile after writing: $!";
}

sub _get_digest_list {
    my ($config_in_ref, $config_out_ref) = @_;
    opendir(DIR, ${$config_out_ref}{'dir_digest'}) || die "no ${$config_out_ref}{'dir_digest'}?: $!";
    my @digests = 
        sort { lc($a) cmp lc($b) } 
        grep { /${$config_in_ref}{'grep_formula'}/ } 
        readdir(DIR);
    closedir(DIR) || die "Could not close ${$config_out_ref}{'dir_digest'}: $!";
    return \@digests;
}

sub _prep_source_file {
    my ($config_in_ref, $config_out_ref, $digests_ref) = @_;  # v1.94
    # %in_out: hash of all instances in directory of a given digest, 
    # value refers to digest's title and its message topics
    my (%in_out, $id);
    foreach (@{$digests_ref}) {
        $_ =~ m/${$config_in_ref}{'pattern_target'}/;
        $id = eval(${$config_out_ref}{'id_format'});  # v1.94
        $in_out{$id} = [ $_ ];
    }
    return \%in_out;
}

sub _identify_target_digest {
    my ($config_in_ref, $config_out_ref, 
            $dig_number, $dig_entry, $digests_ref) = @_;
    my ($hit);
    foreach my $digfile (@{$digests_ref}) {
        $digfile =~ m/${$config_in_ref}{'pattern_target'}/;
        if (defined $2) {
            next unless ($2 == $dig_number);
            $hit = $digfile;
            last;
        } elsif ((defined $1) and (! defined $2)) {
            next unless ($1 == $dig_number);
            $hit = $digfile;
            last;
        } else {
            die "Could'nt process digest filename to identify target digest: $!";
        }
    }
    if (defined $hit) {
        return $hit;
    } else {
        print STDERR "No ${$config_out_ref}{'title'} digest numbered $dig_number could be found in directory\n";
        print STDERR "  ${$config_out_ref}{'dir_digest'}\n";
        exit 0;
    }
}

sub _get_log_data {
    my ($config_out_ref, $choice, $in_out_ref) = @_;
    my $dir_digest  = ${$config_out_ref}{'dir_digest'};
    my $dir_threads = ${$config_out_ref}{'dir_threads'};
    my $logfile     = ${$config_out_ref}{'digests_log'};
    my $readfile    = defined ${$config_out_ref}{'digests_read'}  # new in 1.95
                    ? ${$config_out_ref}{'digests_read'}
                    : "$dir_digest/digests_read.txt";

    # hash which pulls in data from an external log file that 
    # records which digests have been previously processed
    my (%hashlog);
    open(LOG, $logfile) || die "cannot open $logfile for reading: $!";
    while (<LOG>) {
        chomp;
        my @entrydata = split(/;/);
        $hashlog{$entrydata[0]} = [ @entrydata[1..$#entrydata] ];
    }
    close(LOG) || die "cannot close $logfile: $!";

    foreach ( sort keys %$in_out_ref ) {
        # if this is 1st time this digest has been seen for processing ...
        if (! exists $hashlog{$_}) {
            $hashlog{$_}[1] = $hashlog{$_}[0] = scalar localtime;

        # if this digest has been seen for processing already ...
        } else {

            # either we're going to re-process every digest ...
            if ($choice eq 'ALL') {
                chdir($dir_threads) || die "cannot chdir to $dir_threads $!";
                my ($thrfile);
                opendir(THREADS, $dir_threads) || die "no $dir_threads?: $!";
                while ($thrfile = readdir(THREADS) ) {
                    next unless $thrfile =~ /\.thr\.txt$/;
                    unlink $thrfile || warn "having trouble deleting $thrfile: $!";
                }
                closedir(THREADS) or die "Couldn't close $dir_threads: $!";
                chdir($dir_digest) || die "cannot chdir to $dir_digest $!";
                $hashlog{$_}[1] = scalar localtime;

            # or we're only going to process new digest files
            } else {
                delete ${$in_out_ref}{$_};
            }
        }
    }
    _update_digests_log(\%hashlog, $logfile);
    _update_digests_read(
        ${$config_out_ref}{'title'}, 
        \%hashlog, 
        $readfile,  # new in v1.95
    ) if ${$config_out_ref}{'digests_read_flag'}; 
    return ($in_out_ref);
}

sub _update_digests_log {    # must be supplied with ref to %hashlog
    my ($hashlog_ref, $logfile) = @_;
    my ($logstring);
    foreach ( sort keys %$hashlog_ref ) {
#        $logstring .= $_ . ';' . ${%$hashlog_ref}{$_}[0] . ';' . 
#            ${%$hashlog_ref}{$_}[1]. "\n";
        $logstring .= $_ . ';' . ${$hashlog_ref}{$_}[0] . ';' . 
            ${$hashlog_ref}{$_}[1]. "\n";
    }
    open(LOG, ">$logfile") || die "cannot open $logfile for writing: $!";
    print LOG $logstring;
    close(LOG) || die "cannot close $logfile: $!";
}

sub _update_digests_read {    # must be supplied with $title and ref to %hashlog
    my ($title, $hashlog_ref, $readfile) = @_;
    my $readstring = '';
    $readstring .= "$title Digest\n";
    foreach ( sort keys %$hashlog_ref ) {
       $readstring .= "\n$_:\n";
#       $readstring .= "    first processed at          ${%$hashlog_ref}{$_}[0]\n"; 
#       $readstring .= "    most recently processed at  ${%$hashlog_ref}{$_}[1]\n";
       $readstring .= "    first processed at          ${$hashlog_ref}{$_}[0]\n"; 
       $readstring .= "    most recently processed at  ${$hashlog_ref}{$_}[1]\n";
    }
    open(READ, ">$readfile") || die "cannot open $readfile for writing: $!";
    print READ $readstring;
    close(READ) || die "can't close $readfile:$!";
}

sub _strip_down {
    my ($in_out_ref, $config_in_ref, $config_out_ref, $recentref) = @_;
    my $MIME_cleanup_flag      = ${$config_in_ref}{'MIME_cleanup_flag'};
    my $topics_intro           = ${$config_in_ref}{'topics_intro'};
    my $post_topics_delimiter  = ${$config_in_ref}{'post_topics_delimiter'};
    my $source_msg_delimiter   = ${$config_in_ref}{'source_msg_delimiter'};
    my $subject_constant       = ${$config_in_ref}{'subject_constant'}
        if (defined ${$config_in_ref}{'subject_constant'});
    my $archive_kill_trigger   = ${$config_out_ref}{'archive_kill_trigger'};
    my $dir_digest             = ${$config_out_ref}{'dir_digest'};
    my $dir_threads            = ${$config_out_ref}{'dir_threads'};
    my $thread_msg_delimiter   = ${$config_out_ref}{'thread_msg_delimiter'};
    my $optional_fields_ref    = ${$config_out_ref}{'optional_fields'}
        if (defined ${$config_out_ref}{'optional_fields'});
    my $MIME_cleanup_log_flag  = ${$config_out_ref}{'MIME_cleanup_log_flag'}
        if (defined ${$config_out_ref}{'MIME_cleanup_log_flag'});

    my (%recent, $mimelog, %optional_fields);
    %recent = defined $recentref ? %$recentref : ();
    if (defined $optional_fields_ref) {
        my $i = 0;
        foreach my $opt (@{$optional_fields_ref}) {
            my $longkey = $opt . '_style_flag';
            if (defined ${$config_in_ref}{$longkey}) {
                next unless (${$config_in_ref}{$longkey} =~ /\^(.*?):/);
                $optional_fields{$i} = [ $opt, $1 ];
                $i++;
            } else {
                warn "WARNING:\n  '$opt' is not available as a header field for digest ${$config_out_ref}{'title'}\n";
            }
        }
    }

    # Analysis of source message delimiter:
    my $delimiter_core = 
        substr( $source_msg_delimiter, 0, index($source_msg_delimiter, "\n") );

    my $message_count = 0;
    my %seen = ();
    my $seen_ref = \%seen;
    my ($output_ref);
    if ($MIME_cleanup_flag) {
        $mimelog = defined ${$config_out_ref}{'mimelog'} # v1.96
                   ? ${$config_out_ref}{'mimelog'}
                   : "${$config_out_ref}{'dir_digest'}/mimelog.txt";
        if ($MIME_cleanup_log_flag) {
            open MIME, ">$mimelog" or die "Couldn't open $mimelog for writing: $!";
            print MIME <<MIMELOG;
Processed                     Problem

MIMELOG
        }
    }
    chdir($dir_digest) || die "cannot chdir to $dir_digest $!";
    foreach my $digest_no ( sort keys %$in_out_ref ) {
        my (@newfile, %messages_sorted_by_thread);
        my $file = ${$in_out_ref}{$digest_no}[0];
        my ($bigstr, $digest_head, $digest_bal, @digest_header, @digest_balance); 
        open(IN, $file) || die "cannot open $file for reading: $!";
        {
            local $/ = undef;
            $bigstr = <IN>;
        }
        close (IN) || die "can't close $file:$!";
        
        if ($bigstr =~ /(.*?)$post_topics_delimiter(.*)/s) {
            $digest_head = $1;
            $digest_bal = $2;
        } else {
            die "Couldn't extract: $!";
        }

        @digest_header = split(/\n/, $digest_head);
        
        @digest_balance = split(/$source_msg_delimiter/, $digest_bal);
        pop @digest_balance;
        $message_count += scalar(@digest_balance);
        
        # extract topics listing
        $in_out_ref = _prepare_todays_topics(
            \@digest_header, 
            $topics_intro, 
            $delimiter_core, 
            $in_out_ref, 
            $digest_no,
        );
        
        # process each message in a digest file
        foreach my $el (@digest_balance) {
            # analyze message's header
            my $header_ref = _analyze_message_header(
                $el, $config_in_ref, $config_out_ref
            ); 
            # clean up message's title to eliminate characters 
            # forbidden as filenames on this system
            my $thread = _clean_up_thread_title(
                ${$header_ref}{'subject'}, $subject_constant);
            my $full_id = $digest_no . '_' . ${$header_ref}{'message_no'};
            my $thread_full_id = lc($thread . $full_id);
            
            # clean up message's text to eliminate MIME multiparts
            my $text = _analyze_message_body(
                $el, $MIME_cleanup_flag, $full_id, $MIME_cleanup_log_flag);
            

            # add info to hash from which output will be generated
            $messages_sorted_by_thread{$thread_full_id} = [
                $thread,
                $full_id,
                $header_ref,
                $text,
            ];
        }
        # prepare output for this digest file
        foreach ( sort keys %messages_sorted_by_thread ) {
            ($seen_ref, $output_ref) = _prepare_output_string(
                \%messages_sorted_by_thread, 
                $seen_ref, 
                $dir_threads, 
                $thread_msg_delimiter,
                $output_ref,
                \%optional_fields, # new in v1.67
            );                
        }
    }
    if ($MIME_cleanup_log_flag) {
        close MIME, ">$mimelog" or die "Couldn't close $mimelog after writing: $!";
    }
    
    # If I am not archiving a particular digest, then I would never be calling a
    # thread file for that digest back from the archive.
    # Hence, I can simply append.
    if ($archive_kill_trigger == 0 or $archive_kill_trigger = -1) {
        foreach (keys %{$output_ref}) {
           open(NOARCH, ">>$_") || die "cannot open $_ for appending: $!";
           print NOARCH ${$output_ref}{$_};
           close(NOARCH) || die "can't close $_: $!";
        }
    } elsif ($archive_kill_trigger == 1) {
        my $fromarchive = 0;
        my $dearchfile  = defined ${$config_out_ref}{'de_archived_today'}
                        ? ${$config_out_ref}{'de_archived_today'}
                        : "${$config_out_ref}{'dir_digest'}/de_archived_today.txt";
        my $dir_archive_top = ${$config_out_ref}{'dir_archive_top'};
        my ($dearchstr);
        open DEARCH, ">$dearchfile" 
            or die "Couldn't open $dearchfile for writing: $!";
        print DEARCH 'De-archived today (', scalar(localtime), "):\n";
        print DEARCH '-' x 44, "\n";

        # 1st:  See if recent thread exists; if so, open for appending
        # 2nd:  See if archive thread exists; 
        # if so, move from archive to current and open for appending
        # [of course, if a thread has not been active for 14 days, 
        # we may wish to treat a message
        # with the same name as a temporarily new thread and only append it 
        # when archiving once it's stale ]
        # 3rd:  If no recent/archive thread can be found, open new file for writing

        foreach (keys %{$output_ref}) {
           my ($stub);
           if ($_ =~ m|[/\\]([^/\\]*)$|) {
               $stub = $1;            
           } else {
               die "Couldn't extract stub from $_:  $!";
           }
           if ($recent{$stub}) {
               open(OUT2, ">>$_") || die "cannot open $_ for appending: $!";
           } else {
               my ($initial, $newstub);
               $initial = lc(substr $stub, 0, 1);
               $newstub = "$dir_threads/$stub";
               if ( ($initial =~ /[a-zA-Z]/) and 
                 (-f "$dir_archive_top/$initial/$stub") ) {
                   rename("$dir_archive_top/$initial/$stub", $newstub ) or 
                       die "Couldn't de-archive $stub: $!";
                   print "De-archiving:  $stub\n";
                   $dearchstr .= $stub . "\n";
                   $fromarchive++;
                   open(OUT2, ">>$newstub") || 
                       die "cannot open $newstub for appending: $!";
               } elsif (-f "$dir_archive_top/other/$stub") {
                   rename("$dir_archive_top/other/$stub", $newstub ) or 
                       die "Couldn't de-archive $stub: $!";
                   print "De-archiving:  $stub\n";
                   $dearchstr .= $stub . "\n";
                   $fromarchive++;
                   open(OUT2, ">>$newstub") || 
                       die "cannot open $newstub for appending: $!";
               } else {
                   open(OUT2, ">$_") || die "cannot open $_ for writing: $!";
               }
           }
           print OUT2 ${$output_ref}{$_};
           close(OUT2) || die "can't close $_: $!";
        }
        print "$fromarchive files de-archived\n";
        $fromarchive ? print DEARCH $dearchstr : print DEARCH "[None.]\n";
        close DEARCH or die "Couldn't close $dearchfile after writing: $!";
    } else {
        die "Bad value for archive/kill trigger: $!";
    }
    return ($in_out_ref, $message_count, scalar(keys %{$seen_ref}));
}

sub _strip_down_for_reply {
    my ($config_in_ref, $config_out_ref, 
        $digest_verified, $dig_entry, $dir_for_reply) = @_;
    my $MIME_cleanup_flag      = ${$config_in_ref}{'MIME_cleanup_flag'};
    my $post_topics_delimiter  = ${$config_in_ref}{'post_topics_delimiter'};
    my $source_msg_delimiter   = ${$config_in_ref}{'source_msg_delimiter'};
    my $subject_constant       = ${$config_in_ref}{'subject_constant'}
        if (defined ${$config_in_ref}{'subject_constant'});
    my $dir_digest             = ${$config_out_ref}{'dir_digest'};

    chdir($dir_digest) || die "cannot chdir to $dir_digest $!";

    # slurp the digest file in, splitting on message delimiters
    # so that each message is an array element
    my ($bigstr, $digest_head, $digest_bal, @digest_header, @digest_balance); 
    open(IN, $digest_verified) || 
        die "cannot open $digest_verified for reading: $!";
    {
        local $/ = undef;
        $bigstr = <IN>;
    }
    close (IN) || die "can't close $digest_verified:$!";
    
    if ($bigstr =~ /(.*?)$post_topics_delimiter(.*)/s) {
        $digest_head = $1;
        $digest_bal = $2;
    } else {
        die "Couldn't extract: $!";
    }

    @digest_balance = split(/$source_msg_delimiter/, $digest_bal);
    pop @digest_balance;

    my ($el, $replyfile);
    while (defined ($el = shift @digest_balance)) { 
        # analyze message's header
        my $header_ref = 
            _analyze_message_header($el, $config_in_ref, $config_out_ref);  # v1.94
        next unless (${$header_ref}{'message_no'} == $dig_entry);

        # clean up message's title to eliminate characters 
        # forbidden as filenames on this system
        my $thread = _clean_up_thread_title(
            ${$header_ref}{'subject'}, $subject_constant);
        $replyfile = "$dir_for_reply/${thread}.reply.txt";

        # clean up message's text to eliminate MIME multiparts
        my $text = _analyze_message_body($el, $MIME_cleanup_flag, undef, 0);
        my @lines = split(/\n/, $text);
        my ($replytext);
        foreach my $l (@lines) {
            chomp($l);
            $replytext .= '> ' . $l . "\n";
        }

        # print reply
        my $old_fh = select(REPLY);
        open REPLY, ">$replyfile" or die "Couldn't open $replyfile: $!";
        if (defined ${$header_ref}{'reply_to'}) {
            print "Reply-To:\n";
            print "${$header_ref}{'reply_to'}\n\n";
        } elsif (defined ${$header_ref}{'to'}) {
            print "To:\n";
            print "${$header_ref}{'to'}\n\n";
        }
        if (defined ${$header_ref}{'subject'}) {
            my ($subject_clean);
            if (${$header_ref}{'subject'} =~ 
                /^(?:(Re2?|RE2?|re2?|FWD?|Fwd?|AW):?\s+)*(.*)$/) {
                $subject_clean = $2;
            } else {
                $subject_clean = ${$header_ref}{'subject'};
            }
            print "Subject:\n";
            print "$subject_clean\n\n";
        }
        print "On ${$header_ref}{'date'}, ${$header_ref}{'from'} wrote:\n\n";
        print $replytext;
        print "\n";
        close REPLY or die "Couldn't close $replyfile: $!";
        select $old_fh;
        last;
    }
    return $replyfile;
}

sub _prepare_todays_topics {
    my ($digest_header_ref, $topics_intro, 
        $delimiter_core, $in_out_ref, $digest_no) = @_;
    my $counter = 0;
    my @todays_topics = (); # empty out @todays_topics
    foreach ( @{$digest_header_ref} ) {
        if (m/^$topics_intro/) {    # digest-specific
            $counter = 1;    
        }
        if ($counter == 1) {
            if (m/^$topics_intro|^$/) { next; }    # digest-specific
            elsif ($_ !~ m/$delimiter_core/)
                { push (@todays_topics, $_); }
            else { last; }
        }
#        ${%$in_out_ref}{$digest_no}[1] = [ @todays_topics ];
#        # Note:  this is 1st point at which ${%$in_out_ref}{$digest_no}[1] 
        ${$in_out_ref}{$digest_no}[1] = [ @todays_topics ];
        # Note:  this is 1st point at which ${$in_out_ref}{$digest_no}[1] 
        # gets meaningful content
    }
    return $in_out_ref;
}

sub _analyze_message_header {
    my ($el, $config_in_ref, $config_out_ref) = @_;  # v1.94
    my @all = split(/\n/, $el);
    my ($hl, @lines);
    while (defined ($hl = shift(@all)) ) {
        last if $hl =~ /^\s*$/;
        push(@lines, $hl);
    }
    my (%header, %init, $last_analyzed);
    foreach my $key (keys %{$config_in_ref}) {
        next unless ($key =~ /_style_flag$/);
        my ($shortkey);
        if ($key =~ /(.*)_style_flag$/) {
            $shortkey = $1;
        } else {
            warn "Problem in analyzing message header: $!";
        }
        $init{$shortkey}++ unless defined ${$config_in_ref}{$key};
    }
    foreach (@lines) {
        chomp;
        my ($matched);
        unless ($init{'message'}) {
            if (/${$config_in_ref}{'message_style_flag'}/) {
                $header{'message_no'} = 
                    eval(${$config_out_ref}{'output_id_format'});
                $init{'message'}++;
                $last_analyzed = 'message';
                $matched++;
            }
        }
        unless ($init{'from'}) {
            if (/${$config_in_ref}{'from_style_flag'}/) {
                $header{'from'} = $1;
                $init{'from'}++;
                $last_analyzed = 'from';
                $matched++;
            }
        }
        unless ($init{'subject'}) {
            if (/${$config_in_ref}{'subject_style_flag'}/) {
                $header{'subject'} = $1;
                $init{'subject'}++;
                $last_analyzed = 'subject';
                $matched++;
            }
        }
        unless ($init{'to'}) {
            if (/${$config_in_ref}{'to_style_flag'}/) {
                $header{'to'} = $1;
                $init{'to'}++;
                $last_analyzed = 'to';
                $matched++;
            }
        }
        unless ($init{'reply_to'}) {
            if (/${$config_in_ref}{'reply_to_style_flag'}/) {
                $header{'reply_to'} = $1;
                $init{'reply_to'}++;
                $last_analyzed = 'reply_to';
                $matched++;
            }
        }
        unless ($init{'cc'}) {
            if (/${$config_in_ref}{'cc_style_flag'}/i) {
                $header{'cc'} = $1;
                $init{'cc'}++;
                $last_analyzed = 'cc';
                $matched++;
            }
        }
        unless ($init{'date'}) {
            if (/${$config_in_ref}{'date_style_flag'}/) {
                $header{'date'} = $1;
                $init{'date'}++;
                $last_analyzed = 'date';
                $matched++;
            }
        }
        unless ($init{'org'}) {
            if (/${$config_in_ref}{'org_style_flag'}/) {
                $header{'org'} = $1;
                $init{'org'}++;
                $last_analyzed = 'org';
                $matched++;
            }
        }
        unless ($matched) {
            if ($last_analyzed ne 'subject') {
                $_ =~ s/^\s+//;
                $header{$last_analyzed} .= "\n" . ' ' x 14 . $_;
            }
        }
    }
    return \%header;
}

sub _clean_up_thread_title {
    my $subj = shift;
    my $subject_constant = shift if defined $_[0];
    my ($thread, @thread);
    $subj = "No subject" unless $subj; #messages on some lists can be subject-less

    $subj =~ 
      /^(?:(Re\d?|RE\d?|re\d?|Re\[\d?\]|RE\[\d?\]|re\[\d?\]|FWD?|Fwd?|AW):?\s+)*(.*)$/;
    $thread = $2;
    if (defined $subject_constant and $thread =~ /^$subject_constant\s+(.*)/) {
        $thread = $1;
    }
    @thread = split(//, $thread);
    if ($^O eq 'MSWin32') {
        $thread = join("", (grep m/[^*|\\:"<>?\/]/, @thread) ); #"
    }
    if ($unix{$^O}) {  # v2.08
        $thread = join("", (grep m/[^\/]/, @thread) );
    } 
    # squish repeated periods anywhere in file name
    $thread =~ tr/././s;
    # Win32 allows periods in file names, 
    # but I don't want any periods or spaces immediately before '.thr.txt'
    # or at the beginning of the file name
    $thread =~ s/[.\s]+$//;
    $thread =~ s/^[.\s]+//;
    # squish repeated whitespace anywhere in file name (EPP, Item 20, p. 76)
    $thread =~ tr/ \n\r\t\f/ /s;
    $thread = '[Illegal subject]' unless $thread;
    return $thread;
}

sub _analyze_message_body {
    my ($el, $MIME_cleanup_flag, $postid, $MIME_cleanup_log_flag) = @_;
    my @chunks = split(/\n{2,}/, $el);
    return join("\n\n", @chunks[1 .. ($#chunks)] ) 
        unless $MIME_cleanup_flag;
    my (@nextparts);
    if ($chunks[1] =~ /Content-Type:\smultipart\/alternative/o) {    
        # New in v1.84 1/23/04
        for (my $i=1; $i<=$#chunks; $i++) {
            push(@nextparts, $i) if ($chunks[$i] =~ /Content-Type:/);
        }
        if (@nextparts == 4) {
            print MIME "$postid CASE I\n" if $MIME_cleanup_log_flag;
            splice @chunks, $nextparts[2], $nextparts[3] - $nextparts[2] + 1;
            splice @chunks, 1, 2;
            return join("\n\n", @chunks[1 .. ($#chunks-1)] );
        } else {
            print MIME ' ' x 30, 
              "$postid; count:  ", sprintf("%3d", scalar(@nextparts)), " CASE I\n"
                if $MIME_cleanup_log_flag;
            return join("\n\n", @chunks );
        }
    } elsif ($chunks[1] =~ /--Apple-Mail-/o) {    # New in v1.85 1/23/04
        for (my $i=1; $i<=$#chunks; $i++) {
            push(@nextparts, $i) if ($chunks[$i] =~ /--Apple-Mail-/o);
        }
        if (@nextparts == 3 or @nextparts == 4) {
            print MIME "$postid CASE J\n" if $MIME_cleanup_log_flag;
            my ($fragment);
            if (@nextparts == 4) {
                splice @chunks, $nextparts[-1], 1;
            }
            if ($chunks[$nextparts[1]] =~ /(.*?)--Apple-Mail-/os) {
                $fragment = $1;
            }
            splice @chunks, $nextparts[1];
            push @chunks, $fragment if ($fragment);
            splice @chunks, $nextparts[0], 1;
            return join("\n\n", @chunks[1 .. $#chunks] );
        } else {
            print MIME ' ' x 30, "$postid; count:  ", 
              sprintf("%3d", scalar(@nextparts)), " CASE J\n"
                if $MIME_cleanup_log_flag;
            return join("\n\n", @chunks );
        }
    } elsif ($chunks[1] !~ /^This.+?message.+?MIME format/o) { 
        return join("\n\n", @chunks[1 .. ($#chunks)] ); 
    } else {
        if ($chunks[1] =~ /--=_alternative/) {
            for (my $i=1; $i<=$#chunks; $i++) {
                push(@nextparts, $i) if ($chunks[$i] =~ /--=_alternative/);
            }
            if (@nextparts == 3) {
                print MIME "$postid CASE A\n" if $MIME_cleanup_log_flag;
                splice @chunks, 
                    $nextparts[1] + 1, $nextparts[2] - $nextparts[1] + 1;
                $nextparts[1] =~ /^(.*\n)--=_alternative/s;
                my $fragment = $1;
                $chunks[$nextparts[1]] = $fragment;
                splice @chunks, 1, 2;
                return join("\n\n", @chunks[1 .. ($#chunks-1)] );
            } else {
                print MIME ' ' x 30, "$postid; count:  ", 
                  sprintf("%3d", scalar(@nextparts)), " CASE B\n"
                    if $MIME_cleanup_log_flag;
                return join("\n\n", @chunks );
            }
        } elsif ($chunks[1] =~ /cryptographically\ssigned/) { 
            print MIME "$postid CASE H\n" if $MIME_cleanup_log_flag;
            splice @chunks, -3, 2;
            splice @chunks, 1, 2;
            return join("\n\n", @chunks[1 .. ($#chunks-1)] );
        } else {
            for (my $i=2; $i<=$#chunks; $i++) {
                push(@nextparts, $i) if (
                    $chunks[$i] =~ /-{4,6}[_\s]?=_NextPart|
                                    --Boundary_|
                                    --------------InterScan_NT_MIME_Boundary/x
                 );
            }
            if (@nextparts == 3) {
                print MIME "$postid CASE C\n" if $MIME_cleanup_log_flag;
                splice @chunks, $nextparts[1], $nextparts[2] - $nextparts[1] + 1;
                splice @chunks, 1, 2;
                return join("\n\n", @chunks[1 .. ($#chunks-1)] );
            } elsif (@nextparts == 1) {
                print MIME "$postid CASE D\n" if $MIME_cleanup_log_flag;
                splice @chunks, 1, 1;
                return join("\n\n", @chunks[1 .. ($#chunks-1)] );
            } elsif (@nextparts == 5 or @nextparts == 6) {
                print MIME "$postid CASE E\n" if $MIME_cleanup_log_flag;
                splice @chunks, $nextparts[2], $nextparts[-1] - $nextparts[2] + 1;
                splice @chunks, 1, 3;
                return join("\n\n", @chunks[1 .. ($#chunks-1)] );
            } elsif (@nextparts == 7 or @nextparts == 8) {
                print MIME "$postid CASE F\n" if $MIME_cleanup_log_flag;
                splice @chunks, $nextparts[3], $nextparts[-1] - $nextparts[3] + 1;
                splice @chunks, 1, 3;
                return join("\n\n", @chunks[1 .. ($#chunks-1)] );
            } else {
                print MIME ' ' x 30, "$postid; count:  ", 
                  sprintf("%3d", scalar(@nextparts)), " CASE G\n"
                    if $MIME_cleanup_log_flag;
                return join("\n\n", @chunks[1 .. ($#chunks-1)] );
            }
        }
    }
}

sub _prepare_output_string {
    my ($threads_hash_ref, $seen_ref, $dir_threads, $thread_msg_delimiter, 
        $output_ref, $optional_fields_ref) = @_;
    my %messages = %{$threads_hash_ref};
    my %seen = %{$seen_ref};
    my (%output, %opt_fields);
    %output = %{$output_ref} if defined $output_ref;
    %opt_fields = %{$optional_fields_ref};
    my ($pathsep, $out, $lc_out, $outstr);
    $pathsep = ($^O eq 'MSWin32') ? "\\" : '/'; 
    $out = $dir_threads . $pathsep . $messages{$_}[0] . '.thr.txt';
    $lc_out = lc($out);
    $seen{$lc_out}++;
    $outstr  = "Thread:       $messages{$_}[0]\n";
    $outstr .= "Message:      $messages{$_}[1]\n";
    $outstr .= "From:         $messages{$_}[2]{'from'}\n";
    foreach my $i (sort keys %opt_fields) {
        next unless (defined $messages{$_}[2]{$opt_fields{$i}[0]});
        my $space = 13 - length($opt_fields{$i}[1]);
        $outstr .= $opt_fields{$i}[1] . ':' . ' ' x $space . 
            "$messages{$_}[2]{$opt_fields{$i}[0]}\n";
    }
    $outstr .= 'Text:'    . "\n\n" . $messages{$_}[3] . "\n";
    $outstr .= "\n";
    $outstr .= "$thread_msg_delimiter" 
        unless (! defined $thread_msg_delimiter);
    $output{$out} .= $outstr;
    return \%seen, \%output;
}

sub _update_all_topics {
    my ($choice, $config_out_ref, $in_out_ref) = @_;
    my $title      = ${$config_out_ref}{'title'};
    my $topicsfile = defined ${$config_out_ref}{'todays_topics'} # v1.96
                     ? ${$config_out_ref}{'todays_topics'}
                     : "${$config_out_ref}{'dir_digest'}/todays_topics.txt";
    my ($topic, $topicstring);
    if ($choice eq 'ALL') {
        $topicstring = "$title Digest:  Today's Topics\n";
        foreach ( sort keys %$in_out_ref ) {
           $topicstring .= "\n${$in_out_ref}{$_}[0]\n";
           foreach $topic ( @{${$in_out_ref}{$_}[1]} ) {
               $topicstring .= "$topic\n";
           }
        }
        open(TOPICS, ">$topicsfile") 
            || die "cannot open $topicsfile for writing: $!";
        print TOPICS $topicstring;
        close(TOPICS) || die "can't close $topicsfile:$!";
    } else {
        $topicstring = '';
        foreach ( sort keys %$in_out_ref ) {
           $topicstring .= "\n${$in_out_ref}{$_}[0]\n";
           foreach $topic ( @{${$in_out_ref}{$_}[1]} ) {
               $topicstring .= "$topic\n";
           }
        }
        open(TOPICS, ">>$topicsfile") 
            || die "cannot open $topicsfile for appending: $!";
        print TOPICS $topicstring;
        close(TOPICS) || die "can't close $topicsfile:$!";
    }
}

sub _print_results {
    my ($total_digests_processed, $message_count, 
        $config_out_ref, $thread_count) = @_;
print <<XQ19;


                               RESULTS

  Digests processed:\t\t$total_digests_processed
  Messages processed:\t\t$message_count
  Threads directory:\t\t${$config_out_ref}{'dir_threads'}
  Threads created/modified:\t$thread_count
XQ19
}

sub _verify_date {
    my $dateref = shift;
    die "Incorrect date specification: $!"
        unless (
            (exists ${$dateref}{'year'})  &&
            (exists ${$dateref}{'month'}) &&
            (exists ${$dateref}{'day'})
        );
    die "${$dateref}{'year'} is incorrect year specification: $!"
        unless (1900 <= ${$dateref}{'year'});
    die "${$dateref}{'month'} is incorrect month specification: $!"
        unless (
            (1 <= ${$dateref}{'month'})   &&
            (${$dateref}{'month'} <= 12)
        );
    die "${$dateref}{'day'} is incorrect day of month specification: $!"
        unless (
            ( 
                ${$dateref}{'day'} >=  1  and
                ${$dateref}{'day'} <= 28
            )
            ||
            (
                $month31{${$dateref}{'month'}} and 
                ${$dateref}{'day'} >= 29       and
                ${$dateref}{'day'} <= 31
            )
            ||
            (
                $month30{${$dateref}{'month'}} and 
                ${$dateref}{'day'} >= 29       and
                ${$dateref}{'day'} <= 30
            )
            ||
            (
                ${$dateref}{'month'} ==  2  and
                ${$dateref}{'day'}   == 29  and
                  (
                      ${$dateref}{'year'} % 400 == 0   or
                      (
                          ${$dateref}{'year'} % 100 != 0   and
                          ${$dateref}{'year'} %   4 == 0
                      )
                  )
            )
    );
    return timelocal(
        0, 0, 0, 
        ${$dateref}{'day'}, 
        ${$dateref}{'month'} - 1, 
        ${$dateref}{'year'}
    );
}

sub _get_array_of_messages {
    my ($in, $delimiter) = @_;
    my ($fh, $bigstr);
    open $fh, $in or die "Couldn't open $in for reading: $!";
    {
        local $/ = undef;
        $bigstr = <$fh>;
    }
    close $fh or die "Couldn't close $in after reading: $!";
    my @messages = split(/$delimiter/, $bigstr);
    return \@messages;
}

1;

############################ DOCUMENTATION #####################################

=head1 NAME

Mail::Digest::Tools - Tools for digest versions of mailing lists

=head1 VERSION

This document refers to version 2.12 of digest.pl, released May 14, 2011.

=head1 SYNOPSIS

    use Mail::Digest::Tools qw( 
        process_new_digests
        reprocess_ALL_digests
        reply_to_digest_message
        repair_message_order
        consolidate_threads_multiple
        consolidate_threads_single
        delete_deletables
    );

C<%config_in> and C<%config_out> are two configuration hashes whose setup 
is discussed in detail below.

    process_new_digests(\%config_in, \%config_out);

    reprocess_ALL_digests(\%config_in, \%config_out);

    $full_reply_file = reply_to_digest_message(
        \%config_in, 
        \%config_out, 
        $digest_number, 
        $digest_entry, 
        $directory_for_reply,
    );

    repair_message_order(
        \%config_in, 
        \%config_out,
        {
            year   => 2004,
            month  => 01,
            day    => 27,
        }
    );

    consolidate_threads_multiple(
        \%config_in,
        \%config_out,
        $first_common_letters,  # optional integer argument; defaults to 20
    );

    consolidate_threads_single(
        \%config_in, 
        \%config_out, 
        [
            'first_dummy_file_for_consolidation.thr.txt',
            'second_dummy_file_for_consolidation.thr.txt',
        ],
    );

    delete_deletables(\%config_out);

=head1 DESCRIPTION

Mail::Digest::Tools provides useful tools for processing mail which an 
individual receives in a 'daily digest' version from a mailing list.  
Digest versions of mailing lists are provided by a variety of mail processing 
programs and by a variety of list hosts.  Within the Perl community, digest 
versions of mailing lists are offered by such sponsors as Active State, 
Sourceforge, Yahoo! Groups and London.pm.  However, you do not have to be 
interested in Perl to make use of Mail::Digest::Tools.  Mail from I<any> of 
the thousands of Yahoo! Groups, for example, may be processed with this module.

If, when you receive e-mail from the digest version of a mailing list, you 
simply read the digest in an e-mail client and then discard it, you may stop 
reading here.  If, however, you wish to read or store such mail by subject, 
read on.  As printed in a normal web browser, this document contains 40 
pages of documentation.  You are urged to print this documentation out and 
study it before using this module.

To understand how to use Mail::Digest::Tools, we will first take a look at a 
typical mailing list digest.  We will then sketch how that digest looks once 
processed by Mail::Digest::Tool.  We will then discuss Mail::Digest::Tool's 
exportable functions.  Next, we will study how to prepare the two configuration 
hashes which hold the configuration data.  Finally, we will provide some tips 
for everyday use of Mail::Digest::Tools.

=head1 A TYPICAL MAILING LIST DIGEST

Here is a dummied-up version of a typical mailing list digest as it appears 
once saved to a plain-text file.  For illustrative purposes, let us suppose 
that the file is named:  'Perl-Win32-Users Digest, Vol 1 Issue 9999.txt'

    Send Perl-Win32-Users mailing list submissions to
    perl-win32-users@listserv.ActiveState.com

    When replying, please edit your Subject line so it is more specific
    than "Re: Contents of Perl-Win32-Users digest..."

    Today's Topics:

      1. Introducing Mail::Digest::Tools (James E Keenan)
      2. A Different Discussion (steve)
      3. Re:  Introducing Mail::Digest::Tools (David H Adler)

    ----------------------------------------------------------------------

    Message: 1
    From: "James E Keenan" <jkeen@some.web.address.com>
    To: <Perl-Win32-Users@listserv.activestate.com>
    Subject: Introducing Mail::Digest::Tools
    Date: Sat, 31 Jan 2004 14:10:20 -0600

    Mail::Digest::Tools is the greatest thing since sliced bread.
    Go download it now!

    ------------------------------

    Message: 2
    From: "steve" <steve@some.web.address.com>
    To: <Perl-Win32-Users@listserv.activestate.com>
    Subject: A Different Discussion
    Date: Sat, 31 Jan 2004 14:40:20 -0600

    This is a new topic.  I am not discussing Mail::Digest::Tools in this 
    submission.

    ------------------------------

    Message: 3
    From: "David H Adler" <dha@some.web.address.com>
    To: <Perl-Win32-Users@listserv.activestate.com>
    Subject: Re: Introducing Mail::Digest::Tools
    Date: Sat, 31 Jan 2004 14:50:20 -0600

    Jim, what's this nonsense about sliced bread.  Weren't you on the Atkins 
    diet?  Unlike beer, sliced bread is Off Topic.

    ------------------------------

    _______________________________________________
    Perl-Win32-Users mailing list
    Perl-Win32-Users@listserv.ActiveState.com
    To unsubscribe: http://listserv.ActiveState.com/mailman/mysubs

    End of Perl-Win32-Users Digest

Note that the digest has an I<overall> structure, while each message I<within> 
the digest has its own structure.

The digest's overall structure consists of:

=over 4

=item *

I<Digest Header>

The digest header consists of one or more paragraphs providing instructions 
on how to subscribe, post messages, unsubscribe and contact the list 
administrator.

In processing a digest, Mail::Digest::Tools generally discards the digest 
header.

=item *

I<Today's Topics>

Next, each daily digest contains a list of the subjects of the messages found 
in that particular digest.  This list is introduced by a paragraph such as:

    Today's Topics

and is followed by a numbered list of the message subjects and authors.  Some 
digests break the authors into two lines for names and e-mail addresses. 
Others, such as the example above, list only names.

When Mail::Digest::Tools process a digest, it extracts the list of topics as a 
single chunk and appends it to a file containing the topics from all previous 
digests which the user has similarly processed.

=item *

I<Post-Topics Delimiter>

The list of topics is separated from the first message by a string of 
characters which the list sponsor has, we hope, determined is not likely to 
occur in the text of any message posted to that list.  In the example above, 
the source message delimiter is the string:

    ----------------------------------------------------------------------

followed by two C<\n> newlines (so that the delimiter is a paragraph unto 
itself).  Other digests may use a two-line delimiter such as:

    _______________________________________________________
    _______________________________________________________

or

    --__--__--

=item *

I<Source Message Delimiter>

Most mailing list digests use the same string to delimit individual messages 
within the digest that they use to delimit the list of today's topics from the 
very first message in the digest.  (The author tracked one digest for more 
than three-and-a-half years that used the same string for both functions -- 
only to see that digest's provider change its format while this module was 
being prepared for CPAN!)  But the digest may use a different string to 
separate individual messages from each other.  In the sample digest above, 
the source message delimiter is the string:

    ------------------------------

followed by two C<\n> newlines (so that the delimiter is a paragraph unto 
itself).

As we shall see below, correctly identifying the post-topics delimiter and 
source message delimiter used in a particular digest is essential to correct 
configuration of Mail::Digest::Tools, as the module will repeatedly C<split> 
digests on this delimiter.

=item *

I<Individual Messages>

Individual messages have their own structure.

=over 4

=item *

I<Headers>

In addition to normal mail headers, a message in a digest must have a 
message number representing its position within that day's digest.  So a 
message in a digest will typically have some or all of the following headers:

    Message:
    From:
    Organization:
    Reply-To:
    To:
    CC:
    Date:
    Subject:

=item *

I<Message Body>

One of more paragraphs of text, frequently including citations from earlier 
postings to the mailing list.

The main objective of Mail::Digest::Tools is to extract headers and bodies 
from particular digest entries and to append them to plain-text files which 
hold all postings on a particular subject.  See discussion of 
C<process_new_digests> below.

Many mailing lists allow subscribers to post in either plain-text or HTML.  
Some allow users to post attachments; others do not.  Others still 
incorporate the attachments into the message body, often using 'multipart 
MIME' format.  Regrettably, certain mailing list digest programs fail to 
eliminate redundant MIME parts before posting a message to a digest.  This 
leads to severe bloat once Mail::Digest::Tools extracts a message's content 
and posts it to a thread file.  Mail::Digest::Tools, however, provides its 
users with the option of stripping redundant MIME parts from a message 
before posting.

=item *

I<Source Message Delimiter>

As discussed above, each message within a digest is delimited by a string 
which may or may not be the same string which separates the list of Today's 
Topics from the first message in the digest.

=back

=item *

I<Digest Footer>

The digest footer consists of one or more paragraphs containing 
additional information on the digest and signaling the end of the digest.  It 
follows the source message delimiter corresponding to the last message in a 
particular digest.

In processing a given digest, Mail::Digest::Tools generally discards the 
digest footer.

=back

=head2 The Typical Digest After Processing with Mail::Digest::Tools

Using the dummy messages provided above, typical use of Mail::Digest::Tools 
would produce (in a bare-bones configuration) the following results:

=over 4

=item *

Two plain-text 'thread' files holding the ongoing discussion of each topic:

=over 4

=item *

F<Introducing Mail::Digest::Tools.thr.txt>

    Thread:       Introducing Mail::Digest::Tools
    Message:      001_9999_001
    From:         "James E Keenan" <jkeen@some.web.address.com>
    Text:

    Mail::Digest::Tools is the greatest thing since sliced bread.
    Go download it now!

    --__--__--

    Thread:       Introducing Mail::Digest::Tools
    Message:      001_9999_003
    From: "David H Adler" <dha@some.web.address.com>
    Text:

    Jim, what's this nonsense about sliced bread.  Weren't you on the Atkins 
    diet?  Unlike beer, sliced bread is Off Topic.

    --__--__--

=item *

F<A Different Discussion.thr.txt>

    Thread:       A Different Discussion
    Message:      001_9999_002
    From: "steve" <steve@some.web.address.com>
    Text:

    This is a new topic.  I am not discussing Mail::Digest::Tools in this 
    submission.

    --__--__--

=back

=item *

A new entry at the end of file F<todays_topics.txt>:

    Today's Topics

    ...

    Perl-Win32-Users digest, Vol 1 #9999 - 3 msgs.txt
      1. Introducing Mail::Digest::Tools (James E Keenan)
      2. A Different Discussion (steve)
      3. Re:  Introducing Mail::Digest::Tools (David H Adler)

=item *

A new entry at the end of file F<digests_log.txt>:

    001_9999;Fri Feb  6 18:57:41 2004;Fri Feb  6 18:57:41 2004

=back

=head1 FUNCTIONS

Mail::Digest::Tools exports no functions by default.  Each of its current 
seven functions is imported only on request by your script.  

In everyday use, you will probably call just I<one> of Mail::Digest::Tool's 
exportable functions in a particular Perl script.  Typically, you will import 
the function as described in the SYNOPSIS above, populate two configuration 
hashes, and finally call the one function you have imported.  

As will become evident, the most challenging part of using Mail::Digest::Tools 
is I<not> calling the functions.  Rather, it is the initial setup and testing 
of configuration files from which the two configuration hashes passed as 
arguments to the various Mail::Digest::Tools functions are drawn.

More on those configuration hashes later.  For now, let's look at the 
exportable functions.

=head2 C<process_new_digests>

    process_new_digests(\%config_in, \%config_out);

C<process_new_digests()> is the Mail::Digest::Tools function which you will 
use most frequently on a daily basis.  Based on information supplied in the 
two configuration hashes passed to it as arguments, C<process_new_digests()> 
does the following:

=over 4

=item *

Validates the configuration data.

=item *

Conducts an analysis of the directory in which thread files for a given 
digest are stored to determine are old enough:

=over 4

=item *

I<either> to be moved to a subdirectory for archiving -- if you have told the 
configuration file that you wish to archive older threads in a subdirectory

=item *

I<or> to be deleted -- if you have told the configuration file that you do 
I<not> wish to archive older threads

=back

=item *

Conducts an analysis of the directory in which digest files (I<i.e.,> the 
plain-text versions of mailing list digests you have received) are stored to 
determine which digest files are new and need processing and which have 
previously been processed.

=item *

Updates a log file to put a timestamp on the processing of the new digest 
file or files.  Based on options set in the configuration file, this function 
may also update a more human-readable version of this log file.

=item *

Opens each of the digest files identified as needing processing and proceeds 
to 'strip down' those files.  This 'stripping down' includes the following:

=over 4

=item *

The digest file's name is analyzed to extract the digest's number as issued by 
the provider's mailing list program.  This number is used to form part of the 
unique identifier which Mail::Digest::Tools assigns to each message within 
each digest.

=item *

The list of today's topics in the digest is extracted and appended to a 
permanent log file of such topics.

=item *

The digest's contents are split into individual messages.  Each message, in 
turn, is split into headers and body.

=item *

If you have requested in the configuration file that superfluous multipart 
MIME content be purged from messages before posting to thread files, this 
purging is now conducted.

=item *

Each message is appended to an appropriate, plain-text thread file which 
holds the ongoing discussion of that topic.  The following factors are taken 
into consideration:

=over 4

=item *

The name of the thread file is derived from the message's subject, though 
characters in the message's subject which would not be valid in file names 
on your operating system are skipped over.

=item *

To the greatest extent possible, extraneous words in a message's subject 
such as 'Re:' or 'Fwd:' are deleted so that all relevant postings on a given 
subject can be included in a single thread file.  (Should this not succeed 
and a new thread file beginning with 'Re:' or some similar term be created, 
you can fix this later by using Mail::Digest::Tool's 
C<consolidate_threads_single()> function discussed below.)

=back

=item *

A brief summation of results is printed to standard output.

=back

=back

=head2 C<reprocess_ALL_digests>

    reprocess_ALL_digests(\%config_in, \%config_out);

C<reprocess_ALL_digests()> is the Mail::Digest::Tools function which you 
should use ONLY when you are setting up and fine-tuning Mail::Digest::Tools 
to process a given digest -- and you should NEVER use it thereafter!

Why?  Read on!

C<reprocess_ALL_digests()> does almost exactly the same things as does 
C<process_new_digests()>, but it does them on ALL digest files found in the 
directory in which you store such digests -- not just on those previously 
processed.  But in the process it does not merely append new messages to 
already existing thread files, leaving older thread files untouched.  Instead, 
C<reprocess_ALL_digests()> WIPES OUT your entire directory of thread files and 
rebuilds it from scratch.

That's cool if you have retained all instances of a given digest which you 
wish to process into thread files.  But if you've thrown out older instances 
of a given digest and call C<reprocess_ALL_digests()>, you will not be able 
to process the messages contained in those discarded digests.  The message 
sources are gone.  That's cool once you're certain that you've got a given 
digest configured just the way you want it -- but not until that moment.

=over 4

=item * Example

Let's make this more concrete.  Suppose that you have begun to subscribe to 
the digest version of the London Perlmongers mailing list.  When you receive 
e-mails from this provider, you store them in a directory whose contents look 
like this:

    london.pm digest, Vol 1 #1856 - 7 msgs.txt
    london.pm digest, Vol 1 #1857 - 18 msgs.txt
    london.pm digest, Vol 1 #1858 - 15 msgs.txt
    london.pm digest, Vol 1 #1859 - 17 msgs.txt
    london.pm digest, Vol 1 #1860 - 11 msgs.txt

Initially, you decide that you want to post the messages in these digests 
to thread files that are discarded after three days.  You set up your 
configuration files to do precisely this.  (See below for how this is done.)  
You then write a script which calls

    reprocess_ALL_digests(\%config_in, \%config_out);

Three days go by. One or two new london.pm digests arrive each day.  You 
want to process only the newly arrived files, so each day you simply call:

    process_new_digests(\%config_in, \%config_out);

and on Day 4 Mail::Digest::Tools starts to notify you on standard output 
that it is discarding thread files which have not been changed (I<i.e.,> 
received new postings) in three days.

But then you decide that London.pm's contributors are the most witty and 
erudite Perlmongers anywhere and you wish to archive their contributions 
until the end of time (or until the first production release of 
Perl 6, whichever comes first).  Fortunately, you've still got all your 
London.pm digest files going back to the beginning of your subscription.  
You make appropriate changes to your configuration setup to say, ''Instead 
of killing these thread files after 3 days of inactivity, archive them after 
3 days instead.''  (Again, we'll see how to do this below.)  You then call:

    reprocess_ALL_digests(\%config_in, \%config_out);

one last time.  All your previously existing thread files are wiped out, and 
all your London.pm digests are reprocessed from scratch.  But that's okay, 
because you've decided to live with your configuration decisions.  So you 
can now begin to discard older digest files and process newly arrived files 
only with

    process_new_digests(\%config_in, \%config_out);

Your London.pm thread archive grows exponentially, and you live happily ever 
after.

=back

The ALL CAPS in C<reprocess_ALL_digests()> is a little warning that this 
Mail::Digest::Tools function is very powerful, but potentially very dangerous.
You are also alerted to this danger by this screen prompt which appears when 
you call this function:

     By default, this program processes only NEWLY ARRIVED
     [London.pm/other digest] files found in this directory.  Messages in
     these new digests are sorted and appended to the appropriate
     '.thr.txt' files in the 'Threads' subdirectory.

     However, by choosing method 'reprocess_ALL_digests()' you have
     indicated that you wish to process ALL digest files found in this     
     directory -- regardless of whether or not they have previously been
     processed.  This is recommended ONLY for initialization and testing 
     of this program.

     Since this will wipe out all threads files ('.thr.txt') as well -- 
     including threads files for which you no longer have their source 
     digest files -- please confirm that this is your intent by typing 
     ALL at the prompt.


                               GOT IT?

To proceed, you must type C<ALL> in ALL CAPS, hit C<[Enter]>, then respond to 
yet another prompt:

     You have chosen to WIPE OUT all '.thr.txt' files currently
     existing in the 'Threads' subdirectory and reprocess all
     [London.pm/other digest] digest files from scratch.

     Please re-confirm your choice by once again typing 'ALL'
         and hitting [Enter]:

You must again type C<ALL> in ALL CAPS and hit C<[Enter]> to reprocess all 
digests.  Should you fail to type C<ALL> at both of these prompts, your 
script will default to C<process_new_digests()> and only process newly 
arrived digest files.

=head2 C<reply_to_digest_message>

    $full_reply_file = reply_to_digest_message(
        \%config_in, 
        \%config_out, 
        $digest_number, 
        $digest_entry, 
        $directory_for_reply,
    );

Once you have begun to follow discussion threads on a mailing list with the 
aid of Mail::Digest::Tools, you may wish to join the discussion and reply to 
a message.

If you tried to do this by hitting the 'Reply' button in your e-mail client, 
you would probably end up with a 'Subject' line in your e-mail that looked 
this:

    Re: london.pm digest, Vol 1 #1814 - 2 msgs

Needless to say, this is tacky.  So tacky that many mailing list digest 
programs insert this message into each digest's headers:

    When replying, please edit your Subject line so it is more specific
    than "Re: Contents of london.pm digest, Vol 1, #xxxx..."

You don't want to be tacky; you want to be lazy.  You want Perl to do the 
work of initiating an e-mail with a meaningful subject header for you. 
Mail::Digest::Tool's C<reply_to_digest_message> does just this.  It creates 
a plain-text file for you that has a meaningful subject line and prepends 
each line of the body of the message with C<\> >.  You then open this 
plain-text file, edit it to reply to its contents, copy-and-paste it into 
your e-mail client, and send it.

The arguments passed to C<reply_to_digest_message()> are:

=over 4

=item *

a reference to the 'in' configuration hash

=item *

a reference to the 'out' configuration hash

=item *

the number of the digest containing the message to which you are replying

=item *

the number of the message to which you are replying within that digest

=item *

a path to the directory in which you want the plain-text reply file to be 
created

=back

=over 4

=item * Example

Suppose that you wished to reply to message #2 in London.pm digest #1814:

    Message: 2
    From:     James E Keenan <jkeen@some.web.address.com>
    To:       London Perlmongers <london.pm@london.pm.org>
    Date: Fri, 2 Jan 2004 23:41:01 -0500
    Subject: re: language courses
    Reply-To: london.pm@london.pm.org

    On Fri, 2 Jan 2004 22:38:40 +0000 (GMT), Ali Young wrote concerning:
        language courses

    > Depends what you count as useful. Learning Esperanto means that you 
    > can read the current London.pm website.

    BTW, wasn't the Esperanto on the website supposed to expire on 31 Dec?

    Jim Keenan
    Brooklyn, NY

You would call the function as follows:

    $full_reply_file = reply_to_digest_message(
        \%config_in, 
        \%config_out, 
        1814,
        2,
        '/home/jimk/mail/digest/london',
    );

Mail::Digest::Tools will then create a plain-text file which you can use as 
the first draft of your reply.  It will print this screen prompt:

    To complete reply, edit text in:
      /home/jimk/mail/digest/london/language_courses.reply.txt

When you open F<language_courses.reply.txt> in your text editor, it will look 
like this:

    Reply-To:
    london.pm@london.pm.org

    Subject:
    language courses

    On Fri, 2 Jan 2004 23:41:01 -0500, James E Keenan 
    <jkeen@some.web.address.com> wrote:

    > On Fri, 2 Jan 2004 22:38:40 +0000 (GMT), Ali Young wrote concerning:
    >     language courses
    > 
    > > Depends what you count as useful. Learning Esperanto means that you 
    > can 
    > > read the current London.pm website.
    > 
    > BTW, wasn't the Esperanto on the website supposed to expire on 31 Dec?
    > 
    > Jim Keenan
    > Brooklyn, NY
    > 

The 'Reply-To' and 'Subject' paragraphs are provided simply to give you 
something to cut-and-paste into a GUI e-mail client.  The 'Reply-To' 
paragraph will only appear if in C<%config_in> the key 
C<reply_to_style_flag> is defined for a particular digest.

You edit this plain-text file, pop it into the body of your e-mail 
window and send it.  Not elegant, but it at least gives you a first draft.

=back

=head2 C<repair_message_order>

    repair_message_order(
        \%config_in, 
        \%config_out,
        {
            year   => 2004,
            month  => 01,
            day    => 27,
        }
    );

From time to time you may receive digest versions of mailing lists out of 
chronological/numerical sequence.  This is especially true when e-mail 
traffic is being disrupted by worms or viruses.  You may discover that you 
have received and processed

    london.pm digest, Vol 1 #1856 - 7 msgs
    london.pm digest, Vol 1 #1858 - 15 msgs

before realizing that you were missing

    london.pm digest, Vol 1 #1857 - 18 msgs

If you were to now process digest 1857 with C<process_new_digests()>, messages 
from that digest would be appended to their respective thread files I<after> 
messages from digest 1858.  Since the whole point of Mail::Digest::Tools is to 
be able to read a discussion thread in chronological order, this would not be 
desirable.

Fortunately, you can fix this problem as follows:

=over 4

=item * Apply C<process_new_digests()>

Call C<process_new_digests()> as you normally would.  In the above example, 
go ahead and call it on digest 1857 even though it creates thread files with 
messages out of chronological order.

=item * Determine date where need for repair begins

Examine the timestamps on your digest files for the date of the first digest 
you received out of sequence.  In the above example, that would be the date 
of digest 1858.  Since digest files were received out of proper sequence on or 
after that date, all thread files generated after that date may have 
out-of-sequence messages and need re-ordering.

=item * Apply C<repair_message_order()> with the repair date

Call C<repair_message_order()> with the following arguments:

=over 4

=item *

a reference to the 'in' configuration hash

=item *

a reference to the 'out' configuration hash

=item *

a reference to an anonymous hash whose keys are C<year>, C<month> and C<day>, 
the values for which keys are the elements of the repair date.

=back

Mail::Digest::Tools will examine all thread files from midnight local time on 
that date.  Where messages have been posted to the thread files out of proper 
sequence, they will be reposted in the correct order.  The thread file with 
the correct sequence will overwrite the file with the incorrect sequence.

=back

=head2 C<consolidate_threads_multiple>

    consolidate_threads_multiple(
        \%config_in,
        \%config_out,
    );

or

    consolidate_threads_multiple(
        \%config_in,
        \%config_out,
        $first_common_letters,  # optional integer argument
    );

As described above, Mail::Digest::Tool's C<process_new_digests()> function 
will, to the greatest extent possible, delete extraneous words such as 'Re:' 
or 'Fwd:' from a message's subject so that all relevant postings on a given 
subject can be included in a single thread file.  What happens when this is 
not sufficient? For example, suppose someone posts a message to a list with a 
slightly misspelled or altered subject line:

=over 4

=item * Original thread file:

   Help telnetting to remote host through CGI.thr.txt

=item * Thread file created due to altered subject line:

   Help telnetting to remote host thru CGI.thr.txt

=back

Mail::Digest::Tools offers two functions to address this problem.  
C<consolidate_threads_multiple()> is the easier to use and will be discussed 
first.  This function presumes that people who re-type e-mail subject lines 
when replying tend to type the first several words correctly, then make errors 
or alterations toward the end of the subject line.  If the first I<n> letters 
of the subject line of two or more messages are identical, there is a strong 
chance that the messages are discussing the same topic and should be posted to 
the same discussion thread.  Mail::Digest::Tool's default value for I<n> is 
20, but you can set a different value for a particular digest by passing an 
optional third argument as shown above.  C<consolidate_threads_multiple()> 
accordingly:

=over 4

=item *

Makes a list of all thread files for a particular digest.

=item *

Identifies groups of thread files whose names share the first 20 letters.

=item *

Displays a prompt on standard output asking you whether you wish to 
consolidate the files in each such group:

    Candidates for consolidation:
      Help telnetting to remote host through CGI.thr.txt
      Help telnetting to remote host thru CGI.thr.txt

    To consolidate, type YES:  

=over 4

=item *

If you type C<YES> in ALL CAPS, the files will be consolidated into a single 
thread file whose name will be derived from the Subject line of the very first 
posting to the discussion thread.  Standard output will display:

      Files will be consolidated

=item *

If you type anything other than C<YES> in ALL CAPS -- or simply hit C<[Enter]>, 
then the files will not be consolidated and standard output will display:

      Files will not be consolidated

=item *

If the files are consolidated, the original thread files will not automatically 
be deleted.  Rather, they are renamed with the extension C<.DELETABLE>.

    Help telnetting to remote host through CGI.thr.txt.DELETABLE
    Help telnetting to remote host thru CGI.thr.txt.DELETABLE

This is a safety precaution.  The user can then delete the deletable files 
by calling the C<delete_deletables()> function discussed below.

=back

=item *

If there are no files in the threads directory which share the first 20 letters 
in common (or the first I<n> letters if you have passed the optional third 
argument), then you are warned at standard output:

    Analysis of the first 20 letters of each file in
      [threads directory] 
      shows no candidates for consolidation.  Please hard-code
      names of files you wish to consolidate as arguments to
      &consolidate_threads_single

=back

=head2 C<consolidate_threads_single>

    consolidate_threads_single(
        \%config_in, 
        \%config_out, 
        [
            'first_dummy_file_for_consolidation.thr.txt',
            'second_dummy_file_for_consolidation.thr.txt',
        ],
    );

Suppose that the thread files which you wish to consolidate have names whose 
spelling diverges before the 21st letter.  The algorithm which 
C<consolidate_threads_multiple()> applies would not detect the potential 
rationale for consolidation.  This could happen when someone tries to change 
the subject of discussion from:

    Best book for extreme Newbie to programming

to:

    De incunabula nostra (Was Best book for extreme Newbie to programming)

I<Solution:>  Hard-code the files to be consolidated as elements of an 
anonymous array.  Pass a reference to that anonymous array as the third 
argument to C<consolidate_threads_single()> as shown above.

As with C<consolidate_threads_multiple()>, the resulting consolidated file 
will bear the name of the source file containing the very first posting to 
the discussion thread.  The files so consolidated will not automatically be 
deleted.  Rather, they will be renamed with the extension C<.DELETABLE> as a 
safety precaution and left for you to delete with C<delete_deletables()>.

=head2 C<delete_deletables>

    delete_deletables(\%config_out);

Mail::Digest::Tools function C<delete_deletables()> tidies up after use of 
either C<consolidate_threads_multiple()> or C<consolidate_threads_single()>.  
Unlike all other public functions provided by Mail::Digest::Tools, 
C<delete_deletables()> needs to be passed a reference to only one of the 
two configuration hashes, I<viz.,> the 'out' configuration hash.  The 
function simply changes to the directory where thread files for a given 
digest are stored and deletes all files with the extension C<.DELETABLE>.

=head1 CONFIGURATION SETUP OVERVIEW

To use a Mail::Digest::Tool function, you need to answer two fundamental 
questions:

=over 4

=item 1

What internal structure has the mailing list sponsor provided for a given 
digest?

=item 2

How do I want to structure the results of applying Mail::Digest::Tools to a 
particular digest on my system?

=back

Each of these two questions breaks down into sub-parts.  Their answers 
supply you with the information with which you will construct the two 
configuration hashes passed to most Mail::Digest::Tools functions.  
Let us take each in turn.

=head1 C<%config_in>: THE INTERNAL STRUCTURE OF A DIGEST

The best way to learn about the internal structure of a mailing list digest 
(other than to study the application which created the digest in the first 
place) is to accumulate several instances of the digest on your system in a 
directory devoted to that purpose.  Examine the way the digest's filename is 
formed.  Then examine the digest file itself.  You will soon pick up a feel 
for the structure of the digest, which will guide you in configuring 
Mail::Digest::Tools for your system.  That configuration will take the form 
of a Perl hash which, for illustrative purposes, we shall here call 
C<%xxx_config_in> where C<xxx> is a short-hand title for a particular digest.

For heuristic purposes we will examine the characteristics of two mailing 
list digests which the author has been following and archiving for several 
years:  ActiveState's 'Perl-Win32-Users' digest and Yahoo! Groups' Perl 
Beginners group digest.

=head2 Analysis of Digest's File Name

We must study a digest's file name in order to be able to write a pattern 
with which we will be able to distinguish a digest file from any non-digest 
file sitting in the same directory, as well as to be able to extract the 
digest number from that file name.

Once saved as plain-text files, Perl-Win32-Users digest files typically look 
like this in a directory:

    Perl-Win32-Users Digest, Vol 1 Issue 1771.txt
    Perl-Win32-Users Digest, Vol 1 Issue 1772.txt

Similarly, the Perl Beginner digest files look like this:

    [PBML] Digest Number 1491.txt
    [PBML] Digest Number 1492.txt

To correctly identify Perl-Win32-Users digest files from any other files in 
the same directory, we compose a string which would form the core of a Perl 
regular expression, I<i.e.,> everything in a pattern except the outer 
delimiters.  Internally, Mail::Digest::Tools passes the file name through a 
C<grep { /regexp/ }> pattern, so the first key is called C<grep_formula>.

    %pw32u_config_in = (
        grep_formula            => 'Perl-Win32-Users Digest',
        ...
    );

The equivalent pattern for the Perl Beginners digest would be:

    %pbml_config_in = (
        grep_formula            => '\[PBML\]',
        ...
    );

Note that the C<[> and C<]> characters have to be escaped with a C<\> 
backslash because they are normally metacharacters inside Perl regular 
expressions.

We next have to extract the digest number from the digest's file name.  
Certain mailing list programs give individual digests both a 'Volume' number 
as well as an individual digest number.  Perl-Win32-Users typifies this.  In 
the example above we need to capture both the C<1> as volume number and C<1771> 
as digest number.  The next key in our configuration hash is called 
C<pattern_target>:

    %pw32u_config_in = (
        grep_formula            => 'Perl-Win32-Users Digest',
        pattern_target          => '.*Vol\s(\d+),\sIssue\s(\d+)\.txt',
        ...
    );

Note the two sets of capturing parentheses.

Other digests, such as those at Yahoo! Groups, dispense with a volume number 
and simply increment each digest number:

    %pbml_config_in = (
        grep_formula            => '\[PBML\]',
        pattern_target          => '.*\s(\d+)\.txt$',
        ...
    );

Note that this C<pattern_target> contains only one pair of capturing 
parentheses.

=head2 Analysis of Digest's Internal Structure

A digest's internal structure is discussed in detail above (see 
'A TYPICAL MAILING LIST DIGEST').  Here we need to identify two 
characteristics:  the way the digest introduces its list of today's topics 
and the string it uses to delimit the list of today's topics from the first 
individual message in the digest and all subsequent messages from one another.  
Continuing with our two examples from above, we provide values for keys 
C<topics_intro> and C<source_msg_delimiter>: 

    %pw32u_config_in = (
        grep_formula            => 'Perl-Win32-Users digest',
        pattern_target          => '.*Vol\s(\d+),\sIssue\s(\d+)\.txt',
        topics_intro            => 'Today\'s Topics:',
        source_msg_delimiter    => "--__--__--\n\n",
        ...
    );

Note the escaped C<'> apostrophe character in the value for key 
C<topics_intro>.

    %pbml_config_in = (
        grep_formula            => '\[PBML\]',
        pattern_target          => '.*\s(\d+)\.txt$',
        topics_intro            => 'Topics in this digest:',
        source_msg_delimiter    => "________________________________________________________________________\n________________________________________________________________________\n\n",
        ...
    );

Note that the values provided for the respective C<source_msg_delimiter> keys 
had to be double-quoted strings.  That's because all such delimiters include 
two or more C<\n> newline characters so that they form paragraphs unto 
themselves.  Unless indicated otherwise, the values for all other values in 
the configuration hash are single-quoted strings.

Note:  In early 2004, while Mail::Digest::Tools was being prepared for its 
initial distribution on CPAN, ActiveState changed certain features in the 
daily digest versions of its mailing lists.  Hence, the code example presented 
above should not be 'copied-and-pasted' into a configuration hash with which 
you, the user, might follow the current Perl-Win32-Users digest.  In 
particular, the source message delimiter was changed to a string of 30 
hyphens followed by 2 C<\n> newline characters:

    "------------------------------\n\n"

However, since it is not unheard of for contributors to a mailing list to use 
such a string of hyphens within their postings or signatures, using a string 
of hyphens is not a particularly apt choice for a source message delimiter.  
In this particular case, the author is getting better (but not fully tested) 
results by including an additional newline I<before> the hyphen string in 
order to more uniquely identify the source message delimiter:

    "\n------------------------------\n\n"

=head2 Analysis of Individual Messages

The internal structure of an individual message within a digest is also 
discussed in detail above.  Here we need to identify patterns with which we 
can extract the content of the message's headers.

Certain mailing list digest programs allow a wide variety of headers to appear 
in digested messages.  The Perl-Win32-Users digest typifies this.  Each 
message in a Perl-Win32_Users digest I<must> have a message number and headers 
for the message's author, recipients, subject and date.

    Message: 1
    From: Chris Smithson <ChrisSmithson@some.web.address.com>
    To: "'Carter Kraus'" <carter@some.web.address.com>,
           "Perl-Win32-Users (E-mail)" <perl-win32-users@activestate.com>
    Subject: RE: OO Perl Issue.
    Date: Wed, 4 Feb 2004 14:17:24 -0600 

But a message in this digest may have additional headers for the author's 
organization, reply address and/or carbon-copy recipients.

    Message: 5
    Date: Wed, 4 Feb 2004 15:15:44 -0800
    From: Sam Spade <sspade@some.web.address.com>
    Organization: Some Web Address
    Reply-To: Sam Spade <sspade@some.web.address.com>
    To: "Time" <summers@some.web.address.com>
    CC: "Perl List" <perl-win32-users@listserv.activestate.com>
    Subject: Re: New IE Update causes script problems

Patterns are easily developed to capture this information and store it in the 
configuration hash:

    %pw32u_config_in = (
        grep_formula            => 'Perl-Win32-Users digest',
        pattern_target          => '.*Vol\s(\d+),\sIssue\s(\d+)\.txt',
        topics_intro            => 'Today\'s Topics:',
        source_msg_delimiter    => "--__--__--\n\n",
        message_style_flag      => '^Message:\s+(\d+)$',
        from_style_flag         => '^From:\s+(.+)$',
        org_style_flag          => '^Organization:\s+(.+)$',
        to_style_flag           => '^To:\s+(.+)$',
        cc_style_flag           => '^CC:\s+(.+)$',
        subject_style_flag      => '^Subject:\s+(.+)$',
        date_style_flag         => '^Date:\s+(.+)$',
        reply_to_style_flag     => '^Reply-To:\s+(.+)$',
        ...
    );

Other mailing list digest programs allow much fewer headers in digested 
messages.  The Yahoo! Groups digests such as Perl Beginner typify this.

    Message: 4
       Date: Sun, 7 Dec 2003 19:24:03 +1100
       From: Philip Streets <phil@some.web.address.com.au>
    Subject: RH9.0, perl 5.8.2 and qmail-localfilter question

The patterns developed to capture this information and store it in the 
configuration hash would be as follows:

    %pbml_config_in = (
        grep_formula            => '\[PBML\]',
        pattern_target          => '.*\s(\d+)\.txt$',
        topics_intro            => 'Topics in this digest:',
        source_msg_delimiter    => "________________________________________________________________________\n________________________________________________________________________\n\n",
        message_style_flag      => '^Message:\s+(\d+)$',
        from_style_flag         => '^\s+From:\s+(.+)$',
        subject_style_flag      => '^Subject:\s+(.+)$',
        date_style_flag         => '^\s+Date:\s+(.+)$',
        ...
    );

Note that this pattern is written to expect 1 or more whitespaces at the 
beginning of the C<from_style_flag> and the C<date_style_flag>.

We could -- but do not need to -- add the following key-value pairs to the 
C<%pbml_config_in> hash.

        org_style_flag          => undef,
        to_style_flag           => undef,
        cc_style_flag           => undef,
        reply_to_style_flag     => undef,

=head2 Inspection of Messages for Multipart MIME Content

Certain mailing lists allow subscribers to post messages in either plain-text 
or HTML.  Certain lists allow subscribers to post attachments; others do not.  
When it comes to preparing digests of these messages, the programs which 
different lists take lead to different results.  The most annoying situation 
occurs when a list allows a subscriber to post in 'multipart MIME format' and 
then fails to strip out the redundant HTML part after printing the needed 
plain-text part.

I<Example:>  An all too typical example from an older version of an ActiveState 
list digest.  (ActiveState changed the format of its digests in early 2004 to 
strip out HTML attachments.  Hence, the following code no longer accurately 
represents what a subscriber to an ActiveState digest will see.  Other mailing 
lists still suffer from MIME bloat, however, so treat the following code as 
illustrative.)  The message begins:

    Message: 1
    To: Perl-Win32-Users@activestate.com
    Subject: Can not tie STDOUT to scolled Tk widget
    From: John_Wonderman@some.web.address.ca
    Date: Thu, 15 Jan 2004 16:25:17 -0500
    This is a multipart message in MIME format.
    --=_alternative 00750F0485256E1C_=
    Content-Type: text/plain; charset="US-ASCII"
    Hi;
    I am trying to implement a scrolling text widget to capture output for for 
    at tk app. Without scrolling:
    my $text = $mw->Text(-width => 78,
           -height => 32,
           -wrap => 'word',
           -font => ['Courier New','11']
    )->pack(-side => 'bottom',
           -expand => 1,
           -fill => 'both',
    );
    ...

When the plain-text part of the message is finished, it is then repeated in 
HTML:

    --=_alternative 00750F0485256E1C_=
    Content-Type: text/html; charset="US-ASCII"
    <br><font size=2 face="Tahoma">Hi;</font>
    <p><font size=2 face="Tahoma">I am trying to implement a scrolling text
    widget to capture output for for at tk app. Without scrolling:</font>
    <p><font size=2 face="Bitstream Vera Sans Mono">my $text = $mw-&gt;Text(-width
    =&gt; 78,</font>
    <br><font size=2 face="Bitstream Vera Sans Mono">&nbsp; &nbsp; &nbsp; &nbsp;
    -height =&gt; 32,</font>
    <br><font size=2 face="Bitstream Vera Sans Mono">&nbsp; &nbsp; &nbsp; &nbsp;
    -wrap =&gt; 'word',</font>
    <br><font size=2 face="Bitstream Vera Sans Mono">&nbsp; &nbsp; &nbsp; &nbsp;
    -font =&gt; ['Courier New','11']</font>
    <br><font size=2 face="Bitstream Vera Sans Mono">)-&gt;pack(-side =&gt;
    'bottom',</font>
    <br><font size=2 face="Bitstream Vera Sans Mono">&nbsp; &nbsp; &nbsp; &nbsp;
    -expand =&gt; 1,</font>
    <br><font size=2 face="Bitstream Vera Sans Mono">&nbsp; &nbsp; &nbsp; &nbsp;
    -fill =&gt; 'both',</font>

There is no reason to retain this bloat in your thread file.  The digest 
providers should have stripped it out, but the program they were using failed 
to do so.  Other digests, such as those at Yahoo! Groups, eliminate all this 
blather.

Now, with Mail::Digest::Tools, you can eliminate much of the bloat yourself.  
After examining 6-10 instances of a particular mailing list digest, you should 
be able to determine whether the digest needs a dose of digital castor oil or 
not, and you set key C<MIME_cleanup_flag> accordingly.  If the digest contains 
unnecessary multipart MIME content, you set this flag to C<1>; otherwise, to 
C<0>.

And with that you have completed your analysis of the internal structure of a 
given digest and entered the relevant information into the first configuration 
hash:

    %pw32u_config_in = (
        grep_formula            => 'Perl-Win32-Users digest',
        pattern_target          => '.*Vol\s(\d+),\sIssue\s(\d+)\.txt',
        topics_intro            => 'Today\'s Topics:',
        source_msg_delimiter    => "--__--__--\n\n",
        message_style_flag      => '^Message:\s+(\d+)$',
        from_style_flag         => '^From:\s+(.+)$',
        org_style_flag          => '^Organization:\s+(.+)$',
        to_style_flag           => '^To:\s+(.+)$',
        cc_style_flag           => '^CC:\s+(.+)$',
        subject_style_flag      => '^Subject:\s+(.+)$',
        date_style_flag         => '^Date:\s+(.+)$',
        reply_to_style_flag     => '^Reply-To:\s+(.+)$',
        MIME_cleanup_flag       => 1,
    );

    %pbml_config_in = (
        grep_formula            => '\[PBML\]',
        pattern_target          => '.*\s(\d+)\.txt$',
        topics_intro            => 'Topics in this digest:',
        source_msg_delimiter    => "________________________________________________________________________\n________________________________________________________________________\n\n",
        message_style_flag      => '^Message:\s+(\d+)$',
        from_style_flag         => '^\s+From:\s+(.+)$',
        subject_style_flag      => '^Subject:\s+(.+)$',
        date_style_flag         => '^\s+Date:\s+(.+)$',
        MIME_cleanup_flag       => 0,
    );

=head1 C<%config_out>: HOW TO PROCESS A DIGEST ON YOUR SYSTEM

C<%config_in> holds the answers to the question:  What internal structure has 
the mailing list sponsor provided for a given digest?  In contrast, 
C<%config_out> will hold the answer to this question:  How do I want to 
structure the results of applying Mail::Digest::Tools to a particular digest 
on my system?

For purpose of illustration, we will continue to assume that we are processing 
digest files received from the Perl-Win32-Users and Perl Beginner lists.  We 
will make slightly different choices as to how we process those digest files 
so as to illustrate different options available from Mail::Digest::Tools.

We shall also assume that we going to place the scripts from which we call 
Mail::Digest::Tools functions in the directory I<above> the directories in 
which we store the digest files once they have been saved as plain-text files.  
If we call this directory C<digest> and place the scripts in that directory, 
then we will have a directory structure that starts out like this:

    digest/
        process_new.pl
        process_ALL.pl
        reply_digest_message.pl
        repair_digest_order.pl
        consolidate_threads.pl
        deletables.pl
        pw32u/
            Perl-Win32-Users Digest, Vol 1 Issue 1771.txt
            Perl-Win32-Users Digest, Vol 1 Issue 1772.txt
        pbml/
            [PBML] Digest Number 1491.txt
            [PBML] Digest Number 1492.txt

=head2 Required C<%config_out> Keys

There are 9 keys which are required in C<%config_out> in order for 
Mail::Digest::Tools to function properly.  They correspond to 9 decisions 
which you must make in setting up a Mail::Digest::Tools configuration on 
your system.

=over 4

=item 1 Title

Each digest must be given a title which is used whenever Mail::Digest::Tools 
needs to prompt or warn you on standard output.  The key which holds this 
information in C<%config_out> must be called C<title>; the value for this 
element should be sensible.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        ...
    );

=item 2 Digest Directory

For each digest a directory must be designated where individual digest files 
are stored in plain-text format.  The key which holds this information in 
C<%config_out> must be called C<dir_digest>.  In the examples below 
directories are named relative to the 'current' directory (C<..>), 
I<i.e.,> the directory where the script invoking a 
Mail::Digest::Function is stored.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        ...
    );

=item 3 Threads Directory

For each digest a directory must be designated where the thread files created 
by use of Mail::Digest::Tools functions are stored.  The key which holds this 
information in C<%config_out> must be called C<dir_threads>.  In the examples 
below the threads directory is a subdirectory of the digest directory, but 
you may make other choices.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        ...
    );

=item 4 Digests Log File

For each digest a file must be kept which logs whether a given digest file 
has already been processed or not and, if so, when.  The key which holds this 
information in C<%config_out> must be called C<digests_log>.  It has been 
found convenient to keep this file in the digests directory, but you may make 
other choices.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        ...
    );

=item 5 Today's Topics

For each digest a file must be kept which holds an ongoing record of the 
list of topics found in each individual digest file.  The key which holds this 
information in C<%config_out> must be called <todays_topics>.  It has been 
found convenient to keep this file in the digests directory, but you may make 
other choices.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        ...
    );

=item 6 Format for Identifying Digest Number in Output

For each digest you must choose how to format the number(s) of the individual 
digest file being processed when messages from that file are written to a 
threads file.  What you are doing here is formatting the information captured 
by the C<pattern_target> key in a given digest's C<%config_in> (see above).  
You express this choice as a single-quoted string which formats the data 
captured by Perl regular expression which in C<pattern_target>.  This 
formatting is done via the Perl C<sprintf> function.  The resulting string 
is assigned to be the value of C<%config_out> key <id_format>.

We saw above that digests from the Perl-Win32-Users list carried both a volume 
number and an individual digest number.

    Perl-Win32-Users Digest, Vol 1 Issue 1771.txt
    Perl-Win32-Users Digest, Vol 1 Issue 1772.txt

Both numbers were captured by the Perl regular expression in 
C<%pw32u_config_in> key <pattern_target>.

    '.*Vol\s(\d+),\sIssue\s(\d+)\.txt',

Here we have chosen to format the volume number as a 3-digit, 0-padded number 
and the individual digest number as a 4-digit, 0-padded number.  We then join 
these two data with an underscore.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        id_format                  => 'sprintf("%03d",$1) . \'_\' . sprintf("%04d",$2)',
        ...
    );

We saw above that digests from the Perl Beginners list carried only an 
digest number -- no volume number.

    [PBML] Digest Number 1491.txt
    [PBML] Digest Number 1492.txt

This number was captured by the Perl regular expression in C<%pbml_config_in> 
key <pattern_target>.

    '.*\s(\d+)\.txt$'

Here we have chosen to format the digest number as a 5-digit, 0-padded number.

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        id_format                  => 'sprintf("%05d",$1)',
        ...
    );

Note that if you allow for a 4-digit number, the highest numbered digest you 
can process off a given mailing list will be C<9999>.  If you allow for a 
5-digit number, the upper limit will be C<99999>.  The latter should be 
sufficient for a lifetime even for a mailing list (I<e.g.,> London.pm) which 
generates 3 or 4 digest files per day or over 1000 per year.

=item 7 Format for Numbering Individual Messages in Output

For each digest you must choose how to format the number which the digest 
assigns to its individual messages.  Experience suggests that 2 digits should 
be more than sufficient to format this number, as all digests which the author 
has observed have fewer than 100 entries.  However, below we have arbitrarily 
decided to allow for up to 9999 entries in a given digest.  As with the digest 
number, the formatting is accomplished via the Perl C<sprintf> function.  
The result is stored in a C<%config_out> key which must be called 
C<output_id_format>.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        id_format                  => 'sprintf("%03d",$1) . 
                                           \'_\' . sprintf("%04d",$2)',
        output_id_format           => 'sprintf("%04d",$1)',
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        id_format                  => 'sprintf("%05d",$1)',
        output_id_format           => 'sprintf("%04d",$1)',
        ...
    );

=item 8 Thread Message Delimiter

For each digest you must compose a string which will separate one message in 
a threads file from its successor.  This string must be double-quoted and 
assigned to C<%config_out> key C<thread_msg_delimiter>.  For readability, this 
string should terminate in two or more C<\n\n> newline characters so that the 
delimiter is always a paragraph unto itself.

This delimiter may -- or may not -- be the same string which the mailing list 
provider uses to separate messages in the digest files themselves.  In other 
words, you may choose to use the same string for C<thread_msg_delimiter> in 
C<%config_out> as you reported the list provider used in C<%config_in> key 
C<source_msg_delimiter>.

In the example below we make the C<thread_msg_delimiter> for the output from 
Perl-Win32-Users to be the same as its C<source_msg_delimiter>.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        id_format                  => 'sprintf("%03d",$1) . 
                                           \'_\' . sprintf("%04d",$2)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "--__--__--\n\n",
        ...
    );

Note:  In light of the earlier discussion of the changes ActiveState made 
to its mailing list digests in early 2004, the reader is cautioned that the 
code above should not be directly 'copied-and-pasted' into a configuration 
hash with which you might follow an ActiveState mailing list.  Treat it as 
educational.  In particular, the author is now testing the following as a 
setting for C<$pw32u_config_out{'thread_msg_delimiter'}>:

    "\n--__--__--\n\n",

For threads generated by appling Mail::Digest::Tools to the Perl 
Beginners list, we choose an output message delimiter which differs from the 
source message delimiter.

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        id_format                  => 'sprintf("%05d",$1)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "_*_*_*_*_*_\n_*_*_*_*_*_\n\n\n",
        ...
    );

Whatever choice you make for the C<thread_msg_delimiter> it should be a string 
unlikely to occur within the text of a message and should terminate in two or 
more newlines.

=item 9 Archive or Delete Threads?

For each digest you process with Mail::Digest::Tools, you must decide whether 
to retain the resulting thread files in an archive them in a separate 
directory after a specified period of time, to delete them from disk 
after a specified period of time, or to do neither and allow them to 
accumulate indefinitely in the threads directory.  Your decision is represented 
as the value of C<%config_out> key <archive_kill_trigger>.  This value must 
be expressed as one of three numerical values:

     0    Thread files are neither archived nor deleted

     1    Thread files are archived in a separate directory (or directories) 
          after the number of days specified by key 'archive_kill_days' 
          (see below)

    -1    Thread files are deleted after I<n> days as specified by key 
          'archive_kill_days' 

In the examples below we have chosen to archive all threads generated by the 
Perl-Win32-Users list but to kill all threads generated by the Perl Beginner 
list after a number of days whose specification we shall come to shortly.

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        id_format                  => 'sprintf("%03d",$1) . \'_\' . 
                                           sprintf("%04d",$2)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "--__--__--\n\n",
        archive_kill_trigger       => 1,
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        id_format                  => 'sprintf("%05d",$1)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "_*_*_*_*_*_\n_*_*_*_*_*_\n\n\n",
        archive_kill_trigger       => -1,
        ...
    );

=back

This completes the 9 required keys for C<%config_out>.  We now turn to keys 
which are either optional or which are required if you have assigned a value 
of C<1> or C<-1> to key C<archive_kill_trigger>.

=head2 Optional C<%config_out> Keys

=over 4

=item * Digests Read File

As an option, Mail::Digest::Tools offers file to log which instances of a 
particular digest have previously been processed which is more 
human-readable than the file named in C<%config_out> key C<digests_log>.  
That file logs a digest as follows:

    001_9999;Fri Feb  6 18:57:41 2004;Fri Feb  6 18:57:41 2004

It is probably easier to read this data like this:

    09999:
        first processed at            Fri Feb  6 18:57:41 2004
        most recently processed at    Fri Feb  6 18:57:41 2004

To choose this option you need to set I<two> keys in C<%config_out>:

=over 4

=item 1 C<digests_read_flag>

This must be assigned a true value such as C<1>.  This tells 
Mail::Digest::Tools that you indeed want a 'digests read' file.

=item 2 C<digests_read>

This should be assigned the name of the 'digests read' file, but it will 
default to a file F<digests_read.txt> placed in the directory named by key 
C<dir_digest>.

=back

Adding these keys to our C<%config_out>, we get:

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        id_format                  => 'sprintf("%03d",$1) . \'_\' . 
                                           sprintf("%04d",$2)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "--__--__--\n\n",
        archive_kill_trigger       => 1,
        digests_read_flag          => 1,
        digests_read               => "../pw32u/digests_read.txt",
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        id_format                  => 'sprintf("%05d",$1)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "_*_*_*_*_*_\n_*_*_*_*_*_\n\n\n",
        archive_kill_trigger       => -1,
        digests_read_flag          => 1,
        digests_read               => "../pbml/digests_read.txt",
        ...
    );

=item * Keys Needed When Archiving Thread Files

If, as discussed above, you have assigned the value C<1> to the 
C<<archive_kill_trigger> key in C<%config_out>, then Mail::Digest::Tools 
will archive older thread files, I<i.e.,> it will move thread files from the 
directory specified in key C<dir_threads> to an archive directory if the 
thread file has not been modified in a specified number of days.  If new 
messages need to be posted to a thread file which has been archived, that 
file will be de-archived and brought back to the C<dir_threads> directory.  
Thread files which are either archived or de-archived via a call to 
C<process_new_digests()> or C<reprocess_ALL_digests()> will be logged in 
appropriately named files.

Hence, the keys you will need to define when archiving thread files are:

=over 4

=item 1 C<archive_kill_days>

This key must be assigned the number of days after which a thread file sitting 
in the C<dir_threads> directory is moved to an archive directory.  If not 
specified, will default to 14 days.

=item 2 C<dir_archive_top>

This key must be assigned the name of the I<top> archive directory, I<i.e.,> 
the directory at the top of a tree of archive directories.

When you track a particular mailing list digest for a number of years, the 
number of different thread files can grow to enormous proportions.  For 
example, the author has tracked over 10,000 distinct thread files from the 
Perl-Win32-Users list over a three-and-a-half year period.  10,000 files in a 
single directory is completely unwieldy and slows directory read-times 
tremendously.  Mail::Digest::Tools therefore by default provides a tree of 
archive directories:  a top directory which contains no thread files but 
instead holds 27 subdirectories , one for each letter of the English alphabet 
and one for thread files which start with any other character (guaranteed to 
work with ASCII only; not tested with other character sets).

    dir_archive_top
        a
        b
        c
        ...
        z
        other

The user gets to choose where to place the top archive directory but the 27 
subdirectories are automatically placed beneath that one.  The top archive 
directory is the value assigned to C<%config_out> key C<dir_archive_top>.

=item 3 C<archived_today>

This key should be assigned the name of a file which will log any and all 
files archived by a single call to C<process_new_digests()> or 
C<reprocess_ALL_digests()>.  (By 'single' call is meant that this is I<not> 
an ongoing log; it only shows what happened today.)  If not assigned a value, 
it will default to a file called F<archived_today.txt> located in the 
directory named by key C<dir_digest>.

=item 4 C<de_archived_today>

This key should be assigned the name of a file which will log any and all 
files de-archived by a single call to C<process_new_digests()> or 
C<reprocess_ALL_digests()>.  (By 'single' call is meant that this is I<not> 
an ongoing log; it only shows what happened today.)  If not assigned a value, 
it will default to a file called F<de_archived_today.txt> located in the 
directory named by key C<dir_digest>.

=item 5 C<archive_config>

This key is reserved for future use.  In the current version of 
Mail::Digest::Tools it does not need to be set, but, should you be obsessive 
about this, set it to C<0>.

=back

Adding these keys to our sample C<%config_out> hashes, we get:

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        id_format                  => 'sprintf("%03d",$1) . \'_\' . 
                                           sprintf("%04d",$2)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "--__--__--\n\n",
        archive_kill_trigger       => 1,
        digests_read_flag          => 1,
        digests_read               => "../pw32u/digests_read.txt",
        archive_kill_days          => 14,
        dir_archive_top            => "../pw32u/Threads/archive",
        archived_today             => "../pw32u/archived_today.txt",
        de_archived_today          => "../pw32u/de_archived_today.txt",
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        id_format                  => 'sprintf("%05d",$1)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "_*_*_*_*_*_\n_*_*_*_*_*_\n\n\n",
        archive_kill_trigger       => -1,
        digests_read_flag          => 1,
        digests_read               => "../pbml/digests_read.txt",
        ...
    );

Note that since in our example we chose I<not> to archive thread files from 
the Perl Beginner list -- as evinced by the assignment of C<-1> to key 
C<archive_kill_trigger> -- we do not need to assign any values to 
C<dir_archive_top>, C<archived_today> or C<de_archived_today> in 
C<%pbml_config_out>.

=item * Keys Needed When Deleting Thread Files

The keys needed for C<%config_out> when you have chosen to delete thread 
files after a specified interval parallel those you would have needed if you 
had chosen to archive those files instead.

=over 4

=item 1 C<archive_kill_days>

This key must be assigned the number of days after which a thread file sitting 
in the C<dir_threads> directory is deleted.  If not specified, will default 
to 14 days.

=item 2 C<deleted_today>

This key should be assigned the name of a file which will log any and all 
files deleted by a single call to C<process_new_digests()> or 
C<reprocess_ALL_digests()>.  (By 'single' call is meant that this is I<not> 
an ongoing log; it only shows what happened today.)  If not assigned a value, 
it will default to a file called F<deleted_today.txt> located in the 
directory named by key C<dir_digest>.

=back

Adding these keys to our sample C<%config_out> hashes, we get:

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        id_format                  => 'sprintf("%03d",$1) . \'_\' . 
                                           sprintf("%04d",$2)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "--__--__--\n\n",
        archive_kill_trigger       => 1,
        digests_read_flag          => 1,
        digests_read               => "../pw32u/digests_read.txt",
        archive_kill_days          => 14,
        dir_archive_top            => "../pw32u/Threads/archive",
        archived_today             => "../pw32u/archived_today.txt",
        de_archived_today          => "../pw32u/de_archived_today.txt",
        ...
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        id_format                  => 'sprintf("%05d",$1)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "_*_*_*_*_*_\n_*_*_*_*_*_\n\n\n",
        archive_kill_trigger       => -1,
        digests_read_flag          => 1,
        digests_read               => "../pbml/digests_read.txt",
        archive_kill_days          => 14,
        deleted_today              => "../pbml/deleted_today.txt",
        ...
    );

Note that since in our example we chose to archive thread files from 
the Perl-Win32-Users list -- as evinced by the assignment of C<1> to key 
C<archive_kill_trigger> -- we do not need to assign any values to 
C<deleted_today> in C<%pw32u_config_out>.

=item * Keys Needed When Stripping Multipart MIME Content from Thread Files

Recall from above that you had to study a given digest to determine whether or 
not it contained multipart MIME content in need of stripping out.  If a digest, 
such as the ActiveState Perl-Win32-Users digest, contained a lot of such bloat, 
you set key C<MIME_cleanup_flag> in C<%config_in> to a value of C<1>.  If, on 
the other hand, the mailing list provider stripped out the multipart MIME 
content before distributing the digest, you set that key to a value of C<0>.

Mail::Digest::Tools will automatically strip out multipart MIME content once 
you have set C<MIME_cleanup_flag> to C<1>.  All that is left for you to decide 
is:  Do I want to view a log of which messages processed in a I<single> call of 
C<process_new_digests()> or C<reprocess_ALL_digests()> had multipart MIME 
content stripped out -- or not?  If so, you must set two keys in 
C<%config_out>:

=over 4

=item 1 C<MIME_cleanup_log_flag>

This key must be set to a true value such as C<1>.

=item 2 C<mimelog>

This key should be assigned the name of the 'mimelog' file, but if you do not 
specify a value it will default to a file F<mimelog.txt> placed in the 
directory named by key C<dir_digest>.

=back

The logfile so created looks like this:

    Processed                     Problem

    001_1775_0003 CASE C
    001_1775_0015 CASE C
    001_1775_0018 CASE C
    001_1775_0021 CASE E

where items in the 'Processed' column were either (a) successfully stripped of 
multipart MIME content by Mail::Digest::Tools as specified by the internal rule 
denoted by the 'CASE'; or (b) were recognized by Mail::Digest::Tools as 
containing multipart MIME content that could not be stripped out.

This is relatively esoteric and probably of interest mainly to the module's 
developer.  So if you are not interested in this feature set 
C<MIME_cleanup_log_flag> to C<0> and no mimelog will be created -- but 
Mail::Digest::Tools will still do its best to strip out extraneous multipart 
MIME content.

Our sample C<%config_out> hashes are now complete.  They look like this:

    %pw32u_config_out = (
        title                      => 'Perl-Win32-Users',
        dir_digest                 => "../pw32u",
        dir_threads                => "../pw32u/Threads",
        digests_log                => "../pw32u/digests_log.txt",
        todays_topics              => "../pw32u/todays_topics.txt",
        id_format                  => 'sprintf("%03d",$1) . \'_\' . 
                                           sprintf("%04d",$2)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "--__--__--\n\n",
        archive_kill_trigger       => 1,
        digests_read_flag          => 1,
        digests_read               => "../pw32u/digests_read.txt",
        archive_kill_days          => 14,
        dir_archive_top            => "../pw32u/Threads/archive",
        archived_today             => "../pw32u/archived_today.txt",
        de_archived_today          => "../pw32u/de_archived_today.txt",
        mimelog                    => "../pw32u/mimelog.txt",
        MIME_cleanup_log_flag      => 1,
    );

    %pbml_config_out = (
        title                      => 'Perl Beginner',
        dir_digest                 => "../pbml",
        dir_threads                => "../pbml/Threads",
        digests_log                => "../pbml/digests_log.txt",
        todays_topics              => "../pbml/todays_topics.txt",
        id_format                  => 'sprintf("%05d",$1)',
        output_id_format           => 'sprintf("%04d",$1)',
        thread_msg_delimiter       => "_*_*_*_*_*_\n_*_*_*_*_*_\n\n\n",
        archive_kill_trigger       => -1,
        digests_read_flag          => 1,
        digests_read               => "../pbml/digests_read.txt",
        archive_kill_days          => 14,
        deleted_today              => "../pbml/deleted_today.txt",
    );

Note that C<%pbml_config_out> does not have C<MIME_cleanup_log_flag> or 
C<mimelog> keys.  It doesn't need them, because in providing the Perl 
Beginners mailing list Yahoo! Groups strips out unnecessary multipart 
MIME content before sending the digest to you.

=back        

=head1 HELPFUL HINTS

... in which the module author shares what he has learned using 
Mail::Digest::Tools and its predecessors since August 2000.

=head2 Initial Configuration and Testing

As mentioned above, if you are considering creating a local archive of threads 
originating in daily digest versions of a mailing list, you should first 
accumulate 6-10 instances of such digests and both:

=over 4

=item 1

study the internal structure of the digest -- needed to develop a 
C<%config_in> for the digest; and

=item 2

carefully consider how you wish to structure the output from the module's 
use on your system -- needed to develop C<%config_out> for the digest

=back

Once you have developed the initial configuration, you should call 
C<reprocess_ALL_digests()> on the digests, then open the files created to see 
if the results are what you want.  If they are I<not> what you want, then you 
need to think about what you should change in C<%config_in> and/or 
C<%config_out>.  Make those changes, then call C<reprocess_ALL_digests()> 
again.  Repeat as needed, making sure not to delete any of the digest files 
you are using as sources until you are completely satisfied with your 
configuration.

Once, however, you I<are> satisfied with your configuration, you should call 
C<process_new_digests()> on new instances of digests and I<never> call 
C<reprocess_ALL_digests()> for that digest again (lest you not be able to 
regenerate threads containing messages from digests you have deleted over 
time).

=head2 Where to Store the Configuration Hashes

As mentioned above, you will probably find it convenient to write separate 
Perl scripts to call each one of Mail::Digest::Tool's public functions.  You 
could code C<%config_in> and C<%config_out> in each of those scripts just 
before the respective function calls.  But that would violate the principle of 
'Repeated Code Is a Mistake' and multiply maintenance problems.  It's far 
better to code the two configuration hashes in a separate plain-text file and 
'require' that file into your script.  That way, any changes you make in the 
configuration will be automatically picked up by each script that calls a 
Mail::Digest::Tools function.

Here is an example of such a file holding the configuration hashes governing 
use of the Perl-Win32-Users digest, along with a script making use of that file.

    # file:  pw32u.digest.data
    $topdir = "E:/Digest/pw32u";
    %config_in =  (
         grep_formula           => 'Perl-Win32-Users digest',
         pattern_target          => '.*Vol\s(\d+),\sIssue\s(\d+)\.txt',
         # next element's value must be double-quoted
         source_msg_delimiter   => "--__--__--\n\n",
         topics_intro           => 'Today\'s Topics:',
         message_style_flag     => '^Message:\s+(\d+)$',
         from_style_flag        => '^From:\s+(.+)$',
         org_style_flag         => '^Organization:\s+(.+)$',
         to_style_flag          => '^To:\s+(.+)$',
         cc_style_flag          => '^CC:\s+(.+)$',
         subject_style_flag     => '^Subject:\s+(.+)$',
         date_style_flag        => '^Date:\s+(.+)$',
         reply_to_style_flag    => '^Reply-To:\s+(.+)$',
         MIME_cleanup_flag      => 1,
    );

    %config_out =  (
         title                  => 'Perl-Win32-Users',
         dir_digest             => $topdir,
         dir_threads            => "$topdir/Threads",
         dir_archive_top        => "$topdir/Threads/archive",
         archived_today         => "$topdir/archived_today.txt",
         de_archived_today      => "$topdir/de_archived_today.txt",
         deleted_today          => "$topdir/deleted_today.txt",
         digests_log            => "$topdir/digests_log.txt",
         digests_read           => "$topdir/digests_read.txt",
         todays_topics          => "$topdir/todays_topics.txt",
         mimelog                => "$topdir/mimelog.txt",
         id_format              => 'sprintf("%03d",$1) . \'_\' . 
                                        sprintf("%04d",$2)',
         output_id_format       => 'sprintf("%04d",$1)',
         MIME_cleanup_log_flag  => 1,
         # next element's value must be double-quoted
         thread_msg_delimiter   => "--__--__--\n\n",
         archive_kill_trigger   => 1,
         archive_kill_days      => 14,
         digests_read_flag      => 1,
         archive_config         => 0,
    );

    # script:  dig.pl
    # USAGE:  perl dig.pl
    #!/usr/bin/perl
    use strict;
    use warnings;
    use Mail::Digest::Tools qw( process_new_digests );

    our (%config_in, %config_out);
    my $data_file = 'pw32u.digest.data';
    require $data_file;

    process_new_digests(\%config_in, \%config_out);

    print "\nFinished\n";

=head2 Maintaining Local Archives of More than One Digest

The module author has maintained local archives of more than a half dozen 
different mailing list digests over the past several years.  He has found it 
convenient to maintain the configuration information for I<all> the digests 
he is following at a given time in a I<single> configuration file.  The 
advantage to this approach is that if two digests share a similar internal 
structure (perhaps due to being generated by the same mailing list program or 
list provider) and if the user chooses to structure the output from the two 
digests in similar or identical ways, then getting the configuration hashes 
becomes much easier and the potential for error is reduced.

Here is a sample directory and file structure for maintaining archives of 
two different digests on a Win32 system:

    digest/
    digest.data
    process_new.pl
    process_ALL.pl
    reply_digest_message.pl
    repair_digest_order.pl
    consolidate_threads.pl
    deletables.pl
    pw32u/
        Perl-Win32-Users Digest, Vol 1 Issue 1771.txt
        Perl-Win32-Users Digest, Vol 1 Issue 1772.txt
        digest_log.txt
        digest_read.txt
        mimelog.txt
        Threads/
    pbml/
        [PBML] Digest Number 1491.txt
        [PBML] Digest Number 1492.txt
        digest_log.txt
        Threads/

File F<digest.data> would look like this:

    # digest.data
    $topdir = "E:/Digest";
    %digest_structure = (
        pbml =>    {
             grep_formula   => '\[PBML\]',
             pattern_target => '.*\s(\d+)\.txt$',
             ...
           },
        pw32u =>   {
             grep_formula   => 'Perl-Win32-Users digest',
             pattern_target => '.*Vol\s(\d+),\sIssue\s(\d+)\.txt',
             ...
           },
    );
    %digest_output_format = (
        pbml =>    {
             title          => 'Perl Beginner',
             dir_digest     => "$topdir/pbml",
             dir_threads    => "$topdir/pbml/Threads",
             ...
           },
        pw32u =>   {
             title          => 'Perl-Win32-Users',
             dir_digest     => "$topdir/pw32u",
             dir_threads    => "$topdir/pw32u/Threads",
             ...
           },
    );

To accomodate this slightly more complex structure in the configuration file, 
the calling script might be modified as follows:

    # script:  dig.pl
    # USAGE:  perl dig.pl [short-name for digest]
    #!/usr/bin/perl
    use Mail::Digest::Tools qw( process_new_digests );

    my ($this_key, %config_in, %config_out);
    # variables imported from $data_file
    our (%digest_structure, %digest_output_format);    

    my $data_file = 'digest.data';
    require $data_file;

    $this_key = shift @ARGV;
    die "\n     The command-line argument you typed:  $this_key\n     does not call an accessible digest$!" 
        unless (defined $digest_structure{$this_key}
            and defined $digest_output_format{$this_key});

    my ($k,$v);
    while ( ($k, $v) = each %{$digest_structure{$this_key}} ) {
        $config_in{$k} = $v;
    }
    while ( ($k, $v) = each %{$digest_output_format{$this_key}} ) {
        $config_out{$k} = $v;
    }

    process_new_digests(\%config_in, \%config_out);

    print "\nFinished\n";

=head2 Getting Your Mail to the Right Place on Your System

For several years the module author used the scripts which were predecessors 
to Mail::Digest::Tools on a Win32 system where mail was read with Microsoft 
Outlook Express.  He would do a "File/Save as.." on an instance of a digest, 
select text format (*.txt) and save it to an appropriate directory.  Later, 
the author used the shareware e-mail client Poco, in which the same operation 
was accomplished by highlighting a file and keying "Ctrl+S".

But as the number of digests the author was tracking grew, this procedure 
became more and more tedious.  Fortunately, about that time the author was 
assigned to write a review of the second edition of the Perl Cookbook, and he 
learned how to use the Net::POP3 module to receive his e-mail directly.  So 
now he uses a Perl script to get all his digests and save them as text files 
to appropriate directories -- and then lets a GUI e-mail client take care of 
the rest.

Here is a script which more or less accomplishes this:

    # script:  get_digests.pl
    #!/usr/bin/perl
    use strict;
    use warnings;
    use Net::POP3;
    use Term::ReadKey;

    my ($site, $username, $password);
    my ($verref, $pop3, $messagesref, $undeleted, $msgnum, $message);
    my ($k,$v);
    my ($oldfh, $output);

    my %digests = (
        'pbml'   => "E:/Digest/pbml",
        'pw32u'  => "E:/Digest/pw32u",
        'london' => "E:/Digest/london",
    );

    $site = 'pop3.someISP.com';
    $username = 'myuserid';

    $pop3 = Net::POP3->new($site)
            or die "Couldn't open connection to $site: $!";

    print "Enter password for $username at $site:  ";
    ReadMode('noecho');
    $password = ReadLine(0);
    chomp $password;
    ReadMode(0);
    print "\n";

    defined ($pop3->login($username, $password))
        or die "Can't authenticate: $!";

    $messagesref = $pop3->list 
        or die "Can't get list of undeleted messages: $!";

    while ( ($k,$v) = each %$messagesref ) {
        my ($messageref, $line, %headers);
        print "$k:\t$v\n";
        $messageref = $pop3->top($k);
        local $_;
        foreach (@$messageref) {
            chomp;
            last if (/^\s*$/);
            next unless (/^\s*(Date:|From:|Subject:|To:)/);
            if (/^\s*Date:\s*(.*)/) {
                $headers{'Date'} = $1;
            }
            if (/^\s*From:\s*(.*)/) {
                $headers{'From'} = $1;
            }
            if (/^\s*Subject:\s*(.*)/) {
                $headers{'Subject'} = $1;
            }
            if (/^\s*To:\s*(.*)/) {
                $headers{'To'} = $1;
            }
        }
        if ($headers{'Subject'} =~ /^\[PBML\]/) {
            get_digest($pop3, $k, 'pbml', $headers{'Subject'});
        }
        if ($headers{'Subject'} =~ /^Perl-Win32-Users/) {
            get_digest($pop3, $k, 'pw32u', $headers{'Subject'});
        }
        if ($headers{'Subject'} =~ /^london\.pm/) {
            get_digest($pop3, $k, 'london', $headers{'Subject'});
        }
    }

    $pop3->quit() or die "Couldn't quit cleanly: $!";

    print "Finished!\n";

    sub get_digest {
        my ($pop3, $msgnum, $digest, $subj) = @_;
        print "Retrieving $msgnum: $subj";
        my $message = 
            $pop3->get($msgnum) or die "Couldn't get message $msgnum: $!";
        if ($message) {
            print "\n";
            my $digestfile = "$digests{$digest}/$subj.txt";
            _print_message($digestfile, $message);
            print "Marking $msgnum for deletion\n";;
            $pop3->delete($msgnum) or die "Couldn't delete message $msgnum: $!";
        } else {
            print "Failed:  $!\n";
        }
    }

    sub _print_message {
        my ($digestfile, $message) = @_;
        my @lines = @{$message};
        my $counter = 0;
        open(FH, ">$digestfile") 
            or die "Couldn't open $digestfile for writing: $!";
        for (my $i = 0; $i<=$#lines; $i++) {
            chomp($lines[$i]);
            # Identify the first blank line in the digest,
            # i.e., the end of the headers
            if ($lines[$i] =~ /^$/) {
                $counter = $i;
                last;
            }
        };
        # Transfer digest to appropriate directory, skipping over digest header
        # so as to start just above Today's Topics
        foreach my $line (@lines[$counter+1 .. $#lines]) {
            chomp($line);
            # For some reason the $pop3->get() puts a single whitespace at the 
            # start of most (all but the first?) lines
            # That has to be cleaned up so digest.pl can correctly process 
            # header info and identify beginning of Today's Topics
            if ($line =~ /^\s(.*)/) {
                print FH $1, "\n";
            } else {
                print FH $line, "\n";
            }
        }
        close FH or die "Couldn't close after writing: $!";
    }

No promise is made that this script or any script contained in this 
documentation will work correctly on your system.  Hack it up to get it to 
work the way you want it to.

=head1 ASSUMPTIONS AND QUALIFICATIONS

=over 4

=item 1 No Change in Mailing List Digest Software

The main assumption on which Mail::Digest::Tools depends for its success is 
that the provider of a particular digest continues to use the same mailing 
list software to produce the digest.  If the provider changes his/her software, 
you must modify Mail::Digest::Tools' configuration data accordingly.

=item 2 Digest Must Be One E-mail Without Attachments

At its current stage of development Mail::Digest::Tools is only applicable to 
mailing list digests which arrive as one continuous file.  It is C<not> 
applicable to digests (e.g., Cygwin, module-authors@perl.org) which are 
supplied in a format consisting of (a) one file with instructions and a table 
of contents and (b) all the individual messages provided as e-mail attachments.

=item 3 Perl 5.6+ Only

The program was created with Perl 5.6.  Certain features, such as the use of 
the C<our> modifier, were not available prior to 5.6.  Modifications to 
account for pre-5.6 features are left as an exercise for the user.

=item 4 Time::Local

Mail::Digest::Tools internally uses Perl core extension Time::Local.  If at 
some future point this module is not included as part of a Perl core 
distribution, you would have to install it manually from CPAN.

=back

=head1 HISTORY AND FUTURE DEVELOPMENT

=head2 PRE-CPAN HISTORY

ActiveState maintains Perl for Windows-based platforms and also maintains a
variety of mailing lists for users of its Windows-compatible versions of Perl.
Subscribers to these lists can receive messages either as individual e-mails
or as part of a daily digest which contains a listing of the day's topics and
the complete text of each message.  The messages are often best followed as
discussion 'threads' which may extend over several days' worth of digests.

In June of 2000, however, ActiveState had to temporarily take its mailing lists
off-line for technical reasons.  When these lists were restored to service,
their archive capacities were not immediately restored.  I had just begun my 
study of Perl and had come to enjoy reading the Perl-Win32-Users digest.  As 
I set off for the Yet Another Perl Conference in Pittsburgh, I shouted out, 
'I want my Perl-Win32-Users digest!'  I wrote a Perl script called C<digest.pl> 
to fill that gap.

ActiveState has since restored archiving capacity to their lists.  For reasons 
that would perhaps best be explored in a psychotherapeutic context, however, I 
had become attached to my local archive of the 'pw32u' list, so I continued to 
maintain this program and fine-tune its coding.

In early 2001 it became apparent that this program could be applied to a wide
variety of mailing list digests -- not just those provided by ActiveState.  In
particular, valuable digests provided by Yahoo Groups (formerly E-groups) such
as NT Emacs Users, Perl 5 Porters and Perl Beginners could also be archived if
C<digest.pl> were modified appropriately.  I made those modifications and 
began to track several other digests.  I was able to use the archive I had 
developed as a window into one part of the Perl community in a Lightning Talk 
I gave at YAPC::North America in Montreal in June 2001, ''An Index of 
Incivility in the Perl Community.''

Maintaining C<digest.pl> was, to a considerable extent, the way I taught myself 
Perl.  Along the way I incorporated my first profiler into the script -- and 
then discarded it.  Some of the subroutines I had written for early versions of 
the program had applicability to other scripts -- and thus was born my first 
module -- also since discarded.  By July 2003 I was up to version 1.3.  
Following a suggestion by Uri Guttman at the YAPC::EU conference held in Paris 
in July 2003, wherever possible the use of separate
print statements for each line to be printed was eliminated in favor of
concatenating strings to be printed into much larger strings which could be
printed all at once.  This revision reduced the number of times filehandles 
had to be opened for writing.  A given thread file was now opened only once 
per call of this program, rather than once for each message in each digest 
processed per call of the program.  

Various other improvements, such as the possibility of stripping out 
unnecessary multipart MIME content and the introduction of subdirectories 
for archiving, were made in late 2003.  At that point I 
decided to transform the script into a full-fledged Perl module.  At first I 
tried out an object-oriented structure (with which I was familiar from my first 
two CPAN modules, F<List::Compare> and F<Data::Presenter>).  That OO structure 
necessitated one constructor and one method call per typical script, but since 
the constructor did nothing but some cursory validation of the configuration 
data, it was mostly superfluous.  Hence, I jettisoned the OO structure in favor 
of a functional approach.  The result:  Mail::Digest::Tools.

=head2 CPAN

After these revisions, I was up to version 1.96.  Why revert to a lower 
version number at this point?  That is why Mail::Digest::Tools makes its CPAN 
debut in version 2.04.

v1.97 (2/18/2004):  Dealing with problem that Win32 and Unix/Linux may create 
different thread names for the same set of source messages because they have 
different lists of characters forbidden in file names.  This became a problem 
while writing tests for C<process_new_digests()> because it made predicting 
the names of thread files created via that function more difficult to predict.
Tests adjusted appropriately.

v1.98 (2/19/2004):  Eliminated suspect uses of C</o> modifier on regexes.  
This was causing problems when I called C<process_new_digests()> on two 
different types of digests in the same script.  Also, eliminated code 
referring to DOS (I<e.g.,> code eliminating characters unacceptable in 
DOS filenames) as I have no way to test this module on a DOS box.

v1.99 (2/22/2004):  ActiveState introduced a new format for its 
Perl-Win32-Users digest -- the digest which originally inspired the creation 
of this module's predecessor in 2000.  One aspect of this new format was a 
clear improvement:  HTML attachments are now stripped before messages are 
posted to the digest, so multipart MIME content has either been reduced 
considerably or eliminated altogether.  But another aspect of this new 
format upset code going back four years:  The delimiter immediately 
following Today's Topics is now different from the delimiters separating each 
message in the digest.  Working around this appeared to be surprisingly 
difficult, especially since this revision had to be done in the middle of 
writing a test suite for CPAN distribution.  A new key has been added to the 
C<%config_in> hash for each digest:

    $config_in{'post_topics_delimiter'}

v2.00 (2/23/2004):  Testing conducted after the last revision revealed a bug 
going back several versions in the internal subroutine stripping multipart 
MIME content.  The last paragraph of each message which did I<not> have MIME 
content was being stripped off.  The offending code was found within 
C<_analyze_message_body()>.  (The author recently learned of the CPAN
module F<Email::StripMime>.  This looks promising as a replacement for 
the hand-rolled subroutine used within Mail::Digest::Tools, but a full study 
of its possibilities will be deferred to a later version.  Also in this 
version, POD was rewritten to reflect the introduction of the post-topics 
delimiter.

v2.01 (2/24/2004):  Backslashes (except as part of C<\n> newline characters) 
are prohibited in C<%config_out> key C<thread_msg_delimiter>.  This is 
because in the test suite that key's value is used as a variable inside a 
regular expression which in turn is used as an argument to C<split()>.  
Preliminary investigation suggests that to work around the backslash 
metacharacter in that situation would be very time-consuming.

v2.02 (2/26/2004):  Revised C<reply_to_digest_message()> internal 
subroutine C<_strip_down_for_reply> to reflect distinction between post-topics 
delimiter and source message delimiter.

v2.03 (3/04/2004):  Fixed bug in C<readdir> call in C<repair_message_order()>.
Extensive reworking of test suite.

v2.04 (3/05/2004):  No changes in module.  Refinement of test suite only.

v2.05 (3/07/2004):  Fixed accidental deletion of incrementation of 
C<$message_count> in C<_strip_down()>.

v2.06 (3/10/2004):   Correction of errors in test suite.  Elimination of use of List::Compare in test suite.

v2.07 (3/11/2004):  Correction of error in t/03.t

v2.08 (3/11/2004):  Correction in _clean_up_thread_title and in tests.

v2.10 (3/15/2004):  Corrections to README and documentation only.

v2.11 (10/23/2004):  Fixed several errors which resulted in "Bizarre copy of hash in leave" error when running test suite under Devel::Cover.

v2.12 (05/14/2011):  Added 'mirbsd' to list of Unixish-OSes.

=head1 AUTHOR

James E. Keenan (F<jkeenan@cpan.org>).

Creation date: August 21, 2000.
Last modification date: May 14, 2011.
Copyright (c) 2000-2011 James E. Keenan.  United States.  All rights reserved.

This software is distributed with absolutely no warranty, express or implied.  
Use it at your own risk.  This is free software which you may distribute under 
the same terms as Perl itself.

=cut




