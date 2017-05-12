package Log::Log4perl::Appender::SMTP;

our @ISA = qw(Log::Log4perl::Appender);

use strict;
use warnings;
use Carp;
use Net::Domain 'hostfqdn';
use Net::SMTP;

our $VERSION = '0.03';

sub new {
	my($class, @options) = @_;

	my $hname = hostfqdn() || '<unknown>';
	my $user  = getlogin || getpwuid($<) || 'log4perl';

	return bless {
		from    => $user.'@'.$hname,
		to      => 'postmaster',
		subject => "Subject: Log4perl from $hname\n",
		Host    => 'localhost',
		@options
	}, $class;
}

sub log {
	my ($self, %params) = @_;

	my $smtp = Net::SMTP->new(%$self) or return
		carp "log4perl: could not connect to the SMTP server";

	$smtp->mail($self->{from}) or return
		carp "log4perl: sender rejected: $self->{from}";

	$smtp->to($self->{to}) or return
		carp "log4perl: recipient(s) rejected: $self->{to}";

	$smtp->data;
	$smtp->datasend("From: ".$self->{from}."\n");
	$smtp->datasend("To: ".$self->{to}."\n");
	$smtp->datasend("Subject: ".$self->{subject}."\n");
	$smtp->datasend("\n" . $params{message} . "\n");
	$smtp->dataend or carp "log4perl: message could not be sent by smtp";
	$smtp->quit;
}

1;

__END__

=encoding utf8

=head1 NAME

Log::Log4perl::Appender::SMTP - Send logs by email

=head1 SYNOPSIS

  use Log::Log4perl::Appender::SMTP;

  my $app = Log::Log4perl::Appender::SMTP->new(
    Host    => "localhost",
    Hello   => "localhost.localdomain",
    Timeout => 2,
    Debug   => 0,
    from    => "app@company.com",
    to      => "bugs@company.com"
  );

  $app->log(message => "You need to come to the office now!");

=head1 DESCRIPTION

This appender is a very thin layer over the Net::SMTP module. It allows
you to easily send important log messages by email, to one or several
recipients. All of the L<Net::SMTP> attributes are supported.

=head1 OPTIONS

=over 2

=item B<from>

The email address of the sender.

=item B<to>

The email address of the recipient. You can put several addresses separated
by a comma.

=item B<subject>

The subject of the email. Newlines and tabs are forbidden here.

=item B<all of the Net::SMTP options>

They all start with an upper-cased letter. The most common are Host, Hello,
Port, Timeout and Debug. See L<Net::SMTP> for more.

=back

=head1 EXAMPLE

The following Log4perl configuration file allows you to send an email on
each use of C<< $log->fatal() >>.

  # Filter for FATAL
  log4perl.filter.MatchFatal = Log::Log4perl::Filter::LevelMatch
  log4perl.filter.MatchFatal.LevelToMatch  = FATAL
  log4perl.filter.MatchFatal.AcceptOnMatch = true

  # Email Appender for FATAL
  log4perl.appender.mailFatal = Log::Log4perl::Appender::SMTP
  log4perl.appender.mailFatal.to = webmaster@company.com
  log4perl.appender.mailFatal.Host = smtp.company.com
  log4perl.appender.mailFatal.subject = Fatal error on Foo!
  log4perl.appender.mailFatal.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.mailFatal.layout.ConversionPattern = %d F{1} %L %p> %m%n
  log4perl.appender.mailFatal.Filter = MatchFatal

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-log4perl-appender-smtp at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Log4perl-Appender-SMTP>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Olivier Duclos, C<< <odc at cpan.org> >>

=head1 LICENSE

Copyright 2014 Olivier Duclos.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Log4perl>, L<Net::SMTP>
