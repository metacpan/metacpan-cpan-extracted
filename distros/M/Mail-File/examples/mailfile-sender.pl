#!/usr/bin/perl -w
use strict;

use vars qw($VERSION);
$VERSION = '0.03';

=head1 NAME

mailfile-sender - script to read plain text mail files and send via SMTP.

=head1 SYNOPSIS

  perl mailfile-sender.pl

=head1 DESCRIPTION

This scripts searches for a list of plain text mail files, parses each
one and mails them via SMTP.

=cut

# -------------------------------------
# Library Modules

use File::Find::Rule;
use Net::SMTP;
use IO::File;
use Getopt::Long;

# -------------------------------------
# Variables

my %settings = (
	smtp	=> 'smtp.myisp.co.uk',
	from	=> '-',
	path	=> '/tmp/mailfiles',
	extn	=> 'eml',
);

my $count = 0;
my $emailregx = qr/(\w[-._\w]*\w\@\w[-._\w]*\w\.\w{2,3})/;

# -------------------------------------
# The Program

our ($opt_s, $opt_f, $opt_p, $opt_e, $opt_h);
GetOptions(	
	'smtp|s=s'		=> \$opt_s, 
	'from|f=s'		=> \$opt_f, 
	'path|p=s'		=> \$opt_p, 
	'extension|e=s'	=> \$opt_e,
	'help|h'		=> \$opt_h,
);

if ( $opt_h ) {
	print <<HERE;
Usage: $0 [-s smtp] [-f from] [-p path] [-e extn] [-h]
  -s smtp   address of SMTP server
  -f from   'name <name@example.com>' string of sender
  -p path   path to the directory when mail files reside
  -e extn   extension used for mail files
  -h        this help screen
HERE
	exit 1;
}

$opt_s ||= $settings{smtp};
$opt_f ||= $settings{from};
$opt_p ||= $settings{path};
$opt_e ||= $settings{extn};

die "Error: invalid mail-file directory [$opt_p]\n"	unless(-d $opt_p);

# find all the mail-file files in the mail store
my @files = File::Find::Rule->file()->name( '*.'.$opt_e )->in( $opt_p );

foreach my $file (@files) {
	my $fh = IO::File->new($file);
	unless($fh) {
		warn "Warning: Cannot access file [$file]: $!\n";
		next;
	}

	my @lines = <$fh>;
	my $lines = join('',@lines);

	my ($from) = ($lines =~ /\bFrom:\s+(.+)\Z/m);
	my ($recipient) = ($lines =~ /\bTo:\s+$emailregx/m);
	my ($subject) = ($lines =~ /\bSubject:\s+(.*?)\Z/m);

	$opt_f = $from	if($opt_f eq '-');

	my $smtp = Net::SMTP->new($opt_s);
    $smtp->mail($opt_f);

	next	unless($smtp->to($recipient));

#	print STDERR "Mail: [$file] [$subject]\n";

	# send the message
    $smtp->data();
    $smtp->datasend(@lines);
    $smtp->dataend();
    $smtp->quit;
}

print STDERR "$count files sent\n";

__END__

=head1 SEE ALSO

  File::Find::Rule
  Net::SMTP
  IO::File
  Getopt::Long

=head1 AUTHOR

Barbie, C< <<barbie@cpan.org>> >
for Miss Barbell Productions, L<http://www.missbarbell.co.uk>

Birmingham Perl Mongers, L<http://birmingham.pm.org/>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003-2005 Barbie for Miss Barbell Productions

  This distribution is free software; you can redistribute it and/or 
  modify it under the same terms as Perl itself.

=cut
