package Kwiki::Kwiki::Command;
use strict;
use File::Copy;
use File::Path qw(mkpath);
use File::Copy::Recursive qw(dircopy rcopy);
use File::Spec::Functions qw(splitdir catfile catdir);
use Cwd qw(cwd);

sub new {
    my $self = {
        ROOT => "kwiki"
    };
    return bless $self, shift;
}

sub system_command {
    my ($self, $command) = @_;
    warn "> $command\n";
    system($command) == 0
        or die "Command failed\n";
}

sub assert_copy {
    my ($self, $old_path, $new_path) = @_;
    my ($rel_dir) = ($new_path =~ /(.*)\/\w+\.pm$/)
        or die "Can't find directory component for $new_path";
    mkpath($rel_dir) unless -e $rel_dir;
    copy($old_path, $new_path)
        or die "Can't copy $_ to $new_path\n";
    print STDERR "Copy: $old_path -> $new_path\n";
}

sub read_list {
    my $self = shift;
    open LIST, catfile($self->{ROOT}, qw(sources list))
        or die "Can't open $self->{ROOT}/sources/list for input";
    my @lines = <LIST>;
    close LIST;
    my $list = {};
    my $type = undef;
    my $line = 0;
    for (@lines) {
        $line++;
        next if /^(#|\s*$)/;
        if (/===\s+(\w+)/) {
            $type = $1;
            next;
        }
        die "Invalid list format. No type line. (at line $line)\n"
            unless $type;
        die "Invlaid list format. Invalid list line (at line $line)\n"
            unless /^---\s+(.*?)\s*$/; 
        my $list = $list->{$type}{list} ||= [];
        push @$list, $1;
    }
    return $list;
}

1;

__END__

=head1 NAME

Kwiki::Kwiki::Command - Base class for commands.

=head1 DESCRIPTION

See L<Kwiki::Kwiki> for all documentation.

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>
