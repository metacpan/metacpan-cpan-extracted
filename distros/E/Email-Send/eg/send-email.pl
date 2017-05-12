#!/usr/local/bin/perl
use strict;
$^W = 1;

use Email::Send;
use Getopt::Long;

GetOptions my $options = {
   header => {},
   body   => [],
}, 'via=s',
   'to=s@', 'from=s', 'cc=s@', 'bcc=s@',
   'subject=s',
   'header=s%',
   'body=s@',
   'dump';

my $sender  = $options->{via} or die "No Sender set with -via\n";
my @sargs   = @ARGV;
my @headers;

push @headers, "From: $options->{from}" if $options->{from};
foreach (qw[to cc bcc]) {
    next unless $options->{$_} && @{$options->{$_}};
    push @headers, join ': ',
                        ucfirst($_),
                        join(', ', @{$options->{$_}});
}
push @headers, "Subject: $options->{subject}" if $options->{subject};

while (my($k,$v) = each %{$options->{header}}) {
    push @headers, "$k: $v";
}

my $body = join "\r\n", @{$options->{body}};
$body = join "\r\n", map {chomp; $_} <STDIN> unless $body;

my $message = join "\r\n", join("\r\n", @headers, ''), $body, '';

print join $message, (join(' Message ', ('-'x20)x2) . "\n")x2
  if $options->{dump};

print "Send Command: Email::Send->new({
    mailer      => '$sender',
    mailer_args => [". join(', ', map "'$_'", @sargs) ."],
})->send(\$message);\n" if $options->{dump};

my $mailer = Email::Send->new({
    mailer      => $sender,
    mailer_args => \@sargs,
});
my $rv = $mailer->send($message);

if ( $options->{dump} ) {
    use Data::Dumper;
    print "Email::Send::send() results: " . Dumper $rv;
}

__END__

=pod

=head1 NAME

send-email.pl - Simple program that helps test senders

=head1 SYNOPSIS

  send-email.pl -via Sender
                -to Address
                -from Address
                -cc Address
                -bcc Address
                -subject 'Subject Line'
                -header Key=Value
                -body Line
                Sender Args

=head1 EXAMPLE

  perl ./send-email.pl -via SMTP
                       -header X-Test=hello
                       -to 'casey@example.com'
                       -from 'casey@example.com'
                       -body "Hi there"
                       -body "New Line"
                       mx.example.com Debug 1

