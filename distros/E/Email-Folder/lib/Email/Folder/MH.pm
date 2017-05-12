use strict;
use warnings;
package Email::Folder::MH;
{
  $Email::Folder::MH::VERSION = '0.860';
}
# ABSTRACT: reads raw RFC822 mails from an mh folder

use Carp;
use IO::File;
use Email::Folder::Reader;
use parent 'Email::Folder::Reader';


sub _what_is_there {
    my $self = shift;
    my $dir = $self->{_file};

    croak "$dir does not exist"     unless (-e $dir);
    croak "$dir is not a directory" unless (-d $dir);

    my @messages;
                opendir(DIR,"$dir") or croak "Could not open '$dir'";
                foreach my $file (readdir DIR) {
                    if ($^O eq 'VMS'){
                        next unless $file =~ /\A\d+\.\Z/;
                    } else {
                        next unless $file =~ /\A\d+\Z/;
                    }
                    push @messages, "$dir/$file";
                }

    $self->{_messages} = \@messages;
}

sub next_message {
    my $self = shift;
    my $what = $self->{_messages} || $self->_what_is_there;

    my $file = shift @$what or return;
    local *FILE;
    open FILE, $file or croak "couldn't open '$file' for reading";
    join '', <FILE>;
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Email::Folder::MH - reads raw RFC822 mails from an mh folder

=head1 VERSION

version 0.860

=head1 SYNOPSIS

This isa Email::Folder::Reader - read about its API there.

=head1 DESCRIPTION

It's yet another email folder reader!  It reads MH folders.

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

