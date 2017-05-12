use strict;
package Email::LocalDelivery::Store;
our $VERSION = '0.01';
use File::Path qw(mkpath);
use File::Basename qw( dirname );

=head1 NAME

Email::LocalDelivery::Store - deliver mail via L<Email::Store>

=head1 SYNOPSIS

 use Email::LocalDelivery;
 use Email::FolderType::Register qw[register_type];
 register_type Store => sub { $_[0] =~ m/^DBI/i }; 
 ...
 Email::LocalDelivery->deliver($mail, $dsn) or die "couldn't deliver to $dsn";

 ...where $dsn is a full DBI DSN, including user= and password=, e.g.
 'DBI:mysql:database=DATABASE;host=HOSTNAME;port=PORT;user=USER;password=PASSWORD'

=head1 DESCRIPTION

This module is an Email::LocalDelivery wrapper for L<Email::Store>, 
which is a "framework for database-backed email storage." 

It allows you to easily swap in database email storage instead of Mbox or Maildir. 

Just register the "Store" FolderType, like this:

=over
use Email::FolderType::Register qw[register_type];
register_type Store => sub { $_[0] =~ m/^DBI/i }; 
=back

and then call Email::LocalDelivery->deliver( $mail, $dsn )

This module was created to allow L<Siesta> to archive mail in MySQL. 

=head1 METHODS

=head2 deliver( $rfc822, @dsns )

C<$rfc822> is an RFC822 formatted email message, and C<@dsns> is a list of DBI DSN strings.

Since Email::Store is instantiated with the DSN, and I really don't know what I'm doing, 
I had to eval 'use Email::Store $dsn' inside the deliver() method. 
I suspect that this will blow up if you try to pass more than one DSN, so I made it exit after the first one. 

=head1 ATTENTION

L<Email::Store> (obviously) requires some form of database backend. 
Since you will have already figured all that out, this module doesn't test your database connection itself. 

=cut

sub deliver {
    my ($class, $mail, @dsns) = @_;

    my @delivered;
    for my $dsn (@dsns) {
	eval "use Email::Store '$dsn'";
        my $stored = Email::Store::Mail->store($mail);
        push @delivered, $stored;
	last;
    }
    return @delivered;
}

1;
__END__


=head1 AUTHOR

Bowen Dwelle <bowen@dwelle.org>
http://www.dwelle.org/

=head1 COPYRIGHT

Copyright (C) 2004 Bowen Dwelle.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<siesta|http://siesta.unixbeard.net/>, L<Email::LocalDelivery>,
L<Email::FolderType>, L<Email::Store>

=cut

