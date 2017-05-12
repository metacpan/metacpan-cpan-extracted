use strict;
package Mail::Audit::List;
{
  $Mail::Audit::List::VERSION = '1.853';
}
# ABSTRACT: Mail::Audit plugin for automatic list delivery
use Mail::Audit 2.217;

package
  Mail::Audit;

use Mail::ListDetector;
my $DEFAULT_DIR = $ENV{HOME} . "/mail";

sub list_accept {
  my ($self, $dir, $arg) = @_;

  $dir ||= $DEFAULT_DIR;
  $arg ||= {};

  my $list = Mail::ListDetector->new($self);

  if (!(defined $list)) {
    return 0;
  } else {
    my $name = $list->listname;
    $name =~ tr/A-Za-z0-9_-//dc;
    $name = $arg->{munge_name}->($name) if $arg->{munge_name};
    return 0 unless $name;
    my $deliver_filename = join '/', $dir, $name;
    $self->accept($deliver_filename);
    return $deliver_filename;
  }
}

1;

__END__

=pod

=head1 NAME

Mail::Audit::List - Mail::Audit plugin for automatic list delivery

=head1 VERSION

version 1.853

=head1 SYNOPSIS

    use Mail::Audit qw(List);
    my $mail = Mail::Audit->new;
    ...
    $mail->list_accept || $mail->accept;

=head1 DESCRIPTION

This is a Mail::Audit plugin which provides a method for automatically
delivering mailing lists to a suitable mainbox. It requires the CPAN
C<Mail::ListDetector> module.

=head2 METHODS

=over 4

=item C<list_accept($delivery_dir, \%arg)>

Attempts to deliver the message as a mailing list. It will place each 
message in C<$deliver_dir/$list_name>. The default value of C<$deliver_dir>
is C<$ENV{HOME} . "/mail">.

For instance, mail to C<perl5-porters@perl.org> will end up by default in
F</home/you/mail/perl5-porters>. 

Calls C<accept> and returns the filename delivered to if
C<Mail::ListDetector> can identify this mail as coming from a mailing
list, or 0 otherwise. 

Valid named arguments are:

  munge_name - a coderef called to munge the name given by Mail::ListDetector

Note that if you want to use the defailt delivery location, but also to pass
args, you must call the method like this:

  $audit->list_accept(undef, { ... });

The recipe given above should be able to replace a great number of
special-casing recipes.

=back

=head1 SEE ALSO

L<Mail::Audit>

=head1 AUTHOR

Michael Stevens <michael@etla.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Michael Stevens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
