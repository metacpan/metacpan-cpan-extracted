#!/usr/bin/perl
use strict;
use warnings;
use Mail::ThreadKiller;

sub usage
{
	print STDERR <<"EOF";
Usage: $0 path_to_db n

Delets all msgids in the database that are older than n days.
EOF
}


if (!$ARGV[0] || !defined($ARGV[1])) {
	usage();
	exit(1);
}

if ($ARGV[1] !~ /^\d+$/) {
	usage();
	exit(1);
}

my $tk = Mail::ThreadKiller->new();
$tk->open_db_file($ARGV[0]);
my $num = $tk->clean_db($ARGV[1]);
$tk->close_db_file();
print "Cleaned $num " . ($num == 1 ? 'entry' : 'entries') . " from database.\n";
exit(0);

__END__

=head1 NAME

threadkiller-clean-db.pl - Delete old entries from the kill database

=head1 USAGE

    threadkiller-clean-db.pl /path/to/database.db n

=head1 DESCRIPTION

Removes all messages from the kill database that have not been seen in
n days

=head1 AUTHOR

Dianne Skoll <dfs@roaringpenguin.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Roaring Penguin Software Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

threadkiller-kill-msgids.pl, Mail::ThreadKiller
