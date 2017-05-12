package Growl::NotifySend;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp           ();
use File::Which    ();
use Encode         ();
#use Encode::Locale ();

my $encoding = Encode::find_encoding('UTF-8');

my $Command;

__PACKAGE__->command('notify-send');

sub show {
    my $class = shift;
    my %args  = ( @_ == 1 ? %{ $_[0] } : @_ );

    my @opts;
    foreach my $opt(qw(urgency expire_time icon category)) {
        if(defined $args{$opt}) {
            my $o = '--' . $opt;
            $o =~ s/_/-/g;
            push @opts, $o, $args{$o};
        }
    }

    defined(my $s = $args{summary}) or Carp::croak('You must define summary');
    defined(my $b = $args{body})    or Carp::croak('You must define body');

    my @c = map { $encoding->encode($_) } ($Command, @opts, $s, $b);
    system(@c) == 0
        or Carp::croak("Failed to call notify-send (@c)");
}

sub command {
    my($class, $name) = @_;
    $Command = File::Which::which($name)
        || Carp::croak( __PACKAGE__ . ': "$name" is not found')
            if defined $name;
    return $Command;
}

1;
__END__

=head1 NAME

Growl::NotifySend - Perl extention to do something

=head1 VERSION

This document describes Growl::NotifySend version 0.02.

=head1 SYNOPSIS

    use Growl::NotifySend;

    Growl::NotifySend->show(
        summary => 'Hey!',
        body    => 'Good morning!',
    );

=head1 DESCRIPTION

This is a wrapper to C<notify-send(1)>.

=head1 INTERFACE

=head2 C<< Growl::NotifySend->show(%args | \%args) >>

Shows a notification with I<%args> which are text strings.

=over

=item summary

The string displayed at the top of the notification.

=item body

The string displayed at the bottom of the notification.

=item urgency

The urgency level (C<low>, C<normal> or C<critical>).

=item expire_time

The timeout in milliseconds at which to expire the notification.

=item category

The notification category.

=back

=head1 DEPENDENCIES

Perl 5.8.1 or later, and C<notify-send(1)> included in the C<libnotify-bin>
package.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Growl::Any>

L<notify-send(1)>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Fuji, Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
