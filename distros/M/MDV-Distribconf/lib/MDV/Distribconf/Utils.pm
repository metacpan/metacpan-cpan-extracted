package MDV::Distribconf::Utils;

use strict;
use warnings;
use MDV::Packdrakeng;
use Digest::MD5;
use Devel::Peek;

our ($VERSION) = (qq$Revision: 232705 $ =~ /(\d+)/)[0];

=head1 NAME

MDV::Distribconf::Utils

=head1 DESCRIPTION

Contains basic functions used by Distribconf

=head1 FUNCTIONS

=head2 hdlist_vs_dir($hdlistfile, @dirs)

Return two arrayrefs about rpms included only in hdlist or in directories

=cut

sub hdlist_vs_dir {
    my ($hdlist, @dir) = @_;
    my (@only_pack, @only_dir);
    my @rpms;
    foreach my $dir (@dir) {
        push(@rpms, glob("$dir/*.rpm"));
    }
    @rpms = sort { ($b =~ m:.*/+(.*):)[0] cmp ($a =~ m:([^/]+)$:)[0] } @rpms;
    if (-f $hdlist and my $pack = MDV::Packdrakeng->open(archive => $hdlist)) {
        my $hdlisttime = (stat($hdlist))[9];
        my (undef, $files, undef) = $pack->getcontent();
        my @hdrs = sort { $b cmp $a } map { "$_.rpm" } @{$files || []};
        my ($r, $h) = ("", "");
        do {
            my $base_r = ($r =~ m:([^/]+)$:)[0] || '';
            my $comp = ($base_r cmp $h);
            my $st_d = $r ? (stat($r))[9] : 0;
            if ($comp < 0 || !defined($st_d)) { push(@only_pack, $h); }
            elsif ($comp > 0) { push(@only_dir, $base_r); }
            elsif ($r && ($st_d > $hdlisttime)) {
                push(@only_pack, $h);
                push(@only_dir, ($r =~ m:.*/+(.*):)[0]);
            }

            if ($comp <= 0) {
                $h = shift(@hdrs) || '';
            } 
            if ($comp >= 0) {
                $r = shift(@rpms) || '';
            }
        } while (scalar(@rpms) || scalar(@hdrs));
    } else {
        return(undef, [ map { m:.*/+(.*):; $1 } @rpms ]);
    }
    return (\@only_pack, \@only_dir);
}

=head2 checkmd5($md5file, @files)

Return an array ref to unsync file found and a hashref containing
files and their found md5.

=cut

sub checkmd5 {
    my ($md5file, @files) = @_;
    my %foundmd5;
    foreach my $file (@files) {
        my ($basename) = $file =~ m:.*/+([^/]*)$:; #: vi syntax coloring
        if (open(my $hfile, "<", $file)) {
            my $ctx = Digest::MD5->new;
            $ctx->addfile($hfile);
            close($hfile);
            $foundmd5{$basename} = $ctx->hexdigest;
        } else {
            $foundmd5{$basename} = '';
        }
    }
    open(my $hmd5, "<", $md5file) or return([ keys %foundmd5 ], \%foundmd5);
    my %md5;
    while (<$hmd5>) {
        chomp;
        s/#.*//;
        /^(.{32})  (.*)/ or next;
        $md5{$2} = $1;
    }
    close($hmd5);
    my @badfiles = grep { $foundmd5{$_} ne ($md5{$_} || '') } keys %foundmd5;
    return (\@badfiles, \%foundmd5);
}

1;

__END__

=head1 SEE ALSO

L<MDV::Distribconf>

=head1 AUTHOR

Olivier Thauvin <nanardon@mandriva.org>

=head1 LICENSE AND COPYRIGHT

(c) 2005, 2006, 2007 Olivier Thauvin
(c) 2005, 2006, 2007 Mandriva

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
