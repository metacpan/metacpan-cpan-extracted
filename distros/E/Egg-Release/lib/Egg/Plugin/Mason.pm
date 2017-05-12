package Egg::Plugin::Mason;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Mason.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.01';

sub mason {
	$_[0]->{mason} ||= Egg::Plugin::Mason::handler->new(@_);
}

package Egg::Plugin::Mason::handler;
use strict;
use base qw/ Egg::Base /;

__PACKAGE__->mk_accessors(qw/
  attr code_first code_action code_final is_error
  is_complete complete_topic complete_info
  /);

sub prepare {
	my $ms= shift;
	my $attr= $_[0] ? ($_[1] ? {@_}: $_[0]): {};
	my $e= $ms->e;
	$e->page_title($attr->{page_title}) if $attr->{page_title};
	$e->response->no_cache(1) if $attr->{no_cache};
	if (my $expir= $attr->{expires}) {
		$e->response->is_expires($expir);
		$e->response->last_modified($expir);
	}
	if (my $dbname= $attr->{commit_ok}) {
		$e->dbh($dbname eq '1' ? undef: $dbname)->commit_ok(1);
	}
	$ms->{code_first} = $attr->{code_first}  || sub { 0 };
	$ms->{code_action}= $attr->{code_action} || sub { 0 };
	$ms->{code_final} = $attr->{code_final}  || sub { 0 };
	$ms->{attr}= $attr;
	$ms;
}
sub exec {
	$_[0]->code_first->() || $_[0]->code_action->() || $_[0]->code_final->();
}
sub complete {
	my $ms= shift;
	$ms->{complete_topic}= shift || q{Complete !!};
	$ms->{complete_info}= shift
	     || q{<p class="info"><a href="/">Please click.</p>};
	$ms->{is_complete}= 1;
}
sub error_complete {
	my $ms= shift;
	$ms->{complete_topic}= shift || q{Sorry !!};
	$ms->{complete_info} = shift
	     || q{<p class="info"><a href="/">Please click.</p>};
	$ms->{is_error}= 1;
	shift || 0;
}

1;

__END__

=head1 NAME

Egg::Plugin::Mason - Plugin for Egg::View::Mason 

=head1 SYNOPSIS

  package MyApp;
  use Egg qw/
    Mason
    Net::Scan
    MailSend
    FillInForm
    /;

Example template 

  <%init>
  my $ms= $e->mason->prepare(
    page_title => 'Hoge',
    no_cache   => 1,
    commit_ok  => 1,
    );
  $ms->code_first(sub {
    my $scan= $e->port_scan(qw/ 192.168.1.1 25 /);
    return 0 if $scan->is_success;
    $ms->complete('Mail host is stopping.');
   });
  $ms->code_action(sub {
    $e->referer_check(1) || return 0;
    ............
    ....
    $e->mail->send;
    $ms->complete('Mail was sent.');
   });
  $ms->code_final(sub {
    $e->fillin_ok(1);
   });
  $ms->exec;
  </%init>
  %
  <html>
  <body>
  % if ($ms->is_complete) {
    <h1><% $ms->complete_topic %></h1>
  % } else {
    <form method="POST" action= ...... >
    .........
    ....
    </form>
  % } # $ms->complete end.
  </body>
  </html>

=head1 DESCRIPTION

It is a plugin convenient when using it with the template of L<HTML::Mason>.

First of all, a basic setting is done by the prepare method.

And, the code reference defined to 'code_first', 'code_action', 'code_final' as
call the exec method is evaluated and processing is completed.

=head1 METHODS

=head2 mason

Egg::Plugin::Mason::handler オブジェクトを返します。

=head1 HANDLER METHODS

L<Egg::Base> has been succeeded to.

=head2 prepare ([ATTR_HASH])

Prior is set.

As for ATTR_HASH, the following keys are accepted.

  my $ms= $e->mason->prepare(
    page_title => 'home page',
    expires    => '+1D',
    );

=over 4

=item * page_title

It is a character string set to $e-E<gt>page_title.

=item * no_cache 

$e-E<gt>response-E<gt>no_cache is set.

=item * expires

$e-E<gt>response-E<gt>is_expires and $e-E<gt>response-E<gt>last_modified are set.

=item * commit_ok

$e-E<gt>dbh-E<gt>commit_ok is done.

Only being able to use L<Egg::Model::DBI> is effective.

=item * code_first, code_action, code_final

The code reference processed with exec is set.

=back

=head2 exec

The code of code_first, code_action, and code_final set beforehand is processed.

When undefined is returned, each code interrupts processing by the code.

  $e->exec;

=head2 code_first, code_action, code_final

Accessor to code reference to process it with exec.

=head2 complete ([TOPIC_STR], [INFO_STR])

The completion message etc. are set and '1' is returned.

The default when TOPIC_STR is not obtained is 'Complete !!'.

The default when INFO_STR is not obtained is
  'E<lt>p class="info"E<gt>E<lt>a href="/"E<gt>Please click.E<lt>/pE<gt>'.

  $e->complete('is completed', <<END_INFO);
  <a href="/">It returns to top page.</a>
  END_INFO

=head2 error_complete ([TOPIC_STR], [INFO_STR])

The completion message etc. are set and 0 is returned.

The default when TOPIC_STR is not obtained is 'Sorry !!'.

Default when INFO_STR is not obtained is
  'E<lt>p class =" info "E<gt>E<lt>a href ="/"E<gt>Please click.E<lt>/pE<gt>'.

  my $data= $e->get_data || return $e->error_complete('is error.', <<END_INFO);
  <h2>The error occurred.</h2>
  <p><a href="/">It returns to top page.</a></p>
  END_INFO

=head2 is_complete

If 'complete' method is called, it becomes effective.

=head2 is_error

If 'error_complete' method is called, it becomes effective.

=head2 complete_topic

The first argument of 'complete' method or 'error_complete' method is set.

=head2 complete_info

The second argument of 'complete' method or 'error_complete' method is set.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Base>,
L<HTML::Mason>, 

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

