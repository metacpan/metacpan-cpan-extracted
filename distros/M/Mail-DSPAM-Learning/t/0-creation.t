#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;


# use Getopt::Long;
# use Pod::Usage;

use Mail::DSPAM::Learning;

warn "\n\n\tRunning dspam-lean version " . $Mail::DSPAM::Learning::VERSION . "\n";

# my $spam_mailbox = shift @ARGV;

warn "\tCreating DSPAM learner\n";
my $dspam_learner = Mail::DSPAM::Learning->new();

ok(defined $dspam_learner && ref $dspam_learner eq 'Mail::DSPAM::Learning',     'new() works' );


# $dspam_learner->setMailbox($spam_mailbox);

# $dspam_learner->askPassword();

# $dspam_learner->parseMailbox();

# $dspam_learner->forwardMessages();

# exit;


=head1 COMMENTS
# if (($rcfile eq "") || (!(-f $rcfile))) {
#     warn "No such config file or config file is not set\n";
#     pod2usage(1);
# } 


use Mail::MboxParser;
use Mail::Builder;
use Email::Send;
use Mail::Box::Manager;
use Term::ReadKey;


my $delay = 5;

my $password;

if (scalar (@ARGV) == 2) {
    $delay = $ARGV[1];
}

print "Password: ";
ReadMode('noecho');
$password = ReadLine(0);
chomp $password;
ReadMode('restore');

my $mgr    = Mail::Box::Manager->new;
my $folder = $mgr->open(folder => $ARGV[0]);

print STDERR "folder = $folder\n";

my $msg;
my $forward_msg;
my $i = 0;
while ($msg = $folder->message($i)) {    # $msg is a Mail::Message now
    print STDERR "message Id = " . $msg->messageId . "\n";
    $i++;

    my $preamble = Mail::Message::Body->new('data' => "This is a multi-part message in MIME format.");
    $forward_msg = $msg->forwardEncapsulate('To' => 'spam@lipn.univ-paris13.fr',
					    'From' => 'thierry.hamon@lipn.univ-paris13.fr',
					    'Cc' => 'thierry.hamon@lipn.univ-paris13.fr',
					    'Subject' => '[Fwd: ' . $msg->subject . ']',
 					    'preamble' => $preamble,
				       );

    print STDERR "\tSending the message ($i)\n";

     my $mailer = Email::Send->new({mailer => 'SMTP::TLS', 
				    mailer_args => [ 
						     'mail.lipn.univ-paris13.fr',
						     Port => 25,
						     User => 'ht',
						     Password => $password,
						     Hello => 'lipn.univ-paris13.fr',
						   ]
				    })->send($forward_msg->string);

    print STDERR "done ($mailer)\n";
    print STDERR "Sleeping for $delay second\n";
    sleep($delay);

}

exit 0;


__END__


=head1 NAME

ogmios-standalone - Perl script for linguistically annotating files
given in argument and in various format (PDF, Word, etc.).

=head1 SYNOPSIS

ogmios-standalone [options] [<] [Input_document | Directory] > Annotated_Output_Document

=head1 OPTIONS

=over 4

=item    B<--help>            brief help message

=item    B<--man>             full documentation

=item    B<--rcfile=file>     read the given configuration file

=back

=head1 DESCRIPTION

This script linguistically annotates the document given in the
standard input. Documents can be in various formats. They are firstly
converted in the ALVIS XML format.  The annotated document is sent to
the standard output.

The linguistic annotation depends on the configuration variables and
dependencies between annotation levels.

=head1 SEE ALSO

Alvis web site: http://www.alvis.info

=head1 AUTHORS

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2005 by Thierry Hamon

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
