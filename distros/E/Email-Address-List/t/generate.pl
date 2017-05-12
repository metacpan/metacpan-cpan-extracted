use strict; use warnings; use autodie; use lib 'lib/';
use Email::Address::List;

foreach my $file (qw(t/data/RFC5233.single.valid.txt t/data/RFC5233.single.obs.txt)) {
    process_file($file);
}

sub process_file {
    my $file = shift;
    open my $fh, '<', $file;
    my @list = split /(?:\r*\n){2,}/, do { local $/; <$fh> };
    close $fh;

    my %CRE = %Email::Address::List::CRE;

    foreach my $e (splice @list) {
        my ($desc, $mailbox) = split /\r*\n/, $e, 2;
        $desc =~ s/^#\s*//;

        my %res = (
            description => $desc,
            mailbox     => $mailbox,
        );

        my @parse;
        unless ( @parse = ($mailbox =~ /^($CRE{'mailbox'})$/) ) {
            unless ( @parse = ($mailbox =~ /^($CRE{'obs-mailbox'})$/) ) {
                warn "Failed to parse $mailbox";
                next;
            }
        }

        my (undef, $display_name, $local_part, $domain, @comments)
            = Email::Address::List->_process_mailbox( @parse );

        $res{'display-name'} = $display_name;
        $res{'address'} = "$local_part\@$domain";
        $res{'domain'} = $domain;
        $res{'local-part'} = $local_part;
        $res{'local-part'} =~ s/\\(.)/$1/g if $res{'local-part'} =~ s/^"(.*)"$/$1/;
        $res{'comments'} = \@comments;
        push @list, \%res;
    }

    use JSON;
    $file =~ s/txt$/json/;
    open $fh, '>', $file;
    print $fh JSON->new->pretty->encode(\@list);
    close $fh;
}