=encoding utf8

=head1 NAME

Finance::Bank::JP::Mizuho::Account

=head1 SYNOPSIS
    

=head1 DESCRIPTION

Account information of L<Finance::Bank::JP::Mizuho>

=head1 FUNCTIONS

=cut

package Finance::Bank::JP::Mizuho::Account;

use strict;
use warnings;

our $VERSION = '0.02';

=head2 new ( %args )

Creates a new instance.

C<%config> keys:

=over 3

=item *
B<radio_value>

Bank account number

=item *
B<branch>

Name of branch account hosted

=item *
B<type>

Account type: 普通 / 当座

=item *
B<radio_value>

A value used for getting OFX by L<Finance::Bank::JP::Mizuho>

=back

=cut

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self;
}

=head2 number

=cut
sub number { shift->{number} }

=head2 branch

=cut
sub branch   { shift->{branch}   }

=head2 type

=cut
sub type  { shift->{type}  }

=head2 radio_value

=cut
sub radio_value  { shift->{radio_value}  }

=head2 last_downloaded_from

the account's OFX downloaded from

=cut
sub last_downloaded_from  { shift->{last_downloaded_from}  }

=head2 last_downloaded_to

the account's OFX downloaded to

=cut
sub last_downloaded_to  { shift->{last_downloaded_to}  }




1

__END__

=head1 SEE ALSO

L<Finance::Bank::JP::Mizuho>

=head1 AUTHOR

Atsushi Nagase <ngs@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Atsushi Nagase <ngs@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
