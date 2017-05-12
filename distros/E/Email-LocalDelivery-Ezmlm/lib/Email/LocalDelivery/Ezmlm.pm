use strict;
package Email::LocalDelivery::Ezmlm;
our $VERSION = '0.10';
use File::Path qw(mkpath);
use File::Basename qw( dirname );

=head1 NAME

Email::LocalDelivery::Ezmlm - deliver mail into ezmlm archives

=head1 SYNOPSIS

 use Email::LocalDelivery;
 Email::LocalDelivery->deliver($mail, "/some/box//") or die "couldn't deliver";

=head1 DESCRIPTION

This module delivers RFC822 messages into ezmlm-style archive folders.

This module was created to allow easy interoperability between
L<Siesta> and L<colobus>.  Colobus is an nntp server which uses ezmlm
archives as its message store.

=head1 METHODS

=head2 ->deliver( $message, @folders )

used as a class method.  returns the names of the files ultimately
delivered to

=cut

sub deliver {
    my ($class, $mail, @folders) = @_;

    my @delivered;
    for my $folder (@folders) {
        # trim the identifier off, as mkpath doesn't get on with it
        $folder =~ s{//?$}{};
        # XXX should lock the folder - figure out how ezmlm does that

        my $num;
        if (open my $fh, "$folder/num") {
            ($num) = (<$fh> =~ m/^(\d+)/);
        }
        ++$num;

        my $filename = sprintf('%s/archive/%d/%02d',
                               $folder, int $num / 100, $num % 100);
        eval { mkpath( dirname $filename ) };
        open my $fh, ">$filename" or next;
        print $fh $mail;
        close $fh or next;

        open $fh, ">$folder/num" or do { unlink $filename; next };
        print $fh "$num\n";
        close $fh or die "couldn't rewrite '$folder/num' $!";
        push @delivered, $filename;
    }
    return @delivered;
}

1;
__END__


=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net> based on the source of
C<colobus> by Jim Winstead Jr.

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<colobus|http://trainedmonkey.com/colobus/>, L<Email::LocalDelivery>,
L<Email::FolderType>

=cut

