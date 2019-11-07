package MIME::Disclaimer;

use 5.014;
use strict;
use warnings;
use parent -norequire, 'MIME::Signature';

use MIME::Signature qw(_decoded_body _replace_body);
use Class::Method::Modifiers;

our $VERSION = '0.17';

use constant EMPTY           => '';
use constant NEWLINE         => "\n";
use constant LINEBREAK       => '<br />';
use constant HORIZONTAL_RULE => '<hr />';

around 'new' => sub {
  my $orig  = shift;
  my $class = shift;
  my %args  = @_;
  my $self  = $class->$orig(%args);

  for (qw(plain_delimiter html_delimiter enriched_delimiter)) {
    unless (exists $args{$_}) {
      my $delimiter = ($_ eq 'html_delimiter') ? LINEBREAK . HORIZONTAL_RULE : NEWLINE;
      $self->$_($delimiter);
    }
  }

  return $self;
};

around 'handler_text_enriched' => sub {
  my $orig   = shift;
  my $self   = shift;
  my $entity = shift;

  $orig->($self, $entity);

  _replace_body($entity, $self->_disclaimer('enriched') . _decoded_body($entity));
};

around 'handler_text_html' => sub {
  my $orig   = shift;
  my $self   = shift;
  my $entity = shift;

  $orig->($self, $entity);

  my $body = _decoded_body($entity);
  require HTML::Parser;
  my $new_body;
  my $parser = HTML::Parser->new(
    start_h => [
      sub {
        my ($text, $tagname) = @_;
        $new_body .= $text;
        $new_body .= $self->_disclaimer('html') if lc $tagname eq 'body';
      },
      'text,tagname'
    ],
    default_h => [sub {$new_body .= shift}, 'text'],
  );
  $parser->parse($body);
  _replace_body($entity, $new_body);
};

around 'handler_text_plain' => sub {
  my $orig   = shift;
  my $self   = shift;
  my $entity = shift;

  $orig->($self, $entity);

  _replace_body($entity, $self->_disclaimer('plain') . _decoded_body($entity));
};

sub _disclaimer {
  my ($self, $type) = @_;

  defined(my $signature = $self->$type) or return;
  my $delimiter_method = $type . '_delimiter';
  my $delimiter        = $self->$delimiter_method;

  return join(EMPTY, ($delimiter, $signature, $delimiter));
}

sub add {
  my $self = shift;
  return $self->append(@_);
}

1;

__END__

=head1 SYNOPSIS

  my $md = MIME::Disclaimer->new(
    plain => 'Disclaim this',
  );
  $md->parse( \*STDIN );
  $md->add;
  $md->entity->print;

=head1 DESCRIPTION

This module adds disclaimer text to both the beginning and ending of an
email message. It is a subclass of L<MIME::Signature>.

=head1 METHODS

=over 4

=item C<new>

Constructs a L<MIME::Disclaimer> object with the same arguments as L<MIME::Signature>
with the exception that delimiters are overwritten if not passed. The delimiters
are changed to the following:

=over 4

=item plain_delimiter: C<\n>

=item enriched_delimiter: C<\n>

=item html_delimiter: C<< <br /><hr /> >>

=back

=item C<add>

Adds the disclaimer text to both the beginning and end of the message with the
L<MIME::Signature::prepend> and L<MIME::Signature::append>.

=back

=head1 AUTHOR

Chris Scheller <schelcj@pobox.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mime-signature at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MIME-Signature>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MIME::Disclaimer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MIME-Signature>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MIME-Signature>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MIME-Signature>

=item * Search CPAN

L<https://metacpan.org/release/MIME-Signature>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Chris Scheller

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:
L<http://www.perlfoundation.org/artistic_license_2_0>
Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.
If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.
This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.
This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.
Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
