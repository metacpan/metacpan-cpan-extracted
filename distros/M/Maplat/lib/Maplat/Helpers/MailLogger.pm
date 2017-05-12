# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::MailLogger;
use strict;
use warnings;

# This file does major layouting. So, allow magic numbers
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use 5.010;

use base qw(Exporter);
#our @EXPORT= qw();

our $VERSION = 0.995;

use Maplat::Helpers::Strings qw(tabsToTable);
use Maplat::Helpers::DateStrings;
use Mail::Sendmail;
use MIME::QuotedPrint;
use MIME::Base64;
use PDF::Report;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{debugdata} = 0;
    foreach my $key (qw[file subject server port sender reciever debugdata]) {
        $self->{$key} = $args{$key};
    }
    $self->{active} = 0;
    return $self;
}

sub start {
    my ($self) = shift;
    open($self->{fh}, ">", $self->{file}) or return 0;
    my @temp;
    $self->{loglines} = \@temp;
    $self->{active} = 1;
    $self->{errors} = 0;
    $self->{warnings} = 0;
    
    if($self->{debugdata}) {
        $self->warn("Logging DEBUG data, logfile may get HUGE!");
    }
    return;
}

sub finish {
    my ($self) = shift;
    return 0 if(!$self->{active});
    
    $self->{active} = 0;
    
    my $csvmessage = "Time;Warnlevel;Text\n";
    my $textmessage = "The operation has produced the following status messages:\n" .
            $self->{errors} . " error(s)\n" .
            $self->{warnings} . " warning(s)\n" .
            "\n" .
            "Following if a detailed log of actions taken:\n";
    
    my $boundary = "====" . time() . "====";        
    foreach my $line (@{$self->{loglines}}) {
        #$message .= "$line\n";
        $textmessage .= tabsToTable($line, (21, 9)) . "\n";
        my $tmpline = $line;
        $tmpline =~ s/\t/\;/go;
        $csvmessage .= "$tmpline\n";
    }
    $textmessage = encode_qp($textmessage);
    $csvmessage = encode_base64($csvmessage);
    my $pdfmessage = encode_base64($self->makePDF());
    
    my $message = "--$boundary\n" .
                "Content-Type: text/plain; charset=\"iso-8859-1\"\n" .
                "Content-Transfer-Encoding: quoted-printable\n" .
                "\n" .
                "$textmessage\n" .
                "\n" .
                "CSV/Excel version of the log:\n" .
                "--$boundary\n" .
                "Content-Type: text/csv; name=\"Status_Report.csv\"\n" .
                "Content-Transfer-Encoding: base64\n" .
                "Content-Disposition: attachment; filename=\"Status_Report.csv\"\n" .
                "\n" .
                "$csvmessage\n" .
                "--$boundary\n" .
                "Content-Type: text/plain; charset=\"iso-8859-1\"\n" .
                "Content-Transfer-Encoding: quoted-printable\n" .
                "\n" .
                "\n" .
                "PDF/Printable version of the log:\n" .
                "--$boundary\n" .
                "Content-Type: application/pdf; name=\"Status_Report.pdf\"\n" .
                "Content-Transfer-Encoding: base64\n" .
                "Content-Disposition: attachment; filename=\"Status_Report.pdf\"\n" .
                "\n" .
                "$pdfmessage\n" .
                "--$boundary--\n";

    my $subject = $self->{subject};
    if($self->{errors}) {
        $subject = "[ERROR] $subject";
    } elsif($self->{warnings}) {
        $subject = "[WARNING] $subject";
    }
    
    my %mail = (To              => $self->{reciever},
                From            => $self->{sender},
                Subject         => $subject,
                Message         => $message,
                Server          => $self->{server},
                Port            => $self->{port},
                'X-Mailer'      => "Maplat Mail-Logger",
                'content-type'  => "multipart/mixed; boundary=\"$boundary\"",
                
                
                );

    if(!sendmail(%mail)) {
        print {$self->{fh}} "Can't send status mail: " . $Mail::Sendmail::error . "\n"; ## no critic (Variables::ProhibitPackageVars)
    } else {
        print {$self->{fh}} "Status mail sent";
    }

    
    close($self->{fh});
    return 1;
    
}

sub logLine {
    my ($self, %args) = @_;
    return 0 if(!$self->{active});
    my $date = getISODate();
    my $logline = "$date\t" . uc($args{level}) . "\t" . $args{text};
    if(uc($args{level}) eq "ERROR") {
        $self->{errors}++;
    } elsif(uc($args{level}) eq "WARNING") {
        $self->{warnings}++;
    }
    print {$self->{fh}} "$logline\n";
    print tabsToTable($logline, (21, 9)) . "\n";
    push @{$self->{loglines}}, $logline;
    return 1;
}

sub debug {
    my ($self, $text) = @_;
    return 1 if(!$self->{debugdata});
    return $self->logLine(level    => 'DEBUG',
                        text     =>  $text);
}

sub info {
    my ($self, $text) = @_;
    return $self->logLine(level    => 'INFO',
                        text     =>  $text);
}

sub warning {
    my ($self, $text) = @_;
    return $self->logLine(level    => 'WARNING',
                        text     =>  $text);
}

sub error {
    my ($self, $text) = @_;
    return $self->logLine(level    => 'ERROR',
                        text     =>  $text);
}

sub makePDF {
    my $self = shift;
    
    my $pdf = PDF::Report->new(PageSize          => "A4", 
                                PageOrientation => "Portrait",
                                );
    
    my ($pagewidth, $pageheight) = $pdf->getPageDimensions();
    
    my $pagecount = 1;
    
    #$pdf->newpage();
    $pdf->newpage(1);
    
    my $z = $pageheight;
    
    foreach my $line (@{$self->{loglines}}) {
        if($z < 50) {
            $pagecount++;
            $pdf->newpage($pagecount);
            $pdf->openpage($pagecount);
            $z = $pageheight;
        }
        if($z == $pageheight) {
            $pdf->setFont('Arial');
            $pdf->setSize(20);
            $z -= 30;
            $pdf->addRawText("Maplat Status Report", 20, $z, "black");
            #$pdf->addImg("pdf_logo.bmp", $pagewidth-100, $z+15);
            $z -= 35;
            $pdf->setFont('Arial');
            $pdf->setSize(10);

        }
        my @parts = split/\t/, $line;
        my $wcol = "black";
        if($parts[1] eq "WARNING") {
            $wcol = "orange";
        } elsif($parts[1] eq "ERROR") {
            $wcol = "red";
        }
        $pdf->drawLine(18, $z, $pagewidth - 18, $z);
        $pdf->drawLine(18, $z, 18, $z-14);
        $pdf->drawLine(138, $z, 138, $z-14);
        $pdf->drawLine(198, $z, 198, $z-14);
        $pdf->drawLine($pagewidth - 18, $z, $pagewidth - 18, $z-14);
        $pdf->drawLine(18, $z-14, $pagewidth - 18, $z-14);
        $pdf->addRawText($parts[0], 20, $z - 12, $wcol);
        $pdf->addRawText($parts[1], 140, $z - 12, $wcol);
        $pdf->addRawText($parts[2], 200, $z - 12, $wcol);
        $z -= 14;
    }

    for(my $i = 1; $i <= $pagecount; $i ++) {
        $pdf->openpage($i);
        $pdf->addRawText("Page $i / $pagecount", 450, 30, "grey");
    }
    
    return $pdf->Finish();   

}

1;
__END__

=head1 NAME

Maplat::Helpers::MailLogger - Logger on steroids

=head1 SYNOPSIS

  use Maplat::Helpers::MailLogger;
  
  my $logger = new Maplat::Helpers::MailLogger(
                file        => "tempfilename",
                subject     => "Automated mail for yada yada",
                server      => "mail.example.com",
                port        => 25,
                sender      => 'mytool@example.com',
                reciever    => 'user@example.com',
                debugdata   => 1
  );

  while($something) {
    ...
    if($error) {
      $logger->error($errortext);
    }
    ...
    # something *might* be wrong
    $logger->warn("Bistromatic drive needs recalibration");
    ...
    # Log some information
    $logger->info("Fuel level: $remainfuel");
    # and some debig info
    $logger->debug("Module foo has version $bar");
    ...
  }
  $logger->finish; # Finish up log and send it.

=head1 DESCRIPTION

This Module provides an easy way log information and send it as multipart
mail with with a text log, CSV log attachment and a color-coded PDF version.

=head2 new

  my $logger = new Maplat::Helpers::MailLogger(
                file        => "tempfilename",
                subject     => "Automated mail for yada yada",
                server      => "mail.example.com",
                port        => 25,
                sender      => 'mytool@example.com',
                reciever    => 'user@example.com',
                debugdata   => 1
  );

Most options are self explaining (you might also see Mail::Sendmail for details).
$file is the base filename used for the logfiles.
$debugdata is a boolean and determines, if debug() lines are included in the mailed
report.

=head2 start

Start logging.

=head2 debug

Takes one argument, a string. Logs this string with the level DEBUG.

=head2 info

Takes one argument, a string. Logs this string with the level INFO.

=head2 warning

Takes one argument, a string. Logs this string with the level WARNING.

=head2 error

Takes one argument, a string. Logs this string with the level ERROR.

=head2 finish

Finished up the report and sends it. It is prudent to discard the $logger object after
a call to finish. Continuing to use the logger after a call to finish will not work and/or
may have some undesired side effects.

=head2 logLine

Internal helper function.

=head2 makePDF

Internal helper function.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
