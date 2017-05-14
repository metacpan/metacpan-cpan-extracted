package Log::SelfHistory;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(writeCmd);

our $VERSION = '0.01';

my $PWD = `pwd`;
my $DATE = `date`;
my $USER = `whoami`;
my $SCRIPT = $0;
$SCRIPT =~ s/\.?//;
$SCRIPT =~ s/\/?//;
my $sComment = '#--------------------------------------------------';

chomp($PWD); chomp($DATE); chomp($USER);

sub countCmds {
	my $iCount = `grep -E \"Executed(.*) on\" $PWD/$SCRIPT -c`;

	if ($iCount !~ /(\d+)/sg) {
		return 0;
	} else {
		return $1;
	}
}

sub earseCmds {
	my ($iMaxCount, $iActualCount) = @_;

	if ($iActualCount >= $iMaxCount) {
	`sed '/\^\#Executed.*/d' -i $PWD/$SCRIPT`;
	`sed '/\^\#----.*/d' -i $PWD/$SCRIPT`
	}
}

sub writeCmd {
	my ($TAG, $iMaxCount) = @_;

	my $iCount = countCmds(); chomp($iCount);
	earseCmds($iMaxCount, $iCount);
	my $ARGUMENTS = join(' ', @ARGV);
    my $sCMD = "sed 's|\^\#$TAG.*|\#$TAG \\n$sComment\\n\#";
    $sCMD .= "Executed Cmd:\" $PWD/$SCRIPT $ARGUMENTS\\n\#Executed on:";
    $sCMD .=  "$DATE\\n\#Executed by: $USER\\n$sComment|' -i $PWD/$SCRIPT";
    `$sCMD`;
}

1;

=head1 NAME

Log::SelfHistory - Perl extension for logging self execution history. 

=cut

=head1 SYNOPSIS

  use Log::SelfHistory;
  writeCmd("CMD",3); 

  Where:
  "CMD" is the tag in the caller script to place execution history.
  we can place this tag in script were we want execution history to 
  be displayed.

  "3" is no of exectuions to log, so after 3 exectuions the log history
  will be reset.

  Example: 
  
  #Contents is test.pl(caller script).

  use Log::SelfHistory;
  writeCmd("CMD",3);

  #CMD (!!!Please note here the tag is put in form of comment!!!).
  

=cut

=head1 DESCRIPTION

Log self execution history in the caller script itself.
Also control the number of exectuions logged.

****** Module Works on Unix Boxes Only *******

=cut


=head1 AUTHOR

Tushar, tushar@cpan.org
=cut 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Tushar Murudkar 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

