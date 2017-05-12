#!/usr/bin/perl
use strict;
use warnings;
use Mail::ThreadKiller;

sub usage
{
	print STDERR <<"EOF";
Usage: $0 path_to_db msgid1 [msgid2... ]

Adds all listed msgids to the database of threads to kill.
EOF
}


if (!$ARGV[0] || !$ARGV[1]) {
	usage();
	exit(1);
}

my $tk = Mail::ThreadKiller->new();
$tk->open_db_file($ARGV[0]);
shift;
foreach my $msgid (@ARGV) {
	$msgid = "<$msgid" unless ($msgid =~ /^</);
	$msgid = "$msgid>" unless ($msgid =~ />$/);
	$tk->add_message_id($msgid);
	print "Added $msgid\n";
}
$tk->close_db_file();
exit(0);

__END__

=head1 NAME

threadkiller-kill-msgids.pl - Add one or more Message-IDs to the kill database

=head1 USAGE

    threadkiller-kill-msgids.pl /path/to/database.db msgid1 [msgid2 ... ]

=head1 DESCRIPTION

Adds all of the supplied Message-IDs to the kill database.  This will cause
all messages referring to those IDs to be flagged for killing.

=head1 AUTHOR

Dianne Skoll <dfs@roaringpenguin.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Roaring Penguin Software Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

threadkiller-clean-db.pl, Mail::ThreadKiller

