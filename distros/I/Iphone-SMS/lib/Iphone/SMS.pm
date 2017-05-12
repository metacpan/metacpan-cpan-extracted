package Iphone::SMS;

use 5.006;
use strict;
use warnings FATAL => 'all';

use DBI;

use Cwd;
use File::Spec qw();
use File::Find;
use Fcntl qw(:DEFAULT :flock);

=head1 NAME

Iphone::SMS - extract sms from itunes backup files

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Extract your sms in iphone from itunes backup files
Be sure backup your iphone by itunes first

Usage:

    use Iphone::SMS;

    my $foo = Iphone::SMS->new([path]);

    path is the path where itunes backup directory lies

    or

    my $foo = Iphone::SMS->new();

    it will search the itunes default backup path

    my $sms = $foo->get_sms()



=head1 SUBROUTINES/METHODS

=head2 new

     create a iphone::sms
     my $foo = Iphone::SMS->new();

=cut

sub new {
    my ($class, $path) = @_;

    if (not defined $path){
        if ( $^O =~ /ms/i or $^O eq 'cygwin' ) {
            $path = File::Spec->catdir(
                $ENV{'HOME'}, 'AppData', 'Roaming','Apple Computer', 'MobileSync', 'Backup'
            );
        } elsif ( $^O =~ /darwin/i ) {
            $path = File::Spec->catdir(
                $ENV{'HOME'}, 'Library', 'Application Support', 'MobileSync', 'Backup'
            );
        }
    }

    if ( not -d $path ) {
        print "directory [$path] not exists.\n";
        exit;
    }

    bless { backup_path => $path }, $class;
}

=head2 get_sms

    get sms message

    return data: [{ type => 'SMS', number => 'number', message => 'content', time => 'unixtime' }, ...]

    usage: my $sms = $foo->get_sms()

=cut

sub get_sms {
    my $self = shift;
    my $messages;

    find( { wanted => sub {
                return unless file_is_sqlite($File::Find::name);
                ### $File::Find::name
                return unless find_message_table($File::Find::name);
                push @$messages, @{get_sms_message($File::Find::name)};
            },
            follow => 1,
        },
        $self->{backup_path}
    );

    my @msgs;
    for my $text ( @$messages ) {
        my ($guid, $content, $time) = @$text;
        my ($type, undef, $number) = split(/;/, $guid);
        push @msgs, {
            type => $type,
            time => $time,
            message => $content,
            number => $number,
        };
    }

    my @sms = grep { $_->{type} eq 'SMS' } @msgs;

    return \@sms;
}

sub file_is_sqlite {
    my $file = shift;

    # win seems can't open dir
    # and will give permission denied
    return 0 if -d $file or -z $file;

    sysopen my $fh, $file, O_RDONLY
        or die "can't open $file: $!";

    my $data;
    my $length = 20;
    sysread $fh, $data, 20;
    my $flag = 0;
    if ( $data =~ /sqlite/i ) {
        $flag = 1;
    }

    close $fh;
    return $flag;
}

sub get_sms_message {
    my $dbfile = shift;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");

    my $sql = qq{ select chat.guid, message.text, message.date + 978307200 as m_date \
                  from chat, message where chat.account_id=message.account_guid order by \
                  chat.guid, message.date
    };

    # apple sms time from 2001.01.01
    my $data;
    eval {
        $data = $dbh->selectall_arrayref($sql);
    };

    $dbh->disconnect();
    return $data;
}

sub find_message_table {
    my $dbfile = shift;

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","");

    my $sql = qq{SELECT name FROM sqlite_master WHERE type='table' AND name='message';};

    my $data;
    eval {
        $data = $dbh->selectall_arrayref($sql);
    };

    if ( @$data ) {
        return 1;
    }

    $dbh->disconnect();
    return 0;
}

=head1 AUTHOR

Nianhua Wei, C<< <willian.wnh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iphone-sms at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Iphone-SMS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Iphone::SMS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Iphone-SMS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Iphone-SMS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Iphone-SMS>

=item * Search CPAN

L<http://search.cpan.org/dist/Iphone-SMS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Nianhua Wei.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Iphone::SMS
