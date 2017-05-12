use strict;
package Mail::Audit::Vacation;
{
  $Mail::Audit::Vacation::VERSION = '2.228';
}
# ABSTRACT: perform vacation autoresponding
use Mail::Audit;
use vars qw($vacfile $message $subject $replyto $from);
$vacfile = ".vacation-cache";
$message = "This user is on vacation.";
$subject = "Vacation autoresponse";
$replyto = $from = "<>";

package Mail::Audit;
{
  $Mail::Audit::VERSION = '2.228';
}

sub vacation {
  my $item  = shift;
  my $where = shift;
  my $reply = $item->head->get("Reply-To")
    || $item->head->get("From");
  return if $item->head->get("Distribution") =~ /bulk/i or !$reply;
  $item->_log(1, "Vacation thing from $reply");
  if (open TOLD, $Mail::Audit::Vacation::vacfile) {
    while (<TOLD>) {
      if ($_ eq $reply) {
        $item->accept($where);
        return 1;  # Just in case.
      }
    }
  }
  if (open TOLD, ">>" . $Mail::Audit::Vacation::vacfile) {
    print TOLD $item->head->get("Reply-To")
      if $item->head->get("Reply-To");
    print TOLD $item->head->get("From")
      if $item->head->get("From");
    close TOLD;
    use Mail::Mailer qw(sendmail);
    my $out = new Mail::Mailer;
    $out->open(
      {
        From       => $Mail::Audit::Vacation::from,
        Subject    => $Mail::Audit::Vacation::subject,
        To         => $reply,
        "Reply-To" => $Mail::Audit::Vacation::replyto
      }
    );
    print $out $Mail::Audit::Vacation::message;
    $out->close;
  }
  $item->accept($where);

  return 0;
}

__END__

=pod

=head1 NAME

Mail::Audit::Vacation - perform vacation autoresponding

=head1 VERSION

version 2.228

=head1 AUTHORS

=over 4

=item *

Simon Cozens

=item *

Meng Weng Wong

=item *

Ricardo SIGNES

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Simon Cozens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
