use strict;
use warnings;
package Email::Folder::Ezmlm;
{
  $Email::Folder::Ezmlm::VERSION = '0.860';
}
# ABSTRACT: reads raw RFC822 mails from an ezmlm archive

use Carp;
use Email::Folder::Maildir;
use parent 'Email::Folder::Maildir';

# we're a little complicit, just redefining an internal method, but
# that's fine, we maintain both piles :)

sub _what_is_there {
    my $self = shift;
    my $dir = $self->{_file};

    croak "$dir does not exist"           unless (-e $dir);
    croak "$dir is not an ezmlm archive"  unless (-d $dir);
    croak "$dir is not an ezmlm archive"  unless (-e "$dir/archive" && -d "$dir/archive");

    my $num;
    if (my $fh = IO::File->new("$dir/num")) {
        ($num) = (<$fh> =~ m/^(\d+)/);
    }

    $self->{_messages} = [ map {
        sprintf '%s/archive/%d/%02d', $dir, int $_ / 100, $_ % 100
    } 1..$num ];
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Email::Folder::Ezmlm - reads raw RFC822 mails from an ezmlm archive

=head1 VERSION

version 0.860

=head1 AUTHORS

=over 4

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Richard Clamp <richardc@unixbeard.net>

=item *

Pali <pali@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Simon Wistow.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

