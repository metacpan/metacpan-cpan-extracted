# Copyrights 2001-2023 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Wrapper::SpamAssassin;
use vars '$VERSION';
$VERSION = '3.010';

use base 'Mail::SpamAssassin::Message';

use strict;
use warnings;

use Carp;
use Mail::Message::Body;

BEGIN
{   my $v = $Mail::SpamAssassin::VERSION;
    die "ERROR: spam-assassin version $v is not supported (only versions 2.x)\n"
       if $v >= 3.0;
}

#------------------------------------------


sub new(@)    # fix missing infra-structure of base element
{   my ($class, $message, %args) = @_;

    $_->delete for $message->head->spamGroups('SpamAssassin');

    $class->SUPER::new( {message => $message} )->init(\%args);
}

sub init($) { shift }

sub create_new() {croak "Should not be used"}

sub get($) { $_[0]->get_header($_[1]) }

sub get_header($)
{   my ($self, $name) = @_;
    my $head = $self->get_mail_object->head;

    # Return all fields unfolded in list context
    return map { $_->unfoldedBody } $head->get($name)
        if wantarray;

    # Only one field is expected
    my $field = $head->get($name);
    defined $field ? $field->unfoldedBody : undef;
}

sub get_pristine_header($)
{   my ($self, $name) = @_;
    my $field = $self->get_mail_object->head->get($name);
    defined $field ? $field->foldedBody : undef;
}

sub put_header($$)
{   my ($self, $name, $value) = @_;
    my $head = $self->get_mail_object->head;
    $value =~ s/\s{2,}/ /g;
    $value =~ s/\s*$//;      # will cause a refold as well
    return () unless length $value;

    $head->add($name => $value);
}

sub get_all_headers($)
{   my $head = shift->get_mail_object->head;
    "$head";
}

sub replace_header($$)
{   my $head = shift->get_mail_object->head;
    my ($name, $value) = @_;
    $head->set($name, $value);
}

sub delete_header($)
{   my $head = shift->get_mail_object->head;
    my $name = shift;
    $head->delete($name);
}

sub get_body() {shift->get_mail_object->body->lines }

sub get_pristine() { shift->get_mail_object->head->string }

sub replace_body($)
{   my ($self, $data) = @_;
    my $body = Mail::Message::Body->new(data => $data);
    $self->get_mail_object->storeBody($body);
}

sub replace_original_message($)
{   my ($self, $lines) = @_;
    die "We will not replace the message.  Use report_safe = 0\n";
}

1;
