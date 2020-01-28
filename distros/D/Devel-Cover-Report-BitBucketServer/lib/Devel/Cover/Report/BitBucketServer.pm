package Devel::Cover::Report::BitBucketServer;

use strict;
use warnings;
use Path::Tiny qw(path);
use JSON::MaybeXS qw(encode_json);

our $VERSION = '0.3';

sub report {
    my ( $pkg, $db, $options ) = @_;

    my $cover = $db->cover;

    my @cfiles;
    for my $file ( @{ $options->{file} } ) {
        my $f  = $cover->file($file);
        my $st = $f->statement;
        my $br = $f->branch;
        my $cn = $f->condition;

        my %fdata = ( path => $file, );

        my %lines = (co => [], uc => [], pc => [] );
        for my $lnr ( sort { $a <=> $b } $st->items ) {
            my $sinfo = $st->location($lnr) // [];
            my $covered = 0;
            for my $s (@$sinfo) {
                my $scov = $s->covered     // 0;
                my $sunc = $s->uncoverable // 0;
                $covered |= $scov || $sunc;
            }
            my $sto = $covered > 0 ? 'co' : 'uc';
            my $binfo = defined($br) ? $br->location($lnr) // [] : [];
            my $cinfo = defined($cn) ? $cn->location($lnr) // [] : [];
            my $btot = my $bcov = 0;
            for my $b ( @$binfo, @$cinfo ) {
                $btot += $b->total;
                $bcov += $b->covered;
            }
            my $bto = $bcov == $btot ? 'co' : ($bcov == 0 ? 'uc' : 'pc');
            my $to = $sto eq 'uc' ? 'uc' : ( $bto eq 'co' ? 'co': 'pc');
            push @{ $lines{$to} }, $lnr;
        }
        my $co_str = @{ $lines{co} } ? 'C:' . join( ',', @{ $lines{co} } ) : '';
        my $uc_str = @{ $lines{uc} } ? 'U:' . join( ',', @{ $lines{uc} } ) : '';
        my $pc_str = @{ $lines{pc} } ? 'P:' . join( ',', @{ $lines{pc} } ) : '';
        $fdata{coverage} = "$co_str;$uc_str;$pc_str";
        push @cfiles, \%fdata;
    }

    my $json = encode_json( { files => \@cfiles } );
    path('cover_db/bitbucket_server.json')->spew($json);
}


1;

__END__

=pod

=head1 NAME

Devel::Cover::Report::BitBucketServer - BitBucket Server backend for Devel::Cover

=head1 SYNOPSIS

    > cover -report BitBucketServer

=head1 DESCRIPTION

This module generates an JSON file suitable for import into Bitbucket Server from an existing
Devel::Cover database.

It is designed to be called from the C<cover> program distributed with L<Devel::Cover>.

The output file will be C<cover_db/bitbucket_server.json>.

To upload the file to BitBucket Server you have to upload it via the Bitbucket Server REST API provided by the plugin
B<Code Coverage for Bitbucket Server>. Please see
L<https://bitbucket.org/atlassian/bitbucket-code-coverage/src/master/code-coverage-plugin/>
on how to do that.

B<This will not work for Bitbucket Cloud.>

=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=cut
