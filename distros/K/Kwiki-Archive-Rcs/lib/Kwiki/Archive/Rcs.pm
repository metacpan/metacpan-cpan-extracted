package Kwiki::Archive::Rcs;
use Kwiki::Archive -Base;
our $VERSION = '0.16';

sub show_revisions {
    my $page = $self->pages->current;
    my $rcs_text = io($self->assert_file_path($page))->all
      or return 0;
    $rcs_text =~ /^head\s+1\.(\d+)/
      or return 0;
    $1 > 1 ? $1 : 0;
}

sub assert_file_path {
    my $page = shift;
    my $file_path = $self->file_path($page);
    $self->commit($page) unless -e $file_path;
    return $file_path;
}

sub file_path {
    my $page = shift;
    $self->plugin_directory . '/' . $page->id . ',v';
}

sub commit {
    my $page = shift;
    my $props = $self->page_properties($page);
    my $rcs_file_path = $self->file_path($page);
    $self->shell("rcs -q -i -U $rcs_file_path < /dev/null")
      unless -f $rcs_file_path;
    my $msg = $self->$csv_encode($props);
    my $page_file_path = $page->io;
    eval {
        $self->shell(qq{ci -q -l -m"$msg" $page_file_path $rcs_file_path 2>/dev/null});
    };
    if ($@) {
        $self->force_unlock_rcs_file($rcs_file_path);
        $self->shell(qq{ci -q -l -m"$msg" $page_file_path $rcs_file_path});
    }
}

# XXX This is needed because sometimes rcs gets different user name under
# apache.
sub force_unlock_rcs_file {
    my $rcs_file = shift;
    $self->shell("rcs -q -U -M -u $rcs_file < /dev/null 2>/dev/null");
}

sub fetch_metadata {
    my $page = shift;
    my $rev = shift;
    my $rcs_file_path = $self->assert_file_path($page);
    my $rlog = io("rlog -zLT -r $rev $rcs_file_path |") or die $!; 
    $rlog->utf8 if $self->has_utf8;
    $self->parse_metadata($rlog->all);
}

sub parse_metadata {
    my $log = shift;
    $log =~ /
        ^revision\s+(\S+).*?
        ^date:\s+(.+?);.*?\n
        (.*)
    /xms or die "Couldn't parse rlog:\n$log";

    my $revision_id = $1;
    my $archive_date = $2;
    my $msg = $3;
    chomp $msg;

    my $metadata = 
      $self->$csv_decode($msg) ||
      $self->$older_decode($msg) ||
      $self->$oldest_decode($msg);
    $revision_id =~ s/^1\.//;
    $metadata->{revision_id} = $revision_id;
    $metadata->{edit_time} ||= $archive_date;
    $metadata->{edit_unixtime} ||= do {
        require Date::Manip;
        Date::Manip::UnixDate(Date::Manip::ParseDate($archive_date), "%s");
    };
    return $metadata;
}

sub history {
    my $page = shift;
    my $rcs_file_path = $self->assert_file_path($page);
    my $rlog = io("rlog -zLT $rcs_file_path |") or die $!; 
    $rlog->utf8 if $self->has_utf8;

    my $input = $rlog->all;
    $input =~ s/
        \n=+$
        .*\Z
    //msx;
    my @rlog = split /^-+\n/m, $input;
    shift(@rlog);

    return [
        map $self->parse_metadata($_), @rlog
    ];
}

sub fetch {
    my $page = shift;
    my $revision_id = shift;
    return unless $revision_id =~ /^\d+$/;
    my $revision = "1.$revision_id";
    my $rcs_file_path = $self->assert_file_path($page);
    local($/, *CO);
    open CO, qq{co -q -p$revision $rcs_file_path |}
      or die $!;
    binmode(CO, ':utf8') if $self->has_utf8;
    scalar <CO>;
}

sub shell {
    my ($command) = @_;
    use Cwd;
    $! = undef;
    system($command) == 0 
      or die "$command failed:\n$?\nin " . Cwd::cwd();
}

my sub csv_encode {
    my $hash = shift;
    join ',', map {
        my $key = $_;
        my $value = $self->uri_escape($hash->{$key});
        "$key:$value";
    } sort keys %$hash;
}

my sub csv_decode {
    my $string = shift;
    return unless $string =~ /edit_time:/;
    return {
        map {
            my ($key, $value) = split ':', $_, 2;
            $value = $self->uri_unescape($value);
            ($key, $value);
        } split /(?<!\\),/, $string
    };
}

my sub older_decode {
    my $string = shift;
    return unless $string =~ /,/;
    my ($edit_by, $edit_time, $edit_unixtime) = split ',', $string;
    return {
        edit_by => $self->uri_unescape($edit_by),
        edit_time => $edit_time,
        edit_unixtime => $edit_unixtime,
    };
}

my sub oldest_decode {
    my $string = shift;
    if ($string =~ /^[\d\.]{7,}$/) {
        return {edit_address => $string};
    }
    else {
        return {edit_by => $string};
    }
}
    
__DATA__

=head1 NAME 

Kwiki::Archive::Rcs - Kwiki Page Archival Using RCS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
