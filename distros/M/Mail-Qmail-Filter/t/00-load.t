#!perl -T

use 5.014;
use warnings;
use Test::More;

my @modules = qw(
  Mail::Qmail::Filter
  Mail::Qmail::Filter::CheckDeliverability
  Mail::Qmail::Filter::DMARC
  Mail::Qmail::Filter::Dump
  Mail::Qmail::Filter::LogEnvelope
  Mail::Qmail::Filter::Queue
  Mail::Qmail::Filter::RequireFrom
  Mail::Qmail::Filter::RewriteFrom
  Mail::Qmail::Filter::RewriteSender
  Mail::Qmail::Filter::SkipQueue
  Mail::Qmail::Filter::SpamAssassin
  Mail::Qmail::Filter::ValidateFrom
  Mail::Qmail::Filter::ValidateSender
  MailX::Qmail::Queue::Message
);

plan tests => scalar @modules;

diag('Please ignore warning about feedback handle.');    # Better idea, anyone?
use_ok($_) for @modules;
