use 5.014;
use warnings;

package Mail::Qmail::Filter::Graylist;

our $VERSION = '0.12';

use Mo qw(coerce default required);
extends 'Mail::Qmail::Filter';

has defer_text => 'You have been graylisted. Please try again later.';
has dir        => required => 1;
has min_secs   => 300;

sub filter {
    my $self      = shift;
    my $message   = $self->message;
    my $mail_from = $message->from;

    require Path::Tiny and Path::Tiny->import('path') unless defined &path;

    my ( $sender_localpart, $sender_domain ) =
      length $mail_from
      ? split /\@/, lc $mail_from, 2
      : ('_none') x 2;
    my $remote_ip = $message->remote_ip;

    my $passed = 0;
    my @to     = $message->to;
  Rcpt: for ( $message->to ) {
        my ( $rcpt_localpart, $rcpt_domain ) = split /\@/, lc, 2;
        my $graylist_file = path( $self->dir, map y/0-9A-Za-z._-/_/cr,
            $rcpt_domain, $rcpt_localpart, $sender_domain, $sender_localpart );
        if ( $graylist_file->exists ) {
            {
                my $fh = $graylist_file->openr;
                local $_;
                while (<$fh>) {
                    /^\Q$remote_ip\E / or next;
                    chomp;
                    $self->debug( 'known' . ( @to > 1 && " for $_" ) );
                    ++$passed;
                    next Rcpt;
                }
            }
            if ( $^T - $graylist_file->stat->mtime >= $self->min_secs ) {
                $graylist_file->append(
                    "$remote_ip " . $message->remote_host . "\n" );
                ++$passed;
                $self->debug( 'allowed' . ( @to > 1 && " for $_" ) );
                next Rcpt;
            }
            else {
                $self->debug( 'too recent' . ( @to > 1 && " for $_" ) );
            }
        }
        else {
            $graylist_file->parent->mkdir;
            $graylist_file->openw;
        }
    }
    return if $passed == @to;
    $self->defer( $self->defer_text );
}

1;

__END__

=head1 NAME

Mail::Qmail::Filter::Graylist -
spamdyke compatible graylisting

=head1 SYNOPSIS

    use Mail::Qmail::Filter;

    Mail::Qmail::Filter->new->add_filters(
        '::Graylist' => {
            dir => '/var/qmail/spamdyke/graylist',
        },
        '::Queue',
    )->run;

=head1 DESCRIPTION

This L<Mail::Qmail::Filter> plugin tries to implement a graylisting which
is compatible to that of L<Spamdyke|https://www.spamdyke.org> as regards
the file based store used.

=head1 REQUIRED PARAMETERS

=head2 dir

base directory for the graylist database

=head1 OPTIONAL PARAMETERS

=head2 min_secs

minimum amount of time in seconds an entry must exist before it is valid

Default: 300

=head1 SEE ALSO

L<Mail::Qmail::Filter/COMMON PARAMETERS FOR ALL FILTERS>

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Martin Sluka.

This module is free software; you can redistribute it and/or modify it
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
