package MailBot::Util;

require Exporter;
@ISA = qw( Exporter );
@EXPORT_OK = qw( d );

use strict;

my $DEBUG = 1;
my $CONSOLE = 0;

sub d
{
    &MailBot::Util::debug(@_);
}

sub debug
{
    return unless $DEBUG;

    if ($CONSOLE)
    {
	print STDERR @_, "\n";
    }
    else
    {
	my $config = MailBot::Config::current();
	$config -> log(@_);
    }
}

sub erasePattern
{
    my $message = shift;
    my $pattern = shift;

    my $paBody = $message -> body;
    my $body = join('',@$paBody);
    $body =~ s/$pattern//m
	or return 0;

    my @newBody = split(/^/m,$body);

    $message -> body(\@newBody);
    1;
}

sub setBeginPattern
{
    my $message = shift;
    my $beginPattern = shift;

    &erasePattern($message,"(.|\n)*$beginPattern");
}

sub setEndPattern
{
    my $message = shift;
    my $endPattern = shift;

    &erasePattern($message,"$endPattern(.|\n)*");
}

sub fold
{
    my $message = shift;

    my $paBody = $message -> body;
    my $body = join('',@$paBody);
    my @newBody = split(/^/m,$body);
    $message -> body(\@newBody);
}

sub messageToArray
{
    my $internet = shift;

    (@{$internet -> head -> {'mail_hdr_list'}},
     "\n",
     @{$internet -> body});
}

1;
