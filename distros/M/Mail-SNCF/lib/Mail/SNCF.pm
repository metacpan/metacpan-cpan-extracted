package Mail::SNCF;

use warnings;
use strict;

use Data::Dump qw/dump/;

use Email::Folder;
use MIME::QuotedPrint;

=head1 NAME

Mail::SNCF - A parser for booking messages sent by the French rail company

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This module is not intended to be used directly, instead, use
L<SNCF::Ical>, L<SNCF::Text> or L<SNCF::Remind>.

    use Mail::SNCF::Backend;

    my $foo = Mail::SNCF::Backend->parse("Mail/sncf");
    $foo->print;

=head1 FUNCTIONS

=head2 parse

Parse a mail box (as supported by L<Email::Folder>) and create the
object.

=cut

sub parse {
    my ($class, $folder_path) = @_;
    my $folder = Email::Folder->new($folder_path);

    my $self = [];
    bless $self, $class;

    while (my $a = $folder->next_message()) {
		my $subject = $a->header("Subject");
        next unless $subject =~ /Confirmation.*(commande|voyage).*/;
        my @lines = split /\n/, $a->body();
        for(my $i = 0; $i < @lines; $i++) {
            next unless $lines[$i] =~ /=A0------------------------------------------------/;
            next unless $lines[++$i] =~ /=A0TRAIN/;
            while ($lines[$i] !~
					/=A0------------------------------------------------/)
			{
				$i++;
			}
            my $line_from = decode_qp($lines[++$i]);
            my $line_to = decode_qp($lines[++$i]);

            my $trip = {};
            
            $line_from =~ m!\s*:\s*((?:\w|\s)*\w)\s*-\s*(\d\d)h(\d\d)\s*-\s*(\d\d)/(\d\d)/(\d\d\d\d)!;
            $trip->{from}  = $1;
            $trip->{start} = [$2, $3];
            $trip->{date}  = [$4, $5, $6];
            
            $line_to =~ m!\s*:\s*((?:\w|\s)*\w)\s*-\s*(\d\d)h(\d\d)!;
            $trip->{to}  = $1;
            $trip->{end} = [$2, $3];

            push @{$self}, $trip;
        }
    }

    return $self;
}

=head2 file

Output to a file.

=cut

sub file {
    my ($self, $file) = @_;
    open FILE, ">", $file;
    print FILE $self->as_string;
    close FILE;
}

=head2 print

Print the data returned by as_string.

=cut

sub print {
    my ($self) = @_;
    print $self->as_string;
}

=head2 as_string

Give a string representation of the data.

=cut

sub as_string {
    my ($self) = @_;
    dump($self);
}

=head1 AUTHOR

Olivier Schwander, C<< <iderrick at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mail-sncf at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mail-SNCF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mail::SNCF

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mail-SNCF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mail-SNCF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mail-SNCF>

=item * Search CPAN

L<http://search.cpan.org/dist/Mail-SNCF>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Olivier Schwander, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Mail::SNCF
