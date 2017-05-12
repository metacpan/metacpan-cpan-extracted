package Mail::ListDetector::Detector::Fml;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.04';

use base qw(Mail::ListDetector::Detector::Base);
use URI;
use Email::Valid;
use Carp;

sub DEBUG { 0 }

sub match {
    my($self, $message) = @_;
    print "Got message $message\n" if DEBUG;
    carp ("Mail::ListDetector::Detector::Fml - no message supplied") unless defined($message);
    my $mlserver = Email::Abstract->get_header($message, 'X-MLServer') or return;
    $mlserver =~ /^fml \[(fml [^\]]*)\]/ or return;

    # OK, this is FML message
    my $list = Mail::ListDetector::List->new;
    $list->listsoftware($1);

    my $post;
    if ($post = Email::Abstract->get_header($message, 'List-Post')) {
        chomp($post);
        $post = URI->new($post)->to;
    } elsif ($post = Email::Abstract->get_header($message, 'List-Subscribe')) {
        chomp($post);
        $post = URI->new($post)->to;
        $post =~ s/-ctl\@/\@/;
    } elsif ($post = Email::Abstract->get_header($message, 'X-ML-Info')) {
        chomp($post);
        $post =~ s/\n/ /;
        $post =~ m/(<.*>)/;
        $post = $1;
        $post = URI->new($post)->to;
        $post =~ s/-admin\@/\@/;
    } elsif ($post = Email::Abstract->get_header($message, 'Resent-To')) {
        chomp($post);
        $post =~ m/([\w\d\+\.\-]+@[\w\d\.\-]+)/;
        $post = $1;
    }

    if ($post && Email::Valid->address($post)) {
        $list->posting_address($post);
    }

    my $mlname;
    if ($mlname = Email::Abstract->get_header($message, 'X-ML-Name')) {
        chomp($mlname);
        $list->listname($mlname);
    } elsif ($mlname = $list->posting_address) {
        $mlname =~ s/\@.*$//;
		$list->listname($mlname);
    }
        

    $list;
}

1;
__END__

=head1 NAME

Mail::ListDetector::Detector::Fml - FML message detector

=head1 SYNOPSIS

  use Mail::ListDetector::Detector::Fml;

=head1 DESCRIPTION

Mail::ListDetector::Detector::Fml is an implementation of a mailing
list detector, for FML. See http://www.fml.org/ for details about FML.

When used, this module installs itself to Mail::ListDetector. FML
maling list message is RFC2369 compliant, so can be matched with
RFC2369 detector, but this module allows you to parse more FML
specific information about the mailing list.

=head1 METHODS

=over 4

=item new, match

Inherited from L<Mail::ListDetector::Detector::Base>

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mail::ListDetector>

=cut
