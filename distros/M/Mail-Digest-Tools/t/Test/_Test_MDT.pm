package Test::_Test_MDT;
# Contains test subroutines for distribution with Mail::Digest::Tools
# As of:  March 5, 2004
require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw(
    count_records 
    verify_message_count
    compare_arrays
    get_message_numbers_created
    get_paragraph_count
    get_paragraph_count_reply 
    get_paragraphs_replied_to_count 
    test_archive_structure
    empty_as_needed
    truncate_as_needed
    get_intersection
);

sub count_records {
    my ($file, $separator) = @_;
    my $records = 0;
    open IN, $file or die "Could not open $file for reading: $!";
    {
        local $/ = $separator;
        $records++ while (<IN>);
    }
    close IN or die "Could not close $file after reading: $!";
    return $records;
}

sub verify_message_count { 
    my ($file, $delimiter) = @_;
    my (@temp, $bigstr);
    open IN, $file or die "Could not open $file for reading: $!";
    {
        local $/ = undef;
        $bigstr = <IN>;
    }
    close IN or die "Could not close $file after reading: $!";
    @temp = split(/$delimiter/, $bigstr);
    return scalar(@temp);
}

sub compare_arrays {
    my ($predictref, $createdref) = @_;
    return 0 unless (@$predictref == @$createdref);
    my $count = 0;
    for (my $i=0; $i<=$#{$predictref}; $i++) {
        $count++ if ${$predictref}[$i] eq ${$createdref}[$i];
    }
    scalar(@{$predictref}) == $count ? 1 : 0;
}

sub get_message_numbers_created {
    my ($file, $delimiter) = @_;
    my (@messages, $bigstr);
    open IN, $file or die "Could not open $file for reading: $!";
    {
        local $/ = undef;
        $bigstr = <IN>;
    }
    close IN or die "Could not close $file after reading: $!";
    @messages = split(/$delimiter/, $bigstr);
    my (@mess_nos);
    foreach (@messages) {
        my @lines = split(/\n/, $_);
        my ($l);
        while (defined ($l = shift(@lines))) {
            chomp;
            next unless $l =~ /^Message:/;
            if ($l =~ /^Message:\s+(.*)/) {
                push(@mess_nos, $1);
            } else {
                die "Message number not capturable in test: $!";
            }
            last;
        }
    }
    return \@mess_nos;
}

sub get_paragraph_count {
    my ($file, $delimiter) = @_;
    my (@messages, $bigstr);
    open IN, $file or die "Could not open $file for reading: $!";
    {
        local $/ = undef;
        $bigstr = <IN>;
    }
    close IN or die "Could not close $file after reading: $!";
    @messages = split(/$delimiter/, $bigstr);
    my (@paragraph_counts);
    for (my $j=0; $j<=$#messages; $j++) {
        my @temp = split( /\n\n/, $messages[$j] );
        $paragraph_counts[$j] = scalar(@temp);
    }
    return \@paragraph_counts;
} 

sub get_paragraph_count_reply {
    my $file = shift;
    my (@paragraphs);
    open IN, $file or die "Could not open $file for reading: $!";
    {
        local $/ = "\n\n";
        @paragraphs = <IN>;
    }
    close IN or die "Could not close $file after reading: $!";
    return scalar(@paragraphs);
} 

sub get_paragraphs_replied_to_count {
    my ($file, $reply_to_style_flag) = @_;
    my (@paragraphs);
    open IN, $file or die "Could not open $file for reading: $!";
    {
        local $/ = "\n\n";
        @paragraphs = <IN>;
    }
    close IN or die "Could not close $file after reading: $!";
    splice(@paragraphs, 0, 2 + $reply_to_style_flag);
    die "Bad test: $!" unless @paragraphs == 1; 
    my @reply_lines = split(/\n/, $paragraphs[0]);
    my ($m, $bigstr);
    while (defined ($m = shift(@reply_lines))) {
        chomp $m;
        next unless $m =~ /^> /;
        if ($m =~ /^> (.*)/) {
            $bigstr .= $1 . "\n";
        } else {
            die "Malformed reply file: $!";
        }
    }
    my @orig_paras = split(/\n\n/, $bigstr);
    return scalar(@orig_paras);
}

sub test_archive_structure {
   my $archdir = shift;
   chdir $archdir or die "Unable to change to $archdir: $!";
   opendir DIR, $archdir or die "Unable to open $archdir: $!";
   my ($subdir);
   my $count = 0;
   while (defined ($subdir = readdir DIR) ) {
       next unless (-d $subdir);
       next if ($subdir =~ /^\./);
       $count++;
   }
   closedir DIR or die "Unable to close $archdir: $!";
   return $count;
}

sub empty_as_needed {
    my $aref = shift;
    my @need_emptying = @$aref;
    foreach my $thrdir (@need_emptying) {
        unless (! -d $thrdir) {
            chdir $thrdir or die "Couldn't change to $thrdir: $!";
            opendir DIR, $thrdir 
                or die "Couldn't open dirhandle to $thrdir: $!";
            my @thrs = grep {/(\.thr|\.reply)\.txt$/} readdir DIR;
            closedir DIR or die "Couldn't close: $!";
            foreach my $thrfile (@thrs) {
                unlink $thrfile or die "Couldn't unlink $thrfile: $!";
                print "$thrfile has been unlinked\n";
            }
        }
    }
}

sub truncate_as_needed {
    my ($config_out_ref, $truncate_ref) = @_;
    my %config_out = %$config_out_ref;
    foreach my $log (@$truncate_ref) {
        if (-f $config_out{$log}) {
            open TRUN, ">$config_out{$log}"
                or die "Unable to open $log for truncating: $!";
            truncate TRUN, 0;
            close TRUN or die "Unable to close $log after truncating: $!";
        }
    }
};

sub get_intersection {
	die "Incorrect number of arguments for \&get_intersection: $!"
		unless (@_ == 2);
	my ($aref1, $aref2) = @_;
	my (%seenA, @int);
	$seenA{$_}++ foreach (@$aref1);
	foreach (@$aref2) {
		push(@int, $_) if $seenA{$_};
	}
	return @int;
}

