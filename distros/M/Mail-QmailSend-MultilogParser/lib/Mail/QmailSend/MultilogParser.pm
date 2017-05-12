package Mail::QmailSend::MultilogParser;

use strict;
use warnings;

our $VERSION = '0.03';

sub new {
    my ($class, %args) = @_;
    my $self = { callback => undef, %args };
    bless $self, $class;
}

sub parse {
    my ($self, $fh) = @_;

    my(%msg, %dline, $inode, $delnum);
    while (<$fh>) {
	chomp;
	if (m/([^ ]+( [^ ]+)?) new msg (\d+)/) {
	    $inode = $3;
	    $msg{$inode}{time_new} = $1;
	    push @{$msg{$inode}{logs}}, $_;
	} elsif (m/[^ ]+ info msg (\d+): bytes \d+ from <([^>]+)?> qp \d+ uid \d+/) {
	    $inode = $1;
	    $msg{$inode}{from} = $2;
	    push @{$msg{$inode}{logs}}, $_;
	} elsif (m/[^ ]+ starting delivery (\d+): msg (\d+) to (remote|local) ([^ ]+)/) {
	    $inode = $2;
            $delnum = $1;
	    $dline{$delnum} = $2;
	    $msg{$inode}{msgnum} = $2;
	    $msg{$inode}{delivery}{$delnum}{delnum} = $delnum;
	    $msg{$inode}{delivery}{$delnum}{tochan} = $3;
	    $msg{$inode}{delivery}{$delnum}{rcpt} = $4;
	    push @{$msg{$inode}{logs}}, $_;
	} elsif (m/([^ ]+( [^ ]+)?) delivery (\d+): ([^:]+): (.+)/) {
	    if (exists $dline{$3} && length $dline{$3}) {
                $delnum = $3;
		$inode = $dline{$delnum};
		$msg{$inode}{delivery}{$delnum}{action} = $4;
		$msg{$inode}{delivery}{$delnum}{reason} = $5;
		push @{$msg{$inode}{logs}}, $_;
		delete $dline{$delnum};
	    }
	} elsif (m/([^ ]+( [^ ]+)?) end msg (\d+)/) {
	    $inode = $3;
	    push @{$msg{$inode}{logs}}, $_;
	    unless (exists $msg{$inode}{time_new}) {
		delete $msg{$inode};
		next;
	    }
	    $msg{$inode}{time_end} = $1;
	    my $data = {
                        msgnum    => $msg{$inode}{msgnum},
                        time_new  => $msg{$inode}{time_new},
                        time_end  => $msg{$inode}{time_end},
                        from      => $msg{$inode}{from} || '(null)',
                        delivery  => [ map { $msg{$inode}{delivery}{$_} } keys %{$msg{$inode}{delivery}} ],
                        logs      => $msg{$inode}{logs},
                    };
            $self->{callback}->($data) if defined $self->{callback};
	    delete $msg{$inode};
	}
    }
}

1;
__END__

=head1 NAME

Mail::QmailSend::MultilogParser - Parse qmail-send multilog files

=head1 SYNOPSIS

  use Mail::QmailSend::MultilogParser;
  use YAML;

  my $parser = Mail::QmailSend::MultilogParser->new(callback => sub { print YAML::Dump(@_) });
  $parser->parse(\*STDIN);

=head1 DESCRIPTION

This module parses qmail-send logs in multilog formats.

=head1 AUTHOR

Masahito Yoshida E<lt>masahito@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Masahito Yoshida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

=head1 SEE ALSO

L<http://cr.yp.to/qmail.html>
L<http://cr.yp.to/daemontools/multilog.html>

=cut
