package Email::Abstract::QpsmtpdTransaction;
use strict;
use warnings;
our $VERSION = '0.02';

use Email::Abstract::Plugin;

BEGIN {
    @Email::Abstract::QpsmtpdTransaction::ISA = 'Email::Abstract::Plugin';
};

sub target { "Qpsmtpd::Transaction" }

sub construct {
    die "doesn't support now.";
}

sub get_header {
    my ($class, $obj, $header) = @_;
    $obj->header($header);
}

sub get_body {
    my ($class, $obj) = @_;
    $obj->body_as_string();
}

sub set_header {
    my ($class, $obj, $header, @data) = @_;
    $obj->header($header, @data);
}

sub set_body {
    die "doesn't support now.";
}

sub as_string {
    my ($class, $obj) = @_;
    
    if ($obj->{_body_file}) {
        open(my $fh, '<', $obj->body_filename) or die $!;
        my $source = do { local $/; <$fh> };
        close $fh;
        return $source;
    } else {
        return join "", @{ $obj->{_body_array} };
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Email::Abstract::QpsmtpdTransaction - Email::Abstract wrapper for Qpsmtpd::Transaction

=head1 SYNOPSIS

  use Email::Abstract;
  my $email = Email::Abstract->new($transaction)->cast('Email::MIME');
  
  $email->as_string;
  $email->parts;

=head1 DESCRIPTION

Email::Abstract::QpsmtpdTransaction wraps Qpsmtpd::Transaction mail handling library
with an abstract interface, to be used with L<Email::Abstract>.

=head1 *UN*SUPPORTED METHODS

=over 4

=item C<set_body>

=item C<constract>

This means you can cast Qpsmtpd::Transaction to some object
supported by Email::Abstract, but cannot cast Email::Abstract-ed object
to Qpsmtpd::Transaction. Patches are welcome ;)

=back

=head1 SEE ALSO

L<http://coderepos.org/share/browser/lang/perl/Email-Abstract-QpsmtpdTransaction> (repository)

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
